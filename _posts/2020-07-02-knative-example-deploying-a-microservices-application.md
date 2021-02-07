---
layout: post
title: "Knative Example: Deploying a Microservices Application"
date: "2020-07-02"
categories: [Knative,Kubernetes,Serverless,Microservices]
tag: "2020"
---

I have written about Knative Installation, Knative Serving, and Knative Eventing. I have used the simple HelloWorld sample application which is perfectly fine to learn Knative. But I wanted to apply what I have learned with an example that is closer to reality. If you have followed my blog, you should know our pet project [Cloud Native Starter](https://github.com/IBM/cloud-native-starter). It contains sample code that demonstrates how to get started with cloud-native applications and microservice based architectures.

Cloud Native Starter is basically made up of 3 microservices: Web-API, Articles, and Authors. I have used it for an Istio hands-on workshop where one of the objectives is Traffic Management:

![Cloud Native Starter]({{ site.baseurl }}/images/2020/06/cloudnativestarter-architecture.png?w=701)

- A browser-based application requests a list of blog articles from the Web-API via the Istio Ingress.
- The Web-API service retrieves a list of blog articles from the Articles services, and for every article it retrieves author details from the Authors service.
- There are two versions of the Web-API service.
- Container images for all services are available on my Docker Hub repository.

I think this is perfect to exercise my new Knative skills.

For this example I wanted to give Minikube another try. In my first blog about Knative installation I had issues with Minikube together with Knative 0.12 which has specific instructions on how to install it on Minikube. I have now tested Minikube v1.11.0 with Knative Serving 0.15 and Kourier as networking layer using the [default Knative 0.15 installation instructions](https://knative.dev/docs/install/any-kubernetes-cluster/) and I am happy to report:

**Knative Serving 0.15 works on Minikube!**

Here is the experience with Cloud Native Starter and Knative:

## Microservice 1: Authors

The simplest service is Authors, I started to deploy it with a simple Knative YAML file:

```yaml
apiVersion: serving.knative.dev/v1
kind: Service
metadata:
  name: authors
spec:
  template:
    metadata:
      name: authors-v1
    spec:
      containers:
      - image: docker.io/haraldu/authors:1
        env:
        - name: DATABASE
          value: 'local'
        - name: CLOUDANT\_URL
          value: ''
```

The only additional configuration are the two environment variables, DATABASE and CLOUDANT\_URL. With those the service could be configured to use an external Cloudant database to store the author information. With the settings above, authors information is stored in memory (local) only.

When you deploy this on Minikube, it creates a Knative service

```sh
$ kn service list
NAME       URL                                         LATEST        AGE     CONDITIONS   READY   REASON
authors    http://authors.default.example.com          authors-v1    12s     3 OK / 3     True    
```

It shows that the service listens on the URL:

http://authors.default.example.com

This URL cannot be called directly, it is not resolvable via DNS unless you are able to configure your DNS server or use a local hosts file. With a "real" Kubernetes or OpenShift cluster with a real Ingress e.g. provisioned on the IBM Cloud these steps would not be necessary. To be able to call the API, we need the IP address of the Minikube "worker" node:

```sh
$ minikube ip
192.168.39.169
```

And here you can find the NodePort of the Kourier ingress:

```sh
kubectl get svc kourier -n kourier-system
NAME      TYPE           CLUSTER-IP       EXTERNAL-IP   PORT(S)                      AGE
kourier   LoadBalancer   10.109.186.248   <pending>     80:30265/TCP,443:31749/TCP   4d1h
```

The NodePort that serves HTTP is 30265. The correct Ingress IP address is therefore: 192.168.39.169:30265

A REST API call to the Authors service using 'curl' is then build like this:

```sh
$ curl -H 'Host: authors.default.example.com' http://192.168.39.169:30265/api/v1/getauthor?name=Harald%20Uebele
{"name":"Harald Uebele","twitter":"@harald_u","blog":"https://haralduebele.blog"}
```

In this way the Ingress gets the request with the correct host name in the request header.

'authors.default.example.com' is an external URL. But the Authors service needs to be called internally only, it shouldn't be exposed to the outside. A Knative service can be configured as '[private cluster-local](https://knative.dev/docs/serving/cluster-local-route/)'. This is done by tagging either the Knative service or the route:

```sh
$ kubectl label kservice authors serving.knative.dev/visibility=cluster-local
service.serving.knative.dev/authors labeled
```

Checking the Knative service again:

```sh
$ kn service list
NAME       URL                                         LATEST        AGE    CONDITIONS   READY   REASON  
authors    http://authors.default.svc.cluster.local    authors-v1    84m    3 OK / 3     True    
```

The URL is now cluster-local. We can also accomplish that by adding an annotation to the YAML file. This saves one step but we are no longer able test the API in a simple manner with `curl`.

## Microservice 2: Articles

The Articles Knative service definition is this:

```yaml
kind: ConfigMap
apiVersion: v1
metadata:
  name: articles-config
data:
  samplescreation: CREATE
  inmemory: USE\_IN\_MEMORY\_STORE
---
apiVersion: serving.knative.dev/v1
kind: Service
metadata:
  name: articles
  labels:
    serving.knative.dev/visibility: cluster-local
spec:
  template:
    metadata:
      name: articles-v1
    spec:
      containers:
      - image: docker.io/haraldu/articles:1
        ports:
        - containerPort: 8080
        env:
        - name: samplescreation
          valueFrom:
            configMapKeyRef:
              name: articles-config
              key: samplescreation
        - name: inmemory
          valueFrom:
            configMapKeyRef:
              name: articles-config
              key: inmemory
        livenessProbe:
          exec:
            command: \["sh", "-c", "curl -s http://localhost:8080/"\]
          initialDelaySeconds: 20
        readinessProbe:
          exec:
            command: \["sh", "-c", "curl -s http://localhost:8080/health | grep -q articles"\]
          initialDelaySeconds: 40
```

Articles uses a ConfigMap which needs to be created, too.

In the spec.containers section, environment variables are pulled from the ConfigMap and also liveness and readiness probes are defined. Articles is already tagged as 'cluster-local', it will only be callable from within the cluster.

Deploy and check shows nothing unusual:

```sh
$ kn service list
NAME       URL                                         LATEST        AGE    CONDITIONS   READY   REASON
articles   http://articles.default.svc.cluster.local   articles-v1   53s    3 OK / 3     True    
authors    http://authors.default.svc.cluster.local    authors-v1    99m    3 OK / 3     True    
```

Since Articles is cluster-internal, it can not be tested. You could use another container in the cluster that can be SSHed into, e.g. an otherwise empty Fedora container, and call the API from there. So I think the best practice during development is to tag the service cluster-only via command as explained in the Authors service section and not use the label in the YAML file. That way you can test the API using `curl` via external URL and switch to cluster-only once you are confident that the service works as expected.

## Microservice 3: Web-API

This is the service that caused the most trouble although the YAML to deploy it is quite simple:

```yaml
apiVersion: serving.knative.dev/v1
kind: Service
metadata:
  name: web-api
spec:
  template:
    metadata:
      name: web-api-v1
    spec:
      containers:
      - image: docker.io/haraldu/web-api:1
        ports:
        - containerPort: 9080
        livenessProbe:
          exec:
            command: \["sh", "-c", "curl -s http://localhost:9080/"\]
          initialDelaySeconds: 20
        readinessProbe:
          exec:
            command: \["sh", "-c", "curl -s http://localhost:9080/health | grep -q web-api"\]
          initialDelaySeconds: 40
```

It uses readiness and liveness probes like Articles, both services are based on MicroProfile and this is to show the MicroProfile Health feature.

This service must reachable from the outside, no tagging for cluster-local is therefore required.

Deploy it and check for the URL:

```sh
$ kn service list
NAME       URL                                         LATEST        AGE    CONDITIONS   READY   REASON
articles   http://articles.default.svc.cluster.local   articles-v1   53s    3 OK / 3     True    
authors    http://authors.default.svc.cluster.local    authors-v1    99m    3 OK / 3     True    
web-api    http://web-api.default.example.com          web-api-v1a   4d1h   3 OK / 3     True    
```

Test it with 'curl':

```sh
$ curl -H 'Host: web-api.default.example.com' http://192.168.39.169:30265/web-api/v1/getmultiple
```

Nothing happens, the call seems to hang, it returns an empty object. The error log shows:

\[err\] com.ibm.webapi.business.getArticles: Cannot connect to articles service

What is wrong? Digging into the code reveals that Web-API issues REST requests to the wrong URL, e.g. for Articles:

`static final String BASE_URL = "http://articles:8080/articles/v1/";`

Identical situation for Authors:

`static final String BASE_URL = "http://authors:3000/api/v1/";`

The URLs are correct for Kubernetes, both services run in the same namespace and can be called by simply using their name. And they listen on different ports. For Knative they need to be changed to call `http://articles.default.svc.cluster.local/articles/v1/` and `http://authors.default.svc.cluster.local/api/v1/`, both without port definition because Knative and its Ingress require fully qualified DNS names and expose HTTP on port 80. I have changed the code, recompiled the two versions of Web-API and created Container Images on Docker Hub: `docker.io/haraldu/web-api:knative-v1` and `docker.io/haraldu/web-api:knative-v2` (which we need later).

Testing with 'curl' still gives no result, but checking of the pods shows why:

```sh
$ kubectl get pod
NAME READY STATUS RESTARTS AGE
articles-v1-deployment-5ddf9869c7-rslv5 0/2 Running 0 22s
web-api-v1-deployment-ff547b857-pc5ms 2/2 Running 0 2m8s
```

Articles has been scaled to zero and it is still in the process of starting (READY: 0/2). It is a traditional Java app and takes some time to start. `initialDelaySeconds` parameters for liveness and readiness probes add some additional delay. Authors has been scaled to zero, too, but as a Node.js app it starts quickly. For Java based microservices that are supposed to be deployed on Knative, Quarkus is definitely a better choice as it [reduces startup time](http://heidloff.net/article/serverless-quarkus-kubernetes-java-knative/) dramatically.

## Disable Scale-to-Zero

This is the modified YAML for Articles, it includes the cluster-local label and the `minScale: "1"` that prevents scale to zero:

```yaml
kind: ConfigMap
apiVersion: v1
metadata:
  name: articles-config
data:
  samplescreation: CREATE
  inmemory: USE\_IN\_MEMORY\_STORE
---
apiVersion: serving.knative.dev/v1
kind: Service
metadata:
  name: articles
  labels:
    serving.knative.dev/visibility: cluster-local
spec:
  template:
    metadata:
      name: articles-v1
      annotations:
        autoscaling.knative.dev/minScale: "1"
    spec:
      containers:
      - image: docker.io/haraldu/articles:1
        ports:
        - containerPort: 8080
        env:
        - name: samplescreation
          valueFrom:
            configMapKeyRef:
              name: articles-config
              key: samplescreation
        - name: inmemory
          valueFrom:
            configMapKeyRef:
              name: articles-config
              key: inmemory
        livenessProbe:
          exec:
            command: \["sh", "-c", "curl -s http://localhost:8080/"\]
          initialDelaySeconds: 20
        readinessProbe:
          exec:
            command: \["sh", "-c", "curl -s http://localhost:8080/health | grep -q articles"\]
          initialDelaySeconds: 40
```

And here is the one for Web-API (v1):

```yaml
apiVersion: serving.knative.dev/v1
kind: Service
metadata:
  name: web-api
spec:
  template:
    metadata:
      name: web-api-v1
      annotations:
        autoscaling.knative.dev/minScale: "1"
    spec:
      containers:
      - image: docker.io/haraldu/web-api:knative-v1
        ports:
        - containerPort: 9080
        livenessProbe:
          exec:
            command: \["sh", "-c", "curl -s http://localhost:9080/"\]
          initialDelaySeconds: 20
        readinessProbe:
          exec:
            command: \["sh", "-c", "curl -s http://localhost:9080/health | grep -q web-api"\]
          initialDelaySeconds: 40
```

## Canary Testing

In the architecture diagram at the very beginning of this article you can see two versions of Web-API. Their difference is: Version 1 displays a list of 5 articles, Version 2 displays 10 articles. If you deploy a new version of a microservice you will most likely want to test it first, maybe as a canary deployment on a subset of users using Traffic Management.

This is how you define it:

```yaml
apiVersion: serving.knative.dev/v1
kind: Service
metadata:
  name: web-api
spec:
  template:
    metadata:
      name: web-api-v2
      annotations:
        autoscaling.knative.dev/minScale: "1"
    spec:
      containers:
      - image: docker.io/haraldu/web-api:knative-v2
        ports:
        - containerPort: 9080
        livenessProbe:
          exec:
            command: \["sh", "-c", "curl -s http://localhost:9080/"\]
          initialDelaySeconds: 20
        readinessProbe:
          exec:
            command: \["sh", "-c", "curl -s http://localhost:9080/health | grep -q web-api"\]
          initialDelaySeconds: 40
  traffic:
    - tag: v1
      revisionName: web-api-v1
      percent: 75
    - tag: v2
      revisionName: web-api-v2
      percent: 25
```

In the image section, the knative-v2 Container image is referenced.

The traffic sections performs a 75% / 25% split between Version 1 and Version 2. If you know Istio you will know where this function comes from. You will also know how much needs to be configured to enable traffic management with Istio: VirtualService, DestinationRule, and entries to the Ingress Gateway configuration.

## Conclusion and further information

This was the description of an almost "real life" microservices example on Knative. You have seen that with typical Java based microservices with their long start-up times the serverless scale-to-zero pattern doesn't work. If you want to use Java together with scale-to-zero, you need to utilize recent developments in Java like Quarkus with its impressively fast start-up.

So is Knative worth the effort and resources? I am not sure about Knative Eventing. But Knative Serving with its easier deployment files and the easy implementation of auto-scaling and traffic management are definitely worth a try. But keep in mind that Knative is not well suited for every workload that you would deploy on Kubernetes.

Additional reading:

1. Knative documentation, [https://knative.dev/docs](https://knative.dev/docs)
2. Red Hat Knative Tutorial, [https://redhat-developer-demos.github.io/knative-tutorial](https://redhat-developer-demos.github.io/knative-tutorial)
3. Deploying serverless apps with Knative, [https://cloud.ibm.com/docs/containers?topic=containers-serverless-apps-knative](https://cloud.ibm.com/docs/containers?topic=containers-serverless-apps-knative)
