---
layout: exercise
title: Provisioning a SNO Cluster with the Assisted Installer
---

#### What We're Doing

We're provisioning this SNO instance in a VM on a bare-metal instance in the cloud. This is because the cloud doesn't let us boot the discovery ISO. That's not super convenient, so we're just using the VM as a stand-in for an edge computing device that someone would want to be able to provision live in the field. There are some details below about how that might be accomplished in the real world, with real devices, but the goal to understand today is just what the experience would be like for someone who wanted to provision a piece of arbitrary edge hardware into ACM for centralized management.

#### Registering a New Host with ACM

Remember, we may be working in pairs for today's lab if there are VM and metal instances available. If you have a bare metal cluster assignment `metal#`, work with your partner who has the equivalent `vm#` Virtual Machine on this section, with only one of you completing the following exercises and the other observing.

Navigate to the Cockpit Machines interface and identify your assigned VM, opening the console, if it's not still open from the exploration. Click the ![Install](/assets/images/cockpit-vm-install.png?style=small "Install") button. After a few seconds the VM should start booting:

![VM Booting](/assets/images/cockpit-vm-booting.png?style=centered&style=border "VM Booting")

> **Note**
>
> Remember that these VMs have been preconfigured to boot the Discovery ISO to install their operating system and will boot from their virtual hard drive after this.

From the ACM Hub interface, head to `Infrastructure` then `Host Inventory` and click on the name of your Infrastructure Environment, `{{ site.data.login.region }}`.

> **Note**
>
> If you don't see the `Infrastructure` section of the navigation bar on the left, remember to change `local-cluster` to `All clusters` using the pulldown in the top left.

Click on the `Hosts` tab in the main pane and find your assigned VM in the list - it should be named `node#`. You may have to wait a few seconds if it's not showing yet. Click ![Approve Host](/assets/images/acm-approve-host.png?style=small "Approve Host") (then `Approve Host` again in the popup after confirming the correct number in the `node#` hostname) in the `Status` column.

This registers your host as `Available` for binding to a cluster. As long as this host stays booted into the Discovery ISO (from an ISO in the VM in this case, or maybe from a USB storage device in the field), it will remain available for binding to a cluster installation.

