---
layout: post
title: "Blue Cloud Mirror -- A fun IBM Cloud showcase"
date: "2019-01-31"
---

Blue Cloud Mirror is an online game based on multiple IBM Cloud technologies. It has two levels, in level one you need to show five facial expressions like happy, angry, etc. In level two you need to show five body positions. Have a look at it and play it [here](https://blue-cloud-mirror.mybluemix.net){:target="_blank"}.

![]({{ site.baseurl }}/images/2019/01/selection_344.png)

I created the game together with my colleagues [Niklas Heidloff](https://twitter.com/nheidloff){:target="_blank"} and [Thomas Südbröcker](https://twitter.com/tsuedbroecker){:target="_blank"}. Niklas desribed many aspects of it in his blog, starting [here.](http://heidloff.net/article/introducing-blue-cloud-mirror){:target="_blank"}

Basically, Blue Cloud Mirror has three parts:

1. Game, can be played anonymously or as a registered user
2. Scores Service keeps the highscore list for registered users
3. Users Service keeps the user data of the registration

My part of this project is the Users Service. It does not run in the Cloud for several reasons:

- Users may not be comfortable with having their data stored on the Cloud.
- We wanted to deploy part of our microservices on Kubernetes, for example on IBM Cloud Private.
- We wanted to show how easy it is to securely connect a local backend with an application on the Cloud. Instead of the Users Service the connection could be to any application running on-premise.

I really started to develop on a IBM Cloud Private but since we wanted as many people as possible to use our game I decided to switch to a local instance of [Minikube](https://kubernetes.io/docs/setup/minikube/){:target="_blank"} because it is simple, has a small footprint, and if you like you can carry it around on your notebook.

You can find our code in the IBM directory of Github at [https://github.com/IBM/blue-cloud-mirror](https://github.com/IBM/blue-cloud-mirror){:target="_blank"} and you will find the User Service in the users directory of the repository.

I will describe the Users Service in follow on blogs. Stay tuned!
