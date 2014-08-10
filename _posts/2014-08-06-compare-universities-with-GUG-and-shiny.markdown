---
layout: post
title:  "Comparing universities using the Guardian University Guide 2015"
date:   2014-08-06 19:31:55
categories:
- league tables
- shiny
---

[Comparing Universities using the Guardian University Guide 2015](http://grahamrp.shinyapps.io/GUG2015) is my first app using [Shiny](http://shiny.rstudio.com/). Its purpose is to provide for easy comparison between two universities featured in the [Guardian University Guide 2015](http://www.theguardian.com/education/universityguide). Please take a look!

## Shiny first impressions
I'm really impressed with Shiny -- going from nothing to a working interactive application is very quick, and its ability to harness the functionality of R makes it very powerful. There was just a little bit to learn about creating the reactive elements and the page layout, then I could get on with creating the interactive visualisations. Being able to reuse my existing knowledge of creating plots in R was a huge benefit; rather than having to learn a new tool, Shiny allowed me to use existing tools and knowledge, but make them interactive and easy to publish.

I thought I would be asking for trouble by using three different plotting libraries within the same app (base graphics, ggplot2 and rCharts) but Shiny just rendered them all without a problem. Compared to the tools I'm used to using at work (e.g. SAP Web Intelligence, Excel) Shiny's flexibility sets it apart -- I can concentrate almost entirely on how I want to show the data, rather than perusing the menu of built-in charts in a more heavily structured tool, which I find stifles my thought process.

## Slope graph
The main purpose of the app is to show the changes in the university rankings from last year to this year, and a slope graph (also known as a ladder plot, I think) is perfect for this. Encoding the rank changes using the slopes of the lines seems to be very intuitive, and large movements up and down the rankings seem to stand out just the right amount. There's a great post about them at [Charliepark.org](http://www.charliepark.org/slopegraphs), and the R base graphics plot was based on code from [bobthecat](https://github.com/bobthecat/codebox/blob/master/table.graph.r).

![Slope graph screenshot](/assets/slopegraph.png)

One thing I took a bit of a shortcut on was putting the slope graph into the "sidebar" section of the shiny app. I wanted the slope graph to run the length of the page, with the other plots to the side, but I couldn't quickly work out how to do this using the standard shiny layout, so I just plonked it in the sidebar to achieve the same effect.

## Range bar graph
After the slope graph I wanted to show how each measure had changed since last year. I came across one of Stephen Few's newsletters on [Displaying Changes Between Two Points in Time](http://www.perceptualedge.com/articles/visual_business_intelligence/displaying_change_between_two_points_in_time.pdf) which gave excellent advice and included a section on  "range bar graphs" which were new to me and just what I needed. With a bit of trial and error I was able to recreate one in ggplot2.

![Range chart screenshot](/assets/rangechart.png)

In order to plot everything on the same axis I standardised each of the measures (subtracted the mean and divided by the standard deviation for each year of data) which then allows for easier comparison across measures and also from year to year.

## Parallel coordinates
In the final visualisation I wanted to show the actual figures for the latest year -- just showing the standardised scores seemed a bit too far removed from the original source -- and also to show every measure "all at once" to allow for a quick visual comparison between universities. I decided on using a parallel coordinates plot for this, although I'm not sure this was the best idea now.

![Parallel coordinates screenshot](/assets/parallel_coords.png)

The chart was produced using code from [rCharts](http://rcharts.io/parcoords/), which produces some really nice plots. Ideally I would have stuck with ggplot2 or base graphics for simplicity, but I couldn't find an implementation as good as rCharts.

The chart mostly does what I wanted, but perhaps this type of plot is not perfectly suited. I think people's first intuition when seeing the horizontal lines is to assume something happening over time, especially when primed for this in the previous range bar graph.

Part of the point of the parallel coordinates plot is to show the relationship between the measures, by looking at the patterns of lines formed between the axes, but only showing two universities at once doesn't exploit this feature. However, what I do like about it is the form of standardisation that occurs by having different scales on each axis, so all the measures can be seen together even though they cover different ranges, yet the original values are retained.

