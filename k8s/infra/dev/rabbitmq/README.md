# RabbitMQ para Smart City GitOps

Este diretório contém os manifestos Kubernetes para deploy do RabbitMQ no ambiente de desenvolvimento do Smart City.

## 📋 Componentes

- **rabbitmq-deployment.yaml**: Deployment principal do RabbitMQ
- **rabbitmq-service.yaml**: Service para exposição interna (incluído no Deployment)
- **rabbitmq-secret.yaml**: Credenciais de acesso
- **rabbitmq-configmap.yaml**: Configurações e definições do RabbitMQ
- **rabbitmq-pvc.yaml**: Volume persistente para dados
- **rabbitmq-backup-pvc.yaml**: Volume persistente para backups
- **rabbitmq-backup-configmap.yaml**: Scripts de backup e health check
- **rabbitmq-backup-cronjob.yaml**: Backup automático diário
- **rabbitmq-networkpolicy.yaml**: Políticas de rede
- **deploy-rabbitmq.sh**: Script de deploy automatizado

## 🚀 Deploy

### Método 1: Script Automatizado
```bash
cd k8s/infra/dev/rabbitmq
./deploy-rabbitmq.sh
```

### Método 2: Kustomize
```bash
kubectl apply -k k8s/infra/dev/
```

### Método 3: Aplicação Manual
```bash
kubectl apply -f k8s/infra/dev/rabbitmq/
```

## 🔗 Conexão

### AMQP Connection String
```
amqp://smartcity:smartcity123@rabbitmq.smartcity.svc.cluster.local:5672/
```

### Management UI
```
http://rabbitmq.smartcity.svc.cluster.local:15672/
```

### Prometheus Metrics
```
http://rabbitmq.smartcity.svc.cluster.local:15692/metrics
```

### Variáveis de Ambiente para Aplicações
```yaml
env:
- name: RABBITMQ_HOST
  value: "rabbitmq.smartcity.svc.cluster.local"
- name: RABBITMQ_PORT
  value: "5672"
- name: RABBITMQ_USER
  value: "smartcity"
- name: RABBITMQ_PASSWORD
  valueFrom:
    secretKeyRef:
      name: rabbitmq-secret
      key: rabbitmq-password
- name: RABBITMQ_VHOST
  value: "/"
```

## 👥 Usuários

| Usuário | Senha | Permissões |
|---------|-------|------------|
| `smartcity` | `smartcity123` | Administrator completo |
| `admin` | `admin123` | Administrator completo |

## 📊 Monitoramento

### Health Checks
```bash
# Verificar status do pod
kubectl get pods -n smartcity -l app=rabbitmq

# Verificar logs
kubectl logs -n smartcity -l app=rabbitmq

# Verificar recursos
kubectl top pods -n smartcity -l app=rabbitmq
```

### Management UI
```bash
# Port forward para acessar a interface web
kubectl port-forward svc/rabbitmq 15672:15672 -n smartcity
# Acesse: http://localhost:15672
```

### Teste de Conexão
```bash
kubectl run rabbitmq-test --image=curlimages/curl:latest --rm -it --restart=Never \
  --namespace smartcity \
  --env="RABBITMQ_USER=smartcity" \
  --env="RABBITMQ_PASSWORD=smartcity123" \
  -- sh -c 'curl -u "$RABBITMQ_USER:$RABBITMQ_PASSWORD" http://rabbitmq.smartcity.svc.cluster.local:15672/api/overview'
```

### Métricas Prometheus
```bash
# Ver métricas
kubectl run metrics-test --image=curlimages/curl:latest --rm -it --restart=Never \
  --namespace smartcity \
  -- curl http://rabbitmq.smartcity.svc.cluster.local:15692/metrics
```

## 💾 Backup e Restore

### Backup Automático
- **Horário**: Todos os dias às 3:00 AM
- **Localização**: PVC `rabbitmq-backup-pvc`
- **Conteúdo**: Definições, permissões e configurações
- **Retenção**: 7 dias

### Backup Manual
```bash
kubectl run backup-rabbitmq --image=curlimages/curl:latest --rm -it --restart=Never \
  --namespace smartcity \
  --env="RABBITMQ_USER=smartcity" \
  --env="RABBITMQ_PASSWORD=smartcity123" \
  -- /scripts/backup.sh
```

### Restore
```bash
kubectl run restore-rabbitmq --image=curlimages/curl:latest --rm -it --restart=Never \
  --namespace smartcity \
  --env="RABBITMQ_USER=smartcity" \
  --env="RABBITMQ_PASSWORD=smartcity123" \
  -- /scripts/restore.sh /backup/rabbitmq_backup_YYYYMMDD_HHMMSS.tar.gz
```

## ⚙️ Configuração

### Recursos
- **CPU**: 250m request / 500m limit
- **Memória**: 512Mi request / 1Gi limit
- **Storage**: 5Gi para dados / 10Gi para backups

