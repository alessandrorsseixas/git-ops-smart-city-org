# Redis para Smart City GitOps

Este diretório contém os manifestos Kubernetes para deploy do Redis no ambiente de desenvolvimento do Smart City.

## 📋 Componentes

- **redis-deployment.yaml**: Deployment principal do Redis
- **redis-service.yaml**: Service para exposição interna (incluído no Deployment)
- **redis-secret.yaml**: Credenciais de acesso
- **redis-configmap.yaml**: Configurações do Redis
- **redis-pvc.yaml**: Volume persistente para dados
- **redis-backup-pvc.yaml**: Volume persistente para backups
- **redis-backup-configmap.yaml**: Scripts de backup e health check
- **redis-backup-cronjob.yaml**: Backup automático diário
- **redis-networkpolicy.yaml**: Políticas de rede
- **deploy-redis.sh**: Script de deploy automatizado

## 🚀 Deploy

### Método 1: Script Automatizado
```bash
cd k8s/infra/dev/redis
./deploy-redis.sh
```

### Método 2: Kustomize
```bash
kubectl apply -k k8s/infra/dev/
```

### Método 3: Aplicação Manual
```bash
kubectl apply -f k8s/infra/dev/redis/
```

## 🔗 Conexão

### Connection String
```
redis://:smartcity123@redis.smartcity.svc.cluster.local:6379
```

### Variáveis de Ambiente para Aplicações
```yaml
env:
- name: REDIS_URL
  value: "redis://:smartcity123@redis.smartcity.svc.cluster.local:6379"
- name: REDIS_HOST
  value: "redis.smartcity.svc.cluster.local"
- name: REDIS_PORT
  value: "6379"
- name: REDIS_PASSWORD
  valueFrom:
    secretKeyRef:
      name: redis-secret
      key: redis-password
```

## 👥 Usuários

| Usuário | Senha | Permissões |
|---------|-------|------------|
| `default` | `smartcity123` | Acesso completo ao Redis |

## 📊 Monitoramento

### Health Checks
```bash
# Verificar status do pod
kubectl get pods -n smartcity -l app=redis

# Verificar logs
kubectl logs -n smartcity -l app=redis

# Verificar recursos
kubectl top pods -n smartcity -l app=redis
```

### Teste de Conexão
```bash
kubectl run redis-test --image=redis:7.2-alpine --rm -it --restart=Never \
  --namespace smartcity \
  --env="REDIS_PASSWORD=smartcity123" \
  -- redis-cli -h redis.smartcity.svc.cluster.local -a "$REDIS_PASSWORD" ping
```

### Redis CLI
```bash
# Conectar via kubectl
kubectl exec -it deployment/redis -n smartcity -- redis-cli

# Ou com autenticação
kubectl exec -it deployment/redis -n smartcity -- redis-cli -a smartcity123
```

### Métricas de Performance
```bash
# Informações do servidor
kubectl exec -it deployment/redis -n smartcity -- redis-cli -a smartcity123 info server

# Estatísticas de memória
kubectl exec -it deployment/redis -n smartcity -- redis-cli -a smartcity123 info memory

# Estatísticas de clientes
kubectl exec -it deployment/redis -n smartcity -- redis-cli -a smartcity123 info clients
```

## 💾 Backup e Restore

### Backup Automático
- **Horário**: Todos os dias às 4:00 AM
- **Localização**: PVC `redis-backup-pvc`
- **Formato**: RDB (Redis Database File)
- **Retenção**: 7 dias

### Backup Manual
```bash
kubectl run backup-redis --image=redis:7.2-alpine --rm -it --restart=Never \
  --namespace smartcity \
  --env="REDIS_PASSWORD=smartcity123" \
  -- /scripts/backup.sh
```

### Restore
```bash
kubectl run restore-redis --image=redis:7.2-alpine --rm -it --restart=Never \
  --namespace smartcity \
  --env="REDIS_PASSWORD=smartcity123" \
  -- /scripts/restore.sh /backup/redis_backup_YYYYMMDD_HHMMSS.rdb
```

## ⚙️ Configuração

### Recursos
- **CPU**: 200m request / 500m limit
- **Memória**: 256Mi request / 512Mi limit
- **Storage**: 2Gi para dados / 5Gi para backups

### Configurações de Performance
- **maxmemory**: 256MB
- **maxmemory-policy**: allkeys-lru
- **tcp-keepalive**: 300 segundos
- **maxclients**: 10000 conexões

