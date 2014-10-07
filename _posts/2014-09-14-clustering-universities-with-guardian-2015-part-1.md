---
layout: post
title: "University Clustering using the Guardian University Guide 2015: Part 1"
date: 2014-09-14 
---

This is the first in a two-part series of posts about clustering universities using data from the Guardian University Guide 2015. I'll be addressing the following

- Are there any clear clusters of universities based on the Guardian metrics?
- If so, do the clusters have any interesting characteristics?

But in this first part I want to describe the hierarchical clustering technique and discuss the visualising of clusters using dendrograms.

About Hierarchical Clustering
-----------------------------
The version of clustering I'll be using starts by grouping together the two "closest" entities (in this case entities are universities) and then proceeds incrementally by taking the next two closest entities and grouping them together, and so on. The "hierarchical" part comes when the groups get treated as entities in their own right, and we end up with groups of groups of groups, etc.

A trivial example should help to illustrate how it works and some of the issues. I'll create a simple dataset of the Simpsons family, measuring each member on just two variables -- age and intelligence.


{% highlight r %}
simpsons <- data.frame(age = c(10, 37, 40, 1, 8),
                       intelligence = c(6, 10, 5, 4, 15))
row.names(simpsons) = c('bart','marge','homer','maggie','lisa')
print(simpsons)
{% endhighlight %}



{% highlight text %}
##        age intelligence
## bart    10            6
## marge   37           10
## homer   40            5
## maggie   1            4
## lisa     8           15
{% endhighlight %}

Because I am only using two variables it is very easy to visualise the data in an intuitive way, since they map very nicely to the x and y dimensions of a scatterplot.


{% highlight r %}
plot(x = simpsons$age, y = simpsons$intelligence, 
     xlab = 'Age', ylab = 'Intelligence', 
     xlim = c(0, 45), ylim = c(0, 45),  # set the x and y scales to be identical
     main = 'How far apart are the family members?',
     type = 'n')  # "n" for no plotting (just set up the axes, etc.)
text(x = simpsons$age, y = simpsons$intelligence, 
     labels = row.names(simpsons), 
     cex = 0.8)  # reduce the text size a bit
segments(x0 = simpsons$age[4], y0 = simpsons$intelligence[4],
         x1 = simpsons$age[5], y1 = simpsons$intelligence[5],
         lty = 2)  # dashed (l)ine (ty)pe
{% endhighlight %}

![center](/../figs/2014-09-14-clustering-universities-with-guardian-2015-part-1/unnamed-chunk-2.png) 

It's easy to see the distances between family members in the plot above. The dashed line between Maggie and Lisa makes explicit the distance between them, but it's so obvious to us that adding a connecting line is unnecessary. 

What we also have an intuition for is how many clusters are in the dataset. It looks like there are two clearly separated groups, the adults Marge and Homer and then the children Lisa, Maggie and Bart. *Maybe* we might say there are three clusters -- Marge/Homer, Maggie/Bart, and Lisa out on her own, but it is somewhat subjective to say how many clusters there are.

One issue brought out by the plot is that the measurements for age and intelligence are not on the same scale. Age is measured in years and intelligence is measured in a made-up scale that goes from 0 - 20. This creates a problem with the distances between family members -- Lisa is much younger than Marge, and appears quite far away on the plot, however Lisa is also much more intelligent than Maggie, but looks relatively close to her on the plot. Age and intelligence have different scales, and this needs to be accounted for when calculating distances between entities.

Clustering and Dendrograms
--------------------------
Ignoring the scaling issue for the moment, let's see how the same data come out when we apply the hierarchical clustering method and visualise the results using a dendrogram.


{% highlight r %}
simpsons_distances <- dist(simpsons)
simpsons_hclust <- hclust(simpsons_distances)
plot(simpsons_hclust, ann = FALSE)  # plot without annotations
{% endhighlight %}

![center](/../figs/2014-09-14-clustering-universities-with-guardian-2015-part-1/unnamed-chunk-3.png) 

The dendrogram shows the same relationships that we can see so intuitively on the scatterplot, but one benefit of the dendrogram is that it is not limited to just 2 dimensions. In agreement with the scatterplot, a first glance suggests Marge and Homer are in one cluster and the children are in the other, possibly with Lisa being a bit out on her own.

The *heights* of the *horizontal* lines are the primary means of encoding information in the dendrogram. For example, the horizontal line joining Marge and Homer is at just over 5 on the y-axis, which is the "distance" between them. The diagram shows that Bart and Maggie are "further apart" from each other than Marge and Homer because the line between them is placed at a higher point on the y-axis (at about 9).

Once a line has connected two entities, they are then treated as a group for further connections to other entities. Bart and Maggie are connected by the horizontal line at 9; the *group* (bart+maggie) is then connected to Lisa via the horizontal line at about 13, showing how similar Lisa is to this group. The group (lisa+(bart+maggie)) is connected to the group (marge+homer) at about 39, showing that these two groups are very far apart, forming the two main clusters seen already.

Dendrogram Issues
-----------------
Note there is no x-axis on the dendrogram -- it does not matter where the entities sit in the horizontal. For example, if Marge and Homer flipped places the dendrogram would be encoding exactly the same information. This is the main difficulty I have with interpreting dendrograms -- the x-axis does not encode information about clusters, at least not explicitly. The whole diagram can be viewed like it was a hanging mobile with every entity spinning around the centre of its supporting horizontal beam. I find it hard to keep this in mind whilst looking at the diagram. What seems to make it worse is that the entities that are most like each other need to be placed side by side on the diagram to make the layout tidy, so in some ways the x-axis *does* encode some information. That said, the dendrogram still seems to be the best visualisation we have for encoding this type of information.

Now that the hierarchical clustering technique is outlined, in [Part 2]({% post_url 2014-10-05-clustering-universities-with-guardian-2015-part-2 %}) I will apply it to UK universities using the Guardian University Guide 2015 dataset and experiment with some dendrogram visualisations.









