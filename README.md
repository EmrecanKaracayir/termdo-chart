# Termdo Helm Chart

This chart deploys the Termdo application suite—database, backend services, and web frontend—onto a Kubernetes cluster. It packages opinionated defaults for container images hosted in Harbor, horizontal pod autoscaling toggles, and NodePort exposure for public-facing services.

## Features

- Creates a Harbor-backed image pull secret shared by all workloads.
- Provisions a PostgreSQL-compatible database with persistent storage.
- Deploys the Auth, Tasks, and Gateway APIs with consistent resource profiles and optional HPAs.
- Serves the Termdo web client and exposes both the web UI and gateway via NodePort.
- Wires service-to-service environment variables so the components work together out of the box.

## Component Overview

| Component   | Description                                                                                                      |
| ----------- | ---------------------------------------------------------------------------------------------------------------- |
| `db`        | Stateful database Deployment with PVC-backed storage and a `ClusterIP` + NodePort service.                       |
| `auth-api`  | Manages authentication; pulls DB credentials from `db-secret` and optional JWT secret from `auth-api-secret`.    |
| `tasks-api` | Provides task-related APIs; reuses DB credentials and mirrors auth-api resource settings.                        |
| `gateway`   | BFF layer that fronts the APIs; exposes a NodePort and forwards to Auth & Tasks services.                        |
| `web`       | Static web frontend; talks to the gateway service; exposed via NodePort.                                         |

## Prerequisites

- Kubernetes cluster v1.23 or later.
- Helm 3.9+ (Helm 3 is required; no server-side `tiller` components).
- Pull credentials for the Harbor registry containing Termdo images.
- Cluster access that permits NodePort services (or plan to adjust service manifests).

## Quick Start

1. Copy the default values for customization:
   ```bash
   cp values.yaml my-values.yaml
   ```
2. Set the Harbor host/credentials and point each image to the desired tags in `my-values.yaml`.
3. Install the release (namespaced install is recommended):
   ```bash
   helm install termdo . -f my-values.yaml --namespace termdo --create-namespace
   ```
4. Validate the rendered manifests before installation if desired:
   ```bash
   helm lint .
   helm template termdo . -f my-values.yaml
   ```

## Configuration

### Global & Registry

| Key                    | Description                                                                                   | Default                 |
| ---------------------- | --------------------------------------------------------------------------------------------- | ----------------------- |
| `ingress.enabled`      | When `true`, the gateway sets cookies as secure; no ingress resource is created automatically. | `false`                 |
| `harbor.host`          | Harbor registry hostname used to build the `harbor-secret`.                                  | `your_harbor_registry_host` |
| `harbor.secret.name`   | Harbor robot account username.                                                                | `your_harbor_robot_account_name` |
| `harbor.secret.token`  | Harbor robot account token (stored base64-encoded in the secret).                             | `your_harbor_robot_account_token` |

### Database (`db`)

| Key                       | Description                                                     | Default                  |
| ------------------------- | --------------------------------------------------------------- | ------------------------ |
| `db.image.name`           | Database image repository (PostgreSQL-compatible).             | `your_database_image_name` |
| `db.image.tag`            | Image tag.                                                     | `your_database_image_tag` |
| `db.pvc.storage`          | PersistentVolumeClaim request size.                           | `2Gi`                    |
| `db.service.nodePort`     | NodePort exposing Postgres externally; adjust to fit cluster.  | `30001`                  |
| `db.secret.user`          | Database username (stored in `db-secret`).                     | `your_database_user`     |
| `db.secret.password`      | Database password.                                             | `your_database_password` |
| `db.secret.db`            | Default database name.                                         | `your_database_name`     |

### Auth API (`authApi`)

