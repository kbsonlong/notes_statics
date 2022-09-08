#!/bin/bash

# install aeraki

cat << EOF > crd.yaml
# DO NOT EDIT - Generated by Cue OpenAPI generator based on Istio APIs.
apiVersion: apiextensions.k8s.io/v1
kind: CustomResourceDefinition
metadata:
  annotations:
    "helm.sh/resource-policy": keep
  labels:
    app: aeraki
    chart: aeraki
    heritage: Tiller
    release: aeraki
  name: dubboauthorizationpolicies.dubbo.aeraki.io
spec:
  group: dubbo.aeraki.io
  names:
    categories:
    - aeraki-io
    - dubbo-aeraki-io
    kind: DubboAuthorizationPolicy
    listKind: DubboAuthorizationPolicyList
    plural: dubboauthorizationpolicies
    shortNames:
    - dap
    singular: dubboauthorizationpolicy
  scope: Namespaced
  versions:
  - name: v1alpha1
    schema:
      openAPIV3Schema:
        properties:
          spec:
            description: DubboAuthorizationPolicy enables access control on Dubbo
              services.
            properties:
              action:
                description: Optional.
                enum:
                - ALLOW
                - DENY
                type: string
              rules:
                description: Optional.
                items:
                  properties:
                    from:
                      description: Optional.
                      items:
                        properties:
                          source:
                            description: Source specifies the source of a request.
                            properties:
                              namespaces:
                                description: Optional.
                                items:
                                  format: string
                                  type: string
                                type: array
                              notNamespaces:
                                description: Optional.
                                items:
                                  format: string
                                  type: string
                                type: array
                              notPrincipals:
                                description: Optional.
                                items:
                                  format: string
                                  type: string
                                type: array
                              principals:
                                description: Optional.
                                items:
                                  format: string
                                  type: string
                                type: array
                            type: object
                        type: object
                      type: array
                    to:
                      description: Optional.
                      items:
                        properties:
                          operation:
                            description: Operation specifies the operation of a request.
                            properties:
                              interfaces:
                                description: Optional.
                                items:
                                  format: string
                                  type: string
                                type: array
                              methods:
                                description: Optional.
                                items:
                                  format: string
                                  type: string
                                type: array
                              notInterfaces:
                                description: Optional.
                                items:
                                  format: string
                                  type: string
                                type: array
                              notMethods:
                                description: Optional.
                                items:
                                  format: string
                                  type: string
                                type: array
                            type: object
                        type: object
                      type: array
                  type: object
                type: array
            type: object
          status:
            type: object
            x-kubernetes-preserve-unknown-fields: true
        type: object
    served: true
    storage: true
    subresources:
      status: {}

---
apiVersion: apiextensions.k8s.io/v1
kind: CustomResourceDefinition
metadata:
  annotations:
    "helm.sh/resource-policy": keep
  labels:
    app: aeraki
    chart: aeraki
    heritage: Tiller
    release: aeraki
  name: applicationprotocols.metaprotocol.aeraki.io
spec:
  group: metaprotocol.aeraki.io
  names:
    categories:
    - aeraki-io
    - metaprotocol-aeraki-io
    kind: ApplicationProtocol
    listKind: ApplicationProtocolList
    plural: applicationprotocols
    singular: applicationprotocol
  scope: Cluster
  versions:
  - name: v1alpha1
    schema:
      openAPIV3Schema:
        properties:
          spec:
            description: ApplicationProtocol defines an application protocol built
              on top of MetaProtocol.
            properties:
              codec:
                format: string
                type: string
              protocol:
                format: string
                type: string
            type: object
          status:
            type: object
            x-kubernetes-preserve-unknown-fields: true
        type: object
    served: true
    storage: true
    subresources:
      status: {}

---
apiVersion: apiextensions.k8s.io/v1
kind: CustomResourceDefinition
metadata:
  annotations:
    "helm.sh/resource-policy": keep
  labels:
    app: aeraki
    chart: aeraki
    heritage: Tiller
    release: aeraki
  name: metarouters.metaprotocol.aeraki.io
