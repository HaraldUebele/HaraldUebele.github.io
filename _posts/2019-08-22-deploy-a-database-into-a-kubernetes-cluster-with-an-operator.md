---
layout: post
categories: [Kubernetes,OpenShift]
title: "Deploy a Database into a Kubernetes Cluster with an Operator"
date: "2019-08-22"
tag: "2019"
---

Kubernetes Operators are a Kubernetes extension that was introduced by CoreOS. On their [website](https://coreos.com/operators/){:target="_blank"} they explain it like this:

> "An Operator is a method of packaging, deploying and managing a Kubernetes application. A Kubernetes application is an application that is both deployed on Kubernetes and managed using the Kubernetes APIs and kubectl tooling."

IMHO, databases in Kubernetes are the perfect target for Operators: they require a lot of skill to install them -- this typically involves things like stateful sets, persistent volume claims, and persistent volumes to name a few -- and to manage them which includes updates, scaling up and down depending on the load, etc. An operator could and should handle all this.

CoreOS established [OperatorHub.io](https://operatorhub.io){:target="_blank"} as a central location to share Operators. I looked at the Database section there and found a [Postgres-Operator](https://operatorhub.io/operator/postgres-operator){:target="_blank"} provided by Zalando SE and decided to give it a try. This is my experience with it, maybe it is of use to others.

![](/images/2019/08/880_440_v11-categories@2x.png)

One of the easiest ways to test it is using Minikube. I wrote about Minikube before and I still like it a lot. You can try something new and if it doesn't work, instead of trying to get rid of all the artefacts in Kubernetes, stop the cluster, delete it, and start a new one. On my notebook this takes between 5 and 10 minutes. So I started my Operator adventure with a fresh instance of Minikube:

![](/images/2019/08/selection_487.png)

I cloned the Github repository of [Operator Lifecycle Manager](https://github.com/operator-framework/operator-lifecycle-manager){:target="_blank"} (OLM) which

> ... enables users to do the following:

> - Define applications as a single Kubernetes resource that encapsulates requirements and metadata
> 
> - Install applications automatically with dependency resolution or manually with nothing but `kubectl`
> 
> - Upgrade applications automatically with different approval policies ...

There is an [installation guide](https://github.com/operator-framework/operator-lifecycle-manager/blob/master/Documentation/install/install.md){:target="_blank"} and I tried to follow the instructions "Run locally with minikube" but that failed, no idea why. I then simply did the "Manual Installation" and this works perfect on Minikube, too:

```sh
kubectl create -f deploy/upstream/quickstart/crds.yaml
kubectl create -f deploy/upstream/quickstart/olm.yaml
```

Once the OLM is running you can even get a nice UI, installation is described [here](https://github.com/operator-framework/operator-lifecycle-manager#user-interface){:target="_blank"}. It looks a bit weird but what is does is download the Open Source OKD version of the OpenShift web console as Docker image, runs this image locally on your workstation, and connects it to your Kubernetes cluster which in my case is Minikube.

![](/images/2019/08/selection_488.png)

OKD Console with OperatorHub menu

In this list of Operators you can find the [Zalando Postgres-Operator](https://github.com/zalando/postgres-operator){:target="_blank"} and directly install it into your cluster.

![](/images/2019/08/selection_489.png)

You click "Install" and then "Subscribe" to it using the defaults and after a moment you should see "InstallSucceeded" in the list of installed Operators:

![](/images/2019/08/selection_490.png)

The Operator is installed in the Kubernetes "operators" namespace. It allows to create PostgreSQL instances in your cluster. In the beginning there is no instance or Operand:

![](/images/2019/08/selection_491.png)

You can "Create New": "Postgresql" ... but the P dissapears later :-) and then you see the default YAML for a minimal cluster. The creation of a new PostgreSQL cluster only seems to work in the same namespace that the Operator is installed into so make sure that the YAML says "namespace: operators".

![](/images/2019/08/selection_492.png)

Once you click "Create" it takes a couple of minutes until the cluster is up. The okd console unfortunately isn't able to show the resources of the "acid-minimal-cluster". But you can see them in the Kubernetes dashboard and with kubectl:

![](/images/2019/08/selection_493.png)

If you have "psql" (the PostgreSQL CLI) installed you can access the acid-minimal-cluster with:

```sh
$ export HOST_PORT=$(minikube service acid-minimal-cluster -n operators --url | sed 's,.*/,,')  
$ export PGHOST=$(echo $HOST_PORT | cut -d: -f 1)  
$ export PGPORT=$(echo $HOST_PORT | cut -d: -f 2)  
$ export PGPASSWORD=$(kubectl get secret postgres.acid-minimal-cluster.credentials.postgresql.acid.zalan.do -n operators -o 'jsonpath={.data.password}' | base64 -d)  
$ psql -U postgres
```

In the okd / OLM dashboard you can directly edit the YAML of the PostgreSQL cluster, here I have changed the number of instances from 2 to 4 and "Saved" it:

![](/images/2019/08/selection_494.png)

Looking into the Kubernetes dashboard you can see the result, there are now 4 acid-minimal-cluster-* pods:

![](/images/2019/08/selection_495.png)
