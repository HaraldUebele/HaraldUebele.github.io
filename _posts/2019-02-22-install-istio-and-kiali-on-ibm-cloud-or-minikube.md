---
layout: post
categories: [Kubernetes,Istio]
title: "Install Istio and Kiali on IBM Cloud or Minikube"
date: "2019-02-22"
tag: "2019"
---

I recently started to look into Istio and Kiali.

[Istio](https://istio.io){:target="_blank"} is an open-source service mesh that sits on top of Kubernetes. It provides functions for traffic control, fault tolerance, logging and monitoring, and security. It has started as joint project by IBM, Google, and Lyft. Kiali is an Istio dashboard and in my opinion Istio is only half the fun without Kiali.

In order to explore Istio you need a Kubernetes Cluster. I have tested two options:

1. IBM Kubernetes Service on IBM Cloud. There is a free ("lite") cluster that you can use for 21 days.
2. Minikube. If you have a reasonably sized notebook, Minikube is great, too.

### IBM Kubernetes Service

You can create a free Kubernetes cluster (single node, 2 CPUs, 4 GB memory) that will be active for 21 days, after this time it will be deleted. Although the cluster is free, you still need an IBM Cloud account where you entered a credit card.

To create a Kubernetes cluster, select "Kubernetes" from the burger menu in the upper left corner of the IBM Cloud dashboard.

![]({{ site.baseurl }}/images/2019/02/selection_355.png)
{:center: style="text-align: center"}
_Create a free Kubernetes cluster on the IBM Cloud_
{:center}

In the "Kubernetes" dashboard, select "Clusters" on the left, then click on "Create cluster." Select "Free" (1), a location (2), give your cluster a name (3) and click "Create cluster". Creation takes about 15 to 20 minutes.

Once the cluster is deployed and in status "Normal", go to the "Add-ons" tab.

![]({{ site.baseurl }}/images/2019/02/selection_358.png)
{:center: style="text-align: center"}
_Kubernetes Add-Ons on IBM Cloud_
{:center}

Click "Install" for Managed Istio, then select "Istio", "Extras", and "Sample". This is so cool: 5 clicks and you have a managed Istio, with Grafana, Jaeger, and Kiali, and the Istio Bookinfo sample to start with.

Gaining access to the Kubernetes cluster is described in the "Acccess" tab of the cluster dashboard:

![]({{ site.baseurl }}/images/2019/02/selection_359.png)

Basically you need the "ibmcloud" CLI, login to you IBM Cloud account, target the region where you cluster is located, and download the Kubernetes configuration file. The instruction in the dashboard and at the end of the download specify an "export" string that you need to paste into the command shell. After that, kubectl will target the cluster in IBM Kubernetes Service. In addition there is a button in the cluster dashboard that opens the "Kubernetes Dashboard".

Access to Kiali requires a port-forward, the URL for Kiali then is http://localhost:20001

```sh
kubectl -n istio-system port-forward $(kubectl -n istio-system get pod -l app=kiali -o jstadata.name}') 20001:20001
```

If you installed the Bookinfo sample, this is how you can find the public IP address of the worker node:

```sh
ibmcloud ks workers <cluster name> 
```

```sh
kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="http2")].nodePort}' 
```

gives the port number of the istio-ingress-gateway, typically 31380.

Bookinfo productpage is then available at _http://publicIP:31380/productpage_

![]({{ site.baseurl }}/images/2019/02/selection_360.png)
{:center: style="text-align: center"}
_Istio Bookinfo Sample_
{:center}


### Minikube

Installation instructions for Minikube can be found [here](https://kubernetes.io/docs/setup/minikube/). I run it on Linux (Fedora 29) with VirtualBox (Version 5.2.26) as Hypervisor. It starts with a default of 2 CPUs, 2 GB of RAM, and 20 GB diskspace for the Virtual Machine in VirtualBox. This is not sufficient for Istio, I was able to run it on 4 GB of RAM, but the more CPU and memory are available for it, the better it performs.

You can set the configuration for Minikube with these commands before starting it for the first time:

```sh
minikube config set cpus 4
minikube config set memory 8192
minikube config set disk-size 50g
minikube addons enable ingress 
minikube start
```

This starts Minikube with 4 CPUs, 8 GB of memory, a 50 GB virtual disk (VirtualBox uses thin provisioning, it doesn't really use 50 GB of disk space unless the virtual disk really fills up), and it enables Kubernetes Ingress. Starting Minikube can take 15 to 20 minutes for the first start.

"minikube dashboard" will then open the Kubernetes dashboard, "minikube stop" stops the cluster, "minikube start" restarts the existing cluster, and "minikube delete" deletes the cluster (in case you want to start fresh or get rid of it).

The fastest method to install Istio on Minikube is this:

```sh
curl -L https://git.io/getLatestIstio | sh -
```

This will download Istio into a directory "istio-1.0.6" (at the time when I wrote this blog) and will instruct you to add a directory to your PATH variable so that you can use "istioctl", its CLI. Change into the istio-1.x.x directory and install some custom resource definitions:

```sh
kubectl apply -f install/kubernetes/helm/istio/templates/crds.yaml
```

Once this is complete, install Istio itself:

```sh
kubectl apply -f install/kubernetes/istio-demo.yaml
```

Once the installation has completed, check the status of the Istio pods:

```sh
kubectl get pod -n istio-system  
```

![]({{ site.baseurl }}/images/2019/02/selection_361.png)

All pods must be in status Running (2/2) or Completed (0/1). Then install Kiali

```sh
bash <(curl -L http://git.io/getLatestKialiKubernetes)  
```

You are asked for a Kiali admin userid and password. Once installation is complete, check if the Kiali pod is ready ("kubectl get pod -n istio-system"). Once it is ready, look at its log:

```sh
kubectl log kiali-xxxx-xxxx -n istio-system
```

It should look similar to this:

```
I0208 05:56:09.375998       1 update_base_url.go:13] Updating base URL in index.html with [**/kiali**]  
 I0208 05:56:09.376658 1 javascript_config.go:13] Generating env.js from config  
 I0208 05:56:09.379867 1 server.go:44] Server endpoint will start at [:20001/kiali]  
 I0208 05:56:09.379884 1 server.go:45] Server endpoint will serve static content from [/opt/kiali/console]  
 I0208 05:56:09.380503 1 server.go:50] **Server endpoint will require https**
```

This means that Kiali is listening on URI /kiali on https. It is configured to use a NodePort:

```sh
kubectl get svc -n istio-system
```

The Kiali entry looks like this:

```
kiali NodePort 10.103.75.235  20001:**31993**/TCP
```

The Minikube IP address can be found with

```sh
minikube ip
```

In my environment it is 192.168.99.100.

So the Kiali Dashboard can be accessed at https://192.168.99.100:31993/kiali _Accessing the Dashboard requires to accept a security exception since it uses a self-signed TLS certificate!_  

![]({{ site.baseurl }}/images/2019/02/selection_362.png)
{:center: style="text-align: center"}
_Kiali Dashboard_
{:center}

Install the Bookinfo sample, you need to be inside the istio-1.x.x directory:

```sh
kubectl create namespace bookinfo
kubectl apply -n bookinfo -f <(istioctl kube-inject -f  samples/bookinfo/platform/kube/bookinfo.yaml)
```

Once the Bookinfo pods are available ("kubectl get pods -n bookinfo"), create an istio-ingressgateway to access the Bookinfo productpage:

```sh
kubectl apply -n bookinfo -f samples/bookinfo/networking/bookinfo-gateway.yaml
```

The Bookinfo productpage is then at http://minikubeIP.31380/productpage
