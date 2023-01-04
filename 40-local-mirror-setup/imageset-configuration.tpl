apiVersion: mirror.openshift.io/v1alpha2
kind: ImageSetConfiguration
storageConfig:
  registry:
    imageURL: localhost:5000/oc-mirror-metadata:latest
    skipTLS: true
mirror:
  platform:
    channels:
    - name: ${OPENSHIFT_VERSION}
