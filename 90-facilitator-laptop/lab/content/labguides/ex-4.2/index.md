---
layout: exercise
title: Applying our Application
---
{% capture console_url %}
https://console-openshift-console.apps.{{ site.data.login.cluster_name }}.{{ site.data.login.base_domain }}
{% endcapture %}
{% assign ns = site.data.login.region %}

#### What We're Doing

We're about to configure our ACM hub to apply application deployment manifests tracked in `git` to all the cluster(s) selected by our earlier `PlacementRules` that select our cluster(s) by their `student=#` labels. The correct way to do this at scale, with multiple selectors, was described in the ACM [Managing applications documentation](https://access.redhat.com/documentation/en-us/red_hat_advanced_cluster_management_for_kubernetes/2.6/html-single/applications/index#gitops-pattern){:target="_blank}. It involves a single root folder that manages the ACM `local-cluster` with a definition to apply manifests from a `managed-subscriptions` folder, which contains the `Subscription` objects that define our applications that we want running on the edge cluster(s). Also inside that `managed-subscriptions` folder, it recommends subfolders that would contain configuration and policy settings for the managed cluster(s) - like the ones we applied via the console in exercise 3.1.

If this edge computing workshop consisted of me pointing you to a git repo where everything was already managed, it wouldn't fill the allotted time. If I asked you to use `git` to manage your cluster definitions, it wouldn't get done in the allotted time because some of you, I'm sure, don't work with `git` enough to [be comfortable](/assets/images/git-is-scary.png "git is scary"){:target="_blank"}. Not all of you need to be comfortable in `git` to do your jobs, though - even if your job is convincing a customer that `git` is the superior way to manage their application deployments (because it is).

So, we'll be defining an `Application` object on our hub cluster that selects the `Subscription` information for our application, which will reference our workload definition source and our `PlacementRule`. We'll be using the `Import YAML` interface we used earlier, and our `Subscription` will be subscribing the managed edge cluster(s) to a deployment that _is_ defined in `git`. Changes to that deployment definition in `git` would be reflected in our cluster(s) as soon as they're able to reconcile their application `Subscription`, even if the `Subscription` is being managed in a sub-optimal way (the console) for the sake of the lab.

#### The Definition of Our Git-hosted Application Deployment

Application deployment artifacts themselves can be hosted in:

1. A `git` repository
2. A `helm` chart repository
3. An S3 object store

In ACM, application deployment artifact source definition is done with a `Channel` object. The `Channel` we're going to use today is going to be shared amongst all the clusters in our lab and it's already applied to the ACM Hub cluster. Let's look at that definition by clicking [here]({{ console_url }}/k8s/ns/{{ ns }}/apps.open-cluster-management.io~v1~Channel/rust-hello-world/yaml){:target="_blank"}. Note that the git repo called out in this `Channel` is the same repo that all of the other lab content has been sourced from - but doesn't contain any more information than the repository.