### Persistência
- ✅ RDB snapshots (save 900 1, 300 10, 60 10000)
- ✅ AOF (Append Only File) habilitado
- ✅ Appendfsync everysec

### Segurança
- ✅ Autenticação obrigatória (requirepass)
- ✅ Comandos perigosos desabilitados/renomeados
- ✅ Protected mode habilitado

## 🔧 Troubleshooting

### Pod não inicia
```bash
kubectl describe pod -n smartcity -l app=redis
kubectl logs -n smartcity -l app=redis
```

### Erro de conexão
```bash
# Verificar service
kubectl get svc -n smartcity redis

# Verificar endpoints
kubectl get endpoints -n smartcity redis

# Testar conectividade
kubectl run debug-redis --image=redis:7.2-alpine --rm -it --restart=Never \
  --namespace smartcity -- nslookup redis.smartcity.svc.cluster.local
```

### Problemas de memória
```bash
# Verificar uso de memória
kubectl top pods -n smartcity -l app=redis

# Verificar configuração de memória
kubectl exec -it deployment/redis -n smartcity -- redis-cli -a smartcity123 config get maxmemory
```

### Comandos bloqueados
```bash
# Lista de comandos renomeados
kubectl exec -it deployment/redis -n smartcity -- redis-cli -a smartcity123 config get rename-command
```

## 🛠️ Manutenção

### Verificar Status
```bash
kubectl exec -it deployment/redis -n smartcity -- redis-cli -a smartcity123 info
```

### Limpar Cache
```bash
kubectl exec -it deployment/redis -n smartcity -- redis-cli -a smartcity123 flushall
```

### Verificar Conexões
```bash
kubectl exec -it deployment/redis -n smartcity -- redis-cli -a smartcity123 client list
```

### Monitor de Comandos Lentos
```bash
kubectl exec -it deployment/redis -n smartcity -- redis-cli -a smartcity123 slowlog get 10
```

## 🔄 Escalabilidade

### Aumentar Recursos
```yaml
resources:
  requests:
    memory: "512Mi"
    cpu: "400m"
  limits:
    memory: "1Gi"
    cpu: "800m"
```

### Clustering (Futuro)
Para implementar Redis Cluster:
1. Aumentar réplicas para 6+ nós
2. Habilitar cluster mode na configuração
3. Configurar cluster formation
4. Atualizar connection strings das aplicações

### Sentinel (Futuro)
Para implementar Redis Sentinel:
1. Deploy Redis Sentinels
2. Configurar monitoring dos masters
3. Configurar failover automático
4. Atualizar connection strings das aplicações

## 🔒 Segurança

### Autenticação
- ✅ Senha obrigatória para todas as conexões
- ✅ Autenticação via secret do Kubernetes

### Autorização
- ✅ Comandos perigosos desabilitados:
  - FLUSHDB (desabilitado)
  - FLUSHALL (desabilitado)
  - CONFIG (renomeado para CONFIG_REDIS)
  - DEBUG (renomeado para DEBUG_REDIS)

### Rede
- ✅ NetworkPolicy restritivo
- ✅ Isolamento de tráfego
- ✅ Controle de portas específicas

## 📈 Métricas

### Métricas Disponíveis
- **Conexões**: Número de clientes conectados
- **Memória**: Uso de memória e política de eviction
- **Comandos**: Número de comandos processados
- **Latência**: Tempo de resposta dos comandos
- **Persistencia**: Status de RDB/AOF

### Queries de Monitoramento
```bash
# Status geral
kubectl exec -it deployment/redis -n smartcity -- redis-cli -a smartcity123 info

# Uso de memória
kubectl exec -it deployment/redis -n smartcity -- redis-cli -a smartcity123 info memory | grep used_memory

# Número de conexões
kubectl exec -it deployment/redis -n smartcity -- redis-cli -a smartcity123 info clients | grep connected_clients

# Estatísticas de comandos
kubectl exec -it deployment/redis -n smartcity -- redis-cli -a smartcity123 info stats | grep total_commands_processed
```

---

## 📞 Suporte

Para problemas ou dúvidas:
1. Verifique os logs: `kubectl logs -l app=redis -n smartcity`
2. Use o Redis CLI: `kubectl exec -it deployment/redis -n smartcity -- redis-cli -a smartcity123`
3. Teste a conectividade: Use os comandos de teste acima
4. Consulte a documentação Redis oficial

---

**Nota**: Este README é específico para o ambiente de desenvolvimento. Para produção, considere configurações adicionais de segurança, clustering e alta disponibilidade.
