---
layout: post
title: "Exploring League Table Trends with Visualisation and Modelling"
date: 2016-03-21
thumbnail: assets/steady_climbers_thumbnail.png
---


In this post I use the last three years of Guardian League Tables to find institutions who are steadily climbing the rankings, and investigate the limits of visualising data when there are too many observations to show at once.

The Limits of Visualisation
---------------------------
Even with a relatively small dataset like the league table a line chart becomes confusing when trying to find trends in the overall score for all 115 universities.


{% highlight r %}
library(dplyr)
library(ggplot2)
library(broom)

# Load Guardian main (not subject-specific) rankings from 2014, 2015, and 2016
gmain <- read.delim('data/gug_2014_to_2016_main_tables.tsv', 
                    stringsAsFactors = FALSE)

# Plot overall scores (higher is better) for each institution over time
ggplot(gmain, aes(x = year, y = score, group = inst)) +
  geom_line() + theme_minimal() + scale_x_continuous(breaks = c(2014:2016)) +
  ggtitle('Institution Scores per Year')
{% endhighlight %}

![center](/../figs/2016-03-20-exploring-league-table-trends-with-visualisation-and-modelling/line_chart_all-1.png)

This plot is too crowded to make out individual universities but it is still useful to get a sense of the overall spread of scores and how much they change over time.

For example the top two universities seem consistently way ahead of the others (Cambridge and Oxford), and the bottom two universities seem consistently behind the others (London Met and Bucks New University). 

We can also see that it is a crowded market in the middle of the rankings, but it is hard to spot the institutions who are steadily climbing the table.

### Making Better Use of Space
One way of dealing with the overlapping institutions is to spread them out in a meaningful way using small multiples. The plot below shows the same line chart, but repeated for each university mission group.


{% highlight r %}
ggplot(gmain, aes(x = year, y = score, group = inst)) +
  geom_line() + theme_minimal() + scale_x_continuous(breaks = c(2014:2016)) +
  facet_wrap(~group) + 
  geom_text(data = gmain[gmain$year == 2016, ], 
            aes(x = year, y = score, label = inst),
            nudge_x = 0.8, hjust = 1, size = 1.7) +
  ggtitle('Institution Scores per Year by Mission Group')
{% endhighlight %}

![center](/../figs/2016-03-20-exploring-league-table-trends-with-visualisation-and-modelling/line_chart_facet-1.png)

This is a big improvement. The institutions have been spread out, there is now (almost) room to show their names, and the overall picture of how they all compare with each other is retained. 

However, it is still time-consuming to spot those steady climbers. There may be some further visualisation techniques we can use to make them stand out, but hopefully it is easy to see that at some point, as the number of entities (institutions in this case) increases, we can no longer discover patterns by simply plotting *all* of the data. 

Using Models for Focus
----------------------
One approach to deal with this problem is to model the data, and therefore enable numeric rather than visual analysis. The down side to this is that some precision is lost, as all models are an approximation of some kind, but the up side is that this will scale up to much larger datasets. We can focus in on institutions of interest using numerical summaries from our model, and then plot them as before, filtering out the less-interesting institutions.

### Modelling for Steady Climbers
We're looking for the steady climbers who are making swift progress up the table. To find these we could take the differences in scores between each year, and perhaps average these to get a summary statistic of "progress". This is not far off a more robust approach -- making a linear model for each institution, creating the line of best fit for the three years of data. The slope of this line will summarise the trajectory of each university, and we can then look for those with steep upward slopes.


{% highlight r %}
# Fit a linear model for each university, overall score by time, and extract the
# slope estimate and the r-squared
scores_per_year <- data.frame()
for(institution in unique(gmain$inst)){
  m1 <- lm(score ~ year, inst == institution, data = gmain)
  m1 %>% tidy() %>% filter(term == 'year') %>% .$estimate -> spy
  m1 %>% glance(m1) %>% .$r.squared -> rsq
  scores_per_year <- rbind(scores_per_year, 
                           data.frame(inst = institution,
                                      score_per_year = spy,
                                      r.squared = rsq,
                                      stringsAsFactors = FALSE))
}
{% endhighlight %}

