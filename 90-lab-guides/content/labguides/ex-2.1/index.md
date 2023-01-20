---
layout: exercise
title: Provisioning a SNO Cluster with the Assisted Installer
---

#### Registering a new host with ACM

Navigate to the Cockpit Machines interface and identify your assigned VM, opening the console, if it's not still open from the exploration. Click the ![Install](/assets/images/cockpit-vm-install.png?style=small "Install") button. After a few seconds the VM should start booting:

![VM Booting](/assets/images/cockpit-vm-booting.png?style=centered&style=border "VM Booting")

> **Note**
>
> Remember that these VMs have been preconfigured to boot the Discovery ISO to install their operating system and will boot from their virtual hard drive after this.

From the ACM Hub interface, head to `Infrastructure` then `Host Inventory` and click on the name of your Infrastructure Environment, `{{ site.data.login.region }}`. Click on the `Hosts` tab in the main pane and find your assigned VM in the list, or wait a few seconds if it's not showing yet, and then click ![Approve Host](/assets/images/acm-approve-host.png?style=small "Approve Host") (then `Approve Host` again in the popup after confirming the correct Hostname) in the `Status` column.


This registers your host as `Available` for binding to a cluster. As long as this host stays booted into the Discovery ISO (from an ISO in the VM in this case, or maybe from a USB storage device in the field), it will remain available for binding to a cluster installation.

You can take a look directly at the `InfraEnv` object that resulted in the ISO that built this host by clicking [here](https://console-openshift-console.apps.edge1.rhte.edgelab.dev/k8s/ns/{{ site.data.login.region }}/agent-install.openshift.io~v1beta1~InfraEnv/{{ site.data.login.region }}/yaml){:target="_blank"}. Scrolling down to the bottom of the `.status` section of the object definition, note that the ISO URL for discovery is actually _public_ and requires no authentication beyond a token to download. You can imagine a scenario where an [iPXE](https://ipxe.org/){:target="_blank"} image with an [embed script](https://ipxe.org/embed){:target="_blank"} that boots a node [directly to the ISO](https://ipxe.org/cmd/sanboot#boot_from_an_http_target){:target="_blank"}, even [over HTTPS](https://ipxe.org/crypto#embedded_certificates), from a download against the hub cluster is actually [burned to the NIC ROM](https://ipxe.org/howto/romburning){:target="_blank"} on an edge device. This would allow for edge device deployment preparation to take place before rolling a truck to physically connect it and power it on.

So, once some kind of edge device (or VM in our case) goes through some kind of process to boot the Discovery ISO, an administrator can approve those hosts as we have here to make them available for cluster provisioning. Let's get to that, then!

#### Creating a SNO cluster

On the left navigation bar under `Infrastructure`, select `Clusters` and then click ![Create Cluster](/assets/images/acm-create-cluster.png?style=small "Create Cluster"). Select the option to create the cluster from ![Host Inventory](/assets/images/acm-create-from-host-inventory.png?style=small "Host Inventory"). Choose a ![Standalone](/assets/images/acm-create-standalone.png?style=small "Standalone") control plane.

Hosted Control Planes, A.K.A. Hive clusters, are still Tech Preview. All the same, it's not a good idea to try to use a Hosted Control Plane for an edge deployment - even when they reach G.A. - for most use-cases. The reason that Single Node Openshift is so attractive for edge deployments is because the control plane is running right where the workload is. If there's an outage of a cloud-hosted control plane with Hive, or even a break in connectivity between the control plane and the worker, your workload could be descheduled or otherwise degraded. One of the key edge computing characteristics is operating in a Denied, Disconnected, Intermittent, or Low-bandwidth/highly-latent (D/DIL) network environment.

Because we've already provisioned our host, and approved it, on the next screen we'll pick ![Use existing hosts](/assets/images/acm-use-existing-hosts.png?style=small "Use existing hosts").

1. For your cluster name, `student#` where you replace the `#` with your student number, as in your VM's name. In my examples, I've been showing the `student9-na` VM, so I'll put `student9`.
2. For `Base domain`, put `rhte.edgelab.dev`.
3. Pick `OpenShift 4.12.x` from the `OpenShift version` pulldown (It should be the only option right now).
4. Check the `Install single node OpenShift (SNO)` box.
5. Paste a `Pull secret` in the box. I'm not going to give you mine so easy, so head to the [OpenShift Cloud Console](https://console.redhat.com/openshift/install/pull-secret){:target="_blank"}.

Here's how my form looks:

![Create cluster details](/assets/images/acm-create-cluster-details.png?style=centered&style=border "Create cluster details")

Make sure your student number is right and your form matches mine (unless there's a z-stream release for 4.12).

Click ![Next](/assets/images/acm-next.png?style=small) when you're sure your Cluster details are correct. Click it again to skip past the `Automation` section. This section lets us tie an Ansible Automation Platform Job to our cluster provisioning, but we're not using this. This would be good to use for configuring network devices, identity systems, or any other non-OpenShift component we need to orchestrate alongside our SNO cluster.

Review the manifests on the right side of the screen before clicking ![Save](/assets/images/acm-save.png?style=small). These manifests could be applied via a GitOps process to onboard clusters with an audit trail and multiple pairs of human eyes confirming details. We could even use a Helm chart to make templates for our onboarding edge clusters.

When you click `Save`, your cluster will be drafted and queued for binding and installation. To make any changes after this point, you have to delete the cluster from the `Cluster list` and create it again from scratch.

#### Picking our discovered host and binding it to our SNO cluster draft.

Toggle `Auto-select hosts` off, making it look like this: ![Auto-select hosts off](/assets/images/acm-auto-select-hosts-off.png?style=small)  Now, check the box next to your host.
