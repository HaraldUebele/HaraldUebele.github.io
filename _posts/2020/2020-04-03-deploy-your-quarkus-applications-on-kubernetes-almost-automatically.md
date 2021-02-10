---
layout: post
categories: [Kubernetes,OpenShift,Quarkus,Container]
title: "Deploy your Quarkus applications on Kubernetes. Almost automatically!"
date: "2020-04-03"
---

You want to code Java, not Kubernetes deployment YAML files? And you use Quarkus? You may have seen the [announcement blog for Quarkus 1.3.0](https://quarkus.io/blog/quarkus-1-3-0-final-released). Under "much much more" is a feature that is very interesting to everyone using Kubernetes or OpenShift and with a dislike for the required YAML files:

#### _"Easy deployment to Kubernetes or OpenShift"_

_The Kubernetes extension has been overhauled and now gives users the ability to deploy their Quarkus applications to Kubernetes or OpenShift with almost no effort. Essentially the extension now also takes care of generating a container image and applying the generated Kubernetes manifests to a target cluster, after the container image has been generated._"

![Quarkus Logo](/images/2020/04/quarkus_icon.png)
{:center: style="font-size: 90%; text-align: center"}
_Image © quarkus.io_
{:center}

There are two Quarkus extensions required.

1. [Kubernetes Extension](https://quarkus.io/guides/kubernetes)  
    This extension generates the Kubernetes and OpenShift YAML (or JSON) files and also manages the automatic deployment using these files.
2. [Container Images](https://quarkus.io/guides/container-image)  
    There are actually 3 extensions that can handle automatic build using:  
    - Jib  
    - Docker  
    - OpenShift Source-to-image (s2i)

Both extensions use parameters that are placed into the application.properties file. The parameters are listed in the respective guides of the extensions. Note that I use the term "listed". Some of these parameters are really just listed without any further explanation.

You can find the list of parameters for the Kubernetes extension [here](https://quarkus.io/guides/kubernetes#configuration-options), those for the Container Image extension are [here](https://quarkus.io/guides/container-image#customizing).

I tested the functionality in 4 different scenarios: Minikube, IBM Cloud Kubernetes Service, and Red Hat OpenShift in the form of CodeReady Containers (CRC) and Red Hat OpenShift on IBM Cloud. I will describe all of them here.

### Demo Project

I use the simple example from the Quarkus Getting Started Guide as my demo application. The current **Quarkus 1.3.1 uses Java 11 and requires Apache Maven 3.6.2+**. My notebook runs on Fedora 30 so I had to manually install Maven 3.6.3 because the version provided in the Fedora 30 repositories is too old.

The following command creates the Quarkus Quickstart Demo:

```sh
$ mvn io.quarkus:quarkus-maven-plugin:1.3.1.Final:create \
    -DprojectGroupId=org.acme \
    -DprojectArtifactId=config-quickstart \
    -DclassName="org.acme.config.GreetingResource" \
    -Dpath="/greeting"
$ cd config-quickstart
```

You can run the application locally:

```sh
$ ./mvnw compile quarkus:dev
```

Then test it:

```sh
$ curl -w "\n" http://localhost:8080/hello
hello
```

Now add the Kubernetes and Docker Image extensions:

```
$ ./mvnw quarkus:add-extension -Dextensions="kubernetes, container-image-docker"
```

### Edit application.properties

The Kubernetes extension will create 3 Kubernetes objects:

1. Service Account
2. Service
3. Deployment

The configuration and naming of these is based on some basic parameters that have to be added in application.properties:

|Property|Description| 
|---|---|
|`quarkus.kubernetes.part-of=todo-app` | One of the Kubernetes "recommended" labels (recommended, not required)| 
|`quarkus.container-image.registry=`<br>`quarkus.container-image.group=`<br>`quarkus.container-image.name=getting-started`<br>`quarkus.container-image.tag=1.0` | Specifies the container image in the K8s deployment. Result is `image: getting-started:1.0`. Make sure there are no excess or trailing spaces! I specify empty registry and group parameters to obtain predictable results.| 
|`quarkus.kubernetes.service-type=NodePort` | Creates a service of type NodePort, default would be ClusterIP (doesn't really work with Minikube)| 


Now do a test compile with

```sh
$ ./mvnw clean package
```

This should result in `BUILD SUCCESS`. Look at the `kubernetes.yml` file in the `target/kubernetes` directory.

Every object (ServiceAccount, Service, Deployment) has a set of annotations and labels. The annotations are picked up automatically when the source directory is under version control (e.g. git) and from the last compile time. The labels are picked up from the parameters specified in the table above. You can specify additional parameters but the Kubernetes extensions uses specific defaults:

- `app.kubernetes.io/name` and name in the YAML are set to quarkus.container-image.name.
- `app.kubernetes.io/version` in the YAML is set to the container-image.tag parameter.

The definition of the port (http, 8080) is picked up by Quarkus from the source code during compile.

### Deploy to

![Minikube](/images/2020/04/minikube-logo-1024x290.jpg)

With Minikube, we will create the Container (Docker) Image in the Docker installation that is part of the Minikube VM. So after starting Minikube (`minikube start`) you need to point your local docker command to the Minikube environment:

```sh
$ eval $(minikube docker-env)
```

The Kubernetes extension specifies `imagePullPolicy: Always` as the default for a container image. This is a problem when using the Minikube Docker environment, it should be `never` instead. Your application.properites should therefore look like this:

```
quarkus.kubernetes.part-of=todo-app
quarkus.container-image.registry=
quarkus.container-image.group=
quarkus.container-image.name=getting-started
quarkus.container-image.tag=1.0
quarkus.kubernetes.image-pull-policy=never
quarkus.kubernetes.service-type=NodePort
```

Now try a test build & deploy in the getting-started directory:

```sh
$ ./mvnw clean package -Dquarkus.kubernetes.deploy=true
```

Check that everything is started with:

```sh
$ kubectl get pod 
$ kubectl get deploy
$ kubectl get svc
```

Note that in the result of the last command you can see the NodePort of the getting-started service, e.g. 31304 or something in that range. Get the IP address of your Minikube cluster:

```sh
$ minikube ip
```

And then test the service, in my example with:

```sh
$ curl 192.168.39.131:31304/hello
hello
```

The result of this execise:

Installing 2 Quarkus extensions and adding 7 statements to the application.properties file (of which 1 is optional) allows you to compile your Java code, build a container image, and deploy it into Kubernetes with a single command. I think this is cool!

![IKS](/images/2020/04/image.png?w=1024)

What I just described for Minikube also works for the IBM Cloud. IBM Cloud Kubernetes Service (or IKS) does not have an internal Container Image Registry, instead this is a separate service and you may have guessed its name: IBM Cloud Container Registry (ICR). This example works on free IKS clusters, too. A [free IKS cluster](https://cloud.ibm.com/docs/containers?topic=containers-getting-started#clusters_gs) is free of charge and you can use for 30 days.

For our example to work, you need to create a "Namespace" in an ICR location which is different from a Kubernetes namespace. For example, my test Kubernetes cluster (with the name: mycluster) is located in Houston, so I create a namespace called 'harald-uebele' in the registry location Dallas (because it is close to Houston).

Now I need to login and setup the connection using the `ibmcloud` CLI:

```sh
$ ibmcloud login
$ ibmcloud ks cluster config --cluster mycluster
$ ibmcloud cr login
$ ibmcloud cr region-set us-south
```

The last command will set the registry region to us-south which is Dallas and has the URL 'us.icr.io'.

`application.properties` needs a few changes:

- `registry` now holds the ICR URL (us.icr.io)
- `group` is the registry namespace mentioned above
- `image-pull-policy` is changed to always for ICR
- `service-account` needs to be 'default', the service account created by the Kubernetes extension ('getting-started') is not allowed to pull images from the ICR image registry

```
quarkus.kubernetes.part-of=todo-app
quarkus.container-image.registry=us.icr.io
quarkus.container-image.group=harald-uebele
quarkus.container-image.name=getting-started
quarkus.container-image.tag=1.0
quarkus.kubernetes.image-pull-policy=always
quarkus.kubernetes.service-type=NodePort
quarkus.kubernetes.service-account=default
```

Compile & build as before:

```sh
$ ./mvnw clean package -Dquarkus.kubernetes.deploy=true
```

Check if the image has been built:

```sh
$ ibmcloud cr images
```

You should see the newly created image, correctly tagged, and hopefully with a 'security status' of 'No issues'. That is the result of a [Vulnerability Advisor scan](https://cloud.ibm.com/docs/Registry?topic=va-va_index) that is automatically performed on every image.

Now check the status of your deployment:

```sh
$ kubectl get deploy
$ kubectl get pod
$ kubectl get svc
```

With `kubectl get svc` you will see the number of the NodePort of the service, in my example it is 30850. You can obtain the public IP address of an IKS worker node with:

```sh
$ ibmcloud ks worker ls --cluster mycluster
```

If you have multiple worker nodes, any of the public IP addresses will do. Test your service with:

```sh
$ curl <externalIP>:<nodePort>/hello
```

The result should be 'hello'.

### All this also works on

![Red Hat OpenShift](/images/2020/04/logotype-rh-openshift-360x96_0.png)

I have tested this with [CodeReady Containers](https://haralduebele.github.io/2019/09/13/red-hat-openshift-4-on-your-laptop/) (CRC) and on [Red Hat OpenShift on IBM Cloud](https://cloud.ibm.com/docs/openshift?topic=openshift-getting-started). CRC was a bit flaky, sometimes it would build the image, create the deployment config but wouldn't start the pod.

On OpenShift, the container image is built using [Source-to-Image](https://docs.openshift.com/container-platform/4.3/builds/understanding-image-builds.html#build-strategy-s2i_understanding-image-builds) (s2i) and this requires a different Maven extension:

```sh
$ ./mvnw quarkus:add-extension -Dextensions="container-image-s2i"
```

It seems like you can have only container-image extensions in your project. If you installed the `container-image-docker` extension before, you'll need to remove it from the dependency section of the `pom.xml` file, otherwise the build may fail, later.

There is an OpenShift specific section of parameters / options is the [documentation](https://quarkus.io/guides/kubernetes#openshift) of the extension.

Start with log in to OpenShift and creating a new project (quarkus):

```sh
$ oc login ...
$ oc new-project quarkus
```

This is the application.properties file I used:

```
quarkus.kubernetes.deployment-target=openshift
quarkus.container-image.registry=image-registry.openshift-image-registry.svc:5000
quarkus.container-image.group=quarkus
quarkus.container-image.name=getting-started
quarkus.container-image.tag=1.0
quarkus.openshift.part-of=todo-app
quarkus.openshift.service-account=default
quarkus.openshift.expose=true
quarkus.kubernetes-client.trust-certs=true
```

Line 1: Create an OpenShift deployment  
Line 2: This is the (OpenShift internal) image repository URL for OpenShift 4  
Line 3: The OpenShift project name  
Line 4: The image name will also be used for all other OpenShift objects  
Line 5: Image tag, will also be the application version in OpenShift  
Line 6: Name of the OpenShift application  
Line 7: Use the 'default' service account  
Line 8: Expose the service with a route (URL)  
Line 9: Needed for CRC because of self-signed certificates, don't use with OpenShift on IBM Cloud

With these options in place, start a compile & build:

```sh
$ ./mvnw clean package -Dquarkus.kubernetes.deploy=true
```

It will take a while but in the end you should see a "BUILD SUCCESS" and in the OpenShift console you should see an application called "todo-app" with a Deployment Config, Pod, Build, Service, and Route:

![OpenShift Console](/images/2020/04/image-1.png?w=1024)

### Additional and missing options

**Namespaces (Kubernetes) and Projects (OpenShift)** cannot be specified with an option in application.properties. With OpenShift thats not really an issue because you can specify which project (namespace) to work in with the oc CLI before starting the `mvn package`. But it would be nice if there were a namespace and/or project option.

The Kubernetes extension is picking up which Port your app is using during build. But if you need to specify an **additional port** this is how you do it:

```
quarkus.kubernetes.ports.https.container-port=8443
```

This will add an https port on 8443 to the service and an https containerPort on 8443 to the containers spec in the deployment.

The **number of replicas** is supposed to be defined with:

```
quarkus.kubernetes.replicas=4
```

This results in _WARN [io.qua.config](main) Unrecognized configuration key "quarkus.kubernetes.replicas" was provided; it will be ignored_ and the replicas count remains 1 in the deployment. **Instead use** the deprecated configuration option without _quarkus._ (I am sure this will be fixed):

```
kubernetes.replicas=4
```

Adding a key value pair **environment variables** to the deployment:

```
quarkus.kubernetes.env-vars.DB.value=local
```

will result in this YAML:

```yaml

    spec:
      containers:
      - env:
        - name: "DB"
          value: "local"
```

There are many more options, for readiness and liveness probes, mounts and volumes, secrets, config maps, etc. Have a look at the [documentation](https://quarkus.io/guides/kubernetes).
