#!/bin/bash

# Install Istio

Install_Istio_Operator() {
    ## create NameSpace
    kubectl apply -f - <<EOF
---
apiVersion: v1
kind: Namespace
metadata:
  name: istio-operator
EOF

kubectl apply -f - <<EOF
---
# Source: istio-operator/templates/service_account.yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  namespace: istio-operator
  name: istio-operator
---
# Source: istio-operator/templates/crds.yaml
# SYNC WITH manifests/charts/base/files
apiVersion: apiextensions.k8s.io/v1
kind: CustomResourceDefinition
metadata:
  name: istiooperators.install.istio.io
  labels:
    release: istio
spec:
  conversion:
    strategy: None
  group: install.istio.io
  names:
    kind: IstioOperator
    listKind: IstioOperatorList
    plural: istiooperators
    singular: istiooperator
    shortNames:
    - iop
    - io
  scope: Namespaced
  versions:
  - additionalPrinterColumns:
    - description: Istio control plane revision
      jsonPath: .spec.revision
      name: Revision
      type: string
    - description: IOP current state
      jsonPath: .status.status
      name: Status
      type: string
    - description: 'CreationTimestamp is a timestamp representing the server time
        when this object was created. It is not guaranteed to be set in happens-before
        order across separate operations. Clients may not set this value. It is represented
        in RFC3339 form and is in UTC. Populated by the system. Read-only. Null for
        lists. More info: https://git.k8s.io/community/contributors/devel/api-conventions.md#metadata'
      jsonPath: .metadata.creationTimestamp
      name: Age
      type: date
    name: v1alpha1
    subresources:
      status: {}
    schema:
      openAPIV3Schema:
        type: object
        x-kubernetes-preserve-unknown-fields: true
    served: true
    storage: true
---
# Source: istio-operator/templates/clusterrole.yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  creationTimestamp: null
  name: istio-operator
rules:
# istio groups
- apiGroups:
  - authentication.istio.io
  resources:
  - '*'
  verbs:
  - '*'
- apiGroups:
  - config.istio.io
  resources:
  - '*'
  verbs:
  - '*'
- apiGroups:
  - install.istio.io
  resources:
  - '*'
  verbs:
  - '*'
- apiGroups:
  - networking.istio.io
  resources:
  - '*'
  verbs:
  - '*'
- apiGroups:
  - security.istio.io
  resources:
  - '*'
  verbs:
  - '*'
# k8s groups
- apiGroups:
  - admissionregistration.k8s.io
  resources:
  - mutatingwebhookconfigurations
  - validatingwebhookconfigurations
  verbs:
  - '*'
- apiGroups:
  - apiextensions.k8s.io
  resources:
  - customresourcedefinitions.apiextensions.k8s.io
  - customresourcedefinitions
  verbs:
  - '*'
- apiGroups:
  - apps
  - extensions
  resources:
  - daemonsets
  - deployments
  - deployments/finalizers
  - replicasets
  verbs:
  - '*'
- apiGroups:
  - autoscaling
  resources:
  - horizontalpodautoscalers
  verbs:
  - '*'
- apiGroups:
  - monitoring.coreos.com
  resources:
  - servicemonitors
  verbs:
  - get
  - create
  - update
- apiGroups:
  - policy
  resources:
  - poddisruptionbudgets
  verbs:
  - '*'
- apiGroups:
  - rbac.authorization.k8s.io
  resources:
  - clusterrolebindings
  - clusterroles
  - roles
  - rolebindings
  verbs:
  - '*'
- apiGroups:
  - coordination.k8s.io
  resources:
  - leases
  verbs:
  - get
  - create
  - update
- apiGroups:
  - ""
  resources:
  - configmaps
  - endpoints
  - events
  - namespaces
  - pods
  - pods/proxy
  - pods/portforward
  - persistentvolumeclaims
  - secrets
  - services
  - serviceaccounts
  verbs:
  - '*'
---
# Source: istio-operator/templates/clusterrole_binding.yaml
kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: istio-operator
subjects:
- kind: ServiceAccount
  name: istio-operator
  namespace: istio-operator
roleRef:
  kind: ClusterRole
  name: istio-operator
  apiGroup: rbac.authorization.k8s.io
---
# Source: istio-operator/templates/service.yaml
apiVersion: v1
kind: Service
metadata:
  namespace: istio-operator
  labels:
    name: istio-operator
  name: istio-operator
spec:
  ports:
  - name: http-metrics
    port: 8383
    targetPort: 8383
    protocol: TCP
  selector:
    name: istio-operator
---
# Source: istio-operator/templates/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  namespace: istio-operator
  name: istio-operator
spec:
  replicas: 1
  revisionHistoryLimit: 10
  selector:
    matchLabels:
      name: istio-operator
  template:
    metadata:
      labels:
        name: istio-operator
    spec:
      serviceAccountName: istio-operator
      containers:
        - name: istio-operator
          image: docker.io/istio/operator:1.15.0
          command:
          - operator
          - server
          securityContext:
            allowPrivilegeEscalation: false
            capabilities:
              drop:
              - ALL
            privileged: false
            readOnlyRootFilesystem: true
            runAsGroup: 1337
            runAsUser: 1337
            runAsNonRoot: true
          imagePullPolicy: IfNotPresent
          resources:
            limits:
              cpu: 200m
              memory: 256Mi
            requests:
              cpu: 50m
              memory: 128Mi
          env:
            - name: WATCH_NAMESPACE
              value: "istio-system"
            - name: LEADER_ELECTION_NAMESPACE
              value: "istio-operator"
            - name: POD_NAME
              valueFrom:
                fieldRef:
                  fieldPath: metadata.name
            - name: OPERATOR_NAME
              value: "istio-operator"
            - name: WAIT_FOR_RESOURCES_TIMEOUT
              value: "300s"
            - name: REVISION
              value: ""
EOF

kubectl apply -f - <<EOF
---
apiVersion: v1
kind: Namespace
metadata:
  name: istio-system
EOF

kubectl apply -f - <<EOF
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
metadata:
  namespace: istio-system
  name: istiocontrolplane
spec:
  profile: demo
EOF


}

Install_Istio() {
    curl -L https://istio.io/downloadIstio | ISTIO_VERSION=1.15.0 sh -
    cd istio-1.15.0
    export PATH=$PWD/bin:$PATH
    istioctl install --set profile=demo -y
}

Deploy_Bookinfo() {
    kubectl label namespace default istio-injection=enabled
    kubectl apply -f samples/bookinfo/platform/kube/bookinfo.yaml
    kubectl apply -f samples/bookinfo/networking/bookinfo-gateway.yaml
}

Deploy_Obs() {
    kubectl apply -f samples/addons
    kubectl rollout status deployment/kiali -n istio-system
}

main() {
    if [ "$1" == "operator" ];then
        Install_Istio_Operator
    else
        Install_Istio
    fi
    Deploy_Bookinfo
    Deploy_Obs
}

main