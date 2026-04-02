# Dawet Demo Env

> GitOps demo environment for deploying the **Dawet** platform via **Rancher Fleet**.  
> **Target:** Single dev cluster with Infrastructure, Observability, and AI/Workflow layers.
> **Optimization:** Minimal resource usage (suitable for local M-series/WSL development) and Local Storage.

## 📁 Repository Structure

We split the deployments into three `GitRepo` targets to prevent Kubernetes etcd object-size limits during Fleet discovery.

```
dawet-demo-env/
├── infrastructure/                 # [GitRepo: dawet-demo-infra]
│   ├── namespaces/                 # Namespace definitions
│   ├── postgres-cluster/           # PostgreSQL (Unified)
│   └── redis/                      # Cache
├── observability/                  # [GitRepo: dawet-demo-obs]
│   ├── kube-prometheus-stack/      # Metrics + Grafana (with default K8s dashboards)
│   ├── mimir/                      # Metrics backend (Bitnami lightweight version)
│   ├── loki/                       # Logs backend
│   ├── tempo/                      # Traces (Filesystem storage)
│   ├── alloy/                      # OpenTelemetry Collector
│   └── uptime-kuma/                # Uptime Monitoring UI (Embedded SQLite)
├── api-gateway/                    # [GitRepo: dawet-demo-env]
│   └── gravitee/                   # API Management (Bundled Deps)
├── ai-workflow/                    # [GitRepo: dawet-demo-ai]
│   ├── dify/                       # RAG & LLM Ops (Minimal)
│   ├── weaviate/                   # Vector DB
│   └── n8n/                        # Workflow Automation
├── sample-apps/
│   ├── deepseek-config/            # ConfigMaps for LLM API keys
│   └── otel-demo/                  # Generates Traces/Metrics/Logs
└── scripts/
    ├── pre-commit.sh
    └── lint.sh
```

## 🏗️ Deployment Order (Sequential)

```
 1. namespaces              # Create all namespaces
 2. postgres-cluster        # PostgreSQL databases
 3. redis                   # Cache & message queue
 4. weaviate                # Vector DB (Lightweight)
 5. n8n                     # Workflow automation
 6. dify                    # RAG & LLM Ops platform
 7. kube-prometheus-stack   # Metrics + Grafana (default K8s dashboards bundled)
 8. mimir                   # Metrics backend
 9. loki                    # Logs backend (7-day retention)
10. tempo                   # Traces backend (7-day retention)
11. alloy                   # OTel collector — scrapes, PII-masks, remote_writes
12. uptime-kuma             # Service health monitoring
13. gravitee                 # API Gateway + Management UI
14. deepseek-config         # Deepseek tokens configmap
15. otel-demo               # Sample app
```

Each step waits for the previous one to become **Active** before starting.

## 🚀 Deploy

Register in Rancher Fleet by applying the three GitRepo manifests:

```bash
# Example
kubectl apply -f dawet-demo-infra.yaml
kubectl apply -f dawet-demo-obs.yaml
kubectl apply -f dawet-demo-ai.yaml
```

### Cluster Labeling (Critical)

For this single cluster demo to target your cluster, you must add the `env: dev` label:

1.  Go to **Continuous Delivery > Clusters** in Rancher.
2.  Find your cluster.
3.  Click **Edit Config** and add a label: `env=dev`.

Alternatively, use this command:
```bash
kubectl label cluster.fleet.cattle.io local env=dev -n fleet-default
```

## 📦 Components

| Component | Chart | Namespace | Mode |
|-----------|-------|-----------|------|
| **Storage Class** | built-in | `kube-system` | **local-path** |
| PostgreSQL | `bitnami/postgresql` | `postgres-system` | Single instance (Unified) |
| Redis | `bitnami/redis` | `redis-system` | Standalone |
| Prometheus & Grafana | `kube-prometheus-stack` | `observability` | Bundled, generic dashboards |
| Mimir | `bitnami/mimir` | `observability` | Lightweight metrics storage |
| Loki | `grafana/loki` | `observability` | SingleBinary, 7d retention |
| Tempo | `grafana/tempo` | `observability` | Local Filesystem, 7d retention |
| Alloy | `grafana/alloy` | `observability` | DaemonSet, PII masking, remote_write |
| Uptime Kuma | `uptime-kuma` | `observability` | Health checking, embedded SQLite |
| Dify | `langgenius/dify` | `ai-workflow` | Minimal (Local Storage) |
| Weaviate | `weaviate/weaviate` | `ai-workflow` | Standalone |
| n8n | `n8nio/n8n` | `ai-workflow` | Single replica |
| **Gravitee APIM** | `gravitee/apim3` | `api-gateway` | NodePort-only, Bundled Deps |

## 🔑 Demo Credentials

| Service | User/Key | Password |
|---------|----------|----------|
| Grafana | `admin` | `admin-demo-123` |
| PostgreSQL (Unified) | `admin` | `admin-db-123` |
| Redis | - | `redis-demo-123` |
| Gravitee APIM | `admin` | `admin` |
| MySQL (Gravitee) | `gravitee` | `gravitee_password` |
| Dify Bootstrap | - | `rancher-demo` |

> ⚠️ **Demo credentials only** — not for production use.

## 🌐 NodePort Access

| Service | Port | NodePort | URL |
|---------|------|----------|-----|
| Grafana | 3000 | **30300** | `http://<NODE_IP>:30300` |
| Uptime Kuma | 3001 | **30400** | `http://<NODE_IP>:30400` |
| Dify API | 5001 | **30500** | `http://<NODE_IP>:30500` |
| Dify Web | 3000 | **30501** | `http://<NODE_IP>:30501` |
| n8n | 5678 | **30520** | `http://<NODE_IP>:30520` |
| Gravitee UI | 8080 | **30802** | `http://<NODE_IP>:30802` |
| Gravitee Portal | 8080 | **30803** | `http://<NODE_IP>:30803` |
| Gravitee API | 8083 | **30883** | `http://<NODE_IP>:30883` |
| Gravitee Gateway | 8082 | **30882** | `http://<NODE_IP>:30882` |
| OTel Demo | 8080 | **30800** | `http://<NODE_IP>:30800` |

## ✅ Validate

```bash
./scripts/lint.sh
```
