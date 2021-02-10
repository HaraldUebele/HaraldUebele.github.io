---
layout: post
title: "Blue Cloud Mirror -- (Don't) Open The Doors!"
date: "2019-02-17"
---

This isn't specific to our game "Blue Cloud Mirror". Everyone trying to create a Hybrid Cloud will need to decide how to connect a local application in a secure manner with code running on the Cloud without fully opening "the doors". IBM offers a service called Secure Gateway exactly for this purpose. It creates a TLS encrypted tunnel (TLS v1.2) between a Secure Gateway Server on the IBM Cloud and a Secure Gateway Client installed on-premise in your private network. The connection is initiated from the Client so there shouldn't be any issues with your firewall.

![](/images/2019/02/diagramsgw.png?w=1000)
{:center: style="font-size: 90%; text-align: center"}
_IBM Secure Gateway_
{:center}


You can test a limited ("lite") version of IBM Secure Gateway with a free IBM Cloud account. Limited means you can connect to one destination which is one on-premise application with a limited amount of traffic (500 MB/month), sufficient for our needs with Blue Cloud Mirror.

The IBM Secure Gateway Service can be found in the "Integration" section of the IBM Cloud Catalog. [Log on to the IBM Cloud](https://cloud.ibm.com/login){:target="_blank"}, go to the Catalog, select IBM Secure Gateway, choose a region, an organization, and a space, click "Create" and wait a moment until the service is ready.

I wrote about the configuration of IBM Secure Gateway in the [Users](https://github.com/IBM/blue-cloud-mirror/tree/master/users){:target="_blank"} section of our Github repository. There are two things that may be confusing when you start to configure:

_1. What is the difference between Client and Destination?_

The Secure Gateway Client is a piece of software that is installed on a server (physical or virtual) on-premise in your data center. It creates the connection to the IBM Secure Gateway service running on the IBM Cloud.

The Destination is the application or API that you want to connect to. It could run on the same server as the client or it could run somewhere on the same network within the data center.

_2. Why do I need to configure ACLs, too?_

I already specified the destination address and port in the destination configuration. And then I need to specifically allow access to the address and port in the ACL (access control list), too. The ACL is a list that contains information about all clients and their destinations that you manage with an IBM Secure Gateway instance. With the ACL you can "turn off" (deny access) to a destination without deleting it. Maybe you are about to install a new version of the application/API.

At the end of my last blog "[Blue Cloud Mirror – Of Kubes and Couches](https://haralduebele.github.io/2019/02/01/blue-cloud-mirror-of-kubes-and-couches/){:target="_blank"}" I explained that access to the Users API is via a Kubernetes ingress which is configured for a host “users-api.cloud” and secured with a self-signed TLS certificate. Both, the host name and the self-signed certificate would be a problem if I tried to access the API via the Internet directly. With Secure Gateway this is not an issue. In the [README](https://github.com/IBM/blue-cloud-mirror/blob/master/users/README.md){:target="_blank"} I give instructions how to create the TLS certificate and how to add the Ingress (Minikube) IP Address together with the hostname “users-api.cloud” to the servers hosts file so that the Secure Gateway client can resolve it: The hostname and TLS certificate are used in the Secure Gateway destination configuration.

If you go through the configuration yourself you'll notice that the Secure Gateway Client is available as a Docker image, too. I tried to use that and even tried to create a Kubernetes deployment from it. The problem is that you can't easily change the hosts file of the Docker image and without adding the hostname “users-api.cloud” the Secure Gateway Client isn't able to resolve the IP address of the Users API ingress. When installing the Secure Gateway Client locally with a classical installer there is no problem.

With everything in place -- Secure Gateway Service with Client and Destination set up -- the Users API is now available under a very cryptic URL, something like https://cap-eu-de-sg*****.securegateway.appdomain.cloud:12345.

In my next blog I will explain how to manage and describe the API to a developer using IBM API Connect, another service available on the IBM Cloud.
