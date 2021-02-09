---
layout: post
title: "Blue Cloud Mirror - Of Kubes and Couches"
date: "2019-02-01"
---

In my last blog I presented an overview and introduction to Blue Cloud Mirror. In this blog I want to describe the back end of the Users API.


If a player of [Blue Cloud Mirror](https://blue-cloud-mirror.mybluemix.net) decides to enter the competition and enters their user data, they are stored when the game is over and the player clicks "Save Score" on the Results page. Data is stored on premise (off the cloud) with the help of this Users API. The data set contains first name, last name, email, and the acceptance of the terms.


The Users API back end is made up of a Node.js application and CouchDB, both deployed on Minikube. You will find details here [https://github.com/IBM/blue-cloud-mirror/tree/master/users](https://github.com/IBM/blue-cloud-mirror/tree/master/users)

Our original plan was to use IBM Cloud Private ("eat your own cookies") and I started to build a IBM Cloud Private instance but this is too big for a simple demo. There is an IBM Cloud Private Community Edition that everyone can download and use but its resource requirements exceed by far what is available on a typical notebook; no way to carry it around for a demo at a conference. You would need to have a server of a certain size that you can spare for the demo. Instead we decided to go with Minikube.

![](/images/2019/01/users-overview.png?w=836)


[Minikube](https://kubernetes.io/docs/setup/minikube/) is a single node Kubernetes "cluster" that can run on a notebook. It is not suitable for production, of course, but it is sufficient to run this demo. Per default Minikube starts a cluster that uses 2 CPUs (or CPU threads depending on how you count them), 2 GB of RAM, and 20 GB of disk. If your notebook or server has more resources, you can utilize them. Other than that, setup of Minikube is really easy: download the Minikube executable and type "minikube start". After 10 to 15 minutes you'll have a Kubernetes cluster. All you need to do is enable ingress and that's it.


There is a CouchDB container image on Docker Hub which I have used to create a simple deployment with a single pod. You need to persist the configuration and the data of CouchDB, information is available on Docker Hub. My deployment creates two persistent volumes of type HostPath and two persistent volume claims, one for the configuration and one for the data directory. Minikube provides a /data directory in the nodes file system that is [persistent over reboots](https://kubernetes.io/docs/setup/minikube/#persistent-volumes). This is why both persistent volumes point to the /data directory.


CouchDB starts up unconfigured in "Admin Party" mode. To be able to access CouchDB externally there is a NodePort definition for the CouchDB service, using port 32001. Once CouchDB is started, its admin dashboard (Fauxton) is available on this port. CouchDB configuration is described [here](https://github.com/IBM/blue-cloud-mirror/blob/master/users/README.md).

The User Core Service is written in Node.js and provides an API to access CouchDB. It uses "express" for the POST and GET methods, "express-basic-auth" to allow only authenticated access to the API, and "nano" to access CouchDB. The CouchDB URL is passed as environment variable in the Kubernetes deployment, the URL must contain User ID and password of the CouchDB setup.


The API is exposed externally with a Kubernetes ingress. (Remember to enable ingress in Minikube!) The ingress is configured for TLS for a host name "users-api.cloud". TLS uses a self signed certificate and the host name must be entered into the /etc/hosts file of the system running Minikube (unless you are the master of your DNS). Instructions are in the [README](https://github.com/IBM/blue-cloud-mirror/blob/master/users/README.md). Using a self signed TLS certificate is no problem since it is used in only one place, the configuration of IBM Secure Gateway. Which I will explain in my next post. Stay tuned!
