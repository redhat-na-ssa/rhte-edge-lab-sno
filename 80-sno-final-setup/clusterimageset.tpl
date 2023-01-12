---
apiVersion: hive.openshift.io/v1
kind: ClusterImageSet
metadata:
  name: img${openshift_version_z}-x86-64-appsub
  labels:
    channel: candidate
    visible: "false"
spec:
  releaseImage: quay.io/openshift-release-dev/ocp-release:${openshift_version_z}-x86_64
