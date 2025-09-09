# PostgreSQL para Smart City GitOps

Este diretório contém os manifestos Kubernetes para deploy do PostgreSQL no ambiente de desenvolvimento do Smart City.

## 📋 Componentes

- **postgres-statefulset.yaml**: StatefulSet principal do PostgreSQL
- **postgres-service-external.yaml**: Service LoadBalancer para acesso externo
- **postgres-tls-certificate.yaml**: Certificado SSL para domínio externo
- **postgres-service.yaml**: Service para exposição interna (incluído no StatefulSet)
- **postgres-secret.yaml**: Credenciais de acesso
- **postgres-configmap.yaml**: Configurações do PostgreSQL
- **postgres-init-configmap.yaml**: Scripts de inicialização
- **postgres-pvc.yaml**: Volume persistente para dados
- **postgres-backup-pvc.yaml**: Volume persistente para backups
- **postgres-backup-configmap.yaml**: Scripts de backup
- **postgres-backup-cronjob.yaml**: Backup automático diário
- **postgres-networkpolicy.yaml**: Políticas de rede
- **kustomization.yaml**: Configuração Kustomize
- **README-external-access.md**: Documentação de acesso externo
- **application-examples.yaml**: Exemplos de configuração para aplicações
- **dns-config.md**: Configuração DNS
- **deploy-postgres.sh**: Script de deploy automatizado
- **rollback-postgres.sh**: Script de rollback (remove PostgreSQL)
- **health-check-postgres.sh**: Script de verificação de saúde
- **test-external-connection.sh**: Script de teste de conectividade externa

## 🚀 Deploy

### Método 1: Script Automatizado (Recomendado)
```bash
cd k8s/infra/dev/postgres
./deploy-postgres.sh
```

Este script:
- ✅ Verifica pré-requisitos (kubectl, cluster)
- ✅ Cria namespace se necessário
- ✅ Aplica todas as configurações via Kustomize
- ✅ Aguarda PostgreSQL ficar pronto
- ✅ Testa conectividade
- ✅ Mostra informações de acesso

### Método 2: Kustomize
```bash
kubectl apply -k k8s/infra/dev/postgres/
```

### Método 3: Aplicação Manual
```bash
kubectl apply -f k8s/infra/dev/postgres/
```

## 🔄 Rollback

Para remover completamente o PostgreSQL:
```bash
cd k8s/infra/dev/postgres
./rollback-postgres.sh
```

Este script:
- ⚠️  Faz backup automático dos dados
- 🗑️  Remove todos os recursos
- 💾 Preserva PVCs (dados) por padrão
- 📋 Mostra instruções de restauração

## 🔍 Health Check

Para verificar o status do PostgreSQL:
```bash
cd k8s/infra/dev/postgres
./health-check-postgres.sh
```

Este script verifica:
- ✅ Status dos pods e services
- ✅ Conectividade com banco de dados
- ✅ Utilização de recursos
- ✅ Status do storage
- ✅ Configuração de backups
- ✅ Conectividade externa
- ✅ Logs recentes

## 🔗 Conexão

### Acesso Interno (Cluster)
```
postgresql://smartcity:smartcity123@postgres.smartcity.svc.cluster.local:5432/smartcity
```

### Acesso Externo (LoadBalancer)
```
postgresql://smartcity:smartcity123@postgres.dev.smartcity.local:5432/smartcity
```

### Variáveis de Ambiente para Aplicações
```yaml
env:
- name: DATABASE_URL
  value: "postgresql://smartcity:smartcity123@postgres.smartcity.svc.cluster.local:5432/smartcity"
- name: DB_HOST
  value: "postgres.smartcity.svc.cluster.local"
- name: EXTERNAL_DB_HOST
  value: "postgres.dev.smartcity.local"
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

## 🌐 Acesso Externo

O PostgreSQL agora pode ser acessado externamente através do domínio `postgres.dev.smartcity.local`.

### Pré-requisitos
1. **Cert-Manager** instalado no cluster
2. **ClusterIssuer** `letsencrypt-prod` configurado
3. **Ingress Controller** (nginx) instalado
4. **DNS** configurado para apontar para o LoadBalancer

### Como Usar
```bash
# Conexão externa
psql -h postgres.dev.smartcity.local -p 5432 -U smartcity -d smartcity

# Verificar certificado SSL
openssl s_client -connect postgres.dev.smartcity.local:5432 -servername postgres.dev.smartcity.local
```

### Arquivos de Configuração
- `postgres-service-external.yaml`: Service LoadBalancer
- `postgres-tls-certificate.yaml`: Certificado Let's Encrypt
- `README-external-access.md`: Documentação completa
- `dns-config.md`: Configuração DNS
- `application-examples.yaml`: Exemplos para diferentes linguagens

### Segurança
- ✅ SSL/TLS via Let's Encrypt
- ✅ Autenticação obrigatória
- ✅ Network Policy configurada
- ✅ Acesso restrito ao namespace

### Testar Conectividade
```bash
cd k8s/infra/dev/postgres
./test-external-connection.sh
```

Este script testa:
- Conectividade de rede na porta 5432
- Validade do certificado SSL
- Conexão com o banco de dados
- Execução de queries simples
