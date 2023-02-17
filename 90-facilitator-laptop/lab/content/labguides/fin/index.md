---
layout: exercise
section: Reviewing Our Lab
title: Wrap-up
---

![Red Hat OpenShift](/assets/images/red-hat-openshift.png?style=centered "Red Hat OpenShift"){:width="65%"}

Today, you explored managing Single Node OpenShift clusters from deploying bare machines all the way through to deploying and managing workloads. Together, we performed the following tasks:

1. Provisioned a Single Node OpenShift cluster from scratch using Red Hat Advanced Cluster Management for Kubernetes (ACM) and the Assisted Installer
2. Briefly explored a bit of automation that provisioned Single Node OpenShift from scratch, without ACM, at least understanding that it can be done
3. Adopted a cluster provisioned out-of-band under ACM management, while in a challenging network environment (if bare metal hardware was available)
4. Explored mechanisms to group clusters together for management in ACM, regardless of their provenance
5. Applied policies to groups of clusters that enabled us to meet some objectives expected of edge devices
6. Explored and evaluated the mechanisms we might use to manage workloads on edge OpenShift clusters, weighing the pros and cons of each
7. Leveraged ACM's native features to deploy a simple application to multiple clusters, exploring some features that ACM provides for application management

Hopefully, you can see some of the _benefits_ of running Single Node OpenShift in this paradigm. We get so many great OpenShift features in exchange for the overhead it carries with it.
- The self-healing applications
- The declarative configurations
- The native metrics and status mechanisms
- The ability to define pull-style management with ease, and
- The top-to-bottom integration of OpenShift running on RHEL CoreOS
    -  With MachineConfigs available to us give us a great platform to work with in our edge strategy, where we need or want to leverage those features

I appreciate your time exploring these concepts and learning how powerful a platform we can run in the palm of your hand!
