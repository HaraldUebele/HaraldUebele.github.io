---
layout: post
title: "Application Security from a Platform Perspective"
date: "2020-09-03"
categories: [Kubernetes,Istio,Security,OpenShift]
---

We have added an application security example to our pet project [Cloud Native Starter](https://github.com/IBM/cloud-native-starter/tree/master/security){:target="_blank"}.

![Diagram](/images/2020/08/diagram.png?w=1024)
{:center: style="font-size: 90%; text-align: center"}
_Picture 1: Application Architecture_
{:center}

The functionality of our sample is this:

- A Web-App service serves a Vue.js/Javascript Web-App frontend application running in the browser of a client
- This frontend redirects the user to the login page of Keycloak, an open source identity and access management (IAM) system
- After successful login, the frontend obtains a JSON Web Token (JWT) from Keycloak
- It requests a list of blog articles from the Web-API using the JWT
- The Web-API in turn requests the article information from the Articles service, again using the JWT
- The Web-API and Articles services use Keycloak to verify the validity of the JWT and authorize the requests

My colleague Niklas Heidloff has blogged about the language specific application security aspects here:

- [Security in Quarkus Applications via Keycloak](http://heidloff.net/article/security-quarkus-applications-keycloak/){:target="_blank"}
- [Securing Vue.js Applications with Keycloak](http://heidloff.net/article/securing-vue-js-applications-keycloak/){:target="_blank"}

We also created an app security workshop from it, the material is publicly available on [Gitbook](https://ibm-developer.gitbook.io/get-started-with-security-for-your-java-microservi/){:target="_blank"}.

In this article I want to talk about application security from the platform side. This is what we cover in the above mentioned workshop:

![Istio Security Architecture](/images/2020/08/istiosecurityarchitecture.png?w=904)
{:center: style="font-size: 90%; text-align: center"}
_Picture 2: Platform view of the Cloud Native Starter security sample_
{:center}

There are two things that I want to write about:

1. Accessing the application externally using TLS (HTTPS, green arrow)
2. Internal Istio Service Mesh security using mutual TLS (mTLS, red-brown arrows)

#### About the architecture

This is a sample setup for a workshop with the main objective to make it as complete as possible while also keeping it as simple as possible. That's why there are some "short cuts":

1. Istio installation is performed with the demo profile.
2. Istio Pod auto-injection is enabled on the `default` namespace using the required annotation.
3. Web-App deployment in the `default` namespace is part of the Istio service mesh although it doesn't benefit a lot from it, there is no communication with other services in the mesh. But it allows us to use the Istio Ingress for TLS encrypted HTTPS access. In a production environment I would probably place Web-App outside the mesh, maybe even outside of Kubernetes, it is only a web server.
4. Keycloak is installed into the `default` namespace, too. It is an 'ephemeral' development install that consists only of a single pod without persistence. By placing it in the `default` namespace it can be accessed by the Web-App frontend in the browser through the Istio Ingress using TLS/HTTPS which is definitely a requirement for an IAM -- you do not want your authentication information flowing unencrypted through the Internet!  
    Making it part of the Service Mesh itself automatically enables encryption in the communication with the Web-API and Articles services; both call Keycloak to verify the validity of the JWT token passed by the frontend.  
    In a production setup, Keycloak would likely be installed in its own namespace. You could either make this namespace part of the Istio service mesh, too. Or you could [configure the Istio Egress](https://istio.io/latest/docs/tasks/traffic-management/egress/){:target="_blank"} to enable outgoing calls from the Web-API and Articles services to a Keycloak service outside the mesh. Or maybe you even have an existing Keycloak instance running somewhere else. Then you would also use the Istio Egress to get access to it.

We are using [Keycloak](https://www.keycloak.org/){:target="_blank"} in our workshop setup, it is open source and widely used. Actually any OpenID Connect (OIDC) compliant IAM service should work. Another good exampe would be the [App ID service](https://cloud.ibm.com/docs/appid?topic=appid-about){:target="_blank"} on IBM Cloud which has the advantage of being a managed service so you dan't have to manage it.

### Accessing the application with TLS

In this example we are using Istio to help secure our application. We will use the Istio Ingress to route external traffic from the Web-App frontend into the application inside the service mesh.

From a Kubernetes networking view, the Istio Ingress is a Kubernetes service of type LoadBalancer. It requires an external IP address to make it accessible from the Internet. And it will also need a DNS entry in order to be able to create a TLS certificate and to configure the Istio Ingress Gateway correctly.

How you do that is dependent on your Kubernetes implementation and your Cloud provider. In our example we use the IBM Cloud and the IBM Cloud Kubernetes Service (IKS). For IKS the process of exposing the Istio Ingress with a DNS name and TLS is documented in [this article](https://cloud.ibm.com/docs/containers?topic=containers-istio-mesh#tls){:target="_blank"} and [here based on the Istio Bookinfo sample](https://cloud.ibm.com/docs/containers?topic=containers-istio-mesh#istio_expose_bookinfo_tls){:target="_blank"}.

The documentation is very good, I won't repeat it here. But a little background may be required: When you issue the command to create a DNS entry for the load-balancer (`ibmcloud ks nlb-dns create ...`), in the background this command also produces a Let's Encrypt TLS certificate for this DNS entry and it stores this TLS certificate in a Kubernetes secret in the `default` namespace. The Istio Ingress is running in the `istio-system` namespace, it cannot access a secret in `default`. That is the reason for the intermediate step to export the secret with the certificate and recreate it in `istio-system`.

So how is storing a TLS certificate in a Kubernetes secret secure, it is only base64 encoded and not encrypted? That is true but there is are two possible solutions:

1. Use a certificate management system like [IBM Certificate Manager](https://cloud.ibm.com/docs/certificate-manager?topic=certificate-manager-about-certificate-manager){:target="_blank"}: Certificate Manager uses the Hardware Security Module (HSM)-based [IBM Key Protect service](https://cloud.ibm.com/docs/key-protect?topic=key-protect-getting-started-tutorial){:target="_blank"} for storing root encryption keys. Those root encryption keys are used to wrap per-tenant data encryption keys, which are in turn used to encrypt per-certificate keys which are then stored securely within Certificate Manger databases.
2. Add a Key Management System (KMS) to the IKS cluster on the IBM Cloud. There is even a free option, [IBM Key Protect for IBM Cloud](https://cloud.ibm.com/docs/key-protect?topic=key-protect-getting-started-tutorial){:target="_blank"}, or for the very security conscious there is the [IBM Hyper Protect Crypto Service](https://cloud.ibm.com/docs/hs-crypto?topic=hs-crypto-get-started){:target="_blank"}. Both can be used to encrypt the etcd server of the Kubernetes API server and Kubernetes secrets. You would need to manage the TLS certificates yourself, though.

Or use both, the certificate management system to manage your TLS certificates and the KMS for the rest.

We didn't cover adding a certificate management system or a KMS in our workshop to keep it simple. But there is a huge documentation section on many aspects of [protecting sensitive information in your cluster](https://cloud.ibm.com/docs/containers?topic=containers-encryption){:target="_blank"} on the IBM Cloud:

![](/images/2020/09/cs_encrypt_ov_kms.png)
{:center: style="font-size: 90%; text-align: center"}
_Picture 3 (c) IBM Corp._
{:center}


### Istio Security

In my opinion, Istio is a very important and useful addition to Kubernetes when you work with Microservices architectures. It has features for traffic management, security, and observability. The Istio documentation has a very good section on [Istio security features](https://istio.io/latest/docs/concepts/security/){:target="_blank"}.

In our example we set up Istio with "pod auto-injection" enabled for the `default` namespace. This means that into every pod that is deployed into the `default` namespace, Istio deploys an additional container, the Envoy proxy. Istio then changes the routing information in the pod so that all other containers in the pod communicate with services in other pods only through this proxy. For example, when the Web-API service calls the REST API of the Articles service, the Web-API container in the Web-API pod connects to the Envoy proxy in the Web-API pod which makes the request to the Envoy proxy in the Articles pod which passes the request to the Articles container. Sounds complicated but it happens automagically.

The Istio control plane contains a certificate authority (CA) that can manage keys and certificates. This Istio CA creates a X.509 certificate for every Envoy proxy and this certificate can be used for encryption and authentication in the service mesh.

![](/images/2020/09/istio-id-prov.png)
{:center: style="font-size: 90%; text-align: center"}
_Picture 4 (c) istio.io_
{:center}

You can see in Picture 4 that each of our pods is running an Envoy sidecar and each sidecar holds a (X.509) certificate, including the Istio Ingress which is of course part of the service mesh, too.

With the certificates in place in all the pods, all the communication in the service mesh is automatically encrypted using mutual TLS or mTLS. mTLS means that in the case of a client service (e.g. Web-API) calling a server service (e.g. Articles) both sides can verify the authenticity of the other side. When using "simple" TLS, only the client can verify the authenticity of the server, not vice versa.

The Istio CA even performs automatic certificate and key rotation. Imagine what you would need to add to your code to implement this yourself!

You still need to configure the [Istio Ingress Gateway](https://istio.io/latest/docs/tasks/traffic-management/ingress/secure-ingress/){:target="_blank"}. "Gateway" is an Istio configuration resource. This is what its definition looks like

```yaml
apiVersion: networking.istio.io/v1alpha3
kind: Gateway
metadata:
  name: default-gateway-ingress
  namespace: default
spec:
  selector:
	istio: ingressgateway
  servers:
  - port:
	  number: 443
	  name: https
	  protocol: HTTPS
	tls:
	  mode: SIMPLE
	  serverCertificate: /etc/istio/ingressgateway-certs/tls.crt
	  privateKey: /etc/istio/ingressgateway-certs/tls.key
	hosts:
	- "harald-uebele-k8s-1234567890-0001.eu-de.containers.appdomain.cloud"
```

This requires that you followed the instructions that I linked in the previous section "Accessing the application with TLS". These instructions create the DNS hostname specified in the `hosts:` variable and the TLS `privateKey` and `serverCertificate` in the correct location.

Now you can access the Istio Ingress using the DNS hostname and only (encrypted) HTTPS as protocol. HTTPS is terminated at the Istio Ingress which means the communication is decrypted there, the Ingress has the required keys to do so. The Istio Ingress is part of the Istio Service Mesh so all the communication between the Ingress and any other service in the mesh will be re-encrypted using mTLS. This happens automatically.

We also need to define an Istio VirtualService for the Istio Ingress Gateway to configure the internal routes:

```yaml
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: virtualservice-ingress
spec:
  hosts:
  - "harald-uebele-k8s-1234567890-0001.eu-de.containers.appdomain.cloud"
  gateways:
  - default-gateway-ingress
  http:
  - match:
    - uri:
        prefix: /auth
    route:
    - destination:
        port:
          number: 8080
        host: keycloak
  - match:
    - uri:
        prefix: /articles
    route:
    - destination:
        port:
          number: 8081
        host: web-api
  - match:
    - uri:
        prefix: /
    route:
    - destination:
        port:
          number: 80
        host: web-app
```

The DNS hostname is specified in the `hosts:` variable, again.

There are 3 routing rules in this example:

1. `https://harald-uebele-k8s-1234567890-0001.eu-de.containers.appdomain.cloud/auth` will route the request to the Keycloak service, port 8080. If you know Keycloak you will know that 8080 is the unencrypted port!
2. `https://harald-uebele-k8s-1234567890-0001.eu-de.containers.appdomain.cloud/articles` to the Web-API service, port 8081.
3. Calling `https://harald-uebele-k8s-1234567890-0001.eu-de.containers.appdomain.cloud` without a path sends the request to Web-App service which basically is a Nginx webserver listending on port 80. Again: http only!

Is this secure? Yes, because all involved parties establish their service mesh internal communications via the Envoy proxies and those will encrypt traffic.

Can it be more secure? Yes, because the Istio service mesh is using mTLS in "permissive" mode. So you can still access the services via unencrypted requests. This is done on purpose to allow you to migrate into a Istio service mesh without immediately breaking your application. In our example you could still call the Artictles service using its NodePort which effectively bypasses Istio security.

#### Switching to STRICT mTLS

STRICT means that mTLS is _enforced_ for communication in the Istio service mesh. No unencrypted and (X.509!) no unauthorized communication is possible. This eliminates pretty much the possibility of man-in-the-middle attacks.

This requires a PeerAuthentication definition:

```yaml
apiVersion: "security.istio.io/v1beta1"
kind: "PeerAuthentication"
metadata:
  name: "default"
  namespace: "default"
spec:
  mtls:
    mode: STRICT
```

The PeerAuthentication policy can be set mesh wide, for a namespace, or for a workload using a selector. In this example the policy is set for namespace `default`.

Once this definition is applied, only mTLS encrypted traffic is possible. You cannot access any service running inside the Istio service mesh by calling it on its NodePort. This also means that services running inside the service mesh can not call services outside without going through an Istio Egress Gateway.

You can do even more with Istio _without changing a line of your code_. The [Istio security concepts](https://istio.io/latest/docs/concepts/security/){:target="_blank"} and [security tasks](https://istio.io/latest/docs/tasks/security/){:target="_blank"} gives a good overview of what is possible.
