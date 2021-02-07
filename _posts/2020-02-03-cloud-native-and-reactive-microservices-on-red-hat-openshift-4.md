---
layout: post
categories: [Kubernetes,OpenShift,Reactive]
title: "Cloud Native and Reactive Microservices on Red Hat OpenShift 4"
date: "2020-02-03"
tag: "2020"
---

My colleague Niklas Heidloff has started to create [another version of our Cloud Native Starter](https://github.com/IBM/cloud-native-starter/tree/master/reactive#reactive-java-microservices){:target="_blank"} using a reactive programming model, and he has also written an extensive series of blogs about it [starting here](http://heidloff.net/article-development-reactive-applications-quarkus/){:target="_blank"}. He uses Minikube to deploy the reactive example and I have created [documentation and scripts to deploy it on CloudReady Containers](https://github.com/IBM/cloud-native-starter/blob/master/reactive/documentation/OpenShift4.md#reactive-java-microservices-on-openshift-4){:target="_blank"} (CRC) which is running Red Hat OpenShift 4.

The reactive version of Cloud Native Starter is based on [Quarkus](https://quarkus.io/){:target="_blank"} ("Supersonic Subatomic Java"), uses Apache Kafka for messaging, and PostgreSQL for data storage of the articles service. Postgres is accessed via the reactive SQL client. Niklas has blogged about all of the details.

![]({{ site.baseurl }}/images/2020/02/architecture-small.png)
{:center: style="text-align: center"}
_Cloud Native Starter Reactive: High Level Architecture_
{:center}


The deployment on OpenShift is very similar to the deployment of the original Cloud Native Starter which I have written about in my last [blog](https://haralduebele.github.io/2020/01/23/cloud-native-starter-on-red-hat-openshift-4/){:target="_blank"}.

The services (web-app, web-api, authors, articles) are build locally in Docker, then tagged with an image path suitable for the OpenShift image repository, then pushed with Docker into the internal repository.

Two things are different, though:

1. The reactive example currently doesn't require Istio, no need to install it, then.
2. Kafka and Postgres weren't used before.

I install Kafka using the Strimzi operator, and Postgres with the Dev4Devs operator.

In the OpenShift OperatorHub catalog, the Strimzi operator is version 0.14.0, we need version 0.15.0. That's why I use a [script](https://github.com/IBM/cloud-native-starter/blob/master/reactive/os4-scripts/deploy-kafka.sh){:target="_blank"} to install the Strimzi Kafka operator and then deploy a Kafka cluster into a kafka namespace/project.

The Dev4Devs Postgres operator is [installed](https://github.com/IBM/cloud-native-starter/blob/master/reactive/documentation/OpenShift4.md#4-install-postgresql){:target="_blank"} through the OperatorHub catalog in the OpenShift web console into its own namespace (postgres).

![]({{ site.baseurl }}/images/2020/02/postgres-op-succeeded.png)

An example Postgres "cluster" with a single pod is deployed via the operator into the same namespace/project.

Using operators makes it so easy to install components into your architecture. The way they are created in this example is not really applicable to production environments but to create test environments for developers its perfect.
