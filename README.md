# Dawet Demo Env

> GitOps demo environment for deploying the **Dawet** platform via **Rancher Fleet**.  
> Single dev cluster with Infrastructure, Observability (LGTM), and AI/Workflow layers.

## 📁 Repository Structure

```
dawet-demo-env/
├── fleet.yaml                      # Root aggregation config
├── clusters/
│   └── dev/cluster.yaml            # Dev cluster definition
├── infrastructure/
│   ├── local-path-provisioner/     # StorageClass
│   ├── minio/                      # Object Storage (S3-compatible)
│   │   └── overlays/dev-values.yaml
│   ├── postgres-cluster/           # PostgreSQL (Grafana, Milvus, n8n)
│   └── redis/                      # Cache & Message Queue
├── observability/
│   ├── grafana/                    # Dashboards & Alerting
│   ├── mimir/                      # Metrics (Prometheus-compatible)
│   ├── loki/                       # Logs
│   ├── tempo/                      # Traces
│   └── alloy/                      # OpenTelemetry Collector (DaemonSet)
├── ai-workflow/
│   ├── dify/                       # RAG & LLM Ops
│   ├── milvus/                     # Vector DB
│   └── n8n/                        # Workflow Automation
├── sample-apps/
│   └── otel-demo/                  # Generates Traces/Metrics/Logs
├── policies/
│   ├── network-policies/           # Network segmentation
│   ├── resource-quotas/            # Per-namespace resource limits
│   └── pod-security-standards/     # PSS enforcement
└── scripts/
    ├── pre-commit.sh
    ├── lint.sh
    └── validate-deps.sh
```

## 🏗️ Deployment Order

```
1. local-path-provisioner
    ├── 2. minio
    ├── 3. postgres-cluster
    └── 4. redis
            │
            ├── 5. mimir / loki / tempo
            ├── 6. dify / milvus / n8n
            │
            └── 7. alloy → 8. grafana → 9. otel-demo
```

## 🚀 Deploy

Register in Rancher Fleet:

```yaml
apiVersion: fleet.cattle.io/v1alpha1
kind: GitRepo
metadata:
  name: dawet-demo-env
  namespace: fleet-default
spec:
  repo: https://github.com/ihsbramn/dawet-demo-env.git
  branch: main
  paths:
    - infrastructure/
    - observability/
    - ai-workflow/
    - sample-apps/
    - policies/
  targets:
    - clusterSelector:
        matchLabels:
          env: dev
```

## 📦 Components

| Component | Chart | Namespace | Mode |
|-----------|-------|-----------|------|
| Local Path Provisioner | `containeroo/local-path-provisioner` | `local-path-storage` | Default StorageClass |
| MinIO | `minio/minio` | `minio-system` | Standalone |
| PostgreSQL (x3) | `bitnami/postgresql` | `postgres-system` | Single instances |
| Redis | `bitnami/redis` | `redis-system` | Standalone |
| Grafana | `grafana/grafana` | `observability` | Single replica |
| Mimir | `grafana/mimir-distributed` | `observability` | Single replicas |
| Loki | `grafana/loki` | `observability` | SingleBinary |
| Tempo | `grafana/tempo-distributed` | `observability` | Single replicas |
| Alloy | `grafana/alloy` | `observability` | DaemonSet |
| Dify | `difyai/dify` | `ai-workflow` | Single replica |
| Milvus | `zilliztech/milvus` | `ai-workflow` | Standalone |
| n8n | `8gears/n8n` | `ai-workflow` | Single replica |
| OTel Demo | `otel/opentelemetry-demo` | `sample-apps` | Demo app |

## 🔑 Demo Credentials

| Service | User/Key | Password |
|---------|----------|----------|
| MinIO | `minio-admin` | `minio-secret-123` |
| Grafana | `admin` | `admin-demo-123` |
| PostgreSQL (Grafana) | `grafana` | `grafana-db-123` |
| PostgreSQL (Milvus) | `milvus` | `milvus-db-123` |
| PostgreSQL (n8n) | `n8n` | `n8n-db-123` |
| Redis | - | `redis-demo-123` |

> ⚠️ **Demo credentials only** — not for production use.

## 🌐 NodePort Access

| Service | Port | NodePort | URL |
|---------|------|----------|-----|
| Grafana | 3000 | **30300** | `http://<NODE_IP>:30300` |
| Dify API | 5001 | **30500** | `http://<NODE_IP>:30500` |
| Dify Web | 3000 | **30501** | `http://<NODE_IP>:30501` |
| n8n | 5678 | **30520** | `http://<NODE_IP>:30520` |
| MinIO API | 9000 | **30900** | `http://<NODE_IP>:30900` |
| MinIO Console | 9001 | **30901** | `http://<NODE_IP>:30901` |
| OTel Demo | 8080 | **30800** | `http://<NODE_IP>:30800` |

## ✅ Validate

```bash
./scripts/lint.sh
./scripts/validate-deps.sh
```
