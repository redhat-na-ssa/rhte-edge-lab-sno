---
layout: exercise
title: Looking at our Bare Metal Nodes
---

#### General Edge Hardware

Edge devices are often low power, ARM or x86 based ruggedized devices that favor no moving parts. Think - no fans, only fins and the chassis/case acts as a heat sink. They often run on 12V (or less) power input and are designed to function in extreme environments, such as: high heat, freezing cold, and corrosive locations. It is very common to have devices existing in very remote locations where human intervention (typically called “rolling a truck”) may require an extended journey.

The device at your workstation may or may not match these specifications exactly, but we’ll be using it as an approximation of a device that’s been deployed to an extremely remote location, such as a wellhead in an oil field, or attached to a high voltage electrical pole.

Despite the differences, there will be similarities to more traditional devices, such as USB ports, ethernet ports, antennas, etc.

Feel free to investigate the hardware at your workstation, and if you have questions please notify the lab instructor.
{% if site.data.login.region == "na" or site.data.login.region == "emea" %}

#### OnLogic Edge Hardware

The bare metal nodes used with today's lab were purchased by Red Hat with the help of our partners at OnLogic. The Helix HX500 nodes are powerful, fanless, and RHEL Certified. OnLogic is with us today to talk a bit about their edge hardware capabilities, including talking about other form factors and models available.

![OnLogic Helix HX500](/assets/images/hx500.jpg?style=centered&style=border "OnLogic Helix HX500")
{% elsif site.data.login.region == "apac" %}

#### Intel Edge Hardware

The bare metal nodes used with today's lab were graciously provided by our partners at Intel. The NUC Rugged line of hardware are powerful, fanless, and RHEL Certified. Additionally, Intel's modular Compute Element architecture allows for selection of appropriate hardware components and I/O per use-case while remaining standardized on the Compute Element architecture.

![Intel NUC Rugged Chassis and Board Element](/assets/images/nuc-rugged-element.jpg?style=centered&style=border "Intel NUC Rugged Chassis and Board Element")

For more information on the Intel NUC Rugged line, see the [product pages](https://www.intel.com/content/www/us/en/products/docs/boards-kits/nuc/nuc-assets/nuc-elements-austin-beach.html){:target="_blank"}.
{% endif %}
