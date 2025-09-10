# Prometheus Deployment - Smart City Infrastructure

Este diretório contém os arquivos necessários para fazer o deployment do Prometheus no ambiente de desenvolvimento usando Helm e Minikube.

## 📁 Conteúdo do Diretório

```
prometheus-deploy/
├── README.md                      # Este arquivo
├── deploy-prometheus.sh          # Script de deployment
└── prometheus-values-minikube.yaml # Valores específicos para Minikube
```

## 🚀 Deployment

### Método 1: Usando o Script Automático

```bash
# Tornar o script executável (se necessário)
chmod +x deploy-prometheus.sh

# Executar o deployment
./deploy-prometheus.sh
```

### Método 2: Deployment Manual

```bash
# Adicionar repositório Helm do Prometheus
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# Instalar Prometheus
helm install prometheus prometheus-community/prometheus \
  -f prometheus-values-minikube.yaml \
  -n infrastructure \
  --create-namespace
```

## ⚙️ Configuração

### Valores Personalizados (prometheus-values-minikube.yaml)

```yaml
# Configurações específicas para Minikube
server:
  service:
    type: ClusterIP  # Compatível com Minikube

  persistentVolume:
    enabled: true
    size: 8Gi

  resources:
    requests:
      memory: 256Mi
      cpu: 250m
    limits:
      memory: 512Mi
      cpu: 500m

# Configuração do Alertmanager
alertmanager:
  enabled: false  # Desabilitado para desenvolvimento

# Configuração do Pushgateway
pushgateway:
  enabled: false  # Desabilitado para desenvolvimento

# Configuração do Node Exporter
nodeExporter:
  enabled: false  # Desabilitado para Minikube

# Configuração do Kube State Metrics
kubeStateMetrics:
  enabled: false  # Desabilitado para desenvolvimento

# Regras de alerta básicas
serverFiles:
  alerting_rules.yml:
    groups:
      - name: smartcity
        rules:
          - alert: PostgreSQLDown
            expr: up{job="postgres"} == 0
            for: 5m
            labels:
              severity: critical
            annotations:
              summary: "PostgreSQL is down"
              description: "PostgreSQL has been down for more than 5 minutes."
```

## 🔍 Verificação do Deployment

```bash
# Verificar se os pods estão rodando
kubectl get pods -n infrastructure

# Verificar os serviços
kubectl get svc -n infrastructure

# Verificar PVC
kubectl get pvc -n infrastructure
```

## 📊 Acesso ao Prometheus

### Método 1: Interface Web via Port Forwarding

```bash
# Fazer port forwarding para a interface web
kubectl port-forward -n infrastructure svc/prometheus-server 9090:9090

# Acessar no navegador: http://localhost:9090
```

### Método 2: API do Prometheus

```bash
# Consultar métricas via API
curl "http://localhost:9090/api/v1/query?query=up"
```

## 📝 Endpoints Importantes

### Interface Web
- **URL**: `http://prometheus-server.infrastructure.svc.cluster.local:9090`
- **Port Forwarding**: `kubectl port-forward svc/prometheus-server 9090:9090`

### API Endpoints
- **Query**: `http://localhost:9090/api/v1/query`
- **Query Range**: `http://localhost:9090/api/v1/query_range`
- **Targets**: `http://localhost:9090/api/v1/targets`

## 🔧 Configuração de Métricas

### Adicionando Targets Personalizados

Para adicionar aplicações personalizadas ao monitoramento:

```yaml
# Adicionar ao prometheus-values-minikube.yaml
serverFiles:
  prometheus.yml:
    scrape_configs:
      - job_name: 'smartcity-app'
        static_configs:
          - targets: ['smartcity-app.infrastructure.svc.cluster.local:8080']
        metrics_path: '/actuator/prometheus'
```

### Métricas Essenciais para Monitorar

```promql
# Status dos serviços
up{job="postgres"}
up{job="redis"}
up{job="rabbitmq"}

# Uso de recursos
container_memory_usage_bytes{pod=~".*"}
container_cpu_usage_seconds_total{pod=~".*"}

# HTTP requests (para aplicações Spring Boot)
http_server_requests_seconds_count
http_server_requests_seconds_sum
```

## 📋 Dashboards Recomendados

### Grafana Integration

Para visualizar as métricas em dashboards:

```bash
# Instalar Grafana
helm install grafana stable/grafana -n infrastructure

# Importar dashboards do Prometheus
# Dashboard ID: 3662 (Prometheus 2.0 Overview)
# Dashboard ID: 3070 (PostgreSQL)
# Dashboard ID: 4279 (Redis)
```

## 🧹 Limpeza

```bash
# Remover o deployment
helm uninstall prometheus -n infrastructure

# Remover PVC (cuidado: isso apaga os dados de métricas)
kubectl delete pvc -n infrastructure -l app.kubernetes.io/instance=prometheus
```

## 📋 Próximos Passos

1. Verificar se o Prometheus está coletando métricas
2. Configurar alertas importantes
3. Integrar com Grafana para visualização
4. Configurar retenção de dados adequada

## 🔍 Troubleshooting

### Problema: Métricas não aparecem
```bash
# Verificar status dos targets
kubectl port-forward svc/prometheus-server 9090:9090
# Acessar: http://localhost:9090/targets

# Verificar configuração
kubectl exec -it -n infrastructure prometheus-server-0 -- cat /etc/config/prometheus.yml
```

### Problema: Alto uso de disco
```bash
# Verificar tamanho do PVC
kubectl describe pvc -n infrastructure prometheus-server-pvc

# Verificar configuração de retenção
kubectl exec -it -n infrastructure prometheus-server-0 -- cat /etc/config/prometheus.yml | grep retention
```

### Problema: Alertas não funcionam
```bash
# Verificar regras de alerta
kubectl exec -it -n infrastructure prometheus-server-0 -- cat /etc/config/alerting_rules.yml

# Verificar status dos alertas
kubectl port-forward svc/prometheus-server 9090:9090
# Acessar: http://localhost:9090/alerts
```

## 📊 Exemplos de Queries

### Monitoramento de Aplicação
```promql
# Taxa de erro HTTP
rate(http_server_requests_seconds_count{status=~"5.."}[5m]) / rate(http_server_requests_seconds_count[5m])

# Latência média
histogram_quantile(0.95, rate(http_server_requests_seconds_bucket[5m]))

# Uso de memória JVM
jvm_memory_used_bytes / jvm_memory_max_bytes
```

### Monitoramento de Infraestrutura
```promql
# Uso de CPU dos containers
rate(container_cpu_usage_seconds_total[5m])

# Uso de memória dos containers
container_memory_usage_bytes / container_spec_memory_limit_bytes

# Status dos bancos de dados
up{job=~"postgres|redis|mongodb"}
```

## 🔗 Integrações

### Com Spring Boot
Adicione ao `pom.xml`:
```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-actuator</artifactId>
</dependency>
<dependency>
    <groupId>io.micrometer</groupId>
    <artifactId>micrometer-registry-prometheus</artifactId>
</dependency>
```

### Com Node.js
```bash
npm install prom-client express
```

### Com Python
```bash
pip install prometheus_client
```
