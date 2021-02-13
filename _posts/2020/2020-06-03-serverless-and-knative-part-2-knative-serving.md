---
layout: post
title: "Serverless and Knative - Part 2: Knative Serving"
date: "2020-06-03"
categories: [Knative,Kubernetes,Serverless]
---

In the [first part of this series](https://haralduebele.github.io/2020/06/02/serverless-and-knative-part-1-installing-knative-on-codeready-containers/){:target="_blank"} I went through the installation of Knative on CodeReady Containers which is basically Red Hat OpenShift 4.4 running on a notebook.

In this second part I will cover Knative Serving, which is responsible for deploying and running containers, also networking and auto-scaling. Auto-scaling allows scale to zero and is probably the main reason why Knative is referred to as Serverless platform.

![Knative logo](/images/2020/06/m5EQknfW_400x400.jpg)

Before digging into Knative Serving let me share a piece of information from the [Knative Runtime Contract](https://github.com/knative/serving/blob/master/docs/runtime-contract.md){:target="_blank"} which helps to position Knative. It compares Kubernetes workloads (general-purpose containers) with Knative workloads (stateless request-triggered containers):

"_In contrast to general-purpose containers, stateless request-triggered (i.e. on-demand) autoscaled containers have the following properties:_

- _Little or no long-term runtime state (especially in cases where code might be scaled to zero in the absence of request traffic)._
- _Logging and monitoring aggregation (telemetry) is important for understanding and debugging the system, as containers might be created or deleted at any time in response to autoscaling._
- _Multitenancy is highly desirable to allow cost sharing for bursty applications on relatively stable underlying hardware resources._"

Or in other words: Knative sees itself better suited for short running processes. You need to provide central logging and monitoring because the pods come and go. And multi-tenant hardware can be provided large enough to scale for peaks and at the same time make effective use of the resources.

As a developer, I would expect Knative to make my life easier (Knative claims that it is "abstracting away the complex details and enabling developers to focus on what matters") but instead when coming from Kubernetes it gets more complicated and confusing at first because Knative uses new terminology for its resources. They are:

1. **Service**: Responsible for managing the life cycle of an application/workload. Creates and owns the other Knative objects Route and Configuration.
2. **Route**: Maps a network endpoint to one or multiple Revisions. Allows Traffic Management.
3. **Configuration**: Desired state of the workload. Creates and maintains Revisions.
4. **Revision**: A specific version of a code deployment. Revisions are immutable. Revisions can be scaled up and down. Rules can be applied to the Route to direct traffic to specific Revisions.

![Kn object model](/images/2020/06/object_model.png)
(c) knative.dev
{: style="color:gray;font-style: italic; font-size: 90%; text-align: center;"}

Did I already mention that this is confusing? We now need to distinguish between Kubernetes services and Knative services. And on OpenShift, between OpenShift Routes and Knative Routes.

Enough complained, here starts the interesting part:

### Creating a sample application

I am following this [example](https://knative.dev/v0.12-docs/serving/samples/hello-world/helloworld-nodejs/index.html){:target="_blank"} from the Knative web site which is a simple Hello World type of application written in Node.js. The sample is also available in Java, Go, PHP, Python, Ruby, and some other languages.

Instead of using the Docker build explained in the example I am using an OpenShift Binary build which builds the Container image on OpenShift and stores it as an Image stream in the OpenShift Image Repository. Of course, the Container image could also be on Docker Hub or Quay.io or any other repository that you can access. If you follow the Knative example step by step, you create the Node.js application, a Dockerfile, and some more files. On OpenShift, for the Binary build, we need the application code and the Dockerfile and then create an OpenShift project and the Container image with these commands:

```sh
$ oc new-project knativetutorial
$ oc new-build --name helloworld --binary --strategy docker
$ oc start-build helloworld --from-dir=.
```

### Deploying an app as Knative Service

Next I continue with the Knative example. This is the service.yaml file required to deploy the 'helloworld' example as a Knative Service:

```yaml
apiVersion: serving.knative.dev/v1
kind: Service
metadata:
  name: helloworld-nodejs
spec:
  template:
    metadata:
      name: helloworld-nodejs-v1
    spec:
      containers:
        - image: image-registry.openshift-image-registry.svc:5000/knativetutorial/helloword:latest
          env:
            - name: TARGET
              value: "Node.js Sample v1"
```              

If you are familiar with Kubernetes, you have to start to pay close attention to the first line, to see that this is the definition of a _Knative Service_.

All you need for your deployment are the highlighted lines, specifically the first 'metadata'.'name' and the 'containers'.'images' specification to tell Kubernetes where to find the Container image.

Line 11 specifies the location of the Container image just like every other Kubernetes deployment description. In this example, the 'helloworld' image is the Image stream in the OpenShift internal Image Repository in a project called 'knativetutorial'. It is the result of the previous section "Creating a sample application".

Lines 12, 13, and 14 are setting an environment variable and are used to "create" different versions. (In the Hello World code, the variable TARGET represents the "World" part.)

Lines 7 and 8, 'metadata' and 'name', are optional but highly recommended. They are used to provide arbitrary names for the Revisions. If you omit this second name, Knative will use default names for the Revisions ("helloworld-nodejs-xhz5df") and if you have more than one version/revision this makes it difficult to distinguish between them.

With CRC and Knative correctly set up, I simply deploy the service using `oc:`

```sh
$ oc apply -f service.yaml
service.serving.knative.dev/helloworld-nodejs created
```

The reply isn't very spectacular but if you look around (`oc get all`) you can see that a lot has happened:

1. A Kubernetes Pod is created, running two containers: user-container and Envoy
2. Multiple Kubernetes services are created, one is equipped with an OpenShift route
3. An OpenShift Route is created
4. A Kubernetes deployment and a replica-set are created
5. Knative service, configuration, route, and revision objects are created

It would have taken a YAML file with a lot more definitions and specifications to accomplish all that with plain Kubernetes. I would say that the Knative claim of "abstracting away the complex details and enabling developers to focus on what matters" is definitely true!

Take a look at the OpenShift Console, in the Developer, Topology view:

![](/images/2020/06/image.png?w=1024)

I really like the way the Red Hat OpenShift developers have visualized Knative objects here.

If you click on the link (Location) of the Route, you will see the helloworld-nodejs response in a browser:

![](/images/2020/06/image-4.png?w=614)

If you wait about a minute or so, the Pod will terminate: "All Revisions are autoscaled to 0". If you click on the Route location (URL) then, a Pod will be spun up again.

Another good view of the Knative service is available through the [`kn` CLI](https://knative.dev/docs/install/install-kn/){:target="_blank"} tool:

```sh
$ kn service list
NAME                URL                                                         LATEST                 AGE   CONDITIONS   READY   REASON
helloworld-nodejs   http://helloworld-nodejs-knativetutorial.apps-crc.testing   helloworld-nodejs-v1   13m   3 OK / 3     True  
```

```sh
$ kn service describe helloworld-nodejs
Name:       helloworld-nodejs
Namespace:  knativetutorial
Age:        15m
URL:        http://helloworld-nodejs-knativetutorial.apps-crc.testing

Revisions:  
  100%  @latest (helloworld-nodejs-v1) [1] (15m)
        Image:  image-registry.openshift-image-registry.svc:5000/knativetutorial/helloword:latest (at 53b1b4)

Conditions:  
  OK TYPE                   AGE REASON
  ++ Ready                  15m 
  ++ ConfigurationsReady    15m 
  ++ RoutesReady            15m 
```

### Adding a new revision

I will now create a second version of our app and deploy it as a second Revision using a new file, service-v2.yaml:

```yaml
apiVersion: serving.knative.dev/v1
kind: Service
metadata:
  name: helloworld-nodejs
spec:
  template:
    metadata:
      name: helloworld-nodejs-v2
    spec:
      containers:
        - image: image-registry.openshift-image-registry.svc:5000/knativetutorial/helloword:latest
          env:
            - name: TARGET
              value: "Node.js Sample v2 -- UPDATED"
```


I have changed the revision number to '-v2' and modified the environment variable TARGET so that we can see which "version" is called. Apply with:

```sh
$ oc apply -f service-v2.yaml
service.serving.knative.dev/helloworld-nodejs configured
```

Checking with the `kn` CLI we can see that Revision '-v2' is now used:

```sh
$ kn service describe helloworld-nodejs
Name:       helloworld-nodejs
Namespace:  knativetutorial
Age:        21m
URL:        http://helloworld-nodejs-knativetutorial.apps-crc.testing

Revisions:  
  100%  @latest (helloworld-nodejs-v2) [2] (23s)
        Image:  image-registry.openshift-image-registry.svc:5000/knativetutorial/helloword:latest (at 53b1b4)

Conditions:  
  OK TYPE                   AGE REASON
  ++ Ready                  18s 
  ++ ConfigurationsReady    18s 
  ++ RoutesReady            18s 
```

It is visible in the OpenShift Web Console, too:

![](/images/2020/06/image-1.png?w=1024)

Revision 2 has now fully replaced Revision 1.

### Traffic Management

What if we want to Canary test Revision 2? It is just a simple modification in the YAML:

```yaml
apiVersion: serving.knative.dev/v1
kind: Service
metadata:
  name: helloworld-nodejs
spec:
  template:
    metadata:
      name: helloworld-nodejs-v2
    spec:
      containers:
        - image: image-registry.openshift-image-registry.svc:5000/knativetutorial/helloword:latest
          env:
            - name: TARGET
              value: "Node.js Sample v2 -- UPDATED"
  traffic:
    - tag: v1
      revisionName: helloworld-nodejs-v1
      percent: 75
    - tag: v2
      revisionName: helloworld-nodejs-v2
      percent: 25
```

This will create a 75% / 25% distribution between revision 1 and 2. Deploy the change and watch in the OpenShift Web Console:

![](/images/2020/06/image-2.png?w=1024)

Have you ever used Istio? To accomplish this with Istio requires configuring the Ingress Gateway plus defining a Destination Rule and a Virtual Service. In Knative it is just adding a few lines of code to the Service description. Have you noticed the "Set Traffic Distribution" button in the screen shot of the OpenShift Web Console? Here you can modify the distribution on the fly:

![](/images/2020/06/image-3.png?w=540)

### Auto-Scaling

Scale to zero is an interesting feature but without additional tricks (like pre-started containers or pods which aren't available in Knative) it can be annoying because users have to wait until a new pod is started and ready to receive requests. Or it can lead to problems like time-outs in a microservices architecture if a scaled-to-zero service is called by another service and has to be started first.

On the other hand, if our application / microservice is hit hard with requests, a single pod may not be sufficient to serve them and we may need to scale up. And preferably scale up and down automatically.

Auto-scaling is accomplished by simply adding a few annotation statements to the Knative Service description:

```yaml
apiVersion: serving.knative.dev/v1
kind: Service
metadata:
  name: helloworld-nodejs
spec:
  template:
    metadata:
      name: helloworld-nodejs-v3
      annotations:
        # the minimum number of pods to scale down to
        autoscaling.knative.dev/minScale: "1"
        # the maximum number of pods to scale up to
        autoscaling.knative.dev/maxScale: "5"
        # Target in-flight-requests per pod.
        autoscaling.knative.dev/target: "1"
    spec:
      containers:
        - image: image-registry.openshift-image-registry.svc:5000/knativetutorial/helloword:latest
          env:
            - name: TARGET
              value: "Node.js Sample v3 -- Scaling"
```

* minScale: "1" prevents scale to zero, there will always be at least 1 pod active.  
* maxScale: "5" will allow to start a maximum of 5 pods.  
* target: "1" limits every started pod to 1 concurrent request at a time, this is just to make it easier to demo.

All auto-scale parameters are listed and described [here](https://knative.dev/docs/serving/configuring-autoscaling/){:target="_blank"}.

Here I deployed the auto-scale example and run a load test using the [hey](https://github.com/rakyll/hey) command against it:

```sh
$ hey -z 30s -c 50 http://helloworld-nodejs-knativetutorial.apps-crc.testing/

Summary:
  Total:	30.0584 secs
  Slowest:	1.0555 secs
  Fastest:	0.0032 secs
  Average:	0.1047 secs
  Requests/sec:	477.1042
  
  Total data:	501935 bytes
  Size/request:	35 bytes

Response time histogram:
  0.003 [1]	    |
  0.108 [9563]	|■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
  0.214 [3308]	|■■■■■■■■■■■■■■
  0.319 [899]	|■■■■
  0.424 [367]	|■■
  0.529 [128]	|■
  0.635 [42]	|
  0.740 [15]	|
  0.845 [10]	|
  0.950 [5]	    |
  1.056 [3]	    |

Latency distribution:
  10% in 0.0249 secs
  25% in 0.0450 secs
  50% in 0.0776 secs
  75% in 0.1311 secs
  90% in 0.2157 secs
  95% in 0.2936 secs
  99% in 0.4587 secs

Details (average, fastest, slowest):
  DNS+dialup:	0.0001 secs, 0.0032 secs, 1.0555 secs
  DNS-lookup:	0.0001 secs, 0.0000 secs, 0.0197 secs
  req write:	0.0000 secs, 0.0000 secs, 0.0079 secs
  resp wait:	0.1043 secs, 0.0031 secs, 1.0550 secs
  resp read:	0.0002 secs, 0.0000 secs, 0.3235 secs

Status code distribution:
  [200]	14341 responses

$ oc get pod
NAME                                               READY   STATUS    RESTARTS   AGE
helloworld-nodejs-v3-deployment-66d7447b76-4dhql   2/2     Running   0          28s
helloworld-nodejs-v3-deployment-66d7447b76-pvxqg   2/2     Running   0          29s
helloworld-nodejs-v3-deployment-66d7447b76-qxkbc   2/2     Running   0          28s
helloworld-nodejs-v3-deployment-66d7447b76-vhc69   2/2     Running   0          28s
helloworld-nodejs-v3-deployment-66d7447b76-wphwm   2/2     Running   0          2m35s
```

In the end of the output we see 5 pods are started, one of them for a longer time (2m 35s) than the rest. That is the minScale: "1" pre-started pod.

### Jakarta EE Example from Cloud Native Starter

I wanted to see how easy it is to deploy any form of application using Knative Serving.

I used the authors-java-jee microservice that is part of our [Cloud Native Starter](https://github.com/IBM/cloud-native-starter){:target="_blank"} project and that we use in an exercise of an OpenShift workshop. A Container image of this service is stored on Dockerhub in my colleague Niklas Heidloffs registry as `nheidloff/authors:v1`

This is the Knative service.yaml:

```yaml
apiVersion: serving.knative.dev/v1
kind: Service
metadata:
  name: authors-jee
spec:
  template:
    metadata:
      name: authors-jee-v1
    spec:
      containers:
      - image: docker.io/nheidloff/authors:v1
```

When I deployed this I noticed that it never starts (you need to scroll the following view to the right to see the problem):

```sh
$ kn service list
NAME          URL                                                   LATEST   AGE   CONDITIONS   READY     REASON
authors-jee   http://authors-jee-knativetutorial.apps-crc.testing            33s   0 OK / 3     Unknown   RevisionMissing : Configuration "authors-jee" is waiting for a Revision to become ready.

$ oc get pod
NAME                                         READY   STATUS    RESTARTS   AGE
authors-jee-v1-deployment-7dd4b989cf-v9sv9   1/2     Running   0          42s
```

The user-container in the pod never starts and the Revision never becomes ready. Why is that?

To understand this problem you have to know that there are two versions of the authors service: The first version is written in Node.js and listens on port 3000. The second version is the JEE version we try to deploy here. To make it a drop-in replacement for the Node.js version it is configured to listen on port 3000, too. Very unusual for JEE and something Knative obviously does not pick up from the Docker metadata in the image.

The Knative Runtime Contract has some information about [Inbound Network Connectivity](https://github.com/knative/serving/blob/master/docs/runtime-contract.md#inbound-network-connectivity){:target="_blank"}, Protocols and Ports:

_"The developer MAY specify this port at deployment; if the developer does not specify a port, the platform provider MUST provide a default. Only one inbound `containerPort` SHALL be specified in the core.v1.Container specification. The `hostPort` parameter SHOULD NOT be set by the developer or the platform provider, as it can interfere with ingress autoscaling. Regardless of its source, the selected port will be made available in the PORT environment variable."_

I found another piece of information regarding containerPort in the [IBM Cloud documentation about Knative](https://cloud.ibm.com/docs/containers?topic=containers-serverless-apps-knative#knative-container-port){:target="_blank"}:

_"By default, all incoming requests to your Knative service are sent to port 8080. You can change this setting by using the `containerPort` specification."_

I modified the Knative service yaml with ports.containerPort info:

```yaml
apiVersion: serving.knative.dev/v1
kind: Service
metadata:
  name: authors-jee
spec:
  template:
    metadata:
      name: authors-jee-v2
    spec:
      containers:
      - image: docker.io/nheidloff/authors:v1
        ports:
        - containerPort: 3000
```

Note the Revision '-v2'! Check after deployment:

```sh
$ kn service list
NAME          URL                                                   LATEST           AGE   CONDITIONS   READY   REASON
authors-jee   http://authors-jee-knativetutorial.apps-crc.testing   authors-jee-v2   11m   3 OK / 3     True    

$ oc get pod
NAME                                        READY   STATUS    RESTARTS   AGE
authors-jee-v2-deployment-997d44565-mhn7w   2/2     Running   0          51s
```

The authors-java-jee microservice is using Eclipse Microprofile and has implemented specific health checks. They can be used as Kubernetes **readiness and liveness probes**, the YAML file then looks like this, syntax is exactly the standard Kubernetes syntax:

```yaml
apiVersion: serving.knative.dev/v1
kind: Service
metadata:
  name: authors-jee
spec:
  template:
    metadata:
      name: authors-jee-v2
    spec:
      containers:
      - image: docker.io/nheidloff/authors:v1
        ports:
        - containerPort: 3000
        livenessProbe:
          exec:
            command: ["sh", "-c", "curl -s http://localhost:3000/"]
          initialDelaySeconds: 20
        readinessProbe:
          exec:
            command: ["sh", "-c", "curl -s http://localhost:3000/health | grep -q authors"]
          initialDelaySeconds: 40
```

### Microservices Architectures and Knative private services

So far the examples I tested where all exposed on public URLs using the Kourier Ingress Gateway. This is useful for testing and also for externally accessible microservices, e.g. backend-for-frontend services that serve a browser-based web front end or a REST API for other external applications. The multitude of microservices in a cloud native application will only and should only be called cluster local and not be exposed with an external URL.

The Knative documentation has information on how to [label a service cluster-local](https://knative.dev/v0.12-docs/serving/cluster-local-route/){:target="_blank"}. You can either add a label to the Knative service or the Knative route. The steps described in the documentation are to 1. deploy the service and then 2. convert it to cluster-local via the label.

You can easily add the label to the YAML file and immediately deploy a cluster-local Knative service. This is the modified Jakarta EE example of the previous section:

```yaml
apiVersion: serving.knative.dev/v1
kind: Service
metadata:
  name: authors-jee
  labels:
    serving.knative.dev/visibility: cluster-local
spec:
  template:
    metadata:
      name: authors-jee-v2
    spec:
      containers:
      - image: docker.io/nheidloff/authors:v1
        ports:
        - containerPort: 3000
```

When this is deployed to OpenShift, the correct URL shows up in the Route:

![](/images/2020/06/image-5.png?w=493)

Of course you can no longer open the URL in your browser, this address is only available from within the Kubernetes cluster.

### Debugging Tips

There are new places to look for information as to why a Knative service doesn't work. Here is a list of helpful commands and examples:

1. Display the Knative service:

    ```sh
    $ kn service list
    NAME          URL                                                   LATEST   AGE    CONDITIONS   READY   REASON
    authors-jee   http://authors-jee-knativetutorial.apps-crc.testing            3m7s   0 OK / 3     False   RevisionMissing : Configuration "authors-jee" does not have any ready Revision.
    ```

    It is normal and to be expected that the revision is not available for some time immediately after the deployment because the application container needs to start first. But in this example the revision isn't available after over 3 minutes and that is not normal.

    You can also display Knative service info using `oc` instead of `kn` by using 'kservice':

    ```sh
    $ oc get kservice
    NAME          URL                                                   LATESTCREATED    LATESTREADY   READY   REASON
    authors-jee   http://authors-jee-knativetutorial.apps-crc.testing   authors-jee-v2                 False   RevisionMissing
    ```

2. Check the pod:

    ```sh
    $ oc get pod
    No resources found in knativetutorial namespace.
    ```

    That is bad: no pod means no logs to look at.

3. Get information about the revision:

      ```sh
      $ oc get revision
      NAME             CONFIG NAME   K8S SERVICE NAME   GENERATION   READY   REASON
      authors-jee-v2   authors-jee                      1            False   ContainerMissing

      $ oc get revision authors-jee-v2 -o yaml
      apiVersion: serving.knative.dev/v1
      kind: Revision
      [...]
      status:
        conditions:
        - lastTransitionTime: "2020-06-03T08:12:49Z"
          message: 'Unable to fetch image "docker.io/nheidloff/authors:1": failed to resolve
            image to digest: failed to fetch image information: GET https://index.docker.io/v2/nheidloff/authors/manifests/1:
          MANIFEST_UNKNOWN: manifest unknown; map[Tag:1]'
        reason: ContainerMissing
        status: "False"
        type: ContainerHealthy
      - lastTransitionTime: "2020-06-03T08:12:49Z"
        message: 'Unable to fetch image "docker.io/nheidloff/authors:1": failed to resolve
          image to digest: failed to fetch image information: GET https://index.docker.io/v2/nheidloff/authors/manifests/1:
          MANIFEST_UNKNOWN: manifest unknown; map[Tag:1]'
        reason: ContainerMissing
        status: "False"
        type: Ready
      - lastTransitionTime: "2020-06-03T08:12:47Z"
        status: Unknown
        type: ResourcesAvailable
    [...]
    ```

    The conditions under the status topic show that I have (on purpose as a demo) mistyped the Container image tag.

    This is a real example:

    ```sh
    $ oc get revision helloworld-nodejs-v1 -o yaml
    [...]
    status:
      conditions:
      - lastTransitionTime: "2020-05-28T06:42:14Z"
        message: The target could not be activated.
        reason: TimedOut
        severity: Info
        status: "False"
        type: Active
      - lastTransitionTime: "2020-05-28T06:40:04Z"
        status: Unknown
        type: ContainerHealthy
      - lastTransitionTime: "2020-05-28T06:40:05Z"
        message: '0/1 nodes are available: 1 Insufficient cpu.'
        reason: Unschedulable
        status: "False"
        type: Ready
      - lastTransitionTime: "2020-05-28T06:40:05Z"
        message: '0/1 nodes are available: 1 Insufficient cpu.'
        reason: Unschedulable
          status: "False"
          type: ResourcesAvailable
    ```

    These conditions clearly show that the cluster is under CPU pressure and unable to schedule a new pod. This was on my first CRC configuration that used only 6 vCPUs.

---

In my next blog article in this series I will talk about [Knative Eventing](https://haralduebele.github.io/2020/06/10/serverless-and-knative-part-3-knative-eventing/).
