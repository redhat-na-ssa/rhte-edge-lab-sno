---
layout: exercise
title: Adopting a Running SNO Cluster
---

> **Note**
>
> If you don't have any bare metal nodes for your lab iteration, you can read through this exercise without performing any steps. If you have a vm-based cluster assignment and your student number aligns with a student using a nearby bare metal cluster, you should work with them on this section. If you have a bare metal cluster assignment, this section's for you! Look out for your VM-paired friend.

#### What We're Doing

The next SNO instance we'll be working with was provisioned ahead of time by your lab facilitators using [a wee bit of automation](https://github.com/redhat-na-ssa/rhte-edge-lab-sno/blob/main/90-facilitator-laptop/build-isos.sh){:target="_blank"}. In this scenario, you might imagine that the SNO install was done by a hardware OEM or system integrator before shipping the device to your team to deploy it in the field. Note that Red Hat has been working with OEMs and SIs on exactly this kind of thing - using the [ZTP Pipeline Relocatable](https://github.com/rh-ecosystem-edge/ztp-pipeline-relocatable){:target="_blank"} project to let them provision multiple clusters automatically before leaving their facilities.

Your customers may have environments that have a mix of the two kinds of deployment processes we're following today - or they may just have one or the other that they're able to enable. What's important is to understand that even in challenging network conditions, and even with heterogeneous hardware footprints, and even with wildly different deployment methodologies - we're able to manage groups of clusters declaratively, and centrally.

#### Edge Cluster Network Topology

Since these clusters are already provisioned, we're just going to adopt them into ACM management. If you and a partner were working together on the `vm9` cluster, you're now going to work together to adopt the `metal9` cluster.

With our VM SNO clusters, we were in the same VPC as the ACM Hub. ACM was able to discover and provision them just fine. Our metal clusters won't be so easy. The network topology doesn't exactly do us any favors here at the edge. Remember, our lab is organized like this:

![Lab Architecture Diagram](/assets/images/lab-diagram.png?style=border&style=centered "Lab Achitecture Diagram")

Your laptops, on the lab-specific WiFi network, are bridged to and switched on the same network with our bare metal nodes. Everything on this network is routing and masquerading through the facilitator laptop right now - then connected to the internet on a network we likely don't control. This is similar to many edge cluster deployments, especially mobile ones like a processing cluster on a delivery truck or on a vehicle in the defense space. This network is in stark contrast to the VM-installed clusters we just kicked off, which are directly accessible over the internet.

So, how will we adopt our bare metal clusters? By reaching up to the publicly-accessible cloud, of course! First thing's first - we need everyone to be able to log into their clusters.
{% if site.data.passwords %}

#### Edge Cluster logins

Those of you with `metal#` cluster assignments, copy your login command from the following list and run it on your local machine.

> **Note**
>
> If you still need to download `oc` for your laptop's operating system, get it from [here](https://mirror.openshift.com/pub/openshift-v4/clients/ocp/stable/){:target="_blank"} and place it in your `$PATH` - and macOS users remember to get a 4.10 or earlier client.

{% include cluster_logins.html %}

After running the commands above in your local terminal, you should be able to run some basic `oc` commands against the bare-metal SNO cluster. Let's make sure you have everything prepared with administrative rights, you're on the right cluster, and you have the things in your path you'll need in a few steps:

```shell
oc whoami
oc get nodes
oc version
which kubectl &>/dev/null || alias kubectl=oc
kubectl get clusterversion version
```

If there are any errors in the above output, make sure to let a facilitator know that you're having an issue so we can help sort it out.
{% else %}

#### Being Logged In

This section would have existed if there were metal clusters to adopt. You need to log in to them for the next section, in order to be able to run commands against them. It's not present because the `Copy` blocks would have been too enticing for people to click without any metal clusters. You _can_ continue on and do the import steps, without running the commands in your terminal locally at the end.
{% endif %}

#### Hub Cluster Adoption

In the ACM Hub interface, navigate to `Infrastructure` -> `Clusters` and click the ![Import Cluster](/assets/images/acm-import-cluster.png?style=small "Import Cluster") button.

1. Name your cluster using the `metal#` part of your assigned metal cluster.
2. In the `Additional labels` field, apply the same label that your partner used on their VM cluster. Since I was showing off `vm9` earlier, my partner and I are adopting the `metal9` cluster and would enter `student=9` into the labels.
3. Ensure that `Import mode` is set to the default of `Run import commands manually`.

Your cluster details should look like this:

![Import cluster details](/assets/images/acm-import-cluster-details.png?style=centered&style=border "Import cluster details")

You might want to click the pulldown for `Import mode` to see some other modes we could use to import the metal clusters into ACM management. I wouldn't recommend selecting one of them for even a moment - otherwise you have to back up and start again due to some flakiness in the way that validations are processed. If you have a publicly-accessible cluster endpoint, you can choose to just provide an endpoint and token, or upload a whole `kubeconfig`. Because of the network we're dealing with, we can't do that. We maybe could have opened a VPN tunnel, but I have deliberately chosen not to do that to simplify this example and show that OEM-imaged model, without requiring additional configuration on our part.

When your imported cluster definition is good to go, click ![Next](/assets/images/acm-next.png?style=small "Next"). Once again, on the `Automation` screen, just click ![Next](/assets/images/acm-next.png?style=small "Next"). On the `Details` screen, click the ![Generate command](/assets/images/acm-generate-command.png?style=small "Generate command").

Now that the cluster is ready for import, and we have the capability to apply the agent manifests, we have to kick it off from the edge cluster directly - where we have network access to it. {% if site.data.passwords %}Click the ![Copy command](/assets/images/acm-copy-command.png?style=small "Copy command") button. Back in your terminal where you can run `kubectl` commands against your metal SNO cluster, paste the copied command and wait a little bit for magic to happen. {% else %}If you had metal clusters to log into here, you could use the ![Copy command](/assets/images/acm-copy-command.png?style=small "Copy command") button to have a command to run against the cluster locally. You don't have any bare metal clusters, so don't bother. {% endif %}Running this (massive) command against an unmanaged cluster spins up some deployments with enough information to reach out and communicate with our cloud-hosted ACM Hub, enrolling the edge cluster under ACM management.

If you want to wait around for all of your clusters to be ready, you can. It makes more sense, in the interest of time, to get started on the next section defining policy and application deployments for our clusters. Once any clusters we have policy or applications defined for comes up, they will be enforced then.
{% if site.data.passwords %}
> **Note**
>
> You're welcome to keep checking on the status of your imported cluster periodically - it shouldn't take long for the agent and all the klusterlets to come up. You'll know your imported cluster is more-or-less good to go when it shows ![Ready](/assets/images/acm-ready.png?style=small "Ready") in the `Status` field of the `Overview` for the cluster. If you click on the `Add-ons` tab of the cluster page, you can see the individual klusterlets coming up.
{% endif %}
