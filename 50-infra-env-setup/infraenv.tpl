---
apiVersion: v1
kind: Namespace
metadata:
  name: ${env_name}
---
apiVersion: agent-install.openshift.io/v1beta1
kind: InfraEnv
metadata:
  name: ${env_name}
  namespace: ${env_name}
  labels:
    agentclusterinstalls.extensions.hive.openshift.io/location: ${env_loc}
    networkType: static
spec:
  agentLabels:
    'agentclusterinstalls.extensions.hive.openshift.io/location': ${env_loc}
  pullSecretRef:
    name: pullsecret
  sshAuthorizedKey: ${SSH_PUB_KEY}
  nmStateConfigLabelSelector:
      matchLabels:
        infraenvs.agent-install.openshift.io: ${env_name}
status:
  agentLabelSelector:
    matchLabels:
      'agentclusterinstalls.extensions.hive.openshift.io/location': ${env_loc}
---
kind: Secret
apiVersion: v1
metadata:
  name: pullsecret
  namespace: ${env_name}
data:
  '.dockerconfigjson': '${PULL_SECRET_B64}'
type: 'kubernetes.io/dockerconfigjson'
---
kind: Role
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: capi-provider-role
  namespace: ${env_name}
rules:
  - verbs:
      - '*'
    apiGroups:
      - agent-install.openshift.io
    resources:
      - agents
