# Termdo Helm Chart

A Helm chart for deploying the Termdo application on Kubernetes. This chart includes a complete microservices architecture with database, authentication API, tasks API, gateway API, and web frontend.

## Prerequisites

- Kubernetes 1.23.0+
- Helm 3.x
- A Harbor registry for container images

## Architecture

The Termdo application consists of the following components:

- **Database (PostgreSQL)**: Persistent database for storing application data
- **Auth API**: Authentication service handling user authentication and JWT tokens
- **Tasks API**: Service for managing tasks and business logic
- **Gateway API**: API gateway that routes requests to appropriate services
- **Web**: Frontend application serving the user interface

## Installation

### 1. Add Harbor Registry Credentials

Before installing, update the Harbor registry configuration in [`values.yaml`](values.yaml):

```yaml
harbor:
  host: your-harbor-registry.com
  secret:
    name: your-robot-account-name
    token: your-robot-account-token
```

### 2. Configure Application Secrets

Update the application secrets in [`values.yaml`](values.yaml):

```yaml
db:
  secret:
    user: your_db_user
    password: your_secure_db_password
    db: your_database_name

authApi:
  secret:
    jwt: your_jwt_secret_key
```

### 3. Install the Chart

```bash
# Install with default values
helm install termdo .

# Install with custom values file
helm install termdo . -f custom-values.yaml

# Install in a specific namespace
helm install termdo . --namespace termdo --create-namespace
```

## Configuration

### Global Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `harbor.host` | Harbor registry hostname | `harbor.example.com` |
| `harbor.secret.name` | Harbor robot account name | `robot$termdo+robot` |
| `harbor.secret.token` | Harbor robot account token | `your_robot_account_token` |
| `ingress.enabled` | Enable ingress for external access | `false` |

### Database Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `db.image.repository` | Database image repository | `termdo/db` |
| `db.image.tag` | Database image tag | `1.0.0` |
| `db.pvc.storage` | Persistent volume size | `5Gi` |
| `db.secret.user` | Database username | `termdo_user` |
| `db.secret.password` | Database password | `termdo_password` |
| `db.secret.db` | Database name | `termdo_db` |

### Auth API Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `authApi.image.repository` | Auth API image repository | `termdo/auth-api` |
| `authApi.image.tag` | Auth API image tag | `1.0.0` |
| `authApi.replicas` | Number of replicas | `1` |
| `authApi.resources.requests.cpu` | CPU request | `200m` |
| `authApi.resources.requests.memory` | Memory request | `256Mi` |
| `authApi.resources.limits.cpu` | CPU limit | `400m` |
| `authApi.resources.limits.memory` | Memory limit | `512Mi` |
| `authApi.env.appPort` | Application port | `3001` |
| `authApi.secret.jwt` | JWT secret key | `your_auth_api_app_secret` |

### Tasks API Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `tasksApi.image.repository` | Tasks API image repository | `termdo/tasks-api` |
| `tasksApi.image.tag` | Tasks API image tag | `1.0.0` |
| `tasksApi.replicas` | Number of replicas | `1` |
| `tasksApi.resources.requests.cpu` | CPU request | `200m` |
| `tasksApi.resources.requests.memory` | Memory request | `256Mi` |
| `tasksApi.resources.limits.cpu` | CPU limit | `400m` |
| `tasksApi.resources.limits.memory` | Memory limit | `512Mi` |
| `tasksApi.env.appPort` | Application port | `3002` |

### Gateway API Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `gatewayApi.image.repository` | Gateway API image repository | `termdo/gateway-api` |
| `gatewayApi.image.tag` | Gateway API image tag | `1.0.0` |
| `gatewayApi.replicas` | Number of replicas | `1` |
| `gatewayApi.resources.requests.cpu` | CPU request | `100m` |
| `gatewayApi.resources.requests.memory` | Memory request | `128Mi` |
| `gatewayApi.resources.limits.cpu` | CPU limit | `200m` |
| `gatewayApi.resources.limits.memory` | Memory limit | `256Mi` |
| `gatewayApi.service.nodePort` | NodePort for external access | `30003` |
| `gatewayApi.env.appPort` | Application port | `3000` |

