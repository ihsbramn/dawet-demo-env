# Dawet Demo Env

> GitOps demo environment for deploying the **Dawet** platform via **Rancher Fleet**.  
> **Target:** Single dev cluster with Infrastructure, Observability, and AI/Workflow layers.
> **Optimization:** Minimal resource usage (suitable for local/WSL development) and Local Storage.

## 📁 Repository Structure

```
dawet-demo-env/
├── fleet-gitrepo.yaml              # Fleet GitRepo manifest
├── infrastructure/
│   ├── namespaces/                 # Namespace definitions
│   ├── postgres-cluster/           # PostgreSQL (Unified)
│   └── redis/                      # Cache
├── observability/
│   ├── grafana/                    # Dashboards & Alerting
│   ├── prometheus/                 # Metrics Backend (Replaced Mimir)
│   ├── loki/                       # Logs
│   ├── tempo/                      # Traces (Filesystem storage)
│   └── alloy/                      # OpenTelemetry Collector
├── ai-workflow/
│   ├── dify/                       # RAG & LLM Ops (Minimal)
│   ├── weaviate/                   # Vector DB (Replaced Milvus)
│   └── n8n/                        # Workflow Automation
├── sample-apps/
│   └── otel-demo/                  # Generates Traces/Metrics/Logs
└── scripts/
    ├── pre-commit.sh
    └── lint.sh
```

## 🏗️ Deployment Order (Sequential)

```
 1. namespaces           # Create all namespaces
 2. postgres-cluster     # PostgreSQL databases
 3. redis                # Cache & message queue
 4. weaviate             # Vector DB (Lightweight)
 5. n8n                  # Workflow automation
 6. dify                 # RAG & LLM Ops platform
 7. prometheus           # Metrics backend
 8. loki                 # Logs backend
 9. tempo                # Traces backend
10. alloy                # OTel collector (DaemonSet)
11. grafana              # Dashboards
12. otel-demo            # Sample app
```

Each step waits for the previous one to become **Active** before starting.

## 🚀 Deploy

Register in Rancher Fleet by applying the manifest:

```bash
kubectl apply -f fleet-gitrepo.yaml
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
| **Storage Class** | built-in | kube-system | **hostpath** |
| PostgreSQL | `bitnami/postgresql` | `postgres-system` | Single instance (Unified) |
| Redis | `bitnami/redis` | `redis-system` | Standalone |
| Grafana | `grafana/grafana` | `observability` | Single replica |
| Prometheus | `prometheus-community/prometheus` | `observability` | Lightweight |
| Loki | `grafana/loki` | `observability` | SingleBinary |
| Tempo | `grafana/tempo` | `observability` | Local Filesystem |
| Alloy | `grafana/alloy` | `observability` | DaemonSet |
| Dify | `langgenius/dify` | `ai-workflow` | Minimal (Local Storage) |
| Weaviate | `weaviate/weaviate` | `ai-workflow` | Standalone |
| n8n | `n8nio/n8n` | `ai-workflow` | Single replica |

## 🔑 Demo Credentials

| Service | User/Key | Password |
|---------|----------|----------|
| Grafana | `admin` | `admin-demo-123` |
| PostgreSQL (Unified) | `admin` | `admin-db-123` |
| Redis | - | `redis-demo-123` |
| Dify Bootstrap | - | `rancher-demo` |

> ⚠️ **Demo credentials only** — not for production use.

## 🌐 NodePort Access

| Service | Port | NodePort | URL |
|---------|------|----------|-----|
| Grafana | 3000 | **30300** | `http://<NODE_IP>:30300` |
| Dify API | 5001 | **30500** | `http://<NODE_IP>:30500` |
| Dify Web | 3000 | **30501** | `http://<NODE_IP>:30501` |
| n8n | 5678 | **30520** | `http://<NODE_IP>:30520` |
| OTel Demo | 8080 | **30800** | `http://<NODE_IP>:30800` |

## ✅ Validate

```bash
./scripts/lint.sh
```
