---
layout: post
categories: [Kubernetes]
title: "Moving from Minikube to IBM Cloud Kubernetes Service"
date: "2019-04-04"
tag: "2019"
---

In my last blog I have described a project we are working on: [Cloud Native Starter](https://github.com/ibm/cloud-native-starter){:target="_blank"}. It is a microservices architecture, written mostly in Java with Eclipse MicroProfile, and using many Istio features. We started to deploy on Minikube because that is easy to implement if you have a reasonably powerful notebook. Now that everything works on Minikube, I wanted to deploy it on the IBM Cloud, too, using IBM Cloud Kubernetes Service (IKS).

![]({{ site.baseurl }}/images/2019/04/architecture.png?w=1024)

![]({{ site.baseurl }}/images/2019/04/selection_389-1.png)

[IKS](https://cloud.ibm.com/docs/containers?topic=containers-cs_ov#cs_ov){:target="_blank"} is a managed Kubernetes offering that provides Kubernetes clusters on either bare metal or virtual servers in many of IBMs Cloud datacenters in Europe, the Americas, and Asia Pacific. One of the latest features (currently beta) are cluster add-ons to automatically install a managed Istio (together with Kiali, Jaeger, Prometheus, etc) onto an IKS cluster. You can even install the Istio Bookinfo sample with a single click, Knative is also available as preview.

![]({{ site.baseurl }}/images/2019/04/selection_393.png)

There is even a free (lite) Kubernetes cluster available (single node, 2 vCPUs, 4 GB RAM) but you need an IBM Cloud Account with a credit card entered in order to use it, even if it is free of charge. I have heard stories that there was too much Bitcoin mining going on on the lite clusters, go figure! You can also try and get an IBM Cloud promo code, we hand them out at conferences where we are present, your next chances in Germany are JAX in Mainz, WeAreDevelopers and DevOpsCon in Berlin, ContainerDays in Hamburg .

![]({{ site.baseurl }}/images/2019/04/selection_390.png)

There is also an IBM Cloud Container Registry (ICR) available, this is a container image repository comparable to Dockerhub but private on the IBM Cloud. You can store your own container images there and reference them in Kubernetes deployment files for deployment on the IBM Cloud. You can even use ICR to build your container images.

I have created scripts to deploy Cloud Native Starter onto the IBM Cloud and documented the steps [here](https://github.com/ibm/cloud-native-starter/blob/master/IKS-Deployment.md){:target="_blank"}. Here I want to point out the few things that are different and very specific when deploying to IBM Cloud Kubernetes Service compared to deploying to Minikube

First, you need to be logged on the IBM Cloud of course which you do with the ibmcloud CLI, then you need to set the cloud-based Kubernetes environment configuration, and finally login to the Container Registry, too  

```sh
$ ibmcloud login  
$ ibmcloud region-set us-south  
$ ibmcloud ks cluster-config <clustername>  
$ ibmcloud cr login
```

After that, 'kubectl' and 'docker' commands work with the IBM Cloud and not a local resource. 'ibmcloud ks cluster-config' is comparable to the 'minikube docker-env' for Minikube.

'ibmcloud ks cluster-config' outputs an 'export **KUBECONFIG**=/.../... .yaml'. Copy and paste this export statement into your shell and execute it. This statement needs to be executed every time a new shell is opened where a kubectl command should run on your IKS cluster!

This is the command to build the container image for the Authors Service API locally or on Minikube:  
`$ docker build -f Dockerfile -t authors:1 .` 

To build the image on the IBM Container Registry requires this command:  
`$ ibmcloud cr build -f Dockerfile --tag us.icr.io/cloud-native/authors:1 .`  

'cr' is the subcommand for Container Registry, 'us.icr.io' is the URL for the Registry hosted in the US, and 'cloud-native' is a namespace within this registry. This is the dashboard view of the Registry with all images of Cloud Native Starter:

![]({{ site.baseurl }}/images/2019/04/selection_391.png)

The deployment YAML files need to be adapted to reference the correct location of the image. This is the spec for Minikube with the image being locally available in Minikube:

```yaml
spec:
  containers:
  - image: authors:1
    name: authors
```

This is the spec for IBM Cloud Container Registry:

```yaml
spec:
  containers:
  - image: us.icr.io/cloud-native/authors:1
    name: authors
```

Everything else is identical to Minikube in the files. In my deployment scripts, I use 'sed' to automatically create new deployment files.

Deploying to IKS is not different to deploying to Minikube, just make sure that the KUBECONFIG environment is setup to use the IKS cluster.

A lite (free) Kubernetes cluster on the IBM Cloud has no Ingress or Loadbalancer available. That is reserved for paid clusters. Istio, however, has its own Ingress (istio-ingressgateway) and this is accessible via a NodePort, http on port 31380, https on port 31390. To determine the public IP address of an IKS worker node, issue the command:  
`$ ibmcloud ks workers <clustername>`

The result looks like this:

![]({{ site.baseurl }}/images/2019/04/selection_392-1.png)

To access the Cloud Native Starter webapp, simply point your browser to  
`http://149.81.xx.x3:31380` 

In our Github repository is a script iks-scripts/show-urls.sh that will point out all important URLs on the IBM Cloud deployment, including the commands to access Kiali, Jaeger, etc.

![]({{ site.baseurl }}/images/2019/04/iks-urls.png)
