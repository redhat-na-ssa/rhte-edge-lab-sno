---
apiVersion: hive.openshift.io/v1
kind: ClusterImageSet
metadata:
  name: img4.11.24-x86-64-appsub
  labels:
    channel: fast
    visible: "true"
spec:
  releaseImage: quay.io/openshift-release-dev/ocp-release:4.11.24-x86_64
