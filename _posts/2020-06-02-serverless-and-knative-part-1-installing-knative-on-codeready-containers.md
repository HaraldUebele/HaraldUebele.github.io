---
layout: post
title: "Serverless and Knative - Part 1: Installing Knative on CodeReady Containers"
date: "2020-06-02"
categories: [Knative,Kubernetes,Serverless]
tags: 
  - "knative"
  - "kubernetes"
  - "serverless"
---

I have worked with Kubernetes for quite some time now, also with Istio Service Mesh. Recently I decided that I want to explore Knative and its possibilities.

![Knative logo]({{ site.baseurl }}/images/2020/06/m5EQknfW_400x400.jpg)

So what is Knative? The [Knative web site](https://knative.dev/){:target="_blank"} describes it as "components build on top of Kubernetes, abstracting away the complex details and enabling developers to focus on what matters." It has two distinct components, originally it were three:

1. Knative Build. It is no longer part of Knative, it is now a project of its own: "[Tekton](https://github.com/tektoncd){:target="_blank"}"
2. Knative Serving, responsible for deploying and running containers, also networking and auto-scaling. Auto-scaling allows scale to zero and is the main reason why Knative is referred to as Serverless platform.
3. Knative Eventing, connecting Knative services (deployed by Knative Serving) with events or streams of events.

This will be a series of blogs about installing Knative, Knative Serving, and Knative Eventing.

In order to explore Knative you need to have access to an instance, of course, and that may require installing it yourself. The [Knative documentation](https://knative.dev/v0.12-docs/install/){:target="_blank"} (for v0.12) has instructions on how to install it on many different Kubernetes platforms, including Minikube. Perfect, Knative on my notebook.

## Installation

I followed the instructions for Minikube and installed it, and started a tutorial. At some point, I finished for the day, and stopped Minikube. The next morning it wouldn't start again. I tried to find out what went wrong and in the end deleted the Minikube profile, recreated it, and reinstalled Knative again. Just out of curiosity I restarted Minikube and ran into the very same problem. This time I was a little more successful with my investigation and found this issue: [https://github.com/knative/eventing/issues/2544](https://github.com/knative/eventing/issues/2544){:target="_blank"}. I thought about moving to Knative 0.14 shortly but then decided to test it on OpenShift. If you read some of my previous blogs you may know that I am [a fan of CodeReady Containers (CRC)](https://haralduebele.github.io/2019/09/13/red-hat-openshift-4-on-your-laptop/){:target="_blank"}.

Knative on Red Hat OpenShift is called OpenShift Serverless. It has been a preview ("beta") for quite some time but since end of April 2020 it is GA, generally available, no longer preview only. According to the [Red Hat OpenShift documentation](https://access.redhat.com/articles/4912821){:target="_blank"} OpenShift Serverless v1.7.0 is based on Knative 0.13.2 (as of May 1st, 2020) and it is tested on OpenShift 4.3 and 4.4. The CRC version I am currently using (v1.10) is built on top of OpenShift 4.4. So it should work.

The hardware or cluster size requirements for OpenShift Serverless are steep: minimum 10 CPUs and 40 GB of RAM. I only have 8 vCPUs (4 cores) and 32 GB of RAM in my notebook and I do need to run an Operating System besides CRC but I thought I give it a try. I started Knative installation on a CRC config using 6 vCPUs and 20 GB of RAM and so far it seems to work. I have tried it on smaller configurations and got unschedulable pods (Memory and/or CPU pressure).

Installation is accomplished via an OpenShift Serverless Operator and it took me probably less then 20 minutes to have both Knative Serving and Eventing installed by just following the [instructions](https://access.redhat.com/documentation/en-us/openshift_container_platform/4.4/html/serverless_applications/installing-openshift-serverless-1){:target="_blank"}:

1. Install the OpenShift Serverless operator
2. Create a namespace for Knative Serving
3. Create Knative Serving via the Serverless operators API. This also installs [Kourier](https://github.com/knative/net-kourier){:target="_blank"} as "an open-source lightweight Knative Ingress based on Envoy." Kourier is a lightweight replacement for Istio.
4. Create a namespace for Knative Eventing
5. Create Knative Eventing via the Serverless operators API.

I have started and stopped CRC many times now and it doesn't have the issues that Minikube had.

As a future exercise I will test the Knative Add-on for the IBM Cloud Kubernetes Service. This installs Knative 0.14 together with Istio on top of Kubernetes and requires a minimum of 3 worker nodes with 4 CPUs and 16 GB om memory (b3c.4x16 is the machine specification).

In the next blog article I will cover [Knative Serving](https://haralduebele.github.io/2020/06/03/serverless-and-knative-part-2-knative-serving/) with an example from the Knative documentation.
