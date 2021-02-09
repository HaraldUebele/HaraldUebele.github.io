---
layout: post
title: "Red Hat OpenShift 4 on your laptop"
date: "2019-09-13"
categories: [Kubernetes,OpenShift]
---

I use Minishift on my laptop and have [blogged](https://haralduebele.github.io/2019/06/28/cloud-native-starter-and-openshift-okd-minishift/){:target="_blank"} about it. Minishift is based on OKD 3.11, the Open Source upstream version of OpenShift. An update of Minishift to OpenShift 4 never happened and wasn't planned. I haven't actually seen OKD 4.1 except for some source code.

But recently I found something called **Red Hat CodeReady Containers** and this allows to run OpenShift 4.1 in a single node configuration on your workstation. It operates almost exactly like Minishift and Minikube. Actually under the covers it works completely different but that's another story.

CodeReady Containers (CRC) runs on Linux, MacOS, and Windows, and it only supports the native hypervisors: KVM for Linux, Hyperkit for MacOS, and HyperV for Windows.

This is the place where you need to start: [Install on Laptop: Red Hat CodeReady Containers](https://cloud.redhat.com/openshift/install/crc/installer-provisioned){:target="_blank"}.

To access this page you need to register for a Red Hat account which is free. It contains a link to the [Getting Started](https://code-ready.github.io/crc/){:target="_blank"} guide, the download links for CodeReady Containers (for Windows, MacOS, and Linux) and a link to download the pull secrets which are required during installation.

The Getting Started quide lists the hardware requirements, they are similar to those for Minikube and Minishift:

- 4 vCPUs
- 8 GB RAM
- 35 GB disk space for the virtual disk

You will also find the required versions of Windows 10 and MacOS there.

I am running Fedora (F30 at the moment) on my notebook and I normally use VirtualBox as hypervisor. VirtualBox is not supported so I had to install KVM first, here are good [instructions](https://computingforgeeks.com/how-to-install-kvm-on-fedora/){:target="_blank"}. The requirements for CRC also mention NetworkManager as required but most Linux distributions will use it, Fedora certainly does. There are additional instructions for Ubuntu/Debian/Mint users for libvirt in the Getting Started guide.

Start with downloading the CodeReady Containers archive for your OS and download the pull secrets to a location you remember. Extracting the CodeReady Containers archive results in an executable 'crc' which needs to be placed in your PATH. This is very similar to the 'minikube' and 'minishift' executables.

First step is to setup CodeReady Containers:

```sh
$ crc setup
```

This checks the prerequistes, installs some drivers, configures the network, and creates an initial configuration in a directory '.crc' (on Linux).

You can check the configurable options of'crc' with:

```sh
$ crc config view
```

Since I plan to test Istio on crc I have changed the memory limit to 16 GB and added the path to the pull secret file:

```sh
$ crc config set memory 16384
$ crc config set pull-secret-file path/to/pull-secret.txt
```

Start CodeReady Containers with:

```sh
$ crc start
```

This will take a while and in the end give you instructions on how to access the cluster.

```
INFO: To access the cluster using 'oc', run 'eval $(crc oc-env) && oc login -u kubeadmin -p ******* https://api.crc.testing:6443'
INFO: Access the OpenShift web-console here: https://console-openshift-console.apps-crc.testing
INFO: Login to the console with user: kubeadmin, password: ********
CodeReady Containers instance is running
```

I found that you need to wait a few minutes after that because OpenShift isn't totally started then. Check with:

```sh
$ crc status
```

Output should look like:

```
CRC VM:          Running
OpenShift:       Running (v4.x)  
Disk Usage:      11.18GB of 32.2GB (Inside the CRC VM)
Cache Usage:     11.03GB
```

If your cluster is up, access it using the link in the completion message or use:

```
$ crc console
```

User is 'kubeadmin' and the password has been printed in the completion message above. You will need to accept the self-signed certificates and then be presented with an OpenShift 4 Web Console:

![Dashboard](/images/2019/09/2019-09-13_11-52.png?w=1024)

There are some more commands that you probably need:

1. `crc stop` stops the OpenShift cluster
2. `crc delete` completely deletes the cluster
3. `eval $(crc oc-env)` correctly sets the environment for the 'oc' CLI

I am really impressed with CodeReady Containers. They give you the full OpenShift 4 experience with the new Web Console and even include the OperatorHub catalog to get started with Operators.

#### Expiration

Starting with CodeReady Containers (crc) version 1.1.0 and officially with version 1.2.0 released end of November 2019, the certificates no longer expire. Or to be precise: they do expire, but crc will renew them at 'crc start' when they are expired. Instead, 'crc start' will print a message at startup when a newer version of crc, which typically includes a new version of OpenShift, is available. Details are [here](https://code-ready.github.io/crc/#troubleshooting-expired-certificates_gsg){:target="_blank"}.
