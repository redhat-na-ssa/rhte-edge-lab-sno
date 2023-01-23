---
layout: exercise
title: Exploring the ACM Hub
---

The ACM hub interface you get dropped off at should look like this after signing in:

![ACM Hub Overview](/assets/images/acm-hub-landing.png?style=centered&style=border "ACM Hub Overview")

If your interface doesn't show those sections on the left and instead shows a traditional OpenShift console navigation bar, change the pulldown in the top left from ![ACM Local Cluster](/assets/images/acm-local-cluster.png?style=small "ACM Local Cluster") to ![ACM All Clusters](/assets/images/acm-all-clusters.png?style=small "ACM All Clusters") and select `Home` and `Overview` in the left navigation bar if necessary.

You'll be able to view the discovered hosts by browsing the menu on the left. Click ![Infrastructure](/assets/images/acm-infrastructure.png?style=small "Infrastructure"), then ![Host Inventory](/assets/images/acm-host-inventory.png?style=small "Host Inventory"), and click on the name of your Infrastructure Environment from the list (`{{ site.data.login.region }}`).

![ACM Infrastructure Environments](/assets/images/acm-infra-envs.png?style=centered&style=border "ACM Infrastructure Environments")

Next, click on ![Hosts](/assets/images/acm-infra-hosts.png?style=small "Hosts"). This is where discovered hosts will appear to be approved before being bound to a cluster definition.

Back in the `Infrastructure` navigation menu on the left, you should see ![Clusters](/assets/images/acm-infra-clusters.png?style=small "Clusters"). Here at the `Cluster list` will show all clusters managed by ACM and where they're running.

Additional areas of interest include the ![Applications](/assets/images/acm-applications.png?style=small "Applications") and ![Governance](/assets/images/acm-governance.png?style=small "Governance") sections.

We'll be using all of these sections today and referring to them by the menu-drilldown to get into them, so be sure you understand how the navigation bar on the left and various tab views work together.
