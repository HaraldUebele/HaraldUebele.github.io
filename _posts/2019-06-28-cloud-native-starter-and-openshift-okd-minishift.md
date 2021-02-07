---
layout: post
categories: [2019,Kubernetes,OpenShift]
title: "Cloud Native Starter and OpenShift, OKD, Minishift"
date: "2019-06-28"
---

Over the last weeks we have worked intensively on our [Cloud Native Starter](https://github.com/IBM/cloud-native-starter){:target="_blank"} project and made a lot of progress. It is an example of a microservices architecture based on Java, Kubernetes, and Istio. We have developed and tested it on Minikube and [IBM Cloud Kubernetes Service](https://cloud.ibm.com/docs/containers).

Currently we are [enabling Cloud Native Starter to run on Red Hat OpenShift](https://github.com/IBM/cloud-native-starter/blob/master/documentation/SetupMinishift.md){:target="_blank"} starting with Minishift.

[OpenShift](https://www.openshift.com/){:target="_blank"} is Red Hat's commercial Kubernetes distribution. There is a community version of OpenShift called [OKD](https://www.okd.io/) which stands for "Origin Community Distribution of Kubernetes". OKD is the upstream Kubernetes distribution embedded in Red Hat OpenShift. And the there is [Minishift](https://docs.okd.io/latest/minishift/index.html){:target="_blank"}. Like Minikube, it is an OKD based single node Kubernetes cluster running in a VM.

Minishift is currently running OKD/OpenShift Version 3.11 as latest version. OpenShift Version 4 will probably never be supported.

I have experimented with Minishift a while ago when I had a notebook with 2 CPU cores (4 threads) and 8 GB of RAM. That is not enough! My current notebooks has 4 CPU cores (8 threads) and 32 GB of RAM and it runs quite well on this machine.

If you like me come from a plain Kubernetes experience, OpenShift is a challenge. Red Hat enabled many security features like role based access control and also enabled TLS in many places. So you have to learn many things new. And while bringing up Minishift is quite simple ("minishift start"), installing Istio isn't. There are [instructions for OpenShift](https://istio.io/docs/setup/kubernetes/platform-setup/openshift/){:target="_blank"} on the Istio website but they ignore Kiali and I don't want to miss out on Kiali. And I was not able to get automatic injection to work because I couldn't find the file to patch.

One day I stumbled over this [blog](https://medium.com/@kamesh_sampath/3-steps-to-your-istio-installation-on-openshift-58e3617828b0){:target="_blank"} by Kamesh Sampath from Red Hat. And then Istio install on Minishift is almost a breeze:  
1. Set up a Minishift instance with some prerequisites  
2. Download the Minishift Add-ons from Github  
3. Install the Istio add-on

There are still some things missing and I have documented the process that works for me [here](https://github.com/IBM/cloud-native-starter/blob/master/documentation/SetupMinishift.md){:target="_blank"}.

A couple of comments:

The [Istio add-on](https://github.com/minishift/minishift-addons/tree/master/add-ons/istio){:target="_blank"} installs Istio with a Kubernetes operator which is cool. It is based on a project called [Maistra](https://maistra.io/){:target="_blank"} which seems to be the base for the upcoming OpenShift Service Mesh. It installs a very downlevel Istio version (1.0.3), though. But the integration with OpenShift is very good and all security aspects are in place. For testing I think this works very well.

Did I mention security? Maistra by default seems to enable mTLS. Which results in upstream 503 errors between your services once you apply Istio rules. For the sake of simplicity we therefore decided to disable mTLS in our cloud-native-starter project for Minishift.

Automatic sidecar injection is also handled differently in Maistra/Istio: In our Minikube and IBM Kubernetes Service environments we label the namespace with a specific tag ("istio-injection=enabled"). With this label present, every pod in that namespace will automatically get a sidecar injected. Maistra instead relies on opt-in and requires an annotation in the deployment yaml file as described [here](https://maistra.io/docs/getting_started/automatic-injection/){:target="_blank"}. This requires enablement of "[admission webhooks](https://istio.io/docs/setup/kubernetes/platform-setup/openshift/#automatic-injection){:target="_blank"}" in the master configuration file which is done by patching this file. Fortunately, this is made very easy in Minishift. All you need to do is enable an add-on ("minishift addon enable admissions-webhook").
