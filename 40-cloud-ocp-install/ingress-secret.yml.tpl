---
apiVersion: v1
kind: Secret
metadata:
  name: router-certs
  namespace: openshift-ingress
type: kubernetes.io/tls
stringData:
  tls.crt: ${CLUSTER_FULLCHAIN}
