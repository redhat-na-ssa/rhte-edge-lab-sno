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

### Being Ready to Perform the Labs

1. Make sure you have the `oc` client downloaded for your laptop's operating system, ideally in your `$PATH` so that you can call it on the shell without a relative/absolute path. If you don't have this done, you should be able to just grab it from [here](https://mirror.openshift.com/pub/openshift-v4/clients/ocp/stable/){:target="_blank"} and unpack the archive in some valid `$PATH` directory like `/usr/local/bin/`, `~/.local/bin`, or whatever directory you Windows weirdos happen to use. If you want to make sure you have the appropriate `oc` version for our clusters today, you can run `oc version --client`. If the version of `oc` that's running doesn't match what you think you've downloaded and put in the right place, you can try exiting your terminal, opening a new one, and checking again.
2. Optionally, if you'd like to save and apply manifests on the command line later, pick a text editor, any text editor. If you want to use `vi` or `vim` or `nvim` or `lvim` or any lesser editor, I don't care. If you're going to use `VSCode` please don't ask James for help, he doesn't know how to use a mouse.
