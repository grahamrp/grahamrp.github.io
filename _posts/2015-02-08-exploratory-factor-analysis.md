---
layout: post
title: "Exploratory Factor Analysis of the Guardian University Guide 2015"
date: 2015-02-08
thumbnail: assets/efa_thumbnail.png
---

Exploratory Factor Analysis
---------------------------
In a previous post I looked at [clustering universities]({%post_url 2014-09-14-clustering-universities-with-guardian-2015-part-1 %}) using the Guardian league table data. This was an attempt to cluster *universities* together if they had similar characteristics. Exploratory factor analysis is more like attempting to cluster related *characteristics* together (the various league table measures) and attempting to identify any underlying structure.

Here's an example to illustrate what EFA is all about. If a group of people were tested on a bunch of physical activities, say running speed, distance, jumping height, distance, swimming speed, distance, and many more, my guess would be that those who did badly on some would probably do badly on many of the others, and that those that did well on some would do well on many of the others. Perhaps there is just one latent "factor" in all of the test scores, something like physical fitness, or how "sporty" people were. This could be drawn out from the data by examining how the characteristics vary and correlate with each other.

EFA and the Guardian League table
---------------------------------
It does not seem unreasonable to suppose that the various league table measures might be varying in response to one or more latent factors, particularly as several of the measures seem related. Several measures are related to student satisfaction, and others are related to resources (student-to-staff ratio and spend per student). There is certainly a fair amount of correlation between variables, as the following scatterplot matrix illustrates.


{% highlight r %}
library(knitr)

# Load prepared data (Guardian 2015 overall scores and rank) into 'g2015'
load('data/g2015.Rda')

# Plot scatterplot matrix using custom upper panel showing correlation
panel.cor <- function(x, y, digits = 2, prefix = "", cex.cor, ...)
{
  usr <- par("usr"); on.exit(par(usr))
  par(usr = c(0, 1, 0, 1))
  r <- abs(cor(x, y))
  txt <- format(c(r, 0.123456789), digits = digits)[1]
  txt <- paste0(prefix, txt)
  if(missing(cex.cor)) cex.cor <- 0.8/strwidth(txt)
  text(0.5, 0.5, txt, cex = cex.cor * r)
}
pairs(g2015[, 4:11],  # variables 4:11 contain the actual scores
      upper.panel = panel.cor, 
      col=rgb(49,0,98,50,maxColorValue=255))  # purple with transparency
{% endhighlight %}

![center](/../figs/2015-02-08-exploratory-factor-analysis/scatterplot_matrix-1.png) 

The strongest correlation is between `nss.teach` and `nss.all` at 0.89, but there are some other strong correlations, e.g. `ssr` and `tariff` or `career` and `tariff`, and several weaker ones.

### The measures
A full explanation of the Guardian's measures is provided [here](http://www.theguardian.com/education/2014/jun/03/how-to-use-guardian-university-guide) but briefly the 8 measures are:

