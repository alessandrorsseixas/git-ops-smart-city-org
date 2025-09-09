# PostgreSQL para Smart City GitOps

Este diretório contém os manifestos Kubernetes para deploy do PostgreSQL no ambiente de desenvolvimento do Smart City.

## 📋 Componentes

- **postgres-statefulset.yaml**: StatefulSet principal do PostgreSQL
- **postgres-service.yaml**: Service para exposição interna (incluído no StatefulSet)
- **postgres-secret.yaml**: Credenciais de acesso
- **postgres-configmap.yaml**: Configurações do PostgreSQL
- **postgres-init-configmap.yaml**: Scripts de inicialização
- **postgres-pvc.yaml**: Volume persistente para dados
- **postgres-backup-pvc.yaml**: Volume persistente para backups
- **postgres-backup-configmap.yaml**: Scripts de backup
- **postgres-backup-cronjob.yaml**: Backup automático diário
- **postgres-networkpolicy.yaml**: Políticas de rede
- **deploy-postgres.sh**: Script de deploy automatizado

## 🚀 Deploy

### Método 1: Script Automatizado
```bash
cd k8s/infra/dev/postgres
./deploy-postgres.sh
```

### Método 2: Kustomize
```bash
kubectl apply -k k8s/infra/dev/
```

### Método 3: Aplicação Manual
```bash
kubectl apply -f k8s/infra/dev/postgres/
```

## 🔗 Conexão

### String de Conexão
```
postgresql://smartcity:smartcity123@postgres.smartcity.svc.cluster.local:5432/smartcity
```

### Variáveis de Ambiente para Aplicações
```yaml
env:
- name: DATABASE_URL
  value: "postgresql://smartcity:smartcity123@postgres.smartcity.svc.cluster.local:5432/smartcity"
- name: DB_HOST
  value: "postgres.smartcity.svc.cluster.local"
- name: DB_PORT
  value: "5432"
- name: DB_NAME
  value: "smartcity"
- name: DB_USER
  value: "smartcity"
- name: DB_PASSWORD
  valueFrom:
    secretKeyRef:
      name: postgres-secret
      key: postgres-password
```

## 👥 Usuários

| Usuário | Senha | Permissões |
|---------|-------|------------|
| `smartcity` | `smartcity123` | Admin do banco `smartcity` |
| `smartcity_app` | `app123` | Usuário da aplicação com permissões limitadas |
| `backup_user` | `backup123` | Usuário para backups |
| `postgres` | `admin123` | Superusuário PostgreSQL |

## 📊 Monitoramento

### Health Checks
```bash
# Verificar status do pod
kubectl get pods -n smartcity -l app=postgres

# Verificar logs
kubectl logs -n smartcity -l app=postgres

# Verificar recursos
kubectl top pods -n smartcity -l app=postgres
```

### Teste de Conexão
```bash
kubectl run test-postgres --image=postgres:15-alpine --rm -it --restart=Never \
  --namespace smartcity \
  --env="PGPASSWORD=smartcity123" \
  -- psql -h postgres.smartcity.svc.cluster.local -U smartcity -d smartcity -c "SELECT version();"
```

### Métricas de Performance
```sql
-- Consultas úteis para monitoramento
SELECT * FROM pg_stat_activity;
SELECT * FROM pg_stat_database;
SELECT * FROM pg_stat_user_tables;
```

## 💾 Backup e Restore

### Backup Automático
- **Horário**: Todos os dias às 2:00 AM
- **Localização**: PVC `postgres-backup-pvc`
- **Retenção**: 7 dias
- **Formato**: Custom (pg_dump) com compressão

### Backup Manual
```bash
kubectl run backup-postgres --image=postgres:15-alpine --rm -it --restart=Never \
  --namespace smartcity \
  --env="PGPASSWORD=smartcity123" \
  -- pg_dump -h postgres.smartcity.svc.cluster.local -U smartcity -d smartcity > backup.sql
```

