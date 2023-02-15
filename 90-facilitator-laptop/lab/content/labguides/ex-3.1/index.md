---
layout: exercise
title: Managing Configurations
---

#### Cluster configurations

Now that we have several edge clusters (maybe?) running and selectable under the same **student=**{::nomarkdown}<span class="studentId"></span>{:/nomarkdown} label (one being the VM we're installing on, and one bare metal if available), let's look at managing those clusters as part of an overall hybrid cloud infrastructure.

Normally, our selectors would be a bit more broad in order to manage a large group of clusters. We could use selectors to select on clusters:
 - Per region
 - Specific to a use case, or
 - Whatever's appropriate for what your customer is trying to accomplish.
 
Today, we're just trying to make sure that everyone gets to see how ACM works on these edge clusters - so your selectors in the following exercises will be pretty narrowly scoped to just your student number, selecting one or two clusters.

We're going to address some common use cases for basic management of our edge clusters, though our examples will be necessarily simplified for the purposes of the lab. The limits of your ability to apply governance to your collections of clusters is limited only by your ability to test the changes [before deploying them to prod](https://twitter.com/stahnma/status/634849376343429120){:target="_blank"}.

The basics of what we expect from our edge clusters before deploying our workloads in the lab today are:

- Some users other than `kubeadmin` for troubleshooting or administrative work in the field
  - It should be noted that because this is an edge cluster, it may not be necessary to tie this into a central identity management platform
- RBAC for those users
  - Troubleshooting will require cluster-admin most of the time
  - It might make sense to have some lower-privileged users configured as well
- Trusted certificates for at least the router endpoints
  - It's just inconvenient to have to deal with HSTS errors on a technician's laptop
  - Normally we might use an internal CA and certificates we control, but we're going to use some publicly-trusted certificates for the sake of your laptops' CA trust bundles

We're working in pairs and managing both our VM **vm**{::nomarkdown}<span class="studentId"></span>{:/nomarkdown} and bare metal **metal**{::nomarkdown}<span class="studentId"></span>{:/nomarkdown} clusters simultaneously. Ride shotgun (shoulder-surf) and rotate who is driving if you're working in a pair, but don't try to deploy these same things twice.

#### Placement Rules

In the name of time, we're going to just apply some manifests to do this quickly. If your cluster(s) are labelled appropriately with **student=**{::nomarkdown}<span class="studentId"></span>{:/nomarkdown}, we can define a `PlacementRule` for ACM to select those cluster(s) by their labels.

This `PlacementRule` is defined on the ACM hub, so let's use the web UI to import manifests. From the ACM hub interface click the ![Plus button](/assets/images/plus-button.png?style=small "Plus button") icon in the top right.

Copy the following and paste it into the `Import YAML` interface that pops up on ACM Hub.

```yaml
---
apiVersion: apps.open-cluster-management.io/v1
kind: PlacementRule
metadata:
  name: student#-placement
  namespace: {{ site.data.login.region }}
spec:
  clusterSelector:
    matchExpressions:
      - key: student
        operator: In
        values:
          - "#"
  clusterConditions: []
```

You need to replace two things in this file on lines 5 and 13. In the `metadata.name` field, replace `#` with {::nomarkdown}<span class="studentId"></span>{:/nomarkdown}. In the `values` array for the `matchExpression`, you need to also replace `#` with {::nomarkdown}<span class="studentId"></span>{:/nomarkdown}. In the case of all of my examples, that would be `student9-placement` and `- "9"` for my edits.

> **Note**
>
> This is YAML. Woe are they who [mess with the indentation of YAML](https://twitter.com/memenetes/status/1229888446912704513){:target="_blank"}.

Here's what mine looks like, adjusting the definition for my running example of `vm9` and `metal9`:

![PlacementRule YAML](/assets/images/acm-placementrule-yaml.png?style=centered&style=border "PlacementRule YAML")

Also note that the proper way to do this isn't by adding the YAML to the web console. If we were going to do this the right way, we would have some basic bootstrapping of a GitOps framework to apply these to our hub and use pull requests, branches, and code reviews to get our changes to Placements, Policies, and more down to our groups of edge clusters. Working with the web console YAML editor is much more convenient for a diverse group of attendees in a lab/workshop setting though.

> **Note**
>
> If you're trying to use the `oc` CLI to apply these manifests instead of the web console, please make sure you manage your contexts correctly and are applying these to the hub cluster - not one of your edge clusters.

This `PlacementRule` defines a way which we can select groups of workloads for groups of clusters, but it doesn't do anything to select the workloads to apply to that Placement. That object would be a `PlacementBinding`. A `PlacementBinding` can select one `PlacementRule` and many `Policies`. Let's apply this `PlacementRule` by clicking the ![Create](/assets/images/acm-create.png?style=small "Create") button in the bottom-left, then we can define a `Policy` we can bind to the `PlacementRule` and make something actually happen.

#### Policies

Click the ![Plus button](/assets/images/plus-button.png?style=small "Plus button") icon again and after reading through it paste the following YAML into the interface:

```yaml
---
apiVersion: policy.open-cluster-management.io/v1
kind: Policy
metadata:
  name: student#-htpasswd
  namespace: {{ site.data.login.region }}
  annotations:
    policy.open-cluster-management.io/standards: NIST SP 800-53
    policy.open-cluster-management.io/categories: CM Configuration Management
    policy.open-cluster-management.io/controls: CM-2 Baseline Configuration
spec:
  remediationAction: enforce
  disabled: false
  policy-templates:
    - objectDefinition:
        apiVersion: policy.open-cluster-management.io/v1
        kind: ConfigurationPolicy
        metadata:
          name: htpasswd
        spec:
          remediationAction: enforce
          namespaceSelector:
            exclude:
              - kube-*
            include:
              - default
          object-templates:
            - complianceType: musthave
              objectDefinition:
                apiVersion: config.openshift.io/v1
                kind: OAuth
                metadata:
                  name: cluster
                spec:
                  identityProviders:
                   - htpasswd:
                       fileData:
                         name: htpasswd
                     mappingMethod: claim
                     name: htpasswd
                     type: HTPasswd
    - objectDefinition:
        apiVersion: policy.open-cluster-management.io/v1
        kind: ConfigurationPolicy
        metadata:
          name: htpasswd-file
        spec:
          remediationAction: enforce
          namespaceSelector:
            exclude:
              - kube-*
            include:
              - default
          object-templates:
            - complianceType: musthave
              objectDefinition:
                apiVersion: v1
                kind: Secret
                metadata:
                  name: htpasswd
                  namespace: openshift-config
                type: Opaque
                data:
                  htpasswd: bGFidXNlcjokMnkkMDUkOFZYcWxsSVZHLy9GS3ZQalpQV3hXdUFvM0dNcWR6RlNjTEFvSkQzU0RaalNWbnFBcGwzc3UKCg==
    - objectDefinition:
        apiVersion: policy.open-cluster-management.io/v1
        kind: ConfigurationPolicy
        metadata:
          name: htpasswd-user
        spec:
          remediationAction: enforce
          namespaceSelector:
            exclude:
              - kube-*
            include:
              - default
          object-templates:
            - complianceType: musthave
              objectDefinition:
                apiVersion: user.openshift.io/v1
                kind: User
                metadata:
                  name: labuser
                identities:
                - 'htpasswd:labuser'
                groups: []
                fullName: Lab User
    - objectDefinition:
        apiVersion: policy.open-cluster-management.io/v1
        kind: ConfigurationPolicy
        metadata:
          name: htpasswd-rbac
        spec:
          remediationAction: enforce
          namespaceSelector:
            exclude:
              - kube-*
            include:
              - default
          object-templates:
            - complianceType: musthave
              objectDefinition:
                apiVersion: rbac.authorization.k8s.io/v1
                kind: ClusterRoleBinding
                metadata:
                  name: htpasswd-admin
                roleRef:
                  apiGroup: rbac.authorization.k8s.io
                  kind: ClusterRole
                  name: cluster-admin
                subjects:
                - apiGroup: rbac.authorization.k8s.io
                  kind: User
                  name: labuser
```

This policy requires that HTPasswd is configured as an authentication provider for OpenShift, with a defined HTPasswd file that sets up the username to `labuser` and the password to the relatively simple `R3dH4t1!`. It then creates an OpenShift `User` object for this authentication source, and ties authorization as a `cluster-admin` to the user.

Once again, we need to edit the file a bit per student pair. Here, just the `metadata.name` for the `Policy` object needs edited. Change the `#` to {::nomarkdown}<span class="studentId"></span>{:/nomarkdown}. You'll probably have to scroll up to get back to line number 5. Here's how mine looks at this point:

![Policy YAML](/assets/images/acm-policy-yaml.png?style=centered&style=border "Policy YAML")

Clicking again on ![Create](/assets/images/acm-create.png?style=small "Create") will define the `Policy`.

Applying the `Policy` to our clusters, selected by their `student` label, will still require the `PlacementBinding`. Think of a `PlacementBinding` like a `RoleBinding` - a `Role` defines the permissions a user may have, a `User` or `ServiceAccount` defines the identity of an authenticated entity, and the `RoleBinding` ties the two together. Let's tie our `Policy` requiring HTPasswd users and cluster-admin RBAC to our `Placement` that selects our clusters.

#### Placement Bindings

Once again, click the ![Plus button](/assets/images/plus-button.png?style=small "Plus button") in the ACM Hub interface, and paste in the following YAML:

```yaml
---
apiVersion: policy.open-cluster-management.io/v1
kind: PlacementBinding
metadata:
  name: student#-binding
  namespace: {{ site.data.login.region }}
placementRef:
  name: student#-placement
  apiGroup: apps.open-cluster-management.io
  kind: PlacementRule
subjects:
  - name: student#-htpasswd
    apiGroup: policy.open-cluster-management.io
    kind: Policy
```

Again, we need to edit this file before applying it. You'll need to update your `#` with {::nomarkdown}<span class="studentId"></span>{:/nomarkdown} on lines 5, 8, and 12. After updating mine for the `student9` example, it looks like this:

![Placement Binding YAML](/assets/images/acm-placement-binding.png?style=centered&style=border "Placement Binding YAML")

You can click ![Create](/assets/images/acm-create.png?style=small "Create") to create the `PlacementBinding` and it should begin to be enforced immediately.

To see the effects of your policies in ACM, once again make sure you're on the `All Clusters` view of the Hub cluster console (pulldown in the top-left), head to `Governance` in the left navigation bar, head to the `Policies` tab of the main pane, and enter `htpasswd` in the search bar to filter it down quite a bit. Find your policy named `student#-htpasswd` with the correct number, and look over the `Details` and `Results` screens. It may show some ominous red X marks or yellow exclamation points at first, but it should resolve down and give you happy green checkboxes in the `Details` tab: ![Without Violations](/assets/images/acm-policy-without-violations.png?style=small "Without Violations").

> **Note**
>
> If you've been kicking butt and getting through the labs quickly, the installation of your VM SNO cluster may not yet be complete. It's okay to move on, but the `Policy` won't be enforceable until the cluster is installed.

The `Results` tab shows you the affect of every piece of the applied policy - including a little ![View details](/assets/images/acm-policy-event-view-details.png?style=small "View details") link to see lots of information about why the policy shows *without-violation* (if your cluster has finished installing).

> **Note**
>
> If you don't have a metal cluster partner to work with on the next sections, that's okay. You can see the examples as if you did and move on to then [Certificates for VMs](#certificates-for-vms) section.

#### Logging In - Or, Trying To

Let's head to the `Infrastructure` -> `Clusters` screen using the navigation bar on the left, then click on our metal cluster - `metal#` - if you have one available. You might have to search or use the navigation arrows to find it. Let's log in with our new users on the cluster. Click the link for the ![Console URL](/assets/images/acm-console-url-link.png?style=small "Console URL") on the right side of the `Overview` tab, you'll be greeted by a likely familiar sight:

![thisisunsafe](/assets/images/thisisunsafe.png?style=centered&style=border "thisisunsafe")

If you try to just click through the `Advanced` button and access the clusters using your well-trained muscle-memory, you'll find that our cluster has HSTS enabled and you can't just accept the invalid cert in most modern browsers. There's a way around it, which some of you may know, but let's do one better.

#### Certificates for Metal

Back in the cluster `Overview` in the ACM hub interface (this is the same page with the console URL link), click the ![Pencil](/assets/images/acm-pencil.png?style=small "Pencil") icon where it says `Labels` in the left column. At the bottom, add: {% include inline_copyable.html content="certificates-managed=true" %} then press `Enter`. Click on ![Save](/assets/images/acm-save.png?style=small "Save") and scroll down to be able to see the `Status` section of the `Overview` tab. It doesn't stay up long, but for just a few moments you might see:

![Policy violations](/assets/images/acm-policy-violations.png?style=centered&style=border "Policy violations")

Part of the lab build-out included: some free trusted TLS certificates from ZeroSSL (if you know LetsEncrypt, ZeroSSL is like that but cooler) on the Hub cluster, a `Policy` to apply the certificates to the managed clusters, a `Placement` and `PlacementBinding` resource to select your cluster(s) and push the `ConfigurationPolicy` to your cluster(s). So, close the tab with the unsafe TLS warning and try clicking the link again.

#### Validating our Metal Cluster Certificates

It may take a little bit even after the policy shows that it is without violations for the Ingress controller to roll out the new replicas, or it may require you to open the link in a new browser session or incognito window to get the new certificate if you fiddled around with trusting the old one. You should be able to get to the managed bare metal SNO cluster though:

![Trusted cluster login screen](/assets/images/managed-cluster-trusted-login.png?style=centered&style=border "Trusted cluster login screen")

You can log in using the `htpasswd` provider with the information you configured via policy earlier:

 - Username: {% include inline_copyable.html content="labuser" %}
 - Password: {% include inline_copyable.html content="R3dH4t1!" %}

#### Certificates for VMs

Head back to the ACM Hub interface, select `Infrastructure` and `Clusters` from the left navigation bar again, click on your **vm**{::nomarkdown}<span class="studentId"></span>{:/nomarkdown} cluster, and edit the labels there with the ![Pencil](/assets/images/acm-pencil.png?style=small "Pencil") icon, and add the {% include inline_copyable.html content="certificates-managed=true" %} label to this cluster. Click ![Save](/assets/images/acm-save.png?style=small "Save"). It's okay if this cluster still isn't all the way provisioned yet, this `Policy` will take effect when it's able to - just because you added this label.

#### Configuration Wrap-up

There are lots of other `Policy` types we could apply to our clusters. Here, we're just using `ConfigurationPolicies` in our definitions - ways to specify arbitrary Kubernetes YAML. There are several other policy controllers, but this isn't really an ACM features workshop. You can read more about ACM Policy controllers in the [ACM Documentation](https://access.redhat.com/documentation/en-us/red_hat_advanced_cluster_management_for_kubernetes/2.7/html/governance/governance#policy-controllers){:target="_blank"} and see some great examples of different kinds of policies, including the definitions for supported `Policies` that come with an ACM install, as well as some community implementations that are maybe a little less fleshed-out, but still a good basis for customers to leverage in the [policy-collection repository](https://github.com/open-cluster-management-io/policy-collection){:target="_blank"}.

Let's wrap up the lab by getting to workload management.
