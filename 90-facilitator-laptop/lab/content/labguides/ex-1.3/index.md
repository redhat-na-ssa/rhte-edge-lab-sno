---
layout: exercise
title: Exploring the Cockpit Interface
---

The Cockpit interface you get dropped off at should look like this after signing in:

![Cockpit Overview](/assets/images/cockpit-landing.png?style=centered&style=border "Cockpit Overview")

You may not be in "Administrative Access" mode, and be presented with a prompt that you can click to enable administrative access after pasting the password again: ![Cockpit Limited Access](/assets/images/cockpit-limited-access.png?style=small "Cockpit Limited Access")

As a reminder, your `labuser` password is:

```
{{ site.data.login.labuser_password }}
```

> **Note**
>
> That's right, you've got sudo access to this bare metal machine. Please take caution when performing tasks on the shared hypervisor.

Your bare metal node may have a different hostname, or it may have different resources depending on the lab size.

As we've already got the Cockpit Machines addon installed, you can see that we can manage virtual machines using the ![Virtual Machines](/assets/images/cockpit-virtual-machines.png?style=small "Virtual Machines") navigation button on the left.

Because we're running so many VMs to stand-in for bare metal SNO clusters, we needed to preconfigure some load balancers for access to the API servers and OpenShift routers. This requires some DHCP reservations to enable predictable IP addresses. Your SNO VMs were precreated, and are loaded up ready to boot into the discovery ISO.

Don't do anything with the virtual machines just yet, but you can click the name of your assigned VM and look around the console for it. Your seats should have an assignment for your VM or a bare metal node. If not, ask your lab leaders to help identify the appropriate VM for you to use. If you have a bare metal node assignment, you should have someone with a virtual node assignment adjacent to you. You'll be working in pairs, using the number assigned to your VM or metal node together for several exercises. If you aren't paired up, you can just work alone. If there are no bare metal nodes available for your lab, you can read through the guides for those parts but don't need to do anything.

Here's an example of what the main VM console looks like on a per-VM basis:

![Virtual Machine Overview](/assets/images/cockpit-virtual-machine-overview.png?style=centered&style=border "Virtual Machine Overview")

> **Note**
>
> The name in the screenshot doesn't reflect the current naming of **vm**{::nomarkdown}<span class="studentId"></span>{:/nomarkdown}**-{region}**, but it will have a unique number per participant, and the region tag suffixed to it should say `{{ site.data.login.region }}` for this iteration of the lab.

You can scroll around a little bit to see the various configurations. Note the CPU, memory, and disk capacity allocated for these VMs aligns with the [Single Node OpenShift minimums](https://docs.openshift.com/container-platform/4.12/installing/installing_sno/install-sno-preparing-to-install-sno.html#:~:text=Table%201.%20Minimum%20resource%20requirements){:target="_blank"}. This isn't the most capable setup, and we'd be better off with another 16 GB of RAM for workload deployment with some room to grow, but it's enough to host and manage a small workload with all of the OpenShift features working to help us.

We'll be using the `Cockpit` `Virtual Machines` interface for working with our virtual Single Node OpenShift nodes. The definitions for these VMs are pretty straightforward and visible in the [lab source code](https://github.com/redhat-na-ssa/rhte-edge-lab-sno/blob/main/ansible/templates/vm.xml.j2){:target="_blank"}. Also available to poke around is the relatively simple [Ansible playbook](https://github.com/redhat-na-ssa/rhte-edge-lab-sno/blob/main/ansible/hypervisor.yml){:target="_blank"} that configured this bare metal server as a hypervisor. It is responsible for; defining the VMs using the above definition, ensuring that the discovery ISOs are in place, configuring the network, and preparing the disks.
