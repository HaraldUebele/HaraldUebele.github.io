---
layout: post
categories: [2019,Kubernetes,Istio]
title: "Installing Istio 1.4 - New version, new methods"
date: "2019-11-21"
---

The latest release of Istio -- 1.4.x -- is changing the way Istio is installed. There are now two methods, the method using Helm will be deprecated in the future:

- Istio Operator, this is in alpha state at the moment and seems to be similar to the way Red Hat Service Mesh is installed (see [here](https://haralduebele.github.io/2019/09/17/openshift-service-mesh-aka-istio-on-codeready-containers/){:target="_blank"})
- Using `istioctl`

![]({{ site.baseurl }}/images/2019/11/istio1.4.png?w=796)

I have tried the `istioctl` method with a Kubernetes cluster on IBM Cloud (IKS) and want to document my findings.

### Download Istio

Execute the following command:

`$ curl -L https://istio.io/downloadIstio | sh -`

This will download the latest Istio version from Github, currently 1.4.0. When the command has finished there are instructions on how to add `istioctl` to your path environment variable. To do this is important for the next steps.

### Target your Kubernetes cluster

Execute the commands needed (if any) to be able to access your Kubernetes cluster. With IKS this is at least:

`$ ibmcloud ks cluster config <cluster-name>`

### Verify Istio and Kubernetes

`$ istioctl verify-install`

This will try and access your Kubernetes cluster and check if Istio is installable on it. The command should result in: "_Install Pre-Check passed! The cluster is ready for Istio installation."_

### Installation Configuration Profiles

There are 5 built-in Istio installation profiles: default, demo, minimal, sds, remote. Check with:

`$ istioctl profile list`

"minimal" installs only Pilot, "default" is a small footprint installation, "demo" installs almost all features in addition to setting the logging and tracing ratio to 100% (= everything) which is definitely not desirable in a production environment, it would put too much load on your cluster simply for logging and tracing.

[Here](https://istio.io/docs/setup/additional-setup/config-profiles/){:target="_blank"} is a good overview of the different profiles. You can modify the profiles and enable or disable certain features. I will use the demo profile, this has all the options I want enabled.

### Installing Istio

This requires a single command:

`$ istioctl manifest apply --set profile=demo`

### Verify the installation

First, generate a manifest for the demo installation:  
`$ istioctl manifest generate --set profile=demo > generated-manifest.yaml`  
Then verify that this was applied on your cluster correctly:  
`$ istioctl verify-install -f generated-manifest.yaml`  
Result (last lines) should look like this:

```
Checked 23 crds
Checked 9 Istio Deployments
Istio is installed successfully
```

Also check the Istio pods with:

`$ kubectl get pod -n istio-system`

The result should look similar to this:

```
NAME                                      READY   STATUS    RESTARTS   AGE
grafana-5f798469fd-r756w                  1/1     Running   0          7m
istio-citadel-56465d79b9-vtbbd            1/1     Running   0          7m5s
istio-egressgateway-5ff488489-99jkw       1/1     Running   0          7m5s
istio-galley-86c8659987-mlmsb             1/1     Running   0          7m4s
istio-ingressgateway-66c76dfc5f-kp8zb     1/1     Running   0          7m5s
istio-pilot-68bd4747d8-89qqt              1/1     Running   0          7m3s
istio-policy-77964b9766-v8l8n             1/1     Running   1          7m4s
istio-sidecar-injector-759bf6b4bc-ppwg2   1/1     Running   0          7m2s
istio-telemetry-5649c7d7c6-xt8wz          1/1     Running   1          7m3s
istio-tracing-cd67ddf8-ldvlp              1/1     Running   0          7m6s
kiali-7964898d8c-qb4jb                    1/1     Running   0          7m3s
prometheus-586d4445c7-tmw2q               1/1     Running   0          7m4s 
```

### Kiali, Prometheus, Jaeger

Kiali is Istio's dashboard and this is one of the coolest features in 1.4.x: To open the Kiali dashboard you no longer need to execute complicated port-forwarding commands, simply type

`$ istioctl dashboard kiali`

Then login with admin/admin:

![]({{ site.baseurl }}/images/2019/11/kiali.png?w=1024)

The same command works for Prometheus (monitoring) and Jaeger (tracing), too:

`$ istioctl dashboard prometheus`  
`$ istioctl dashboard jaeger`
