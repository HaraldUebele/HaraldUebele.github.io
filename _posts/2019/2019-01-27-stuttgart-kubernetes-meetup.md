---
layout: post
title: "Stuttgart Kubernetes Meetup"
date: "2019-01-27"
allow_comments: "yes"
---

Last Thursday night was the [Stuttgart Kubernetes Meetup](https://www.meetup.com/Stuttgart-Kubernetes-Meetup/events/256940404/){:target="_blank"}, hosted by CGI in Echterdingen (thanks!!!). I got the chance to talk about "Project Eirini".

![Eirini logo](/images/2019/01/eirini.jpeg)

There is Kubernetes and there is Cloud Foundry. Both are Cloud PaaS platforms, both offer container orchestration and scheduling, and both are available on the IBM Cloud. While Kubernetes is all about container orchestration, Cloud Foundry is a developer experience where the concept of containers is pretty much hidden from the developer. Both have their strengths and weaknesses: You can do almost anything with Kubernetes but it has a steep learning curve, as a developer you have to know a lot about orchestration. Cloud Foundry is limited to stateless or 12-factor apps but as a developer you only focus on your code, Cloud Foundry takes care of the rest.

A while ago, SuSE started a project in the Cloud Foundry Incubator called "Cloud Foundry (CF) Containerization". It converts the VMs running CF Management or backplane functions into containers and deploys them on Kubernetes. It uses a component called "fissile" to do that. There is a [Github repo](https://github.com/SUSE/scf){:target="_blank"} for this. This has been around for a while and works quite well. IBM uses this technology for "Cloud Foundry Enterprise Edition" to run a Cloud Foundry for one customer on top of a Kubernetes cluster.

Cloud Foundry has a container orchestration component called "Diego", Kubernetes is a container orchestrator. With the CF Containerization approach, Diego cells -- the equivalent to Kubernetes worker nodes -- are deployed as Pods. That way, Cloud Foundry apps run as containers within containers (nested). They are not visible to Kubernetes. If you deploy Kubernetes apps via kubectl into the Kubernetes cluster that hosts Cloud Foundry Containerization, those apps are not visible to Diego. Diego and Kubernetes then work against each other instead of together. This is where Project Eirini starts.

Eirini is the greek goddess of peace :-)

Eirini replaces Diego with Kubernetes (actually it gives you a choice between the two). When you deploy an application to Cloud Foundry (native), Diego uses a buildpack -- a runtime that matches the programming language of the application -- and combines it with the application code and dependencies to form what is called a "droplet". The droplet is then placed into an empty container end executed, this forms the running application.

Eirini uses a mechanism published by buildpacks.io, it creates a container image instead of a droplet, plus it creates a helm chart, and deploys the application as stateful set directly into Kubernetes. The application is visible in Kubernetes and the Kubernetes cluster can be used to run other Kubernetes native applications as well.

This is the [Eirini repository](https://github.com/cloudfoundry-incubator/eirini){:target="_blank"} on Github, it contains information on how to run CF Containerization and Eirini together. In December 2018, Eirini has passed the Cloud Foundry Acceptance tests and should be production ready in a while.