### Restore
```bash
kubectl run restore-postgres --image=postgres:15-alpine --rm -it --restart=Never \
  --namespace smartcity \
  --env="PGPASSWORD=smartcity123" \
  -- psql -h postgres.smartcity.svc.cluster.local -U smartcity -d smartcity < backup.sql
```

## ⚙️ Configuração

### Recursos
- **CPU**: 250m request / 500m limit
- **Memória**: 512Mi request / 1Gi limit
- **Storage**: 10Gi para dados / 20Gi para backups

### Configurações de Performance
- **shared_buffers**: 128MB
- **effective_cache_size**: 256MB
- **work_mem**: 4MB
- **maintenance_work_mem**: 64MB
- **max_connections**: 100

### Extensões Habilitadas
- `uuid-ossp`: Para geração de UUIDs
- `pg_stat_statements`: Para monitoramento de queries
- `pg_buffercache`: Para análise de cache

## 🔧 Troubleshooting

### Pod não inicia
```bash
kubectl describe pod -n smartcity -l app=postgres
kubectl logs -n smartcity -l app=postgres
```

### Erro de conexão
```bash
# Verificar service
kubectl get svc -n smartcity postgres

# Verificar endpoints
kubectl get endpoints -n smartcity postgres

# Testar conectividade
kubectl run debug-postgres --image=postgres:15-alpine --rm -it --restart=Never \
  --namespace smartcity -- nslookup postgres.smartcity.svc.cluster.local
```

### Problemas de storage
```bash
kubectl get pvc -n smartcity
kubectl describe pvc -n smartcity postgres-pvc
```

### Queries Lentas
```sql
-- Identificar queries lentas
SELECT query, calls, total_time, mean_time, rows
FROM pg_stat_statements
ORDER BY mean_time DESC
LIMIT 10;
```

## 🛠️ Manutenção

### Vacuum e Analyze
```bash
kubectl run maintenance-postgres --image=postgres:15-alpine --rm -it --restart=Never \
  --namespace smartcity \
  --env="PGPASSWORD=smartcity123" \
  -- psql -h postgres.smartcity.svc.cluster.local -U smartcity -d smartcity -c "VACUUM ANALYZE;"
```

### Reindex
```bash
kubectl run reindex-postgres --image=postgres:15-alpine --rm -it --restart=Never \
  --namespace smartcity \
  --env="PGPASSWORD=smartcity123" \
  -- psql -h postgres.smartcity.svc.cluster.local -U smartcity -d smartcity -c "REINDEX DATABASE smartcity;"
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

### Read Replicas (Futuro)
Para implementar read replicas:
1. Criar novos StatefulSets
2. Configurar replication
3. Atualizar connection strings das aplicações

## 🔒 Segurança

### Autenticação
- ✅ SCRAM-SHA-256 para hash de senhas
- ✅ Usuários com permissões específicas
- ✅ NetworkPolicy restritivo

### Autorização
- ✅ Usuário da aplicação com permissões limitadas
- ✅ Usuário de backup com acesso apenas leitura
- ✅ Superusuário isolado

### Auditoria
- ✅ Logging de conexões e desconexões
- ✅ Logging de DDL statements
- ✅ pg_stat_statements para análise de queries

## 📈 Métricas

### Queries para Monitoramento
```sql
-- Conexões ativas
SELECT count(*) as active_connections FROM pg_stat_activity;

-- Tamanho do banco
SELECT pg_size_pretty(pg_database_size('smartcity'));

-- Tabelas maiores
SELECT schemaname, tablename, pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename))
FROM pg_tables
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC
LIMIT 10;
```

---

## 📞 Suporte

Para problemas ou dúvidas:
1. Verifique os logs: `kubectl logs -l app=postgres -n smartcity`
2. Teste a conectividade: Use o comando de teste acima
3. Verifique recursos: `kubectl describe pod -l app=postgres -n smartcity`
4. Consulte a documentação PostgreSQL oficial
