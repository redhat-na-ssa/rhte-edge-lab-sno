---
layout: exercise
title: Adopting a Running SNO Cluster
---

#### What we're doing

The next SNO instance we'll be working with in pairs was provisioned ahead of time by your lab facilitators. In this scenario, you might imagine that the SNO install was done by a hardware OEM or system integrator before shipping the device to your team to deploy it in the field. Note that Red Hat has been working with OEMs and SIs on exactly this kind of thing - using the [ZTP Pipeline Relocatable](https://github.com/rh-ecosystem-edge/ztp-pipeline-relocatable){:target="_blank"} project to let them provision multiple clusters automatically before leaving their facilities.

Your customers may have environments that have a mix of the two kinds of deployment processes we're following today - or they may just have one or the other that they're able to enable. What's important is to understand that even in challenging network conditions, and even with heterogeneous hardware footprints, and even with wildly different deployment methodologies - we're able to manage groups of clusters declaratively, and centrally.

#### Edge Cluster Network Topology

With our VM SNO clusters, we're in the same VPC as the ACM Hub. ACM was able to discover and provision them just fine, and will even have a link directly to their consoles when they're done.

Next up in our pairs, we're going to adopt the already-running bare metal clusters into ACM management. If you were working together on the `student9` VM for example, you're now going to work together to adopt the `metal9` cluster. The network topology doesn't exactly do us any favors here at the edge. Remember, our lab is organized like this:

![Lab Architecture Diagram](/assets/images/lab-diagram.png?style=border&style=centered "Lab Achitecture Diagram")

Your laptops, on the local wifi network, are bridged to and switched on the same network with our bare metal nodes. Everything on this network is routing through the facilitator laptop right now - then connected (through the conference network) to the internet. The clusters whose installations we kicked off before are directly accessible from the internet, just like the Hub cluster we're spinning up. We don't control the conference network, even if we do control this small network underneath it, so our metal clusters in the room are definitely not directly accessible from the internet.

So, how will we adopt our bare metal clusters? By reaching up to the publicly-accessible cloud, of course! First thing's first - we need everyone to be able to log into their clusters.

#### Edge Cluster logins

Those of you with `metal#` cluster assignments, copy your login command from the following list and run it on your local machine. Those of you with `student#` cluster assignments, just observe with your partners.

> **Note**
>
> If you still need to download `oc` for your laptop's operating system, get it from [here](https://mirror.openshift.com/pub/openshift-v4/clients/ocp/stable/){:target="_blank"} and place it in your `$PATH` quietly without telling your lab facilitator about it because they might shame you for not having had it in the first place.

{% include cluster_logins.html %}

After running the commands above in your local terminal, you should be prompted to accept the untrusted certificate - do that - and then you should be able to run some basic `oc` commands against the bare-metal SNO cluster. Let's make sure you have everything prepared with administrative rights, you're on the right cluster, and you have the things in your path you'll need in a few steps:

```shell
oc whoami
oc get nodes
which kubectl &>/dev/null || alias kubectl=oc
kubectl get clusterversion version
```

If there are any errors in the above output, make sure to let a facilitator know that you're having an issue.

#### Hub Cluster Adoption

In the ACM Hub interface, navigate to `Infrastructure` -> `Clusters` and click the ![Import Cluster](/assets/images/acm-import-cluster.png?style=small "Import Cluster") button.

1. Name your cluster using the `metal#` part of your assigned metal cluster.
2. In the `Additional labels` field, apply the same label that your partner used on their VM cluster. Since I was showing off `student9` earlier, my partner would be working on `metal9` and would enter `student=9` into their labels.
3. Ensure that `Import mode` is set to the default of `Run import commands manually`.

Your cluster details should look like this:

![Import cluster details](/assets/images/acm-import-cluster-details.png?style=centered&style=border "Import cluster details")

You might want to click the pulldown for `Import mode` to see some other modes we could use to import the metal clusters into ACM management. I wouldn't recommend clicking one of them - otherwise you have to back up and start again. If you have a publicly-accessible cluster endpoint, you can choose to just provide an endpoint and token, or upload a whole `kubeconfig`. Because of the network we're dealing with, we can't do that. We maybe could have opened a VPN tunnel, but I have deliberately chosen not to do that to simplify this example and show that OEM-imaged model, without requiring additional configuration on our part.

When your imported cluster definition is good to go, click ![Next](/assets/images/acm-next.png?style=small "Next"). Once again, on the `Automation` screen, just click ![Next](/assets/images/acm-next.png?style=small "Next"). On the `Details` screen, click the ![Generate command](/assets/images/acm-generate-command.png?style=small "Generate command").

Now that the cluster is ready for import, and we have the capability to apply the agent manifests, we have to kick it off from the edge cluster directly - where we have network access to it. Click the ![Copy command](/assets/images/acm-copy-command.png?style=small "Copy command") button. Back in your terminal where you can run `kubectl` commands against your metal SNO cluster, paste the copied command and wait a little bit for magic to happen.

> **Note**
>
> Now is a decent time to check on your VM SNO cluster. Check the `View Cluster Events` button on the cluster, accessed by clicking its name from the `Infrastructure` -> `Clusters` view in the `Cluster list` tab. You know that setup completed if you see an entry like this: ![Successfully completed installing cluster](/assets/images/acm-successfully-completed-installing.png?style=small "Successfully completed installing cluster")

If you want to wait around for your two clusters, `metal#` and `student#` to be ready, you can. It makes more sense to get started on the next section defining policy and application deployments for our clusters, however, so let's get right into that!

> **Note**
>
> You're welcome to keep checking on the status of your imported cluster periodically - it shouldn't take long for the agent and all the klusterlets to come up. You'll know your imported cluster is more-or-less good to go when it shows ![Ready](/assets/images/acm-ready.png?style=small "Ready") in the `Status` field of the `Overview` for the cluster. If you click on the `Add-ons` tab of the cluster page, you can see the individual klusterlets coming up.
