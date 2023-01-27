---
layout: exercise
title: Adopting a Running SNO Cluster
---

#### Edge Cluster Network Topology

With our VM SNO clusters, we're in the same VPC as the ACM Hub. ACM was able to discover and provision them just fine, and will even have a link directly to their consoles when they're done.

Next up in our pairs, we're going to adopt the already-running bare metal clusters. If you were working together on the `student9` VM for example, you're now going to work together to adopt the `metal9` cluster. It's already been provisioned by the lab staff before you got here, but the network topology doesn't exactly do us any favors here at the edge. Remember, our lab is organized like this:

![Lab Architecture Diagram](/assets/images/lab-diagram.png?style=border&style=centered "Lab Achitecture Diagram")

Your laptops, on the local wifi network, are bridged to and switched on the same network with our bare metal nodes. Everything on this network is routing through the facilitator laptop right now - then connected (through the conference network) to the internet. The clusters we're installing in VMs are directly accessible from the internet, just like the Hub cluster we're spinning up. We don't control the conference network, even if we do control this small network underneath it.

With that said, the normal method of adopting a cluster reaches down from ACM into the managed cluster's API endpoint. We have no meaningful way to do that right now without a VPN tunnel - which I deliberately haven't set up.

So, how will we adopt our bare metal clusters? By reaching up to the publicly-accessible cloud, of course! First thing's first - we need everyone to be able to log into their clusters.

#### Edge Cluster logins

Those of you with `metal#` cluster assignments, copy your login command from the following list and run it on your local machine. Those of you with `student#` cluster assignments, just observe with your partners.

> **Note**
>
> If you still need to download `oc` for your laptop's operating system, get it from [here](https://mirror.openshift.com/pub/openshift-v4/clients/ocp/stable/){:target="_blank"} and place it in your `$PATH` quietly without telling your lab facilitator about it because they might shame you for not having had it in the first place.

{% include cluster_logins.html %}

#### Hub Cluster Adoption

In the ACM Hub interface, navigate to `Infrastructure` -> `Clusters` and click the ![Import Cluster](/assets/images/acm-import-cluster.png?style=small "Import Cluster") button.

1. Name your cluster using the `metal#` part of your assigned metal cluster.
2. In the `Additional labels` field, apply the same label that your partner used on their VM cluster. Since I was showing off `student9` earlier, my partner would be working on `metal9` and would enter `student=9` into their labels.
3. Ensure that `Import mode` is set to the default of `Run import commands manually`.

Your cluster details should look like this:

![Import cluster details](/assets/images/acm-import-cluster-details.png?style=centered&style=border "Import cluster details")

When your imported cluster definition is good to go, click ![Next](/assets/images/acm-next.png?style=small "Next"). Once again, on the `Automation` screen, just click ![Next](/assets/images/acm-next.png?style=small "Next"). On the `Details` screen, click the ![Generate command](/assets/images/acm-generate-command.png?style=small "Generate command").

In your local shell (or PowerShell, if that's what you're in to and you can translate this generic `shell` into `PowerShell`), verify that `kubectl` is in your path, or that `oc` is in your path, with the following:

```shell
which kubectl || { which oc && alias kubectl=oc || echo "No oc or kubectl in PATH" >&2 ; }
kubectl get clusterversion version
```

If you don't see `No oc or kubectl in PATH`, and you do see the cluster version showing what we expect, then you're good to go as a `cluster-admin` on your bare metal cluster with a valid login and access to the API endpoint.

Now that the cluster is ready for import, and we have the capability to apply the agent manifests, we have to kick it off from the edge cluster directly - where we have network access to it. Click the ![Copy command](/assets/images/acm-copy-command.png?style=small "Copy command") button. Back in your terminal where you can run `kubectl` commands against your metal SNO cluster, paste the copied command and wait a little bit for magic to happen.

> **Note**
>
> Now is a decent time to check on your VM SNO cluster. Check the `View Cluster Events` button on the cluster, accessed by clicking its name from the `Infrastructure` -> `Clusters` view in the `Cluster list` tab. You know that setup completed if you see an entry like this: ![Successfully completed installing cluster](/assets/images/acm-successfully-completed-installing.png?style=small "Successfully completed installing cluster")

If you want to wait around for your two clusters, `metal#` and `student#` to be ready, you're welcome to. We _can_ get started on the next section defining policy and application deployments for our clusters, however, so let's get right into that!

> **Note**
>
> You're welcome to keep checking on the status of your imported cluster periodically - it shouldn't take long for the agent and all the klusterlets to come up. You'll know your imported cluster is more-or-less good to go when it shows ![Ready](/assets/images/acm-ready.png?style=small "Ready") in the `Status` field of the `Overview` for the cluster.
