---
layout: post
categories: 2020
title: "Two great additions to 'kubectl'"
date: "2020-05-20"
tags: 
  - "kubectl"
  - "kubernetes"
---

I started to learn Kubernetes in its vanilla form. Almost a year ago I made my first steps on Red Hat OpenShift. From then on, going back to vanilla Kubernetes made me miss the easy way you switch namespaces (aka projects) in OpenShift. With 'oc project' it is like switching directories on your notebook. You can do that with 'kubectl' somehow but it is not as simple.

Recently I found 2 power tools for kubectl: 'kubectx' and 'kubens'. Ahmet Alp Balkan, a Google Software Engineer, created them and open sourced them ([https://github.com/ahmetb/kubectx](https://github.com/ahmetb/kubectx){:target="_blank"}).

The Github repo has installation instructions for macOS and diferent flavours of Linux. When you install them, also make sure to install 'fzf' ("A command-line fuzzy finder", [https://github.com/junegunn/fzf](https://github.com/junegunn/fzf){:target="_blank"}), it is a cool addition.

### kubens

'kubens' allows you to quickly switch namespaces in Kubernetes. Normally you work in 'default' and whenever you need to check something or do something in another namespace you need to add the '-n namespace' parameter to your command.

'kubens istio-system' will make 'istio-system' your new home and a subsequent 'kubectl get pod' or 'kubectl get svc' will show the pods and services in istio-system. Thats not all.

'kubens' without a parameter will list all namespaces and with 'fzf' installed too you have a selectable list:

![]({{ site.baseurl }}/images/2020/05/peek-2020-05-20-09-13.gif)

I think that is even better than 'oc projects'!

### kubectx

'kubectx' is really helpful when you work with multiple Kubernetes clusters. I typically work with a Kubernetes cluster on the IBM Cloud (IKS) and then very often start CRC (CodeReady Containers) to try something out on OpenShift. When I log into OpenShift, my connection to the IKS cluster drops. It actually doesn't drop but the kube context is switched to CRC. With 'kubectx' you can switch between them.

In this example I have two contexts, one is CRC, the other IKS (Kubernetes on IBM Cloud):

![]({{ site.baseurl }}/images/2020/05/2020-05-20_09-26.png?w=603)

Not exactly easy to know which one is which, isn't it? But you can set aliases for the entries like this:

```sh
$ kubectx CRC=default/api-crc-testing:6443/kube:admin
$ kubectx IKS=knative/br1td2of0j1q10rc8aj0
```

And then you get a list with recognizable names:

![]({{ site.baseurl }}/images/2020/05/peek-2020-05-20-10-14.gif)

You can now switch via the list. In addition, with 'kubectx -' you can switch to the previous context.

When you constantly create new kube contexts, e.g. create new CRC or Minikube instances, this list may grow and get unmanageable. But with 'kubectx -d <NAME>' you can delete entries from the list. (They will still be in the kube context, though.)
