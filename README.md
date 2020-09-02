# Fork Info

This is a fork of https://github.com/kubernetes-csi/node-driver-registrar.git to simplify building multi-arch images.

[![Build Status](https://travis-ci.org/kubernetes-csi/node-driver-registrar.svg?branch=master)](https://travis-ci.org/kubernetes-csi/node-driver-registrar)

# Node Driver Registrar

The node-driver-registrar is a sidecar container that registers the CSI driver
with Kubelet using the
[kubelet plugin registration mechanism](https://kubernetes.io/docs/concepts/extend-kubernetes/compute-storage-net/device-plugins/#device-plugin-registration).

This is necessary because Kubelet is responsible for issuing CSI `NodeGetInfo`,
`NodeStageVolume`, `NodePublishVolume` calls. The `node-driver-registrar` registers
your CSI driver with Kubelet so that it knows which Unix domain socket to issue
the CSI calls on.

## Compatibility

This information reflects the head of this branch.

| Compatible with CSI Version                                                                | Container Image                                         | [Min K8s Version](https://kubernetes-csi.github.io/docs/kubernetes-compatibility.html#minimum-version) |
| ------------------------------------------------------------------------------------------ | ------------------------------------------------------- | --------------- |
| [CSI Spec v1.3.0](https://github.com/container-storage-interface/spec/releases/tag/v1.3.0) | k8s.gcr.io/sig-storage/csi-node-driver-registrar        | 1.13            |

For release-0.4 and below, please refer to the [driver-registrar
repository](https://github.com/kubernetes-csi/driver-registrar).

## Usage

There are two UNIX domain sockets used by the node-driver-registrar:

* Registration socket:
  * Registers the driver with kubelet.
  * Created by the `node-driver-registrar`.
  * Exposed on a Kubernetes node via hostpath in the Kubelet plugin registry.
    (typically `/var/lib/kubelet/plugins_registry/<drivername.example.com>-reg.sock`).
    The hostpath volume must be mounted at `/registration`.

* CSI driver socket:
  * Used by kubelet to interact with the CSI driver.
  * Created by the CSI driver.
  * Exposed on a Kubernetes node via hostpath somewhere other than the Kubelet plugin registry. (typically `/var/lib/kubelet/plugins/<drivername.example.com>/csi.sock`).
  * This is the socket referenced by the `--csi-address` and `--kubelet-registration-path` arguments.
  * Note that before Kubernetes v1.17, if the csi socket is in the `/var/lib/kubelet/plugins/` path, kubelet may log a lot of harmless errors regarding grpc `GetInfo` call not implemented (fix in kubernetes/kubernetes#84533). The `/var/lib/kubelet/csi-plugins/` path is preferred in Kubernetes versions prior to v1.17.

### Required arguments

* `--csi-address`: This is the path to the CSI driver socket (defined above) inside the
  pod that the `node-driver-registrar` container will use to issue CSI
  operations (e.g. `/csi/csi.sock`).
* `--kubelet-registration-path`: This is the path to the CSI driver socket on
  the host node that kubelet will use to issue CSI operations (e.g.
  `/var/lib/kubelet/plugins/<drivername.example.com>/csi.sock). Note this is NOT
  the path to the registration socket.

### Optional arguments

* `--health-port`: This is the port of the health check server for the node-driver-registrar,
  which checks if the registration socket exists. A value <= 0 disables the server.
  Server is disabled by default.

### Required permissions

The node-driver-registrar does not interact with the Kubernetes API, so no RBAC
rules are needed.

It does, however, need to be able to mount hostPath volumes and have the file
permissions to:

* Access the CSI driver socket (typically in `/var/lib/kubelet/plugins/<drivername.example.com>/`).
  * Used by the `node-driver-registrar` to fetch the driver name from the driver
    contain (via the CSI `GetPluginInfo()` call).
* Access the registration socket (typically in `/var/lib/kubelet/plugins_registry/`).
  * Used by the `node-driver-registrar` to register the driver with kubelet.

### Example

Here is an example sidecar spec in the driver DaemonSet. `<drivername.example.com>` should be replaced by
the actual driver's name.

```bash
      containers:
        - name: csi-driver-registrar
          image: k8s.gcr.io/sig-storage/csi-node-driver-registrar:v1.3.0
          args:
            - "--csi-address=/csi/csi.sock"
            - "--kubelet-registration-path=/var/lib/kubelet/plugins/<drivername.example.com>/csi.sock"
            - "--health-port=9809"
          volumeMounts:
            - name: plugin-dir
              mountPath: /csi
            - name: registration-dir
              mountPath: /registration
          ports:
            - containerPort: 9809
              name: healthz
          livenessProbe:
            httpGet:
              path: /healthz
              port: healthz
            initialDelaySeconds: 5
            timeoutSeconds: 5
      volumes:
        - name: registration-dir
          hostPath:
            path: /var/lib/kubelet/plugins_registry/
            type: Directory
        - name: plugin-dir
          hostPath:
            path: /var/lib/kubelet/plugins/<drivername.example.com>/
            type: DirectoryOrCreate
```

## Community, discussion, contribution, and support

Learn how to engage with the Kubernetes community on the [community page](http://kubernetes.io/community/).

You can reach the maintainers of this project at:

* Slack channels
  * [#wg-csi](https://kubernetes.slack.com/messages/wg-csi)
  * [#sig-storage](https://kubernetes.slack.com/messages/sig-storage)
* [Mailing list](https://groups.google.com/forum/#!forum/kubernetes-sig-storage)

### Code of conduct

Participation in the Kubernetes community is governed by the [Kubernetes Code of Conduct](code-of-conduct.md).
