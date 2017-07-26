# kubernetes

## Introduction

The scripts in this folder are in no way meant for a production system.  At the time I started "learning" Kubernetes there was a lot of encouragement to use "helper" tools to get Kubernetes up and running but they all had significant flaws:  For some the tools and documentation didn't match, or required an underlying system I could not replicate orchestration, or made "opinionated" assumptions which were not true and/or dangerous.

These scripts are the "helpers" I wrote myself so I could learn what is necessary to build a kuberenetes system and to better understand what the other available tools are trying to do.

## Kubernetes in Practice

Using/Adapting these scripts to get a small Kubernetes system up and running is a great learning exercise but in practice you will want a "manager" to help orchestrate and run kubernetes.  Examples of such managers are [http://rancher.com/|Rancher] and [https://supergiant.io/|Supergiant].

Why would you want a manager ?  Well, two advantages of Kubernetes for micro-service architectures are scaling and high-availability.  The scripts in this folder set up a static Kubernetes infrastructure - if this were deployed to 1000 nodes, Kubernetes would be costing you 1000 nodes.  A manager (and dashboard) can turn this into a dynamic Kubernetes infrastructure - the manager can buy in new nodes or drop current ones as load demands so it costs what you are actually using.

A Kubernetes manager can load-balance the infrastructure as well as the services running on it.  It can also help migrate services between nodes to provide fault tolerance and high-availability.

## Kubernetes Caveats

As mentioned above, all of the Kubernetes install methods had short comings.  I'll list them below because they are a useful checklist when looking at Kubernetes install methods and spec'ing an infrastructure for Kubernetes.

### Tightly coupled to an orchestration system

Some of the Kubernetes setup-tools/systems I tried had obviously started out as bash+go+... tools.  These typically configure and build a cluster on top of an operating system (eg. Ubuntu 16.04, CoreOs) and, as with the scripts here, create a static infrastructure.   The advantages of a dynamic, fault tolerant  infrastructure naturally pushes setup systems towards full orchestration systems which can manage the creation of clean nodes right the way to Kubernetes deployment.  But this also mean tools become tightly coupled to the deployment system used by the developer (eg. AWS orchestration of Google orchestration etc) and difficult to use (without significant re-development) if they are to be used with a different hardware orchestration system.

### Code, tools and documentation out of sync

Containers (Docker and Rkt) and orchestration systems (Heat, TOSCA standards, ignition, ansible and others) and overlay networks (Calico, flannel, canal etc) and basically everything you need for Kubernetes is undergoing rapid development.     And the result is that all of the released elements: The code, the tools, the configurations, the features and the documentation are not as well synchronized as they could be.  Deploying a new Kubernetes instance is not a simple click install. To make use of Kubernetes in continuous integration and continuous deployment settings demands staff with time and knowledge to keep on top of this ever changing mare's nest.

Maybe it is just me but I believe I am also seeing a very annoying trend where projects are "documenting" significant quirks of their systems as replies to issues on their code repository (eg. github).  When you hit such a problematic quirk you need an unhealthy dose google foo and luck to find the existing answer.

### Network Ownership

Most setup-tools/systems I have tried make a nasty assumption that you are in full control the network, including routing, between nodes - well that is the only "sane" explanation I can come up with for not using TLS/SSL everywhere and/or use IPSEC.  Some tools make no effort on network security, some give it a nod with TLS/SSL between kubernetes pods but then fail to secure etcd.  Some of them claim "full" use of TLS/SSL but then fail to generate certificates for the etcd service etc.
There are only two architecture options.

1.  You own the network, routing and all (eg. it is inside your data centre) - in this case selected encryption (eg. only at the kubernetes edges) is practical.

2.  You do not own the network or cannot control network routing (eg. your deploying to real or virtual machines in someone else's data centre).  In this case you should protect all network traffic at the edges and within Kubernetes.

### Reincarnation of old problems
