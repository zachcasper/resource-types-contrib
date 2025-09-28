# Recipe for deploying Containers resources to Kubernetes using Bicep

Overall Recipe structure:

- Deployment
- Service for each container (if ports specified)
- Horizontal Pod Autoscaler (if autoScaling specified)
- Secret containing connected resource properties
- Role granting access to the secret

Implement later:

- daprSidecar extension
- platformOptions punch through

Other notes:

- The intention when developing the Containers resource type definition was to enable high-level objects to just be passed directly in by reference (e.g., `PodSpec.containers: context.resource.properties.containers`). But there are exceptions like mounting secrets as an environment variable. Consider a patching approach rather than enumerating each property.
- There are a lot of arrays in the PodSpec but the Radius Containers uses maps. Consider whether the Containers resource type definition should be modified to be more arrays than maps.

## [DeploymentSpec Properties](https://kubernetes.io/docs/reference/kubernetes-api/workload-resources/deployment-v1/#DeploymentSpec)

| DeploymentSpec | Radius Containers |
| ---------------| ----------------- |
| selector | N/A |
| template (PodSpec) | See below |
| replicas (int32) | context.resource.properties.replicas (string) |
| minReadySeconds (int32) | Not used |
| strategy (DeploymentStrategy) | Not used |
| - strategy.type (string) | Not used |
| - strategy.rollingUpdate (RollingUpdateDeployment) | Not used |
|   - strategy.rollingUpdate.maxSurge (IntOrString) | Not used |
|   - strategy.rollingUpdate.maxUnavailable (IntOrString) | Not used |
| revisionHistoryLimit (int32) | Not used |
| progressDeadlineSeconds (int32) | Not used |
| paused (boolean) | Not used |

## [PodSpec Properties](https://kubernetes.io/docs/reference/kubernetes-api/workload-resources/pod-v1/#PodSpec)

| PodSpec | Radius Containers |
| --------| ----------------- |
| containers ([]Container), required | context.resource.properties.containers transformed to an array and filtered for initContainers null or false |
| initContainers ([]Container) | context.resource.properties.containers transformed to an array and filtered for initContainers true |
| ephemeralContainers ([]EphemeralContainer) | Not used |
| imagePullSecrets ([]LocalObjectReference) | Not used |
| enableServiceLinks (boolean) | Not used |
| os (PodOS) | Not used |
| volumes ([]Volume) | context.resource.properties.volumes <-- Transformed to an array |
| nodeSelector (map[string]string) | Not used |
| nodeName (string) | Not used |
| affinity (Affinity) | Not used |
| - affinity.nodeAffinity (NodeAffinity) | Not used |
| - affinity.podAffinity (PodAffinity) | Not used |
| - affinity.podAntiAffinity (PodAntiAffinity) | Not used |
| tolerations ([]Toleration) | Not used |
| - tolerations.key (string) | Not used |
| - tolerations.operator (string) | Not used |
| - tolerations.value (string) | Not used |
| - tolerations.effect (string) | Not used |
| - tolerations.tolerationSeconds (int64) | Not used |
| schedulerName (string) | Not used |
| runtimeClassName (string) | Not used |
| priorityClassName (string) | Not used |
| priority (int32) | Not used |
| preemppreemptionPolicy (string)tionPolicy | Not used |
| topologySpreadConstraints ([]TopologySpreadConstraint) | Not used |
| - topologySpreadConstraints.maxSkew (int32), required | Not used |
| - topologySpreadConstraints.topologyKey (string), required | Not used |
| - topologySpreadConstraints.whenUnsatisfiable (string), required | Not used |
| - topologySpreadConstraints.labelSelector (LabelSelector) | Not used |
| - topologySpreadConstraints.matchLabelKeys ([]string) | Not used |
| - topologySpreadConstraints.minDomains (int32) | Not used |
| - topologySpreadConstraints.nodeAffinityPolicy (string) | Not used |
| - topologySpreadConstraints.nodeTaintsPolicy (string) | Not used |
| overhead (map[string]Quantity) | Not used |
| restartPolicy (string) | context.resource.properties.restartPolicy (string) |
| terminationGracePeriodSeconds (int64) | Not used |
| activeDeadlineSeconds (int64) | Not used |
| readinessGates ([]PodReadinessGate) | Not used |
| - readinessGates.conditionType (string), required | Not used |
| hostname (string) | Not used |
| hostnameOverride (string) | Not used |
| setHostnameAsFQDN (boolean) | Not used |
| subdomain (string) | Not used |
| hostAliases ([]HostAlias) | Not used |
| - hostAliases.ip (string), required | Not used |
| - hostAliases.hostnames ([]string) | Not used |
| dnsConfig (PodDNSConfig) | Not used |
| - dnsConfig.nameservers ([]string) | Not used |
| - dnsConfig.options ([]PodDNSConfigOption) | Not used |
| - dnsConfig.options.name (string) | Not used |
| - dnsConfig.options.value (string) | Not used |
| - dnsConfig.searches ([]string) | Not used |
| dnsPolicy (string) | Not used |
| hostNetwork (boolean) | Not used |
| hostPID (boolean) | Not used |
| hostIPC (boolean) | Not used |
| shareProcessNamespace (boolean) | Not used |
| serviceAccountName (string) | Not used |
| automountServiceAccountToken (boolean) | Not used |
| securityContext (PodSecurityContext)  | Not used |