### Plugins Habilitados
- ✅ `rabbitmq_management`: Interface web de gerenciamento
- ✅ `rabbitmq_prometheus`: Métricas para monitoramento
- ✅ `rabbitmq_peer_discovery_k8s`: Descoberta de peers para clustering

### Configurações de Performance
- **vm_memory_high_watermark**: 80% da memória
- **disk_free_limit**: 2.0GB mínimo
- **channel_max**: 2047 conexões por canal
- **max_message_size**: 128MB

### Recursos Pré-configurados

#### Virtual Hosts
- `/`: Virtual host padrão
- `smartcity`: Virtual host específico da aplicação

#### Exchanges
- `smartcity.topic`: Exchange do tipo topic
- `smartcity.direct`: Exchange do tipo direct

#### Queues
- `smartcity.notifications`: Fila para notificações
- `smartcity.events`: Fila para eventos

#### Políticas
- `ha-all`: High availability para todas as queues

## 🔧 Troubleshooting

### Pod não inicia
```bash
kubectl describe pod -n smartcity -l app=rabbitmq
kubectl logs -n smartcity -l app=rabbitmq
```

### Erro de conexão
```bash
# Verificar service
kubectl get svc -n smartcity rabbitmq

# Verificar endpoints
kubectl get endpoints -n smartcity rabbitmq

# Testar conectividade
kubectl run debug-rabbitmq --image=curlimages/curl:latest --rm -it --restart=Never \
  --namespace smartcity -- nslookup rabbitmq.smartcity.svc.cluster.local
```

### Problemas de memória
```bash
# Verificar uso de memória
kubectl top pods -n smartcity -l app=rabbitmq

# Verificar limites
kubectl describe pod -n smartcity -l app=rabbitmq
```

### Management UI não acessível
```bash
# Verificar se o plugin está habilitado
kubectl exec -it deployment/rabbitmq -n smartcity -- rabbitmq-plugins list

# Verificar logs do management
kubectl logs -n smartcity -l app=rabbitmq | grep management
```

## 🛠️ Manutenção

### Verificar Status do Cluster
```bash
kubectl exec -it deployment/rabbitmq -n smartcity -- rabbitmqctl cluster_status
```

### Listar Conexões Ativas
```bash
kubectl exec -it deployment/rabbitmq -n smartcity -- rabbitmqctl list_connections
```

### Listar Queues
```bash
kubectl exec -it deployment/rabbitmq -n smartcity -- rabbitmqctl list_queues
```

### Reset do Nó
```bash
kubectl exec -it deployment/rabbitmq -n smartcity -- rabbitmqctl reset
```

## 🔄 Escalabilidade

### Aumentar Recursos
```yaml
resources:
  requests:
    memory: "1Gi"
    cpu: "500m"
  limits:
    memory: "2Gi"
    cpu: "1000m"
```

### Clustering (Futuro)
Para implementar clustering:
1. Aumentar réplicas no deployment
2. Configurar peer discovery
3. Configurar políticas de HA
4. Atualizar connection strings das aplicações

### Load Balancing
Para balanceamento de carga:
1. Usar Service do tipo LoadBalancer
2. Implementar consumer load balancing
3. Configurar multiple consumers

## 🔒 Segurança

### Autenticação
- ✅ Usuários com senhas seguras
- ✅ Erlang cookie para clustering
- ✅ Autenticação obrigatória

### Autorização
- ✅ Usuários com permissões específicas
- ✅ Virtual hosts isolados
- ✅ Controle de acesso por vhost

### Rede
- ✅ NetworkPolicy restritivo
- ✅ Isolamento de tráfego
- ✅ Controle de portas específicas

## 📈 Métricas

### Métricas Disponíveis
- **Conexões**: Número de conexões ativas
- **Canais**: Número de canais abertos
- **Queues**: Número e status das filas
- **Mensagens**: Taxa de entrada/saída de mensagens
- **Memória**: Uso de memória do broker
- **Disco**: Uso de espaço em disco

### Queries de Monitoramento
```bash
# Número de conexões
curl -s -u smartcity:smartcity123 http://rabbitmq.smartcity.svc.cluster.local:15672/api/connections | jq length

# Número de queues
curl -s -u smartcity:smartcity123 http://rabbitmq.smartcity.svc.cluster.local:15672/api/queues | jq length

# Status do cluster
curl -s -u smartcity:smartcity123 http://rabbitmq.smartcity.svc.cluster.local:15672/api/nodes
```

---

## 📞 Suporte

Para problemas ou dúvidas:
1. Verifique os logs: `kubectl logs -l app=rabbitmq -n smartcity`
2. Acesse a Management UI: `kubectl port-forward svc/rabbitmq 15672:15672 -n smartcity`
3. Teste a conectividade: Use os comandos de teste acima
4. Consulte a documentação RabbitMQ oficial

---

**Nota**: Este README é específico para o ambiente de desenvolvimento. Para produção, considere configurações adicionais de segurança, clustering e alta disponibilidade.
