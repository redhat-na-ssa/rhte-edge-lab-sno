---
layout: exercise
title: Managing Configurations
---

#### Cluster configurations

Now that we have several edge clusters (maybe?) running and managed under the same label, let's look at managing those clusters as part of an overall hybrid cloud infrastructure.

We're going to address some common use-cases for basic management of our edge clusters, though our examples will be necessarily pretty simplified for the purposes of the lab. The limits of your ability to apply governance to your collections of clusters is limited only by your ability to test the changes [before deploying them to prod](https://twitter.com/stahnma/status/634849376343429120){:target="_blank"}.

The basics of what we expect from our edge clusters before deploying our workloads in the lab today are:

- Some users other than kubeadmin for managing workloads or troubleshooting
- RBAC for those users
- Trusted certificates for at least the router endpoints

In the name of time, we're going to just apply some manifests to do this quickly. If both of your clusters are labelled appropriately with `student=#`, we can define a `PlacementRule` for ACM to select those cluster by their labels.