### Web Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `web.image.repository` | Web image repository | `termdo/web` |
| `web.image.tag` | Web image tag | `1.0.0` |
| `web.replicas` | Number of replicas | `1` |
| `web.resources.requests.cpu` | CPU request | `50m` |
| `web.resources.requests.memory` | Memory request | `64Mi` |
| `web.resources.limits.cpu` | CPU limit | `200m` |
| `web.resources.limits.memory` | Memory limit | `256Mi` |
| `web.service.nodePort` | NodePort for external access | `30008` |
| `web.env.appPort` | Application port | `80` |

## Auto-scaling

All application components support Horizontal Pod Autoscaler (HPA). To enable auto-scaling:

```yaml
authApi:
  hpa:
    enabled: true
    minReplicas: 2
    maxReplicas: 10
    targetCpuUtilization: 70

tasksApi:
  hpa:
    enabled: true
    minReplicas: 2
    maxReplicas: 10
    targetCpuUtilization: 70

gatewayApi:
  hpa:
    enabled: true
    minReplicas: 2
    maxReplicas: 10
    targetCpuUtilization: 70

web:
  hpa:
    enabled: true
    minReplicas: 2
    maxReplicas: 10
    targetCpuUtilization: 70
```

## Services and Networking

### Internal Services

- **Database**: ClusterIP service on port 5432
- **Auth API**: ClusterIP service on port 3001
- **Tasks API**: ClusterIP service on port 3002

### External Services

- **Gateway API**: NodePort service on port 30003
- **Web**: NodePort service on port 30008

### Service Dependencies

```
Web (80) => Gateway API (3000) => Auth API (3001)  => Database (5432)
                               => Tasks API (3002) =>
```

## Storage

The database uses a PersistentVolumeClaim for data persistence:

- **PVC Name**: `db-pvc`
- **Access Mode**: `ReadWriteOnce`
- **Default Size**: `5Gi`
- **Mount Path**: `/var/lib/postgresql/data`

## Secrets Management

The chart creates and manages the following secrets:

1. **Harbor Secret** ([`templates/harbor.secret.yaml`](templates/harbor.secret.yaml)): Docker registry authentication
2. **Database Secret** ([`templates/db.secret.yaml`](templates/db.secret.yaml)): PostgreSQL credentials
3. **Auth API Secret** ([`templates/auth-api.secret.yaml`](templates/auth-api.secret.yaml)): JWT signing key

## Upgrading

To upgrade the chart:

```bash
# Upgrade with new values
helm upgrade termdo . -f updated-values.yaml

# Upgrade to a specific chart version
helm upgrade termdo . --version 1.1.0
```

## Uninstalling

To uninstall the chart:

```bash
helm uninstall termdo
```

**Note**: This will not delete the PersistentVolumeClaim. To delete it manually:

```bash
kubectl delete pvc db-pvc
```

## Troubleshooting

### Common Issues

1. **ImagePullBackOff**: Verify Harbor registry credentials in [`values.yaml`](values.yaml)
2. **Database Connection Issues**: Check database service and secret configuration
3. **Pod CrashLoopBackOff**: Review application logs and resource limits

### Viewing Logs

```bash
# View logs for specific components
kubectl logs deployment/auth-api-deployment
kubectl logs deployment/tasks-api-deployment
kubectl logs deployment/gateway-api-deployment
kubectl logs deployment/web-deployment
kubectl logs deployment/db-deployment
```

### Checking Resources

```bash
# Check all resources
kubectl get all -l app.kubernetes.io/instance=termdo

# Check persistent volumes
kubectl get pvc

# Check secrets
kubectl get secrets
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test with `helm lint` and `helm template`
5. Submit a pull request

## License

This project is licensed under the MIT License - see the [LICENSE.md](LICENSE.md) file for details.

## Support

For support, please contact [developer@karacayir.com](mailto:developer@karacayir.com) or create an issue in the repository.
