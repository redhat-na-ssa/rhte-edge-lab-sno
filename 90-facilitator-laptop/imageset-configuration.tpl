apiVersion: mirror.openshift.io/v1alpha2
kind: ImageSetConfiguration
storageConfig:
  registry:
    imageURL: registry.internal.${BASE_DOMAIN}
mirror:
  platform:
    channels:
    - name: ${OPENSHIFT_VERSION}