If you want to look at the (relatively simple) application deployment manifests we're using here, you can check them out [in the repo directly](https://github.com/redhat-na-ssa/rhte-edge-lab-sno/tree/main/app){:target="_blank"}. Notice that the app is in a subdirectory of the repository referenced by the `Channel`. If you want to see how the container image we're using in the `Deployment` is built, you can head to [this other repository](https://github.com/RedHatGov/ingress-route-examples/tree/main/demo-application){:target="_blank"}. For our purposes, the application itself isn't super important. This isn't a very "edge" application, it's just a simple `hello-world`. It's written in Rust and designed to be incredibly light on resources, though, so it's convenient for our resource-constrained edge lab. The [entire program](https://github.com/RedHatGov/ingress-route-examples/blob/main/demo-application/hello-world/src/main.rs){:target="_blank"} is 26 lines of code - including whitespace. It was originally written to provide a very small example application to show off some specific behavior of the OpenShift Router for [a blog post](https://cloud.redhat.com/blog/a-guide-to-using-routes-ingress-and-gateway-apis-in-kubernetes-without-vendor-lock-in){:target="_blank"}.

#### Selecting Clusters to Deploy To

As mentioned, we're going to reuse the same `PlacementRule` you wrote earlier for the `Policy`. You can see the list of `PlacementRules` already deployed to the cluster [here]({{ console_url }}/api-resource/ns/{{ ns }}/apps.open-cluster-management.io~v1~PlacementRule/instances?orderBy=desc&sortBy=Name){:target="_blank"}. Clicking on your `student#-placement` `PlacementRule` you should see in the `status` section that ACM has evaluated your selectors in the `spec` and settled on your one or two clusters that we've labelled so far.

#### Declaring Intent to Deploy Our Application

We're working in pairs here (if applicable) and managing both our VM-based `vm#` and our metal-based `metal#` clusters simultaneously here. Shoulder-surf one way or another if you need to, but don't try to deploy these same things twice.

Back in the ACM Hub interface, click on our now-familiar ![Plus button](/assets/images/plus-button.png?style=small "Plus button") icon in the top right. Read through the following `Application`, including its selected `Subscription`, before pasting it into the `Import YAML` interface.

```yaml
---
apiVersion: app.k8s.io/v1beta1
kind: Application
metadata:
  name: hello-world-student#
  namespace: {{ ns }}
spec:
  componentKinds:
  - group: apps.open-cluster-management.io
    kind: Subscription
  descriptor: {}
  selector:
    matchExpressions:
      - key: app
        operator: In
        values: 
          - hello-world-student#
---
apiVersion: apps.open-cluster-management.io/v1
kind: Subscription
metadata:
  annotations:
    apps.open-cluster-management.io/git-branch: main
    apps.open-cluster-management.io/git-path: app
    apps.open-cluster-management.io/reconcile-option: merge
  labels:
    app: hello-world-student#
  name: hello-world-student#
  namespace: {{ ns }}
spec:
  channel: {{ ns }}/rust-hello-world
  placement:
    placementRef:
      kind: PlacementRule
      name: student#-placement
```

As before, you need to update `student#` with your actual number throughout. On this file, that means lines 5, 17, 27, 28, and 35.

Continuing with my theme of using the `vm9` and `metal9` clusters, here's how mine looks right now:

![ACM Application and Subscription](/assets/images/acm-app-subscription.png?style=centered&style=border "ACM Application and Subscription")

After making sure your `Application` and `Subscription` definitions are correct, hit ![Create](/assets/images/acm-create.png?style=small "Create") in the bottom-left. Ensure your pulldown in the top-left is, once again, set to `All Clusters` instead of `local-cluster`, then head into `Applications` on the left navigation bar. Grab the ![Filter](/assets/images/acm-filter.png?style=small "Filter") pulldown near the top of the main `Overview` tab and check the `Subscription` box to reduce some of the noise from our initial ACM deployment. Here you should see your `hello-world-student#` `Application`, complete with some basic status showing you that it's selected to deploy to some amount of remote clusters: ![2 Remote](/assets/images/acm-2-remote.png?style=small "2 Remote"). It should indicate that it's using a `Git` resource to back the `Application`. Click on the link in the `Name` column for your application and head over to the `Topology` tab. You should see a view something like this one:

![ACM Application Topology](/assets/images/acm-application-topology.png?style=centered&style=border "ACM Application Toplogy")

As our edge clusters get their updated instructions from the Hub, pull the image down locally (this can take a little bit in some cases, like poor network connectivity), and start the pods - all of these statuses should green up.

When they do, go ahead and check out your application deployments!

{% include app_links.html %}

If you have any issues with your apps coming up, you should be able to access the details of the app by clicking on the component in the `Topology` view. Ideally, we'd have alerts configured on our Hub and it would be able to let me know when it spotted a problem, but this might be a good place to start investigating after being notified. For example, I induced this failure in my app and see a lot of information that could help me when I click on the `Pod` marker with its error indicator:

![ACM Induced Failure](/assets/images/acm-app-induced-failure.png?style=centered&style=border "ACM Induced Failure"){:width="70%"}

> **Note**
>
> Your applications should not have this failure - this is a contrived example. Yours should all green up - if they don't, let a lab facilitator know and we'll use these features to _actually_ troubleshoot your problem.

If I had a failure on a cluster that ACM can't reach out to directly, I may find myself unable to access the logs in the ACM interface directly:

![ACM Logs Error](/assets/images/acm-logs-error.png?style=centered&style=border "ACM Logs Error")

Easy enough to reach out to the cluster via some means that _can_ reach it, which lets me diagnose that the application required an instruction set on the CPU that wasn't supported.

![ACM Induced Failure Logs](/assets/images/acm-induced-failure-logs.png?style=centered&style=border "ACM Induced Failure Logs")

> **Note**
>
> How did this failure get induced? I booted a VM cluster with the wrong CPU type set on purpose, so that everything worked except this app.

Then, after either (notionally) upgrading my field hardware or (notionally) improving my application build pipeline to support this older hardware I have in the field, the app comes up fine:

![ACM Induced Failure Fixed](/assets/images/acm-induced-failure-fixed.png?style=centered&style=border "ACM Induced Failure Fixed")

And remember, `Applications` (the root of this topology view) can be composed of multiple `Subscriptions` targeting multiple clusters through their `Placement`. Our complex applications can be composed of many pieces, managed and lifecycled independently, and tracked centrally - but without requiring push-style management of our edge clusters. It's up to the cluster administrators, the ACM Hub users, to follow best-practices for tracking and managing these applications and their deployments. By following the documented prescriptive process, you can have a system and process that scales to thousands of clusters.

With that, let's review everything we did today.
