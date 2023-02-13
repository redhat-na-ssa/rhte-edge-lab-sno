---
layout: exercise
title: Ways to Deploy Workloads to Edge Clusters
---

#### The Challenges Associated with Managing Edge Cluster Workloads

First, let's consider the kinds of workloads you would expect to be running on an edge-deployed Single Node OpenShift cluster. Some rehashing of our edge-specific content that you may have heard about this week may follow.

> **Note**
>
> Boring monologue ahead. If you already know everything about the characteristics of edge workload management, skip to the next exercise - this is just information.

#### What is Edge Computing?

Edge computing is defined based on the *management* model and environment for your infrastructure. If you're working in a data center and have IT staff, that's not edge computing. If you're on a public cloud provider in one of their data centers, that's not edge computing. If you're in the back of a store (usually called ROBO) that _might_ be edge computing. If you have IT staff onsite and a little 12U rack with hard-line WAN access, that may not sound very _edge_-like, but in some ways that rack might face edge-computing type challenges. If your store is processing data locally and performing advanced analytics and the guy who's on site specializes in turning it off and on again, but the workloads are being centrally managed across many sites and data or metadata from those sites is being streamed to some higher-tier aggregation point, it might be edge computing.

The driving factor for _why_ people are doing this - remotely managing clusters in resource-constrained environments - is data. [Gartner's analysis](https://www.gartner.com/en/documents/4019489){:target="_blank"} indicates that 75% of enterprise data will be processed at the edge by 2025. With the advent of the operationalization of Data Science workloads as a common part of enterprise architectures, the need for understanding and making sense of massive volumes of data continues to climb - and so do the cloud computing bills for those who try to consolidate all that data. As customers in self-checkout lanes continue to expect a faster, more fluid experience from the places they shop, the need to react quickly at the site of the store rises. In manufacturing, the automated capabilities required to build more complex machines and iterate more rapidly is driving the need for smarter systems that don't have time to wait for packets to make it to a data center and back. In military applications this is nearly self-evident - more information to the war fighter when they need it, and more insights into conditions for commanders aggregated from a multitude of data sources in the field. For a city looking to improve their ability to react to changes day to day, better dealing with emergencies and gracefully handling fluctuations in daily activity in a way that provides a desirable place to live.

#### Data Gravity

![Data Gravity](/assets/images/data-gravity.png?style=centered&style=border "Data Gravity")

Data gravity is the concept that data, when sufficiently amassed, tends to exert a kind of gravitational force on the elements of the architecture around it. That is, as you get more data generated away from your data centers and the cloud (at the edge), elements of your architecture tend to move themselves closer to the data. There are multiple reasons that data has this characteristic. These include the following:

1. Limited networking capabilities relative to the volume of data being generated or needing processed (throughput).
2. The speed at which that data must be turned into actionable information nearest the site of generation (latency).
3. The costs associated with cloud storage, including ingress and egress of that data (common sense).

#### What This Means in Practice

It's unlikely that a retailer, or manufacturer, or anyone leveraging data science to gain insight at the edge is operating just one of these sites. Smart cities talk about computers running every crosswalk and intersection, lighting systems, HVAC, and more - all over the city. Retail giants operate hundreds or thousands of stores. Manufacturing is an innately large-scale operation, with one facility operating many machines - and often a manufacturing company will operate multiple factories.

So - you have a complex application that needs to perform at the edge, and you need to manage those at scale. Visibility into the workloads and the platforms running them are key. If you have a small team of people centrally managing thousands of deployments of an application, they need to know how those applications are performing, because hardware failures _will_ happen. Applications _will_ expose bugs rapidly if you're running them thousands of times in different environments.

At the same time, it's common to have limited networking capabilities between your centralized management and the edge computing platform - after all, that's often why you did it in the first place. Imagine a case where you have a mobile edge computing need, say in a [HMMWV](https://en.wikipedia.org/wiki/Humvee) or a maintenance truck, and you don't always know when that platform would have access to Wi-Fi again - or who runs it. So how do you pull off this trick of competing priorities?

#### Distributed Execution is Key

In this environment, it's important that the edge platforms have a few characteristics:

1. Self-healing
  - If your workload can't keep running without care and feeding, you're going to have a bad time.
2. Ability to export operational metrics
  - You need to analyze the statistics of all of your deployed footprint in aggregate to understand where problems may arise - or where they already have.
3. Declarative configuration
  - If you're going to manage potentially thousands of these machines, you must be able to describe the desired configuration state and have the remote endpoints reconcile themselves based on this definition.
4. Pull-based management
  - Not a given, but often the network topology dictates that you cannot reach "down" to manage nodes, they must reach "up." We have a mix of these topologies in the lab (if you have metal available).

#### The GitOps Paradigm

A platform, like Single Node OpenShift, that provides self-healing and platform-and-application-level metrics, has most of these characteristics inherent. The only thing that's really required to pull off the whole recipe is not a feature of the platform but a management capability that has the characteristics you need.

GitOps, the management methodology not the OpenShift operator, is the management practice of defining declarative configuration state in a Source Code Management (SCM) tool, most often `git`. Hosting declarative text in an SCM that describes configuration and applications, and reconciling that configuration via some kind of controller for the application to the cluster, is the name of the game. This lets you collaborate within whole teams to described desired configuration and deployments, review changes to them, and roll back when a change doesn't do what you expect.

![GitOps](/assets/images/gitops.png?style=centered&style=border "GitOps")

When picking a controller to perform these reconciliations between desired declared state and the running platform, it's important to consider the amount of observability that tool will offer you. So, let's look at some things we could use to do this.

#### Red Hat Advanced Cluster Management for Kubernetes

ACM is what we're already using to manage our clusters, because nothing offers quite as powerful a distributed cluster lifecycle engine. ACM offers a native feature for managing applications, documented [here](https://access.redhat.com/documentation/en-us/red_hat_advanced_cluster_management_for_kubernetes/2.6/html-single/applications/index){:target="_blank"}.

ACM allows subscribing managed clusters to `git`-defined manifests with their application `Subscription` resource. It also allows the flexibility to define Helm charts or S3 object storage buckets as the source of an application's definition, while still allowing the definitions of the `Subscription` to be managed in a GitOps paradigm. The documentation around application management paradigms is available [here](https://access.redhat.com/documentation/en-us/red_hat_advanced_cluster_management_for_kubernetes/2.6/html-single/applications/index#managing-application-resources){:target="_blank"} and it includes recommendations around organizing a repository for GitOps-style management.

For our clusters, you can see that the `application-manager` klusterlet is deployed on our clusters by looking at the `Infrastructure` -> `Clusters` page, clicking on one of your managed clusters (possibly filtering with the search bar to find it first), and then looking at the `Add-ons` tab. Here's what one of mine looks like:

![Cluster Add-ons](/assets/images/acm-cluster-add-ons.png?style=centered&style=border "Cluster Add-ons")

This klusterlet will reach up to our ACM hub from the managed cluster and ask for updated application definitions - which meets our overall intent.

#### OpenShift GitOps

OpenShift GitOps, based on ArgoCD, is explicitly designed to synchronize applications on Kubernetes clusters based on definitions in `git`. Its entire mission in life is to provide reconciliation of desired state from `git`, and to expose and provide metrics about the progress of that state.

![ArgoCD](/assets/images/argocd.jpeg?style=centered&style=border "ArgoCD"){:width="70%"}

It may make sense to deploy OpenShift GitOps in one of two ways for edge cluster workload management, depending primarily on two factors:

1. Whether you have a connection from the cloud or data center to your edge clusters
  - The `ApplicationSet` controller in ArgoCD allows for a centralized deployment to reach to multiple cluster API endpoints, maybe through a VPN or other tunnel, to define desired state directly to the edge cluster - while the controller itself continues to run in the cloud.
2. Whether you have the resources to deploy ArgoCD onto the edge cluster directly
  - Having an edge cluster reach out to a `git` source, pull down updated deployment definitions, apply them to itself, and be capable of reporting to an aggregated metrics endpoint is great. But running the controller directly on the edge cluster is not without overhead - and it may not be possible or make sense for you to do this (note that our memory-limited bare metal clusters may not be able to do this, if they only have 16GB of RAM).

For our labs today, we're not in either of those states. We didn't deploy a VPN tunnel (though you certainly can!) or anything like an application-layer tunnel such as [Skupper](https://skupper.io/){:target="_blank"} to provide us access to our Kubernetes API endpoints directly from the Hub - at least, it's not possible for our bare metal clusters (if we have any) right now.

Despite finding ourselves without consistent access to our edge cluster API endpoints, OpenShift GitOps is well integrated with our cluster life-cycle management tool, ACM. There is a whole section of the ACM documentation devoted to talking about this integration available for your perusal [here](https://access.redhat.com/documentation/en-us/red_hat_advanced_cluster_management_for_kubernetes/2.6/html-single/applications/index#gitops-config){:target="_blank"}.

It should be noted, also, that while features and capabilities may vary, other open source or third-party solutions similar to ArgoCD/OpenShift GitOps may support this application management paradigm. If your customer is happily using [Flux](https://fluxcd.io/){:target="_blank"} or similar tooling to manage their existing Kubernetes cluster workloads, it can work just fine with OpenShift and you shouldn't necessarily try to force them to use our supported tooling. Woo them, maybe - but don't turn them off our platform because they're using alternative tooling.

#### Red Hat Ansible Automation Platform

AAP is designed from the ground up for supporting GitOps-style infrastructure management - and works well for managing OpenShift clusters directly through the Kubernetes API. As you (hopefully) know, AAP Controller supports syncing `Projects` from a `git` repository on every `Job` execution. Combined with either a trigger to run a `JobTemplate` on a `git push` event in your SCM or a `Schedule` that triggers a `Job` from a `JobTemplate`, you get a very GitOps-style approach to managing workloads behind a Kubernetes API.

Importantly, controlling your edge deployments with AAP gives you the ability to bring GitOps to more than just your OpenShift clusters - it lets you manage bare metal servers through their Baseboard Management Computers (BMCs), manage network devices like switches, routers, firewalls, wireless access points, and VPN gateways through their remote management interfaces, manage operating systems and virtual machines, and more - all through the same management plane that you can reach and manage your OpenShift cluster from.

Using AAP Controller in this way does (for now) require that our network permits us to reach into the network at least adjacent to our edge cluster (using an Automation Mesh node if necessary) in order to reach the cluster API endpoint. It may make sense for a topology like our lab to deploy a Mesh node on this little subnet with all of our managed clusters, with access to that Mesh node poked through some firewalls to let a cloud-hosted AAP Controller reach into our environment.

![AAP Automation Mesh](/assets/images/aap-mesh.png?style=centered&style=border "AAP Automation Mesh"){:width="70%"}

One other supported capability in AAP, though admittedly less sexy and harder to talk about, is [ansible-pull](https://docs.ansible.com/ansible/latest/cli/ansible-pull.html){:target="_blank"}. Ansible-pull can be delivered as a supported executable in Red Hat AAP installed via the repositories, it can draw from supported collections, and can even be leveraged _inside_ a supported Ansible Execution Environment. `ansible-pull` will, given a `git` repo and playbook name, pull the repository, change the working directory into that repository root (inheriting any inventory variables and `ansible.cfg` present), and then execute the playbook specified from the repository root. This can be used on a minimal endpoint inside an edge network enclave to manage multiple machines, or all the playbooks could target the host that performs the pull. On RHEL, this could be run with a `systemd` unit with a timer, or a simple `cron` job, or triggered via some external means - perhaps with a `systemd` socket-activated service. On OpenShift, a `CronJob` fits the bill perfectly - or you can wire up some advanced OpenShift Pipelines (Tekton) `Tasks`and `Pipelines`. Supported tooling for building collections, customizing execution environments, and hosting those EEs as container images anywhere you need - combined with the OpenShift integrated Image Registry and its ability to trigger actions after successfully pulling a remote image - makes a solution built around `ansible-pull` capable of overcoming nearly any networking shortcoming.

![Supported ansible-pull](/assets/images/aap-pull-ee.png?style=centered&style=border "Supported ansible-pull")

The catch is that it's hard to do - and you don't get those wonderful consolidated AAP Controller metrics for free any more (once again, for now - stay tuned). A customer implementing a system like this must be incredibly mature and capable of operating without any guard rails. They'll need to define their own infrastructure using our tooling as a foundation while meeting their own observability needs likely through the Ansible content itself. This path is not for the faint of heart.

#### Roll Your Own

Another alternative that would give us the ability to define our edge applications, and gives us more flexibility than even `ansible-pull` while simultaneously requiring even more effort, would be to roll our own GitOps system. After all, any container with `git` and either `oc` or `kubectl` in the `$PATH`, a `ServiceAccount` defined at the Kubernetes API with the necessary privileges, and a remote git repository with manifests or charts or what have you should be able to wire up the same kind of system.

There are some serious advantages to a system like this. It could be made to be very minimal and support running on very small footprints. It could enable integrations with strange technologies in use at your customer like ancient logging stacks or custom applications for which they already have clients. It could be tuned to support exactly the amount of monitoring/alerting they need in basically any system.

It's also the highest barrier to entry amongst all our options for workload management. We can help customers with the pieces of this solution necessary for it to work, but there will need to be a lot of risk acceptance by the organization for them to take on so much of the control of their edge workload management.

#### So - What To Do?

Today, thanks to our resource constraints on the clusters, the restrictive network topology we're in with our (possibly notional) bare metal clusters, and the fact that we already have Advanced Cluster Management in play for managing our cluster life-cycles, we're going to use ACM Application Subscriptions.

Every time you're looking at the right solution for a customer, don't use a hammer on every screw. Pick the best solution for their problem set, requirements, and environment.
