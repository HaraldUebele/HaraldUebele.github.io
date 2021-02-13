---
layout: post
categories: [Kubernetes,OpenShift]
title: "Deploying the Cloud Native Starter microservices on Minishift"
date: "2019-07-03"
---

Initially I thought that different Kubernetes environments are more or less identical. I have learned in the past weeks that some of them are more and some are less so and there are always differences so here are my notes on deployments on Minishift. As a seasoned OpenShift user you might find it strange why I describe the obvious but if you come from a plain Kubernetes background like I did, this maybe helpful. Since I am still a noob in all things OpenShift maybe things are really done differently?

OpenShift enforces role based access control and security and thus enables strict separation of "projects" which are based on Kubernetes namespaces.

So in order to start a new project on OpenShift/Minishift, you create a project and apply some security policies to it. The project automatically includes a Kubernetes namespace of the same name and an "[image stream](https://docs.openshift.com/enterprise/3.0/architecture/core_concepts/builds_and_image_streams.html#image-streams){:target="_blank"}" - also of the same name - to store Docker images in the OpenShift Docker registry. In my last [blog](https://haralduebele.github.io/2019/06/28/cloud-native-starter-and-openshift-okd-minishift/){:target="_blank"}, I wrote about Minishift setup and Istio installation and that Maistra, the Istio "flavour" I installed, is enforcing mTLS. Since we haven't implemented mTLS in Cloud Native Starter, we need to apply a [no-mtls](https://github.com/IBM/cloud-native-starter/blob/master/minishift-scripts/no-mtls.yaml){:target="_blank"} policy to our projects name space. The [setup-project.sh](https://github.com/IBM/cloud-native-starter/blob/master/minishift-scripts/setup-project.sh){:target="_blank"} script does exactly this.

![](/images/2019/07/selection_463.png)
The final result in the Minishift Console
{: style="color:gray;font-style: italic; font-size: 90%; text-align: center;"}

With Minikube, Docker images can be built in the Docker environment that runs in the VM (by using the `eval $(minikube docker-env)` command) and Kubernetes can pull the images directly from there.

With the IBM Cloud Container Registry (ICR), you can build images locally on your workstation, tag them for ICR, and then push them to the registry, or you can use the CLI to build them directly in the repository (`ibmcloud cr build`).

Minishift is similar to ICR: You can do the _docker build, docker tag, docker push_ sequence, use the Minishift Docker environment for the build (`eval $(minishift docker-env)`), and then push the image to the OpenShift Docker Registry. This is what I do in the script "[deploy-authors-nodejs.sh](https://github.com/IBM/cloud-native-starter/blob/master/minishift-scripts/deploy-authors-nodejs.sh){:target="_blank"}":

## Create Docker Image and push to registry 

```sh
eval $(minishift docker-env)
docker login -u admin -p $(oc whoami -t) $(minishift openshift registry)
imagestream=$(minishift openshift registry)/cloud-native-starter/authors:1
docker build -f Dockerfile -t authors:1 .
docker tag authors:1 $imagestream
docker push $imagestream
```

Note the `docker login ...`, this is required to access the OpenShift Docker Registry.

One issue here is the Docker version in Minishift, currently it is Version 1.13.1 (which is equivalent to Version 17.03 in the new Docker versioning scheme). We use multi-stage builds on Minikube for the articles and web-api service and for the web-app. This means, we use build containers as stage 1 and deploy the generated artifacts into stage 2 and thus into the final container image ([example](https://github.com/IBM/cloud-native-starter/blob/master/web-app-vuejs/Dockerfile){:target="_blank"}). But multi-stage build requires at least Docker Version 17.05. So for the web-app in script [deploy-web-app.sh](https://github.com/IBM/cloud-native-starter/blob/master/minishift-scripts/deploy-web-app.sh){:target="_blank"} I use an OpenShift build option, "binary build", which supports multi-stage build:

```sh
oc new-build --name web-app --binary --strategy docker
oc start-build web-app --from-dir=.
```

This creates a "build config" on OpenShift in our project, uploads the code to OpenShift into a build container, builds the image, and pushes it into the OpenShift Docker Registry, specifically into the image stream for our project.

And then I use `oc apply -f kubernetes-minishift.yaml` to create the Kubernetes deployment. Why not use the OpenShift `oc new-app` command? Because I want to specify the Istio sidecar inject annotation in the [yaml](https://github.com/IBM/cloud-native-starter/blob/master/web-app-vuejs/deployment/kubernetes-minishift.yaml){:target="_blank"} file. I haven't found a way to do that with `oc new-app`.

How can you access this service running on OpenShift? Again there are multiple options: OpenShift specific is to [create a route](https://github.com/IBM/cloud-native-starter/blob/master/minishift-scripts/deploy-web-app.sh){:target="_blank"} (`oc expose svc/web-app`). Or Istio specific by using the [Istio Ingress Gateway](https://github.com/IBM/cloud-native-starter/blob/master/istio/istio-ingress-gateway.yaml){:target="_blank"} and a [VirtualService](https://github.com/IBM/cloud-native-starter/blob/master/istio/istio-ingress-service-web-api-v1-only.yaml){:target="_blank"} using the Gateway.

![](/images/2019/07/selection_464.png)
Cloud Native Starter in the Kiali dashboard
{: style="color:gray;font-style: italic; font-size: 90%; text-align: center;"}

