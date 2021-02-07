---
layout: post
categories: [Kubernetes,OpenShift]
title: "Cloud Native Starter on Red Hat OpenShift 4"
date: "2020-01-23"
tag: "2020"
---

I have written about [Cloud Native Starter](https://github.com/IBM/cloud-native-starter){:target="_blank"} many times in this blog. It is a project created by Niklas Heidloff, Thomas Südbröcker, and myself that demonstrates how to get started with cloud-native applications and microservice based architectures. We have started it on Minikube, and ported it to IBM Cloud Kubernetes Service and to Red Hat OpenShift in the form of Minishift and Red Hat OpenShift on IBM Cloud, the last two based on OpenShift version 3.

![]({{ site.baseurl }}/images/2020/01/image-1.png?w=1024)

Cloud Native Starter Vue.js frontend

OpenShift 4 on the IBM Cloud is imminent and Minishift has a successor based on version 4 called [CodeReady Containers or CRC](https://haralduebele.github.io/2019/09/13/red-hat-openshift-4-on-your-laptop/){:target="_blank"}. Time to move Cloud Native Starter to OpenShift 4. Here is a summary of my experience.

![]({{ site.baseurl }}/images/2020/01/logo-red_hat-codeready_containers-a-standard-rgb-profile-square-300x127-1.png?w=300)
{:center: style="text-align: center"}
_© Red Hat Inc._
{:center}

#### Install CRC

I have [blogged about CRC before](https://haralduebele.github.io/2019/09/13/red-hat-openshift-4-on-your-laptop/){:target="_blank"} and back then in September 2019, CRC was version 1.0.0-beta3 and based on OpenShift 4.1.11. Today CRC is version 1.4, and based on OpenShift 4.2.13. It has matured quite a bit. The installation hasn't changed: CRC is still free of charge, but you need a Red Hat ID (also free) to obtain the pull secrets to install/start it. If you want to use Istio (of course you do!), the minimum requirement of 8 GB memory will not suffice, in my opinion 16 GB of memory are a requirement in this case. Other than that, setting up CRC is done by entering two commands: 'crc setup' which checks the prerequisites and does some setup for virtualization and networking, and 'crc start' which does the rest. First start takes around 15 minutes. In the end, it will tell you that the cluster is started (hopefully), issue a warning ("The cluster might report a degraded or error state. This is expected since several operators have been disabled to lower the resource usage.") and give you the credentials to log into OpenShift as kubeadmin and as developer.

#### Install OpenShift Service Mesh aka Istio

There is a simple way to install Istio -- which is called OpenShift Service Mesh by Red Hat -- into OpenShift 4. It uses Operators and I already described it [in another blog](https://haralduebele.github.io/2019/09/17/openshift-service-mesh-aka-istio-on-codeready-containers/){:target="_blank"}. Service Mesh requires 4 Operators for Elasticsearch, Jaeger, Kiali, and Service Mesh itself. The official documentation still states that you have to install all 4 of them in this sequence. Actually, last time I tried I simply installed the Service Mesh Operator and this pulled the other three without intervention.

While Service Mesh is Istio under the covers, Red Hat has added some features. You can have more than one Istio Control Plane in an OpenShift cluster, and they can have different configurations (demo and production for example). A 'Member Roll' then describes which OpenShift projects (namespaces) are a member of a specific Istio Control Plane. With vanilla upstream Istio, a namespace can be tagged to enable 'automatic sidecar injection'. When a deployment is made to a tagged namespace, an envoy sidecar is then automatically injected into each pod. This is very convenient in Kubernetes but not helpful in OpenShift. Consider constantly doing binary builds: this automatic sidecar injection would inject an envoy into every build pod where it has zero function because this pod will terminate once the build is complete and it doesn't communicate. Red Hat decided to trigger sidecar injection by adding an annotation to the deployment yaml file:

![]({{ site.baseurl }}/images/2020/01/image.png?w=507)

"Vanilla" Kubernetes/Istio ignores this annotation, there is no problem to have it in yaml files that are used on vanilla Kubernetes/Istio, too.

The telemetry tools and my favorite, Kiali, are integrated into the OpenShift authentication and accessible via a simple OpenShift route (https://kiali-istio-system.apps-crc.testing):

![]({{ site.baseurl }}/images/2020/01/image-3.png?w=1024)

Kiali as part of OpenShift Service Mesh

#### Access the OpenShift Internal Image Repository

For the CRC/OpenShift 4 port of Cloud Native Starter, I decided to do the container image builds on the local Docker daemon, then tag the resulting image, and push it into the internal image repository of OpenShift. How do you access the internal image repository? You need to login to OpenShift first, the do a 'docker login' to the repository:

```sh
$ oc login --token=<APITOKEN> --server=https://api.crc.testing:6443
$ docker login -u developer -p $(oc whoami -t) default-route-openshift-image-registry.apps-crc.testing
```

Problem is that the Docker CLI uses TLS and doesn't "know" the internal repository. The 'docker login' will terminate with a x509 error.

```
Error response from daemon: Get https://default-route-openshift-image-registry.apps-crc.testing/v2/: **x509: certificate signed by unknown authority**
```

CRC uses self signed certificates that Docker doesn't know about. But you can extract the required certificate and pass it to docker though, I have described the process [here](https://github.com/IBM/cloud-native-starter/blob/master/documentation/OS4Requirements.md#access-the-openshift-internal-image-repository){:target="_blank"}.

With the certificate in place for Docker, 'docker login' to the OpenShift repository is possible. 'docker build' in our scripts is local, the image is then tagged on the local Docker, and in the end push to OpenShift, e.g. for authors-nodejs service:

```sh
$ docker build -f Dockerfile -t  authors:1 .
$ docker tag authors:1 default-route-openshift-image-registry.apps-crc.testing/cloud-native-starter/authors:1
$ docker push default-route-openshift-image-registry.apps-crc.testing/cloud-native-starter/authors:1
```

After that the deployment is standard Kubernetes business with the notable exception that the image name in the deployment YAML file must reflect the location of the image within the OpenShift repository. Of course, our deployment scripts take care of that.

#### OpenShift and Container Permissions

In Cloud Native Starter there is one service, web-app-vuejs, that provides a Vue.js application, the frontend, to the browser of the user. To do that, Nginx is used as web server. The docker build has two stages: stage 1 builds the Vue.js application with yarn, stage 2 puts the resulting Vue.js into directory /usr/share/nginx/html in the image and Nginx serves this directory at default port 80. Works with vanilla Kubernetes (e.g. Minikube).

The pod reports "CrashLoopBackoff" and never starts in OpenShift. When you look at the logs you'll notice messages about non-root users and permissions. This image will never run on OpenShift unless you lower security constraints on the project -- they were implemented for a reason.

Information on how to solve this problem can be found in the blog [Deploy VueJS applications on OpenShift](https://blog.openshift.com/deploy-vuejs-applications-on-openshift/){:target="_blank"} written by Joel Lord:

1. Start Nginx on a port number above 1024, default port 80 and anything up to 1024 requires root
2. Move all temporary files (PID, cache, logs, CGI, etc.) to the /tmp directory (can be accessed by everyone
3. Use /code as base directory

Look here for my modified [nginx.conf](https://github.com/IBM/cloud-native-starter/blob/master/web-app-vuejs/nginx-os4.conf){:target="_blank"} and [Dockerfile](https://github.com/IBM/cloud-native-starter/blob/master/web-app-vuejs/Dockerfile.os4){:target="_blank"}.

#### Result

This is the Cloud Native Starter project in the OpenShift 4 Console:

![]({{ site.baseurl }}/images/2020/01/image-2.png?w=1024)

Project Overview in OpenShift 4
