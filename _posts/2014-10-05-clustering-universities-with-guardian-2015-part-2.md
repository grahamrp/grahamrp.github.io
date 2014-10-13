---
layout: post
title: "University Clustering using the Guardian University Guide 2015: Part 2"
date: 2014-10-05 
thumbnail: assets/clusterthumbnail.png
---

This is the second in a two-part series of posts about clustering universities using data from the Guardian University Guide 2015. I'll be addressing the following

- Are there any clear clusters of universities based on the Guardian metrics?
- If so, do the clusters have any interesting characteristics?

In [Part 1]({% post_url 2014-09-14-clustering-universities-with-guardian-2015-part-1 %}) I described the hierarchical clustering technique and the use of dendrograms to visualise the results. Now in Part 2 I'll prepare the university data, cluster the universities, and look at the results.

A full explanation of the Guardian's measures is provided [here](http://www.theguardian.com/education/2014/jun/03/how-to-use-guardian-university-guide) but briefly the 8 measures are:

- **Course satisfaction**: the percentage of final-year students who agree with the statement "Overall, I am satisfied with the quality of the course" in the [National Student Survey](http://www.thestudentsurvey.com)(NSS).
- **Teaching quality**: the percentage of final-year students satisfied with the teaching they received, based on 4 related NSS questions
- **Feedback**: the percentage of final-years satisfied with feedback and assessment by lecturers, based on 5 related NSS questions
- **Staff/student ratio**: the number of students per member of teaching staff
- **Spend**: the amount of money spent on each student, given as a rating out of 10
- **Average entry tariff**: the average [UCAS tariff](http://www.ucas.com/how-it-all-works/explore-your-options/entry-requirements/ucas-tariff) scores for new students
- **Value-added**: a score from 1 - 10 representing the extent to which students enter the university with relatively low qualifications and graduate with high ones
- **Career**: the percentage of graduates who find graduate-level jobs, or are studying further, within six months of graduation, as determined by the [Destinations of Leavers Survey](https://www.hesa.ac.uk/index.php?option=com_content&view=article&id=1899&Itemid=634)

Preparing the data
------------------

The Guardian do a great job of providing their university data in an easy to use format. The 2014 data are provided on the Guardian [Datablog](http://www.theguardian.com/news/datablog) via a Google Doc [here](https://docs.google.com/spreadsheets/d/1BY2Slb3OEr_Pl1CVmxE4nWTZDxu1FSTP0FXyPU2lLYI/edit?pli=1), which can be downloaded as an Excel&reg; workbook.

The data need a bit of preparation before clustering. Firstly the data need to be liberated from the Excel workbook and then the "Ranking" column needs to be parsed. This column contains rankings for the last three years in the format "rank2013  → rank2014 → rank2015", which needs to be split out into separate columns. The rankings might not be used for this analysis, but it doesn't hurt to parse them into a useable format. Also the column headings will be given more succinct names.


{% highlight r %}
# load required packages
library(XLConnect)  # for reading Excel
library(stringr)  # string manipulation
library(stringi)  # for character encoding conversion
library(dplyr)  # data manipulation
library(reshape2)  # data manipulation
library(ggplot2)  # data visualisation
library(ape)  # producing nice cluster diagrams
library(knitr)  # for table formatting (kable)
{% endhighlight %}


{% highlight r %}
wb2015 <- loadWorkbook("data/originals/Undergraduate Guardian University Guide 2015.xlsx")
table2015 <- readWorksheet(wb2015, sheet = "Institution", header = TRUE, startRow = 3)

# split out column 1 into 3 columns
mat <- matrix(unlist(strsplit(table2015$Ranking, " → ")), ncol = 3, byrow = TRUE)
table2015$Ranking <- NULL  # delete original composite column
df <- as.data.frame(mat)
colnames(df) <- c('rank2013','rank2014','rank2015')
table2015 <- cbind(df, table2015)
# convert ranks from text to numbers
table2015$rank2013 <- as.numeric(as.character(table2015$rank2013))
table2015$rank2014 <- as.numeric(as.character(table2015$rank2014))
table2015$rank2015 <- as.numeric(as.character(table2015$rank2015))

names(table2015) <- c('rank13','rank14','rank15','institution','score','nss.teach',
                      'nss.all','spend','ssr','career','value','tariff','nss.feedback')

# replace Glyndŵr with Glyndwr since cluster plotter does not like it
table2015$institution <- stri_trans_general(table2015$institution, 'Latin-ASCII')

# remove University Campus Suffolk since it does not have a full set of measures
table2015 <- table2015[table2015$institution != 'University Campus Suffolk', ]
{% endhighlight %}

The data now look like this:


{% highlight r %}
kable(head(table2015), format = 'markdown')
{% endhighlight %}



| rank13| rank14| rank15|institution      | score| nss.teach| nss.all| spend|   ssr| career| value| tariff| nss.feedback|
|------:|------:|------:|:----------------|-----:|---------:|-------:|-----:|-----:|------:|-----:|------:|------------:|
|      1|      1|      1|Cambridge        | 100.0|     91.09|   90.23| 9.675| 11.57|  85.76| 5.953|  615.8|        72.35|
|      2|      2|      2|Oxford           |  94.4|     92.46|   90.65| 9.900| 11.00|  78.73| 7.259|  580.1|        71.43|
|      4|      4|      3|St Andrews       |  92.4|     94.09|   92.04| 7.489| 11.77|  79.60| 7.735|  523.3|        75.68|
|      9|      7|      4|Bath             |  83.4|     92.49|   93.69| 5.885| 16.63|  83.40| 6.288|  489.4|        74.37|
|     13|      9|      5|Imperial College |  82.9|     88.18|   87.32| 8.351| 11.66|  87.83| 6.378|  576.3|        69.22|
|     12|      8|      6|Surrey           |  82.5|     91.44|   90.94| 7.488| 15.43|  73.30| 6.659|  422.3|        74.10|

The data are ready to be put into the right shape for hierarchical clustering. This means creating a new dataframe containing just the measures used to produce the scores (not the overall score or the rankings), and *scaling* these scores so that they are all on a comparable scale. Without scaling the scores universities would be considered equally far apart if they had a difference of 10 in student satisfaction or 10 in UCAS tariff points, but a 10 percentage point difference in satisfaction is huge whereas a 10 point increase in average UCAS tariff pretty small.


{% highlight r %}
clustdata <- table2015
# move institution names to rownames
row.names(clustdata) <- paste0(clustdata$institution, ' (', clustdata$rank15, ')')
#row.names(clustdata) <- clustdata$institution

# remove superflous columns
to_keep <- c('nss.teach','nss.all','spend','ssr','career','value','tariff','nss.feedback')
clustdata <- clustdata[, to_keep]

# invert the student/staff ratio to be staff/student ratio
# the result is that for all measures "higher is better"
# this is not necessary for clustering but might be useful in later analyses
clustdata$ssr <- 1 / clustdata$ssr

# scale the data (subtract mean and then divide by standard deviation)
scaled <- as.data.frame(scale(clustdata))
{% endhighlight %}

The data now look like this:


{% highlight r %}
kable(round(head(scaled),1), format = 'markdown')
{% endhighlight %}



|                     | nss.teach| nss.all| spend| ssr| career| value| tariff| nss.feedback|
|:--------------------|---------:|-------:|-----:|---:|------:|-----:|------:|------------:|
|Cambridge (1)        |       1.4|     1.2|   2.6| 2.3|    2.0|   0.4|    3.1|          0.4|
|Oxford (2)           |       1.8|     1.3|   2.7| 2.6|    1.3|   1.7|    2.7|          0.2|
|St Andrews (3)       |       2.3|     1.6|   1.3| 2.1|    1.4|   2.2|    2.0|          1.2|
|Bath (4)             |       1.8|     2.0|   0.4| 0.1|    1.8|   0.7|    1.6|          0.9|
|Imperial College (5) |       0.5|     0.5|   1.8| 2.2|    2.2|   0.8|    2.6|         -0.4|
|Surrey (6)           |       1.5|     1.4|   1.3| 0.5|    0.8|   1.1|    0.7|          0.8|

Now that the data are scaled it's actually easier to compare institutions with each other and across the measures. The scores are now "number of standard deviations from the average", with positive values being above average and negative below. We can see from the top 6 universities above nearly all the scores are above average, as would be expected from the top performers, with one interesting exception that Imperial College scores just below average on NSS Feedback (-0.4 on the scaled score). Across measures it's easy to see which are the really strong points for an institution, for example Cambridge are only just above average on *value* (0.4) but are exceptionally high on *tariff* (3.1).

Clustering
----------

The first step in hierarchical clustering is to calculate the distances between universities using the 8 measures in the dataset. The resultant distance matrix is then fed into the clustering function and the results are plotted.


{% highlight r %}
distances <- dist(scaled)
hcluster <- hclust(distances)
plot(hcluster,
     cex = 0.8,  # reduce size of labels
     ann = FALSE)  # remove annotations
{% endhighlight %}

![center](/../figs/2014-10-05-clustering-universities-with-guardian-2015-part-2/basic_cluster.png) 

### How many clusters?

The number of clusters shown by the dendrogram above is somewhat subjective, and dependent on what we want to use the results for. I want to see if there are relatively large groupings of universities -- whether or not they fit into a small number of "types". It looks to me as though there are 2 or 3 clusters. Slicing across the graph at 10 on the y-axis would break the dendrogram into the 2 most distinct clusters, and slicing across the graph at about 7 would break the dendrogram into 3 clusters:


{% highlight r %}
par(mfcol = c(1, 2))  
# highlight 2 clusters
plot(hcluster,
     labels = FALSE,  # remove institution labels
     ann = FALSE)  # remove annotations
rect.hclust(hcluster, k = 2) 
title('Main 2 clusters', cex.main = 0.8)

# highlight 3 clusters
plot(hcluster,
     labels = FALSE,  # remove labels
     ann = FALSE)  # remove annotations
rect.hclust(hcluster, k = 4) 
title('Main 3 clusters', cex.main = 0.8) 
{% endhighlight %}

![center](/../figs/2014-10-05-clustering-universities-with-guardian-2015-part-2/show_clusters.png) 

Taking a look at the main dendrogram we can see that the 2-cluster solution has identified the cluster of very strong institutions on the left, and "everyone else" on the right. The 3-cluster solution separates institutions into the very strong group on the left, a weaker group to the right of it, and "everyone else" further to the right. Interpreting the dataset as 4, 5 or more clusters could also yield some interesting groups.

A closer look at the clusters
-----------------------------

In order to investigate the clusters more fully I will switch to a more flexible plotting function provided by the `ape` package, which will allow colours to be added to encode additional information, and some cosmetic changes too.

To get a feel for the strong/weaker makeup of the groups I will colour the labels according to the overall league table position. I will also flip the diagram on its side to make reading the institution names easier.


{% highlight r %}
colfunc <- colorRampPalette(c("black", "gray92"))  # colour gradient from dark to light
# institutions are in rank order so the colours can be passed directly to the plot
plot(as.phylo(hcluster), type = 'phylo', cex = 0.5, 
     tip.color = colfunc(nrow(scaled)),  
     font = 1, rotate.tree = 10, no.margin = TRUE)
{% endhighlight %}

![center](/../figs/2014-10-05-clustering-universities-with-guardian-2015-part-2/colour_by_rank.png) 

As we might expect, the best-performing institutions can be seen clearly, at the bottom of the dendrogram as a band of dark grey. These fall into a distinct cluster since they will tend to perform well on all measures. Likewise, the adjacent light-grey band above it shows the worst-performing institutions, who tend to perform poorly on all measures. The remaining institutions are a bit more varied, perhaps excelling in one area but not doing so well in another, hence they are more "distant" from each other and appear as a less-distinctive cluster.

Another interesting cluster is the three institutions at the bottom -- King's College London, UCL and Edinburgh. These actually appear as a separate cluster if the dendrogram is split into 4. Taking a look at the standardised scores it looks as if these universities share higher than average scores in most of the measures, but worse than average in student satisfaction, particularly satisfaction with feedback (Edinburgh has the worst in the league).


{% highlight r %}
kable(scaled[grepl('College London|UCL|Edinburgh$', table2015$institution), ], 
      format = 'markdown')
{% endhighlight %}



|                           | nss.teach| nss.all|  spend|   ssr| career|  value| tariff| nss.feedback|
|:--------------------------|---------:|-------:|------:|-----:|------:|------:|------:|------------:|
|UCL (11)                   |   -0.2753| -0.4544| 2.0238| 3.181|  1.592| 1.1801|  1.944|       -2.089|
|Edinburgh (18)             |   -0.5608| -0.7709| 2.3065| 1.088|  1.023| 0.9973|  1.548|       -3.743|
|King's College London (40) |    0.0937| -0.5479| 0.7777| 2.335|  1.682| 0.6893|  1.305|       -1.292|

Colouring by University group
-----------------------------

Many universities belong to "mission groups" that have similar market positions and ambitions. I thought it would be interesting to add some of the common mission groups to the clustering to see if there are any patterns. The groups I've selected are:

 - [Russell](https://en.wikipedia.org/wiki/Russell_Group): Research-intensive group of 24 institutions
 - [1994](https://en.wikipedia.org/wiki/1994_Group): Group of smaller research-intensive institutions, dissolved late 2013 but still useful as a grouping for this analysis
 - [Million+](https://en.wikipedia.org/wiki/Million%2B): Think-tank of 22 newer universities and colleges
 - [GuildHE](https://en.wikipedia.org/wiki/GuildHE): Group of newer universities and colleges tending to be smaller and having a specialism, e.g. art and design or sports
 - [University Alliance](https://en.wikipedia.org/wiki/University_Alliance): Group of newer universities focussing on the professions, science/tech and design, often keen on business engagement and employability of graduates.
 
 The following plot shows the same dendrogram, but this time coloured by the university mission group (or grey if the university does not belong to any of the above groups).


{% highlight r %}
uni_groups <- read.delim('data/originals/University Groups.csv', 
                         stringsAsFactors = FALSE)
# replace Glyndŵr with Glyndwr to match league table dataframe
uni_groups$institution <- stri_trans_general(uni_groups$institution, 'Latin-ASCII')

table2015$group <- uni_groups[match(table2015$institution, uni_groups$institution), 
                              'group']

# vector of colours
group_colours <- data.frame(
  colour = c('grey','magenta','brown','navy','royalblue1','orange1'),
  group = c('','Million','Guild','Russell','1994','Alliance'), stringsAsFactors = F)

cols <- group_colours$colour[match(table2015$group, group_colours$group)]

plot(as.phylo(hcluster), type = 'phylo', cex = 0.5, 
     tip.color = cols,  
     font = 1, rotate.tree = 10, no.margin = TRUE)
legend('topleft', legend = group_colours$group, col = group_colours$colour, 
       fill = group_colours$colour, bty = 'n', border = 0, cex = 0.5)
{% endhighlight %}

![center](/../figs/2014-10-05-clustering-universities-with-guardian-2015-part-2/coloured_by_group.png) 

The university names have been plotted over each other a bit because I am more concerned with the overall colours than any specific institution. What shows through quite clearly is the separation between the research-focussed groups (Russell, 1994) in blue vs. the others. There are two blue bands, one at the bottom in the high-performing cluster, and another nearer the top. Institutions not belonging to a group are spread throughout the clustering, and the Million+/GuildHE/Alliance groups tend to be fairly evenly mixed.

It can be difficult to differentiate between each cluster using the dendrogram above. It is also important to remember that the ordering of institutions in the dendrogram above is arbitrary, what matters is how they are connected to each other via the lines. As an alternative method of plotting, the `ape` packages gives more flexibility in presenting these hierarchical relationships. Plotting the universities in a radial layout helps to separate the groups out, and also has the benefit of making the y-axis unambiguously meaningless.


{% highlight r %}
plot(as.phylo(hcluster), type = 'un', cex = 0.4, 
     tip.color = cols, lab4ut = 'axial', 
     font = 1, rotate.tree = 10, mar = c(0, 0, 1, 0))
legend('topleft', legend = group_colours$group, fill = group_colours$colour, 
       bty = 'n', border = 0, cex = 0.5)
title('Coloured by Mission Group', cex.main = 0.6)
{% endhighlight %}

![center](/../figs/2014-10-05-clustering-universities-with-guardian-2015-part-2/coloured_by_group2.png) 

One group that looks interesting is the other "Russell/1994" cluster at the top-left of the above plot, which is identified as a distinct group once the dendrogram is split into 7. This corresponds to the green cluster 3 in the cluster diagram as illustrated below:


{% highlight r %}
plot(as.phylo(hcluster), type = 'un', cex = 0.4, 
     tip.color = cutree(hcluster, k = 7), lab4ut = 'axial', 
     font = 1, rotate.tree = 10, mar = c(0, 0, 1, 0))
legend('topleft', legend = 1:7, fill = 1:7, bty = 'n', border = 0, cex = 0.5)
title('Coloured by Cluster Group', cex.main = 0.6)
{% endhighlight %}

![center](/../figs/2014-10-05-clustering-universities-with-guardian-2015-part-2/coloured_by_cluster.png) 

The cluster is composed of the following institutions and measures:



{% highlight r %}
# the cluster of interest just happens to be number '3'
kable(scaled[cutree(hcluster, k = 7) == '3', ], 
      format = 'markdown')
{% endhighlight %}



|                      | nss.teach| nss.all|   spend|     ssr|  career|   value|  tariff| nss.feedback|
|:---------------------|---------:|-------:|-------:|-------:|-------:|-------:|-------:|------------:|
|Loughborough (15)     |    0.0567|  0.7611|  0.7429|  0.4211|  1.0548|  0.3496|  0.5212|       0.4002|
|Kent (20)             |    0.0984|  0.5436|  0.3466|  1.1879|  0.5742|  0.6416|  0.0933|      -0.4180|
|Aston (22)            |   -0.0315|  0.4240|  0.3301|  0.2234|  0.8128|  0.6661|  0.2095|       0.4577|
|Glasgow (25)          |    1.5543|  1.1107|  0.5420|  0.5307|  0.9569| -1.0933|  1.5254|      -0.6127|
|Newcastle (28)        |    0.7908|  1.0975|  0.0395|  0.5494|  1.4902| -0.1080|  0.9129|       0.1010|
|Reading (30)          |    0.4729|  0.5133|  0.9125|  0.7254|  0.4190| -0.5371|  0.1361|      -0.7231|
|Queen Mary (32)       |    0.4718|  0.7089|  1.1782|  1.0146|  0.4666| -0.8135|  0.7442|      -0.2088|
|Manchester (33)       |    0.1681| -0.2799|  1.1014|  1.0545|  0.6705| -0.6230|  0.9665|      -0.4728|
|Bristol (34)          |    0.7886|  0.2220|  0.0280|  0.9876|  1.4074|  0.3019|  1.4678|      -0.9851|
|City (35)             |   -0.2986|  0.5262|  0.8937| -0.1780|  0.5762|  0.2922|  0.3729|       0.2472|
|Royal Holloway (36)   |    1.1348|  0.8733| -0.5254|  0.4777| -0.1645| -0.3598|  0.5041|      -0.0591|
|Sheffield (37)        |    1.0947|  1.1026|  0.2892|  0.6407|  0.6869| -0.0423|  0.9221|      -0.1616|
|Strathclyde (38)      |    0.4221|  0.4685|  0.4161| -0.6193|  0.9665| -0.2492|  1.3121|      -1.7545|
|Aberdeen (41)         |    0.6977|  0.6467| -0.1703|  0.4378|  1.1218| -0.2449|  0.9904|      -0.8801|
|Keele (41)            |    1.1802|  1.5847| -0.8827|  0.5549|  0.3968|  0.0466|  0.2360|       0.6024|
|Sussex (43)           |    0.5727|  0.8221|  0.4335|  0.1063| -1.0413| -0.0926|  0.5468|      -1.3927|
|Queen's, Belfast (46) |    0.9037|  0.6425| -0.3754|  0.4338|  0.9963| -0.6229|  0.3303|       0.5546|
|Dundee (47)           |    0.9483|  1.2004|  0.2555|  0.6693|  0.6082|  0.1885|  0.5488|      -0.2040|
|Swansea (57)          |   -0.2296| -0.1656| -0.2370|  0.4376|  1.2364|  0.1081| -0.2988|      -0.4632|
|Stirling (63)         |    0.3411|  0.1449| -0.5914|  0.3741| -0.1068| -1.6779|  0.1947|      -1.0146|

They are all similarly ranked, but it's pretty tough to stare at the table to draw out any more commonalities. Even summarising the measures for each group doesn't make things much easier:


{% highlight r %}
# create separate dataframe with cluster membership added
scaled_with_groups <- scaled
scaled_with_groups$clust_group7 <- cutree(hcluster, k = 7)

# calculate the mean of each column for each group
group_summary <- scaled_with_groups %>%
  group_by(clust_group7) %>%
  summarise_each(funs(mean))

kable(group_summary, format = 'markdown')
{% endhighlight %}



| clust_group7| nss.teach| nss.all|   spend|     ssr|  career|   value|  tariff| nss.feedback|
|------------:|---------:|-------:|-------:|-------:|-------:|-------:|-------:|------------:|
|            1|    0.9328|  0.9627|  1.1896|  1.2255|  1.1591|  0.6511|  1.3413|       0.0672|
|            2|   -0.2475| -0.5911|  1.7027|  2.2015|  1.4324|  0.9555|  1.5990|      -2.3748|
|            3|    0.5569|  0.6474|  0.2363|  0.5015|  0.6564| -0.1935|  0.6118|      -0.3494|
|            4|    0.0541|  0.0545| -0.6014| -0.4543| -0.5055| -0.1922| -0.5998|       0.7026|
|            5|   -2.6181| -3.4914|  1.6740| -0.8869| -0.7233|  0.3202| -0.4327|      -0.8186|
|            6|   -0.6819| -0.6940| -0.5916| -0.8282| -0.2913|  0.9749| -0.4240|      -0.7720|
|            7|   -1.4124| -1.3849| -0.5051| -0.9336| -1.1221| -1.0296| -1.0430|      -0.5481|

Rather than stare at the numbers, visualising the spread of each variable within each group should give some clues as to why the universities in similar mission groups (Russell/1994) have been placed into different clusters (clusters 1 and 3).


{% highlight r %}
# reshape the data
molten <- melt(scaled_with_groups, id.vars = "clust_group7")

ggplot(molten[molten$clust_group7 %in% c(1, 3),], 
       aes(x = value, col = as.factor(clust_group7))) + 
  geom_density() + 
  facet_wrap(~variable) + 
  scale_color_discrete('Cluster', labels = c('Russell/1994 Top-performers (group 1)', 
                                             'Russell/1994 Good-performers (group 3)')) +
  theme_bw()
{% endhighlight %}

![center](/../figs/2014-10-05-clustering-universities-with-guardian-2015-part-2/plot_group7.png) 

Cluster 3 has a similar profile to the cluster 1 across each measure, but consistently lags behind slightly. The other main difference is in student/staff ratio where cluster 1 has more of a spread from slightly below average to way above average, whereas cluster 3 tends to have institutions with an SSR of just above average. 




Conclusion
----------

That concludes my brief look at clustering universities using data from the Guardian University Guide 2015. Hierarchical clustering provides an interesting perspective into the data, for example showing how clearly delineated the research-intensive universities are from the others, despite there not being a research-related measure in the Guardian's league table, and also that there appear to be two distinct sets of the research-intensive universities, with one lagging slightly behind the other on most measures.