- **Course satisfaction** (`nss.all`): the percentage of final-year students who agree with the statement "Overall, I am satisfied with the quality of the course" in the [National Student Survey](http://www.thestudentsurvey.com)(NSS).
- **Teaching quality** (`nss.teach`): the percentage of final-year students satisfied with the teaching they received, based on 4 related NSS questions
- **Feedback** (`nss.feedback`): the percentage of final-years satisfied with feedback and assessment by lecturers, based on 5 related NSS questions
- **Staff/student ratio** (`ssr`): the number of students per member of teaching staff
- **Spend**: the amount of money spent on each student, given as a rating out of 10
- **Average entry tariff** (`tariff`): the average [UCAS tariff](http://www.ucas.com/how-it-all-works/explore-your-options/entry-requirements/ucas-tariff) scores for new students
- **Value-added** (`value`): a score from 1 - 10 representing the extent to which students enter the university with relatively low qualifications and graduate with high ones
- **Career** (`career`): the percentage of graduates who find graduate-level jobs, or are studying further, within six months of graduation, as determined by the [Destinations of Leavers Survey](https://www.hesa.ac.uk/index.php?option=com_content&view=article&id=1899&Itemid=634)

Having only 8 variables with which to draw out any underlying structure is asking a lot of this technique. It would normally be applied with many more variables, as each one provides an additional perspective on what is going on underneath.

### The data

The first few rows of data look like this:


{% highlight r %}
kable(head(g2015), row.names = FALSE, digits = 1)
{% endhighlight %}



|inst           | rank15| score| nss.teach| nss.all| nss.feedback| spend| ssr| career| value| tariff|
|:--------------|------:|-----:|---------:|-------:|------------:|-----:|---:|------:|-----:|------:|
|Aberdeen       |     41|  62.5|      88.9|    88.0|         67.1|   4.9| 0.1|   76.6|   5.3|  444.3|
|Abertay Dundee |    101|  46.3|      86.2|    83.6|         59.6|   2.4| 0.0|   67.7|   6.6|  330.0|
|Aberystwyth    |    106|  43.8|      84.2|    82.1|         65.1|   4.5| 0.1|   54.0|   4.5|  325.0|
|Anglia Ruskin  |    105|  44.1|      85.8|    80.6|         71.6|   7.8| 0.0|   61.8|   3.4|  251.9|
|Aston          |     22|  70.4|      86.5|    87.0|         72.5|   5.8| 0.1|   73.5|   6.2|  381.4|
|Bangor         |     82|  52.4|      85.6|    83.9|         71.1|   4.7| 0.1|   65.6|   4.4|  305.5|

The `inst`, `rank15`, and `score` (referring to the overall score) columns will be removed before the factor analysis as these are summary variables rather than the underlying measures.



{% highlight r %}
# Remove non-measure variables
gmeasures <- g2015[, 4:11]
{% endhighlight %}

### Calculate the number of factors
The first step of factor analysis is to try to determine the number of underlying factors present. The scree plot below can help with this, although there is not necessarily a definitive answer. The blue line in the plot illustrates how much of the variability in the dataset is captured by assuming different numbers of factors, with the line dropping as more variability is explained.


{% highlight r %}
library(psych)
fa.parallel(gmeasures, fa = 'fa', sim = FALSE, show.legend = FALSE)
{% endhighlight %}

![center](/../figs/2015-02-08-exploratory-factor-analysis/unnamed-chunk-2-1.png) 

{% highlight text %}
## Parallel analysis suggests that the number of factors =  2  and the number of components =  2
{% endhighlight %}

Trying to represent the dataset with just 1 factor shows the unexplained variance to be relatively high, but this declines sharply with 2 factors, and declines again (but less sharply) with 3 factors. Adding more factors after this point doesn't have much effect on the unexplained variance, so it looks like we have either 2 or 3 factors. The text output above from `fa.parallel` suggests a 2 factor model. Generally it would be best to take a look at both, but for brevity I'll stick with the 2 factor model.

### Interpreting the results
By choosing a 2 factor model we are essentially trying to represent the variability of the 8 Guardian measures using only 2 variables. The `fa()` function is used to calculate the 2 variables.


{% highlight r %}
fa.nfact2 <- fa(gmeasures, nfactors = 2, rotate = 'varimax', fm = 'pa')
{% endhighlight %}

We can use `fa.plot` to view how the 2 new factors relate to the original 8 variables.


{% highlight r %}
fa.plot(fa.nfact2, labels = rownames(fa.nfact2$loadings), pos = 3, title = NULL,
        ylim = c(-0.2, 1), xlim = c(-0.4, 1))  # adjustments to fit labels
{% endhighlight %}

![center](/../figs/2015-02-08-exploratory-factor-analysis/unnamed-chunk-3-1.png) 

`career`, `ssr`, `tariff`, and `spend` are all fairly close together and heavily related to the first factor (on the right of the x-axis of PA1). `nss.all` and `nss.teach` are plotted on top of each other, and are heavily related to the second factor (high on the y-axis of PA2). `value` and `nss.feedback` are a bit further away from the other variables and not that well represented by either factor.

A simplified way of viewing the relationships between the 2 factors and the 8 variables is given by `fa.diagram()`. Using `simple = TRUE` shows just the relationships between the factors and the variables that they are most closely related to.


{% highlight r %}
fa.diagram(fa.nfact2, simple = TRUE, main = NULL)
{% endhighlight %}

![center](/../figs/2015-02-08-exploratory-factor-analysis/unnamed-chunk-4-1.png) 

We can see more clearly now that the National Student Survey measures are strongly related to one factor, and all the other measures are related to the other factor. As with the 2 dimensional plot using `fa.plot()` above, we can see `value` is not well represented by PA1, nor is `nss.feedback` particularly well represented by PA2.

Conclusion
----------
It is interesting that the factor analysis has managed to draw out two underlying factors of the Guardian league table measures, particularly the one factor related primarily to student satisfaction (the other factor encompassing "all the rest"). The high correlation between students' satisfaction overall (`nss.all`) and their satisfaction with teaching quality (`nss.teach`) might suggest that one of them could be removed from the measures, to leave just 7, without making much difference to the rankings. Satisfaction with feedback (`nss.feedback`) and value-added (`value`) remain fairly independent from the other measures, suggesting that they represent a quality unique to the other variables.