## [Container Properties](https://kubernetes.io/docs/reference/kubernetes-api/workload-resources/pod-v1/#Container)

| PodSpec Containers | Radius Containers |
| -------------------| ----------------- |
| name (string), required | context.resource.containers[].name (string) |
| image (string) | context.resource.containers[].image (string) |
| imagePullPolicy (string) | Not used |
| command ([]string)| context.resource.containers[].command ([]string) |
| args ([]string)| context.resource.containers[].args ([]string) |
| workingDir (string) | context.resource.containers[].workingDir (string) |
| ports ([]ContainerPort) | context.resource.containers[].ports <-- Transformed to an array |
| - ports.name (name) | context.resource.containers[].ports.name |
| - ports.containerPort (int32), required | context.resource.containers[].ports.containerPort (integer) |
| - ports.hostIP (int32) | Not used |
| - ports.hostPort (string) | Not used |
| - ports.protocol (string) | context.resource.containers[].ports.protocol (string) |
| env ([]EnvVar) | |
| - env.name (string), required | context.resource.containers[].env.name (object) <-- Transformed to an array |
| - env.value (string) | context.resource.containers[].env.value (string) |
| - env.valueFrom (EnvVarSource) | context.resource.containers[].env.valueFrom (object) |
|   - env.valueFrom.configMapKeyRef (ConfigMapKeySelector) | Not used |
|     - env.valueFrom.configMapKeyRef.key (string), required | Not used |
|     - env.valueFrom.configMapKeyRef.name (string) | Not used |
|     - env.valueFrom.configMapKeyRef.optional (boolean) | Not used |
|   - env.valueFrom.fieldRef (ObjectFieldSelector) | Not used |
|   - env.valueFrom.fileKeyRef (FileKeySelector) | Not used |
|     - env.valueFrom.fileKeyRef.key (string), required | Not used |
|     - env.valueFrom.fileKeyRef.path (string), required | Not used |
|     - env.valueFrom.fileKeyRef.volumeName (string), required | Not used |
|     - env.valueFrom.fileKeyRef.optional (boolean) | Not used |
|   - env.valueFrom.resourceFieldRef (ResourceFieldSelector) | Not used |
|   - env.valueFrom.secretKeyRef (SecretKeySelector) | TODO: This one is tricky because the Radius Containers has a reference to a Radius Secret resource, not a Kubernetes Secret. The Radius Secret Recipe could store the secret somewhere other than Kubernetes (that's kind of the point). I'm not even sure what should happen here. We need to research how to inject secrets from Hashicorp Vault and Azure Key Vaule. See Containers.containers[].env.valueFrom.secretKeyRef |
|     - env.valueFrom.secretKeyRef.name (string) | See comment above |
|     - env.valueFrom.secretKeyRef.key (string), required | See comment above |
|     - env.valueFrom.secretKeyRef.optional (boolean) | Not used |
| envFrom ([]EnvFromSource) | Not used |
| - envFrom.configMapRef (ConfigMapEnvSource) | Not used |
|   - envFrom.configMapRef.name (string) | Not used |
|   - envFrom.configMapRef.optional (boolean) | Not used |
| - envFrom.prefix (string) | Not used |
| - envFrom.secretRef (SecretEnvSource) | Not used, envFrom.secretRef is similar to env.valueFrom.secretKeyRef but brings all keys, not just one |
|   - envFrom.secretRef.name (string) | Not used |
|   - envFrom.secretRef.optional (boolean) | Not used |
| volumeMounts ([]VolumeMount) | context.resource.containers[].volumeMounts[] |
| - volumeMounts.name (string), required | context.resource.containers[].volumeMounts[].volumeName (string) |
| - volumeMounts.mountPath (string), required | context.resource.containers[].volumeMounts[].mountPath (string) |
| - volumeMounts.mountPropagation (string) | Not used |
| - volumeMounts.readOnly (boolean) | Not used |
| - volumeMounts.recursiveReadOnly (string) | Not used |
| - volumeMounts.subPath (string) | Not used |
| - volumeMounts.subPathExpr (string) | Not used |
| volumeDevices ([]VolumeDevice) | Not used |
| - volumeDevices.devicePath (string), required | Not used |
| - volumeDevices.name (string), required | Not used |
| resources (ResourceRequirements) | |
| - resources.claims ([]ResourceClaim) | Not used |
|   - resources.claims.name (string), required | Not used |
|   - resources.claims.request (string) | Not used |
| - resources.limits (map[string]Quantity) | context.resource.containers[].resources (map[string]integer) |
| - resources.requests (map[string]Quantity) | context.resource.containers[].resources (map[string]integer) |
| resizePolicy ([]ContainerResizePolicy) | Not used |
| - resizePolicy.resourceName (string), required | Not used |
| - resizePolicy.restartPolicy (string), required | Not used |
| lifecycle (Lifecycle) | Not used |
| - lifecycle.postStart (LifecycleHandler) | Not used |
| - lifecycle.preStop (LifecycleHandler) | Not used |
| - lifecycle.stopSignal (string) | Not used |
| terminationMessagePath (string) | Not used |
| terminationMessagePolicy (string) | Not used |
| livenessProbe (Probe) | |
| - exec (ExecAction) | |
| - exec.command ([]string) | context.resource.containers[].livenessProbe.exec.command ([]string) |
| - httpGet (HTTPGetAction) | |
|   - httpGet.port (IntOrString), required | context.resource.containers[].livenessProbe.httpGet.port (integer) |
|   - httpGet.host (string) | Not used |
|   - httpGet.httpHeaders ([]HTTPHeader) | |
|     - httpGet.httpHeaders.name (string), required | context.resource.containers[].livenessProbe.httpGet.httpHeaders.name (string) |
|     - httpGet.httpHeaders.value (string), required | context.resource.containers[].livenessProbe.httpGet.httpHeaders.value (string) |
|   - httpGet.path (string) | context.resource.containers[].livenessProbe.httpGet.path (string) |
|   - httpGet.scheme (string) | context.resource.containers[].livenessProbe.httpGet.scheme (string)|
| - tcpSocket (TCPSocketAction) | |
|   - tcpSocket.port (IntOrString), required | context.resource.containers[].livenessProbe.tcpSocket.port (integer)|
|   - tcpSocket.host (string) | Not used |
| - initialDelaySeconds (int32) | context.resource.containers[].livenessProbe.initialDelaySeconds (integer) |
| - terminationGracePeriodSeconds (int64) | context.resource.containers[].livenessProbe.terminationGracePeriodSeconds (integer) |
| - periodSeconds (int32) | context.resource.containers[].livenessProbe.periodSeconds (integer) |
| - timeoutSeconds (int32) | context.resource.containers[].livenessProbe.timeoutSeconds (integer) |
| - failureThreshold (int32) | context.resource.containers[].livenessProbe.failureThreshold (integer) |
| - successThreshold (int32) | context.resource.containers[].livenessProbe.successThreshold (integer) |
| - grpc (GRPCAction) | Not used |
| readinessProbe (Probe) | |
| - exec (ExecAction) | |
| - exec.command ([]string) | context.resource.containers[].readinessProbe.exec.command ([]string) |
| - httpGet (HTTPGetAction) | |
|   - httpGet.port (IntOrString), required | context.resource.containers[].readinessProbe.httpGet.port (integer) |
|   - httpGet.host (string) | Not used |
|   - httpGet.httpHeaders ([]HTTPHeader) | |
|     - httpGet.httpHeaders.name (string), required | context.resource.containers[].readinessProbe.httpGet.httpHeaders.name (string) |
|     - httpGet.httpHeaders.value (string), required | context.resource.containers[].readinessProbe.httpGet.httpHeaders.value (string) |
|   - httpGet.path (string) | context.resource.containers[].readinessProbe.httpGet.path (string) |
|   - httpGet.scheme (string) | context.resource.containers[].readinessProbe.httpGet.scheme (string)|
| - tcpSocket (TCPSocketAction) | |
|   - tcpSocket.port (IntOrString), required | context.resource.containers[].readinessProbe.tcpSocket.port (integer)|
|   - tcpSocket.host (string) | Not used |
| - initialDelaySeconds (int32) | context.resource.containers[].readinessProbe.initialDelaySeconds (integer) |
| - terminationGracePeriodSeconds (int64) | context.resource.containers[].readinessProbe.terminationGracePeriodSeconds (integer) |
| - periodSeconds (int32) | context.resource.containers[].readinessProbe.periodSeconds (integer) |
| - timeoutSeconds (int32) | context.resource.containers[].readinessProbe.timeoutSeconds (integer) |
| - failureThreshold (int32) | context.resource.containers[].readinessProbe.failureThreshold (integer) |
| - successThreshold (int32) | context.resource.containers[].readinessProbe.successThreshold (integer) |
| - grpc (GRPCAction) | Not used |
| startupProbe (Probe) | Not used |
| restartPolicy (string) | context.resource.containers[].restartPolicy (string) |
| restartPolicyRules ([]ContainerRestartRule) | Not used |
| - restartPolicyRules.action (string), required | Not used |
| - restartPolicyRules.exitCodes (ContainerRestartRuleOnExitCodes) | Not used |
| - restartPolicyRules.exitCodes.operator (string), required | Not used |
| - restartPolicyRules.exitCodes.values ([]int32) | Not used |
| securityContext (SecurityContext) | Not used |
| stdin (boolean) | Not used |
| stdinOnce (boolean) | Not used |
| tty (boolean) | Not used |

## [VolumesSpec Properties](https://kubernetes.io/docs/reference/kubernetes-api/config-and-storage-resources/volume/#Volume)

| VolumesSpec | Radius Containers |
| ------------| ----------------- |
| name (string), required | context.resource.properties.containers[].volumes.name |
| persistentVolumeClaim (PersistentVolumeClaimVolumeSource) | |
| - persistentVolumeClaim.claimName (string), required | This needs to be the PVC name created by the Radius PersistentVolume resource referenced by context.resource.properties.containers[].volumes.persistentVolumes.resourceId |
| - persistentVolumeClaim.readOnly (boolean) | Not used |
| configMap (ConfigMapVolumeSource) | Not used |
| - configMap.name (string) | Not used |
| - configMap.optional (boolean) | Not used |
| - configMap.defaultMode (int32) | Not used |
| - configMap.items ([]KeyToPath) | Not used |
| secret (SecretVolumeSource) | |
| - secret.secretName (string) | See comment above about secrets. The context.resource.properties.containers[].volumes.persistentVolumes.secretId is a reference to a Radius Secret |
| - secret.optional (boolean) | Not used |
| - secret.defaultMode (int32) | Not used |
| - secret.items ([]KeyToPath) | Not used |
| downwardAPI (DownwardAPIVolumeSource) | Not used |
| - downwardAPI.defaultMode (int32) | Not used |
| - downwardAPI.items ([]DownwardAPIVolumeFile) | Not used |
| projected (ProjectedVolumeSource) | Not used |
| - projected.defaultMode (int32) | Not used |
| - projected.sources ([]VolumeProjection) | Not used |
|   - projected.sources.clusterTrustBundle (ClusterTrustBundleProjection) | Not used |
|     - projected.sources.clusterTrustBundle.path (string), required | Not used |
|     - projected.sources.clusterTrustBundle.labelSelector (LabelSelector) | Not used |
|     - projected.sources.clusterTrustBundle.name (string) | Not used |
|     - projected.sources.clusterTrustBundle.optional (boolean) | Not used |
|     - projected.sources.clusterTrustBundle.signerName (string) | Not used |
|   - projected.sources.configMap (ConfigMapProjection) | Not used |
|     - projected.sources.configMap.name (string) | Not used |
|     - projected.sources.configMap.optional (boolean) | Not used |
|     - projected.sources.configMap.items ([]KeyToPath) | Not used |
|   - projected.sources.downwardAPI (DownwardAPIProjection) | Not used |
|     - projected.sources.downwardAPI.items ([]DownwardAPIVolumeFile) | Not used |
|   - projected.sources.podCertificate (PodCertificateProjection) | Not used |
|     - projected.sources.podCertificate.keyType (string), required | Not used |
|     - projected.sources.podCertificate.signerName (string), required | Not used |
|     - projected.sources.podCertificate.certificateChainPath (string) | Not used |
|     - projected.sources.podCertificate.credentialBundlePath (string) | Not used |
|     - projected.sources.podCertificate.keyPath (string) | Not used |
|     - projected.sources.podCertificate.maxExpirationSeconds (int32) | Not used |
|   - projected.sources.secret (SecretProjection) | Not used |
|     - projected.sources.secret.name (string) | Not used |
|     - projected.sources.secret.optional (boolean) | Not used |
|     - projected.sources.secret.items ([]KeyToPath) | Not used |
|   - projected.sources.serviceAccountToken (ServiceAccountTokenProjection) | Not used |
|     - projected.sources.serviceAccountToken.path (string), required | Not used |
|     - projected.sources.serviceAccountToken.audience (string) | Not used |
|     - projected.sources.serviceAccountToken.expirationSeconds (int64) | Not used |
| emptyDir (EmptyDirVolumeSource) | |
| - emptyDir.medium (string) | context.resource.properties.containers[].volumes.emptyDir.medium (string)|
| - emptyDir.sizeLimit (Quantity) | Not used |
| hostPath (HostPathVolumeSource) | Not used |
| - hostPath.path (string), required | Not used |
| - hostPath.type (string) | Not used |
| csi (CSIVolumeSource) | Not used |
| - csi.driver (string), required | Not used |
| - csi.fsType (string) | Not used |
| - csi.nodePublishSecretRef (LocalObjectReference) | Not used |
| - csi.readOnly (boolean) | Not used |
| - csi.volumeAttributes (map[string]string) | Not used |
| ephemeral (EphemeralVolumeSource) | Not used |
| - ephemeral.volumeClaimTemplate (PersistentVolumeClaimTemplate) | Not used |
|   - ephemeral.volumeClaimTemplate.spec (PersistentVolumeClaimSpec), required | Not used |
|   - ephemeral.volumeClaimTemplate.metadata (ObjectMeta) | Not used |
| fc (FCVolumeSource) | Not used |
| - fc.fsType (string) | Not used |
| - fc.lun (int32) | Not used |
| - fc.readOnly (boolean) | Not used |
| - fc.targetWWNs ([]string) | Not used |
| - fc.wwids ([]string) | Not used |
| iscsi (ISCSIVolumeSource) | Not used |
| - iscsi.iqn (string), required | Not used |
| - iscsi.lun (int32), required | Not used |
| - iscsi.targetPortal (string), required | Not used |
| - iscsi.chapAuthDiscovery (boolean) | Not used |
| - iscsi.chapAuthSession (boolean) | Not used |
| - iscsi.fsType (string) | Not used |
| - iscsi.initiatorName (string) | Not used |
| - iscsi.iscsiInterface (string) | Not used |
| - iscsi.portals ([]string) | Not used |
| - iscsi.readOnly (boolean) | Not used |
| - iscsi.secretRef (LocalObjectReference) | Not used |
| image (ImageVolumeSource) | Not used |
| - image.pullPolicy (string) | Not used |
| - image.reference (string) | Not used |
| nfs (NFSVolumeSource) | Not used |
| - nfs.path (string), required | Not used |
| - nfs.server (string), required | Not used |
| - nfs.readOnly (boolean) | Not used |

## [ServiceSpec Properties](https://kubernetes.io/docs/reference/kubernetes-api/service-resources/service-v1/)

Create a Service resource for each container with a containerPort specified. 

| ServiceSpec | Radius Containers |
| ------------| ----------------- |
| selector (map[string]string) | The labels of the Deployment |
| ports ([]ServicePort) | |
| - ports.name (string) | context.resource.containers[].ports.name |
| - ports.port (int32), required | context.resource.containers[].ports.containerPort (integer) |
| - ports.targetPort (IntOrString) | context.resource.containers[].ports.containerPort (integer) |
| - ports.protocol (string) | context.resource.containers[].ports.protocol (string) |
| - ports.nodePort (int32) | Not used |
| - ports.appProtocol (string) | Not used |
| type (string) | 'ClusterIP' |
| ipFamilies ([]string) | Not used |
| ipFamilyPolicy (string) | Not used |
| clusterIP (string) | Not used |
| clusterIPs ([]string) | Not used |
| externalIPs ([]string) | Not used |
| sessionAffinity (string) | Not used |
| loadBalancerIP (string) | Not used |
| loadBalancerSourceRanges ([]string) | Not used |
| loadBalancerClass (string) | Not used |
| externalName (string) | Not used |
| externalTrafficPolicy (string) | Not used |
| internalTrafficPolicy (string) | Not used |
| healthCheckNodePort (int32) | Not used |
| publishNotReadyAddresses (boolean) | Not used |
| sessionAffinityConfig (SessionAffinityConfig) | Not used |
| - sessionAffinityConfig.clientIP (ClientIPConfig) | Not used |
|   - sessionAffinityConfig.clientIP.timeoutSeconds (int32) | Not used |
| allocateLoadBalancerNodePorts (boolean) | Not used |
| trafficDistribution (string) | Not used |

## [HorizontalPodAutoscalerSpec Properties](https://kubernetes.io/docs/reference/kubernetes-api/workload-resources/horizontal-pod-autoscaler-v2/)


| HorizontalPodAutoscalerSpec  | Radius Containers |
| -----------------------------| ----------------- |
| maxReplicas (int32), required | context.resource.autoScaling.maxReplicas (string) |
| scaleTargetRef (CrossVersionObjectReference), required | Not used |
| - scaleTargetRef.kind (string), required | Not used |
| - scaleTargetRef.name (string), required | Not used |
| - scaleTargetRef.apiVersion (string) | Not used |
| minReplicas (int32)
| behavior (HorizontalPodAutoscalerBehavior) | Not used |
| - behavior.scaleDown (HPAScalingRules) | Not used |
|   - behavior.scaleDown.policies ([]HPAScalingPolicy) | Not used |
|   - behavior.scaleDown.policies.type (string), required | Not used |
|   - behavior.scaleDown.policies.value (int32), required | Not used |
|   - behavior.scaleDown.policies.periodSeconds (int32), required | Not used |
|   - behavior.scaleDown.selectPolicy (string) | Not used |
|   - behavior.scaleDown.stabilizationWindowSeconds (int32) | Not used |
|   - behavior.scaleDown.tolerance (Quantity) | Not used |
| - behavior.scaleUp (HPAScalingRules) | Not used |
|   - behavior.scaleUp.policies ([]HPAScalingPolicy) | Not used |
|   - behavior.scaleUp.policies.type (string), required | Not used |
|   - behavior.scaleUp.policies.value (int32), required | Not used |
|   - behavior.scaleUp.policies.periodSeconds (int32), required | Not used |
|   - behavior.scaleUp.selectPolicy (string) | Not used |
|   - behavior.scaleUp.stabilizationWindowSeconds (int32) | Not used |
|   - behavior.scaleUp.tolerance (Quantity) | Not used |
| metrics ([]MetricSpec) | |
| - metrics.type (string), required | 'Resource' if context.resource.autoScaling.metrics[].kind is 'cpu' or 'memory. 'External' if custom. |
| - metrics.containerResource (ContainerResourceMetricSource) | Not Used |
|   - metrics.containerResource.container (string), required | Not Used |
|   - metrics.containerResource.name (string), required | Not Used |
|   - metrics.containerResource.target (MetricTarget), required | Not Used |
|   - metrics.containerResource.target.type (string), required | Not Used |
|   - metrics.containerResource.target.averageUtilization (int32) | Not Used |
|   - metrics.containerResource.target.averageValue (Quantity) | Not Used |
|   - metrics.containerResource.target.value (Quantity) | Not Used |
| - metrics.external (ExternalMetricSource) | |
|   - metrics.external.metric (MetricIdentifier), required | |
|   - metrics.external.metric.name (string), required | context.resource.autoScaling.metrics[].customMetric |
|   - metrics.external.metric.selector (LabelSelector) | Not Used |
|   - metrics.external.target (MetricTarget), required | |
|   - metrics.external.target.type (string), required | 'Utilization', 'Value', or 'AverageValue' based on user input (error if multiple values were specified) |
|   - metrics.external.target.averageUtilization (int32) | context.resource.autoScaling.metrics[].target.averageValue (integer) |
|   - metrics.external.target.averageValue (Quantity) | context.resource.autoScaling.metrics[].target.value (integer) |
|   - metrics.external.target.value (Quantity)
| - metrics.object (ObjectMetricSource) | Not Used |
|   - metrics.object.describedObject (CrossVersionObjectReference), required | Not Used |
|   - metrics.object.describedObject.kind (string), required | Not Used |
|   - metrics.object.describedObject.name (string), required | Not Used |
|   - metrics.object.describedObject.apiVersion (string) | Not Used |
|   - metrics.object.metric (MetricIdentifier), required | Not Used |
|   - metrics.object.metric.name (string), required | Not Used |
|   - metrics.object.metric.selector (LabelSelector) | Not Used |
|   - metrics.object.target (MetricTarget), required | Not Used |
|   - metrics.object.target.type (string), required | Not Used |
|   - metrics.object.target.averageUtilization (int32) | Not Used |
|   - metrics.object.target.averageValue (Quantity) | Not Used |
|   - metrics.object.target.value (Quantity) | Not Used |
| - metrics.pods (PodsMetricSource) | Not Used |
|   - metrics.pods.metric (MetricIdentifier), required | Not Used |
|   - metrics.pods.metric.name (string), required | Not Used |
|   - metrics.pods.metric.selector (LabelSelector) | Not Used |
|   - metrics.pods.target (MetricTarget), required | Not Used |
|   - metrics.pods.target.type (string), required | Not Used |
|   - metrics.pods.target.averageUtilization (int32) | Not Used |
|   - metrics.pods.target.averageValue (Quantity) | Not Used |
|   - metrics.pods.target.value (Quantity) | Not Used |
| - metrics.resource (ResourceMetricSource) | |
|   - metrics.resource.name (string), required | context.resource.autoScaling.metrics[].kind if kind is not 'custom' |
|   - metrics.resource.target (MetricTarget), required | |
|   - metrics.resource.target.type (string), required | 'Utilization', 'Value', or 'AverageValue' based on user input (error if multiple values were specified) |
|   - metrics.resource.target.averageUtilization (int32) | context.resource.autoScaling.metrics[].target.averageUtilization (integer) |
|   - metrics.resource.target.averageValue (Quantity) | context.resource.autoScaling.metrics[].target.averageValue (integer) |
|   - metrics.resource.target.value (Quantity) | context.resource.autoScaling.metrics[].target.value (integer) |
