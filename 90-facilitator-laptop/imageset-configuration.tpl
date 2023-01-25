apiVersion: mirror.openshift.io/v1alpha2
kind: ImageSetConfiguration
storageConfig:
  registry:
    imageURL: registry.internal.${BASE_DOMAIN}:443/metadata
mirror:
  platform:
    channels:
    - name: ${OPENSHIFT_VERSION}