| Key                                 | Description                                                                | Default                          |
| ----------------------------------- | -------------------------------------------------------------------------- | -------------------------------- |
| `authApi.image.name` / `tag`        | Container image reference.                                                | `your_auth_api_image_*`          |
| `authApi.resources.requests/limits` | CPU & memory reservations.                                                | `200m/256Mi` requests, `400m/512Mi` limits |
| `authApi.replicas`                  | Replica count when HPA is disabled.                                       | `1`                              |
| `authApi.hpa.enabled`               | Enable HorizontalPodAutoscaler; disables static `replicas` when true.     | `false`                          |
| `authApi.hpa.minReplicas`           | Minimum pods when HPA enabled.                                            | `1`                              |
| `authApi.hpa.maxReplicas`           | Maximum pods when HPA enabled.                                            | `10`                             |
| `authApi.hpa.targetCpuUtilization`  | Target CPU utilization percentage.                                        | `80`                             |
| `authApi.env.appPort`               | Container port & service port.                                            | `3001`                           |
| `authApi.secret.jwt`                | JWT/APP secret, base64-encoded into `auth-api-secret`.                    | `your_auth_api_app_secret`       |

### Tasks API (`tasksApi`)

Mirrors Auth API settings with its own image and port:

| Key                                | Description                                           | Default                          |
| ---------------------------------- | ----------------------------------------------------- | -------------------------------- |
| `tasksApi.image.name` / `tag`      | Container image reference.                            | `your_tasks_api_image_*`         |
| `tasksApi.resources.*`            | CPU/memory requests & limits.                         | `200m/256Mi`, `400m/512Mi`       |
| `tasksApi.replicas`               | Static replicas when HPA disabled.                    | `1`                              |
| `tasksApi.hpa.*`                  | HPA toggle and scaling parameters.                    | Disabled / `1-10` / `80`         |
| `tasksApi.env.appPort`            | Container and service port.                           | `3002`                           |

### Gateway API (`gatewayApi`)

| Key                                   | Description                                                         | Default                          |
| ------------------------------------- | ------------------------------------------------------------------- | -------------------------------- |
| `gatewayApi.image.name` / `tag`       | Gateway container image.                                            | `your_gateway_api_image_*`       |
| `gatewayApi.resources.*`              | Resource requests/limits.                                           | `100m/128Mi`, `200m/256Mi`       |
| `gatewayApi.replicas`                 | Replica count when HPA disabled.                                    | `1`                              |
| `gatewayApi.hpa.*`                    | HPA toggle & parameters.                                            | Disabled / `1-10` / `80`         |
| `gatewayApi.env.appPort`              | Gateway container/service port.                                     | `3000`                           |
| `gatewayApi.service.nodePort`         | NodePort exposed outside the cluster; adjust to avoid conflicts.    | `30003`                          |

The gateway Deployment also consumes:
- `AUTH_API_*` env vars pointing to the Auth API service.
- `TASKS_API_*` env vars pointing to the Tasks API service.
- `COOKIE_IS_SECURE` mirroring `ingress.enabled`.

### Web Frontend (`web`)

| Key                               | Description                                              | Default                     |
| --------------------------------- | -------------------------------------------------------- | --------------------------- |
| `web.image.name` / `tag`          | Static site/container image.                             | `your_web_image_*`          |
| `web.resources.*`                 | CPU/memory requests and limits.                          | `50m/64Mi`, `200m/256Mi`    |
| `web.replicas`                    | Static replica count when HPA disabled.                  | `1`                         |
| `web.hpa.*`                       | HorizontalPodAutoscaler configuration.                   | Disabled / `1-10` / `80`    |
| `web.env.appPort`                 | Container/service port.                                  | `80`                        |
| `web.service.nodePort`            | NodePort exposed externally.                             | `30008`                     |

## Secrets & Persistence

- `harbor-secret` (Docker config JSON) is rendered from `harbor.*` values and used by all Deployments via `imagePullSecrets`.
- `db-secret` stores database credentials; referenced by DB, Auth API, and Tasks API Deployments.
- `auth-api-secret` stores the JWT/APP secret.
- The database PVC (`db-pvc`) requests the `db.pvc.storage` capacity with `ReadWriteOnce`.

## Operations

- Upgrade:
  ```bash
  helm upgrade termdo . -f my-values.yaml --namespace termdo
  ```
- Uninstall:
  ```bash
  helm uninstall termdo --namespace termdo
  ```
  Consider manually deleting the PVC if you need to drop persisted data.

## Development Tips

- Run `helm lint .` to validate chart structure.
- Render manifests locally with `helm template termdo . -f my-values.yaml` before applying.
- Adjust NodePort services to `LoadBalancer` or `ClusterIP` if your environment does not permit NodePorts; this currently requires editing the templates.

## License

Released under the [MIT License](LICENSE.md).
