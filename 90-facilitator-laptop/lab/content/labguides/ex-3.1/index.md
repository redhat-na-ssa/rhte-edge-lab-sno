---
layout: exercise
title: Managing Configurations
---

#### Cluster configurations

Now that we have several edge clusters (maybe?) running and (definitely) listed under the same label, let's look at managing those clusters as part of an overall hybrid cloud infrastructure.

We're going to address some common use-cases for basic management of our edge clusters, though our examples will be necessarily pretty simplified for the purposes of the lab. The limits of your ability to apply governance to your collections of clusters is limited only by your ability to test the changes [before deploying them to prod](https://twitter.com/stahnma/status/634849376343429120){:target="_blank"}.

The basics of what we expect from our edge clusters before deploying our workloads in the lab today are:

- Some users other than kubeadmin for managing workloads or troubleshooting
  - It should be noted that, this being an edge cluster, it may not be necessary to tie this into a central identity management platform
- RBAC for those users
  - The users we're using should still have some basic best-practices
- Trusted certificates for at least the router endpoints
  - It's just inconvenient to have to deal with HSTS errors on a technician's laptop
  - Normally we might use an internal CA and certificates we control, but we're going to use some publicly-trusted certificates for the sake of your laptops' CA trust bundles

In the name of time, we're going to just apply some manifests to do this quickly. If both of your clusters are labelled appropriately with `student=#`, we can define a `PlacementRule` for ACM to select those cluster by their labels.

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

You need to replace two things in this file. In the `metadata.name` field, replace `#` with your actual student number. In the `values` array for the `matchExpression`, you need to also replace `#` with your actual student number. In the case of all of my examples, that would be `student9-placement` and `- "9"` for my edits.

> **Note**
>
> This is YAML. Woe are they who mess with the indentation of YAML.

Here's what mine looks like, adjusting the definition for my running example of `student9`:

![PlacementRule YAML](/assets/images/acm-placementrule-yaml.png?style=centered&style=border "PlacementRule YAML")

This `PlacementRule` defines a way which we can select groups of workloads for groups of clusters, but it doesn't do anything to define the workloads themselves. That object would be a `PlacementBinding`. A `PlacementBinding` can select one `PlacementRule` and many `Policies`. Let's apply this `PlacementRule` by clicking the ![Create](/assets/images/acm-create.png?style=small "Create") button in the bottom-left, so we can get on to doing something with it.

Click the ![Plus button](/assets/images/plus-button.png?style=small "Plus button") icon again, and paste the following YAML into the interface:

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

Once again, we need to edit the file a bit per student pair. Here, just the `metadata.name` for the `Policy` object needs edited. Change the `#` to match your student number as before. You'll probably have to scroll up to get back to line number 5. Here's how mine looks at this point:

![Policy YAML](/assets/images/acm-policy-yaml.png?style=centered&style=border "Policy YAML")

Clicking again on ![Create](/assets/images/acm-create.png?style=small "Create") will define the policy. This policy requires that HTPasswd is configured as an authentication provider for OpenShift, with a defined HTPasswd file that sets up the username to `labuser` and the password to the relatively simple `R3dH4t1!`. It then creates an OpenShift `User` object for this authentication source, and ties authorization as a `cluster-admin` to the user.
