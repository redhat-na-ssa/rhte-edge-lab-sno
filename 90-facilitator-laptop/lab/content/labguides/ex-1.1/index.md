---
layout: exercise
title: Preflight Checks
---
{% capture virt_node %}{{ site.data.login.cluster_name }}-virt.{{ site.data.login.base_domain }}{% endcapture %}
{% capture cluster_router %}apps.{{ site.data.login.cluster_name }}.{{ site.data.login.base_domain }}{% endcapture %}
### Getting Connected

1. Make sure you're on the correct WiFi network - the instructor has this information.
2. Make sure you can pull up the [Cockpit Interface](https://{{ virt_node }}:9090){:target="_blank"} for our bare-metal hypervisor.
  - Username: `labuser`
  - Password:
    ```
    {{ site.data.login.labuser_password }}
    ```
3. Make sure you can pull up the [ACM Hub Cluster](https://console-openshift-console.{{ cluster_router }}/multicloud/home/overview){:target="_blank"} interface for managing our nodes.
  - Username: `kubeadmin`
  - Password:
    ```
    {{ site.data.login.kubeadmin_password }}
    ```