We can take the ten institutions with the steepest upward slopes and just plot these.


{% highlight r %}
scores_per_year %>% 
  top_n(10, score_per_year) %>% 
  left_join(gmain) ->
  swift_climbers
ggplot(swift_climbers, aes(x = year, y = score, group = inst, col = inst)) +
  geom_line() + theme_minimal() + scale_x_continuous(breaks = c(2014:2016)) +
  geom_text(data = swift_climbers[swift_climbers$year == 2016, ], 
            aes(x = year, y = score, label = inst),
            nudge_x = 0.3, hjust = 1, size = 3) +
  ggtitle('Climbers')
{% endhighlight %}

![center](/../figs/2016-03-20-exploring-league-table-trends-with-visualisation-and-modelling/line_chart_steepest-1.png)

Now that we have a model to represent the data we are able to interrogate it much more easily, e.g. we could select those institutions who had kept a steady ranking across the years (those with near zero slopes) or those that have declined sharply (those with large negative slopes).

However, the chart above illustrates the problem with modelling without visualisation. The approximation that has been made (drawing a line of best fit across all three years) has resulted in some institutions being identified as steady climbers but in fact their behaviour is not  necessarily *steady*, for example Leeds Trinity actually fell from 2014 to 2015 but then jumped significantly in 2016. The detail is lost in the model, but is clear in the visualisation.

One way of refining the model to get the *steady* climbers is to use its R-squared value in concert with the slope. The R-squared value measures how well the model fits the data, taking a value from 0 to 1. Models with a high r-squared will fit the data closely, and in this case will look more like a straight line. For example, Leeds Trinity has a steep upward slope (7.85 points per year) but doesn't look much like a straight line (**R-squared 0.73**) whereas Falmouth has a steep slope (8.65 points per year) but also looks more like a straight line (**R-squared 0.96**).

We want institutions whose trajectory looks like a straight line *and* is sloped upward, so a high R-squared and a high slope estimate.


{% highlight r %}
scores_per_year %>% 
  filter(r.squared >= 0.95) %>% 
  top_n(10, score_per_year) %>% 
  left_join(gmain) ->
  steady_climbers
  ggplot(steady_climbers, aes(x = year, y = score, group = inst, col = inst)) +
  geom_line() + theme_minimal() + scale_x_continuous(breaks = c(2014:2016)) +
  geom_text(data = steady_climbers[swift_climbers$year == 2016, ], 
            aes(x = year, y = score, label = inst),
            nudge_x = 0.3, hjust = 1, size = 3) +
    ggtitle('Steady Climbers')
{% endhighlight %}

![center](/../figs/2016-03-20-exploring-league-table-trends-with-visualisation-and-modelling/line_chart_steady_and_steep-1.png)

And we've done it! The institutions in the plot above are "steady" (I've chosen an R-squared of at least 0.95) whilst climbing the table at the fastest rate.

Bonus Material -- Combining Both Approaches
-------------------------------------------
For datasets that are not too big, such as this one, it is possible to augment the visualisation of all of the institutions, but highlight the ones of interest using the information from the modelling. In this way we can still plot all the data to preserve the context, whilst not overwhelming the reader since the model provides the focus.


{% highlight r %}
  ggplot(gmain, aes(x = year, y = score, group = inst)) +
    geom_line(col = 'grey', alpha = 0.7) + theme_minimal() + scale_x_continuous(breaks = c(2014:2016)) +
    geom_line(data = steady_climbers,
              aes(x = year, y = score, group = inst, col = inst),
              size = 1) +
    geom_text(data = steady_climbers[swift_climbers$year == 2016, ], 
              aes(x = year, y = score, label = inst),
              nudge_x = 0.7, hjust = 1, size = 2) + facet_wrap(~group) +
    ggtitle('All Institutions with Steady Climbers')
{% endhighlight %}

![center](/../figs/2016-03-20-exploring-league-table-trends-with-visualisation-and-modelling/all_plus_model-1.png)
  