You can take a look directly at the `InfraEnv` object that resulted in the ISO that built this host by clicking [here](https://console-openshift-console.apps.{{ site.data.login.cluster_name }}.{{ site.data.login.base_domain }}/k8s/ns/{{ site.data.login.region }}/agent-install.openshift.io~v1beta1~InfraEnv/{{ site.data.login.region }}/yaml){:target="_blank"}. Scrolling down to the bottom of the `.status` section of the object definition, note that the ISO URL for discovery is actually _public_ and requires no authentication beyond a token to download. You can imagine a scenario where an [iPXE](https://ipxe.org/){:target="_blank"} image with an [embed script](https://ipxe.org/embed){:target="_blank"} that boots a node [directly to the ISO](https://ipxe.org/cmd/sanboot#boot_from_an_http_target){:target="_blank"}, even [over HTTPS](https://ipxe.org/crypto#embedded_certificates), from a download against the hub cluster is actually [burned to the NIC ROM](https://ipxe.org/howto/romburning){:target="_blank"} on an edge device. This would allow for edge device deployment preparation to take place before rolling a truck to physically connect it and power it on.

So, once some kind of edge device (or VM in in this case) goes through some kind of process to boot the Discovery ISO, an administrator can approve those hosts as we have here to make them available for cluster provisioning. Let's get to that, then!

#### Creating a SNO Cluster

On the ACM Hub's left navigation bar under `Infrastructure`, select `Clusters` and then click ![Create Cluster](/assets/images/acm-create-cluster.png?style=small "Create Cluster"). Select the option to create the cluster from ![Host Inventory](/assets/images/acm-create-from-host-inventory.png?style=small "Host Inventory"). Choose a ![Standalone](/assets/images/acm-create-standalone.png?style=small "Standalone") control plane.

Hosted Control Planes, A.K.A. Hive clusters, are still Tech Preview. All the same, it's not a good idea to try to use a Hosted Control Plane for an edge deployment - even when they reach G.A. - for most use-cases. The reason that Single Node Openshift is so attractive for edge deployments is because the control plane is running right where the workload is. If there's an outage of a cloud-hosted control plane with Hive, or even a break in connectivity between the control plane and the worker, your workload could be descheduled or otherwise degraded. One of the key edge computing characteristics is operating in a Denied, Disconnected, Intermittent, or Low-bandwidth/highly-latent (D/DIL) network environment.

Because we've already provisioned our host, and approved it, on the next screen we'll pick ![Use existing hosts](/assets/images/acm-use-existing-hosts.png?style=small "Use existing hosts").

1. For your cluster name, put `vm#` where you replace the `#` with your student number, as in your VM's name. In my examples, I've been working with the `vm9-na` VM, so I'll put `vm9`. Make sure you don't put `vm#-{{ site.data.login.region }}` for the cluster name, as DNS for these metal nodes is preprovisioned.
2. {::nomarkdown}For {:/}`Base domain`{::nomarkdown}, put: {% include inline_copyable.html content=site.data.login.base_domain %}{:/}
3. Pick `OpenShift 4.11.24` from the `OpenShift version` pulldown (It should be the only option right now, and selected by default).
4. Check the `Install single node OpenShift (SNO)` box.
5. In the `Additional labels` box, enter `student=#` replacing `#` with your student number from your cluster name. In my example, I'm entering `student=9`.
  - It should look like this: ![Additional labels](/assets/images/acm-cluster-additional-labels.png?style=border "Additional labels")
6. Paste a `Pull secret` in the box. I'm not going to give you mine so easy, so head to the [OpenShift Cloud Console](https://console.redhat.com/openshift/install/pull-secret){:target="_blank"} to copy your own to put in this block.

Click ![Next](/assets/images/acm-next.png?style=small) when you're sure your Cluster details are correct. Click it again to skip past the `Automation` section. This section lets us tie an Ansible Automation Platform Job to our cluster provisioning, but we're not using this today. This would be good to use for configuring network devices, identity systems, or any other non-OpenShift component we need to orchestrate alongside our SNO cluster.

Review the manifests on the right side of the screen before clicking ![Save](/assets/images/acm-save.png?style=small). If you don't see the manifests, you can toggle them on with the button: ![ACM Yaml On](/assets/images/acm-cluster-enable-yaml.png?style=small "ACM Yaml On"). These manifests could be applied via a GitOps process to onboard clusters with an audit trail and multiple pairs of human eyes confirming details. We could even use a Helm chart to make templates for onboarding our edge clusters. Our interactive lab is simplifying this by using the wizard to reinforce key concepts.

When you click `Save`, your cluster will be drafted and queued for binding and installation. If, for any reason, you have to make any changes after this point, you have to delete the draft cluster from the `Cluster list` tab in the `Infrastructure` -> `Clusters` interface using the ![Three dots](/assets/images/acm-cluster-three-dots.png?style=small "Three dots") button, then create it again from scratch.

#### Picking our Discovered Host and Binding it to our SNO Cluster Draft

Toggle `Auto-select hosts` off, making it look like this: ![Auto-select hosts off](/assets/images/acm-auto-select-hosts-off.png?style=small)  Now, check the box next to your host - it will be named `node#` where `#` matches the name of the cluster you're provisioning. For example, installing the `vm9` cluster, my selected cluster host looks like this: ![ACM Checked Host](/assets/images/acm-checked-host.png?style=small "ACM Checked host"). Click on ![Next](/assets/images/acm-next.png?style=small "Next"). It may take a few moments to let you move to the next screen while validation wraps up.

#### Finishing our Cluster Installation

You can just hit ![Next](/assets/images/acm-next.png?style=small "Next") on the `Networking` screen when it lights up. There may be an additional delay on this screen as the last of the cluster network validation completes. The SSH key will be inherited from the default key for our `InfraEnv` if you leave it blank - this was pre-configured by your facilitators. The rest of this information would change depending on our network environment, but because we have DHCP reservations for our VM hosts they filled correctly by default.

When you're ready and your cluster shows all green for validations on the `Review and create` screen (you may have to wait a few more seconds if you've been quick so far), you can click ![Install cluster](/assets/images/acm-install-cluster.png?style=small "Install cluster").

In about twenty to thirty minutes, this cluster will be up and publicly accessible, though using self-signed certificates for now. If you click ![View Cluster Events](/assets/images/acm-create-cluster-events.png?style=small) you can view the installation progress. We don't need to sit around and wait for that node to install, though. Let's go adopt our bare metal clusters!