spec:
  group: metaprotocol.aeraki.io
  names:
    categories:
    - aeraki-io
    - metaprotocol-aeraki-io
    kind: MetaRouter
    listKind: MetaRouterList
    plural: metarouters
    singular: metarouter
  scope: Namespaced
  versions:
  - name: v1alpha1
    schema:
      openAPIV3Schema:
        properties:
          spec:
            description: MetaRouter defines route policies for MetaProtocol proxy.
            properties:
              exportTo:
                description: A list of namespaces to which this MetaRouter is exported.
                items:
                  format: string
                  type: string
                type: array
              globalRateLimit:
                description: Global rate limit policy.
                properties:
                  denyOnFail:
                    type: boolean
                  descriptors:
                    items:
                      properties:
                        descriptorKey:
                          format: string
                          type: string
                        property:
                          format: string
                          type: string
                      type: object
                    type: array
                  domain:
                    description: The rate limit domain to use when calling the rate
                      limit service.
                    format: string
                    type: string
                  match:
                    description: Match conditions to be satisfied for the rate limit
                      rule to be activated.
                    properties:
                      attributes:
                        additionalProperties:
                          oneOf:
                          - not:
                              anyOf:
                              - required:
                                - exact
                              - required:
                                - prefix
                              - required:
                                - regex
                          - required:
                            - exact
                          - required:
                            - prefix
                          - required:
                            - regex
                          properties:
                            exact:
                              format: string
                              type: string
                            prefix:
                              format: string
                              type: string
                            regex:
                              description: RE2 style regex-based match (https://github.com/google/re2/wiki/Syntax).
                              format: string
                              type: string
                          type: object
                        description: If the value is empty and only the name of attribute
                          is specified, presence of the attribute is checked.
                        type: object
                    type: object
                  rateLimitService:
                    description: The cluster name of the external rate limit service
                      provider.
                    format: string
                    type: string
                  requestTimeout:
                    description: The timeout in milliseconds for the rate limit service
                      RPC.
                    type: string
                type: object
              hosts:
                description: The destination service to which traffic is being sent.
                items:
                  format: string
                  type: string
                type: array
              localRateLimit:
                description: Loacal rate limit policy.
                properties:
                  conditions:
                    description: The more specific rate limit conditions, the first
                      match will be used.
                    items:
                      properties:
                        match:
                          description: Match conditions to be satisfied for the rate
                            limit rule to be activated.
                          properties:
                            attributes:
                              additionalProperties:
                                oneOf:
                                - not:
                                    anyOf:
                                    - required:
                                      - exact
                                    - required:
                                      - prefix
                                    - required:
                                      - regex
                                - required:
                                  - exact
                                - required:
                                  - prefix
                                - required:
                                  - regex
                                properties:
                                  exact:
                                    format: string
                                    type: string
                                  prefix:
                                    format: string
                                    type: string
                                  regex:
                                    description: RE2 style regex-based match (https://github.com/google/re2/wiki/Syntax).
                                    format: string
                                    type: string
                                type: object
                              description: If the value is empty and only the name
                                of attribute is specified, presence of the attribute
                                is checked.
                              type: object
                          type: object
                        tokenBucket:
                          properties:
                            fillInterval:
                              description: The fill interval that tokens are added
                                to the bucket.
                              type: string
                            maxTokens:
                              description: The maximum tokens that the bucket can
                                hold.
                              type: integer
                            tokensPerFill:
                              description: The number of tokens added to the bucket
                                during each fill interval.
                              nullable: true
                              type: integer
                          type: object
                      type: object
                    type: array
                  tokenBucket:
                    properties:
                      fillInterval:
                        description: The fill interval that tokens are added to the
                          bucket.
                        type: string
                      maxTokens:
                        description: The maximum tokens that the bucket can hold.
                        type: integer
                      tokensPerFill:
                        description: The number of tokens added to the bucket during
                          each fill interval.
                        nullable: true
                        type: integer
                    type: object
                type: object
              routes:
                description: An ordered list of route rules for MetaProtocol traffic.
                items:
                  properties:
                    match:
                      description: Match conditions to be satisfied for the rule to
                        be activated.
                      properties:
                        attributes:
                          additionalProperties:
                            oneOf:
                            - not:
                                anyOf:
                                - required:
                                  - exact
                                - required:
                                  - prefix
                                - required:
                                  - regex
                            - required:
                              - exact
                            - required:
                              - prefix
                            - required:
                              - regex
                            properties:
                              exact:
                                format: string
                                type: string
                              prefix:
                                format: string
                                type: string
                              regex:
                                description: RE2 style regex-based match (https://github.com/google/re2/wiki/Syntax).
                                format: string
                                type: string
                            type: object
                          description: If the value is empty and only the name of
                            attribute is specified, presence of the attribute is checked.
                          type: object
                      type: object
                    mirror:
                      properties:
                        host:
                          description: The name of a service from the service registry.
                          format: string
                          type: string
                        port:
                          description: Specifies the port on the host that is being
                            addressed.
                          properties:
                            number:
                              type: integer
                          type: object
                        subset:
                          description: The name of a subset within the service.
                          format: string
                          type: string
                      type: object
                    mirrorPercentage:
                      description: Percentage of the traffic to be mirrored by the
                        `mirror` field.
                      properties:
                        value:
                          format: double
                          type: number
                      type: object
                    name:
                      description: The name assigned to the route for debugging purposes.
                      format: string
                      type: string
                    requestMutation:
                      description: Specifies a list of key-value pairs that should
                        be mutated for each request.
                      items:
                        properties:
                          key:
                            description: Key name.
                            format: string
                            type: string
                          value:
                            description: alue.
                            format: string
                            type: string
                        type: object
                      type: array
                    responseMutation:
                      description: Specifies a list of key-value pairs that should
                        be mutated for each response.
                      items:
                        properties:
                          key:
                            description: Key name.
                            format: string
                            type: string
                          value:
                            description: alue.
                            format: string
                            type: string
                        type: object
                      type: array
                    route:
                      description: A Route rule can forward (default) traffic.
                      items:
                        properties:
                          destination:
                            properties:
                              host:
                                description: The name of a service from the service
                                  registry.
                                format: string
                                type: string
                              port:
                                description: Specifies the port on the host that is
                                  being addressed.
                                properties:
                                  number:
                                    type: integer
                                type: object
                              subset:
                                description: The name of a subset within the service.
                                format: string
                                type: string
                            type: object
                          weight:
                            type: integer
                        type: object
                      type: array
                  type: object
                type: array
            type: object
          status:
            type: object
            x-kubernetes-preserve-unknown-fields: true
        type: object
    served: true
    storage: true
    subresources:
      status: {}

---
apiVersion: apiextensions.k8s.io/v1
kind: CustomResourceDefinition
metadata:
  name: redisdestinations.redis.aeraki.io
spec:
  group: redis.aeraki.io
  names:
    categories:
    - redis-aeraki-io
    kind: RedisDestination
    listKind: RedisDestinationList
    plural: redisdestinations
    shortNames:
    - rd
    singular: redisdestination
  scope: Namespaced
  versions:
  - additionalPrinterColumns:
    - description: The name of a service from the service registry
      jsonPath: .spec.host
      name: Host
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
    schema:
      openAPIV3Schema:
        properties:
          spec:
            properties:
              host:
                format: string
                type: string
              trafficPolicy:
                properties:
                  connectionPool:
                    properties:
                      redis:
                        properties:
                          auth:
                            oneOf:
                            - not:
                                anyOf:
                                - required:
                                  - secret
                                - required:
                                  - plain
                            - required:
                              - secret
                            - required:
                              - plain
                            properties:
                              plain:
                                description: redis password.
                                properties:
                                  password:
                                    format: string
                                    type: string
                                  username:
                                    format: string
                                    type: string
                                type: object
                              secret:
                                description: Secret use the k8s secret in current
                                  namespace.
                                properties:
                                  name:
                                    format: string
                                    type: string
                                  passwordField:
                                    format: string
                                    type: string
                                  usernameField:
                                    format: string
                                    type: string
                                type: object
                            type: object
                          discoveryEndpoints:
                            items:
                              format: string
                              type: string
                            type: array
                          mode:
                            enum:
                            - PROXY
                            - CLUSTER
                            type: string
                        type: object
                      tcp:
                        properties:
                          connectTimeout:
                            description: TCP connection timeout.
                            type: string
                          maxConnections:
                            description: Maximum number of HTTP1 /TCP connections
                              to a destination host.
                            format: int32
                            type: integer
                          tcpKeepalive:
                            description: If set then set SO_KEEPALIVE on the socket
                              to enable TCP Keepalives.
                            properties:
                              interval:
                                description: The time duration between keep-alive
                                  probes.
                                type: string
                              probes:
                                type: integer
                              time:
                                type: string
                            type: object
                        type: object
                    type: object
                type: object
            type: object
          status:
            type: object
            x-kubernetes-preserve-unknown-fields: true
        type: object
    served: true
    storage: true
    subresources:
      status: {}

---
apiVersion: apiextensions.k8s.io/v1
kind: CustomResourceDefinition
metadata:
  name: redisservices.redis.aeraki.io
spec:
  group: redis.aeraki.io
  names:
    categories:
    - redis-aeraki-io
    kind: RedisService
    listKind: RedisServiceList
    plural: redisservices
    shortNames:
    - rsvc
    singular: redisservice
  scope: Namespaced
  versions:
  - additionalPrinterColumns:
    - description: The destination hosts to which traffic is being sent
      jsonPath: .spec.hosts
      name: Hosts
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
    schema:
      openAPIV3Schema:
        properties:
          spec:
            description: RedisService provide a way to config redis service in service
              mesh.
            properties:
              faults:
                description: List of faults to inject.
                items:
                  properties:
                    commands:
                      description: Commands fault is restricted to, if any.
                      items:
                        format: string
                        type: string
                      type: array
                    delay:
                      description: Delay for all faults.
                      type: string
                    percentage:
                      description: Percentage of requests fault applies to.
                      properties:
                        value:
                          format: double
                          type: number
                      type: object
                    type:
                      description: Fault type.
                      enum:
                      - DELAY
                      - ERROR
                      type: string
                  type: object
                type: array
              host:
                items:
                  format: string
                  type: string
                type: array
              redis:
                items:
                  properties:
                    match:
                      oneOf:
                      - not:
                          anyOf:
                          - required:
                            - key
                      - required:
                        - key
                      properties:
                        key:
                          properties:
                            prefix:
                              description: String prefix that must match the beginning
                                of the keys.
                              format: string
                              type: string
                            removePrefix:
                              description: Indicates if the prefix needs to be removed
                                from the key when forwarded.
                              type: boolean
                          type: object
                      type: object
                    mirror:
                      items:
                        properties:
                          excludeReadCommands:
                            type: boolean
                          percentage:
                            properties:
                              value:
                                format: double
                                type: number
                            type: object
                          route:
                            properties:
                              host:
                                format: string
                                type: string
                              port:
                                type: integer
                            type: object
                        type: object
                      type: array
                    route:
                      properties:
                        host:
                          format: string
                          type: string
                        port:
                          type: integer
                      type: object
                  type: object
                type: array
              settings:
                properties:
                  auth:
                    description: Downstream auth.
                    oneOf:
                    - not:
                        anyOf:
                        - required:
                          - secret
                        - required:
                          - plain
                    - required:
                      - secret
                    - required:
                      - plain
                    properties:
                      plain:
                        description: redis password.
                        properties:
                          password:
                            format: string
                            type: string
                          username:
                            format: string
                            type: string
                        type: object
                      secret:
                        description: Secret use the k8s secret in current namespace.
                        properties:
                          name:
                            format: string
                            type: string
                          passwordField:
                            format: string
                            type: string
                          usernameField:
                            format: string
                            type: string
                        type: object
                    type: object
                  bufferFlushTimeout:
                    type: string
                  caseInsensitive:
                    description: Indicates that prefix matching should be case insensitive.
                    type: boolean
                  enableCommandStats:
                    type: boolean
                  enableHashtagging:
                    type: boolean
                  enableRedirection:
                    type: boolean
                  maxBufferSizeBeforeFlush:
                    type: integer
                  maxUpstreamUnknownConnections:
                    nullable: true
                    type: integer
                  opTimeout:
                    description: Per-operation timeout in milliseconds.
                    type: string
                  readPolicy:
                    description: Read policy.
                    enum:
                    - MASTER
                    - PREFER_MASTER
                    - REPLICA
                    - PREFER_REPLICA
                    - ANY
                    type: string
                type: object
            type: object
          status:
            type: object
            x-kubernetes-preserve-unknown-fields: true
        type: object
    served: true
    storage: true
    subresources:
      status: {}

---
EOF

cat << EOF > aeraki.yaml
# Copyright Aeraki Authors
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: aeraki
  namespace: istio-system
  labels:
    app: aeraki
spec:
  selector:
    matchLabels:
      app: aeraki
  replicas: 1
  template:
    metadata:
      labels:
        app: aeraki
      annotations:
        sidecar.istio.io/inject: "false"
    spec:
      serviceAccountName: aeraki
      containers:
        - name: aeraki
          image: aeraki/aeraki:1.1.2
          # imagePullPolicy should be set to Never so Minikube can use local image for e2e testing
          imagePullPolicy:
          env:
            - name: AERAKI_IS_MASTER
              value: "true"
            - name: AERAKI_ISTIOD_ADDR
              value: istiod.istio-system:15010
            - name: AERAKI_CLUSTER_ID
              value:
            # In case of TCM, Istio config store can be a different k8s API server from the one Aeraki is running with
            - name: AERAKI_ISTIO_CONFIG_STORE_SECRET
              value:
            - name: AERAKI_XDS_LISTEN_ADDR
              value: ":15010"
            - name: AERAKI_ENABLE_ENVOY_FILTER_NS_SCOPE
              # False(Default): The generated envoyFilters will be placed under Istio root namespace
              # True: The generated envoyFilters will be placed under the service namespace
              value: "false"
            - name: AERAKI_LOG_LEVEL
              value: "all:debug"
            - name: AERAKI_NAMESPACE
              valueFrom:
                fieldRef:
                  fieldPath: metadata.namespace
            - name: AERAKI_SERVER_ID
              valueFrom:
                fieldRef:
                  fieldPath: metadata.name
          volumeMounts:
            - name: istiod-ca-cert
              mountPath: /var/run/secrets/istio
              readOnly: true
      volumes:
        - name: istiod-ca-cert
          configMap:
            name: istio-ca-root-cert
            defaultMode: 420
---
apiVersion: v1
kind: Service
metadata:
  labels:
    app: aeraki
  name: aeraki
  namespace: istio-system
spec:
  ports:
    - name: grpc-xds
      port: 15010
      protocol: TCP
      targetPort: 15010
    - name: https-validation
      port: 443
      protocol: TCP
      targetPort: 15017
  selector:
    app: aeraki
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: aeraki
  namespace: istio-system
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  labels:
    app: aeraki
  name: aeraki
  namespace: istio-system
rules:
  - apiGroups:
      - ""
    resources:
      - configmaps
      - events
    verbs:
      - '*'
  - apiGroups:
      - coordination.k8s.io
    resources:
      - '*'
    verbs:
      - '*'
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  labels:
    app: aeraki
  name: aeraki
  namespace: istio-system
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: aeraki
subjects:
  - kind: ServiceAccount
    name: aeraki
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  labels:
    app: aeraki
  name: aeraki
rules:
  - apiGroups:
      - ""
    resources:
      - secrets
      - namespaces
      - configmaps
    verbs:
      - '*'
  - apiGroups:
      - networking.istio.io
    resources:
      - '*'
    verbs:
      - '*'
  - apiGroups:
      - redis.aeraki.io
      - dubbo.aeraki.io
      - metaprotocol.aeraki.io
    resources:
      - '*'
    verbs:
      - '*'
  - apiGroups:
      - networking.istio.io
    resources:
      - virtualservices
      - destinationrules
      - envoyfilters
      - serviceentries
    verbs:
      - '*'
  - apiGroups:
      - admissionregistration.k8s.io
    resources:
      - validatingwebhookconfigurations
    verbs:
      - '*'
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  labels:
    app: aeraki
  name: aeraki
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: aeraki
subjects:
  - kind: ServiceAccount
    name: aeraki
    namespace: istio-system
---
apiVersion: metaprotocol.aeraki.io/v1alpha1
kind: ApplicationProtocol
metadata:
  name: dubbo
spec:
  protocol: dubbo
  codec: aeraki.meta_protocol.codec.dubbo
---
apiVersion: metaprotocol.aeraki.io/v1alpha1
kind: ApplicationProtocol
metadata:
  name: thrift
spec:
  protocol: thrift
  codec: aeraki.meta_protocol.codec.thrift
EOF


kubectl delete crd applicationprotocols.metaprotocol.aeraki.io || true
kubectl apply -f crd.yaml
kubectl apply -f aeraki.yaml -n istio-system