# MongoDB para Smart City GitOps

Este diretório contém os manifestos Kubernetes para deploy do MongoDB no ambiente de desenvolvimento do Smart City.

## 📋 Componentes

- **mongodb-statefulset.yaml**: StatefulSet principal do MongoDB
- **mongodb-service.yaml**: Service para exposição interna
- **mongodb-metrics-service.yaml**: Service para métricas
- **mongodb-secret.yaml**: Credenciais de acesso
- **mongodb-configmap.yaml**: Configurações e scripts de inicialização
- **mongodb-pvc.yaml**: Volume persistente para dados
- **mongodb-backup-pvc.yaml**: Volume persistente para backups
- **mongodb-backup-configmap.yaml**: Scripts de backup
- **mongodb-backup-cronjob.yaml**: Backup automático diário
- **mongodb-networkpolicy.yaml**: Políticas de rede
- **kustomization.yaml**: Orquestração com Kustomize
- **deploy-mongodb.sh**: Script de deploy automatizado

## 🚀 Deploy

### Método 1: Script Automatizado
```bash
cd k8s/infra/dev/mongo
./deploy-mongodb.sh
```

### Método 2: Kustomize
```bash
kubectl apply -k k8s/infra/dev/mongo/
```

### Método 3: Aplicação Manual
```bash
kubectl apply -f k8s/infra/dev/mongo/
```

## 🔗 Conexão

### String de Conexão
```
mongodb://smartcity:smartcity123@mongodb.smartcity.svc.cluster.local:27017/smartcity?authSource=admin
```

### Variáveis de Ambiente para Aplicações
```yaml
env:
- name: MONGODB_URI
  value: "mongodb://smartcity:smartcity123@mongodb.smartcity.svc.cluster.local:27017/smartcity?authSource=admin"
- name: MONGODB_DATABASE
  value: "smartcity"
- name: MONGODB_USERNAME
  value: "smartcity"
- name: MONGODB_PASSWORD
  valueFrom:
    secretKeyRef:
      name: mongodb-secret
      key: mongodb-password
```

## 👥 Usuários

| Usuário | Senha | Permissões |
|---------|-------|------------|
| `smartcity` | `smartcity123` | Read/Write no DB `smartcity` |
| `admin` | `admin123` | Admin completo |

## 📊 Monitoramento

### Health Checks
```bash
# Verificar status do pod
kubectl get pods -n smartcity -l app=mongodb

# Verificar logs
kubectl logs -n smartcity -l app=mongodb

# Verificar recursos
kubectl top pods -n smartcity -l app=mongodb
```

### Teste de Conexão
```bash
kubectl run test-mongo --image=mongo:6.0 --rm -it --restart=Never \
  --namespace smartcity \
  -- mongo mongodb://smartcity:smartcity123@mongodb.smartcity.svc.cluster.local:27017/smartcity?authSource=admin
```

## 💾 Backup e Restore

### Backup Manual
```bash
kubectl run backup-mongo --image=mongo:6.0 --rm -it --restart=Never \
  --namespace smartcity \
  -- mongodump --host mongodb.smartcity.svc.cluster.local \
  --username smartcity --password smartcity123 --authenticationDatabase admin \
  --db smartcity --out /backup/$(date +%Y%m%d_%H%M%S)
```

### Backup Automático
- **Horário**: Todos os dias às 2:00 AM
- **Localização**: PVC `mongodb-backup-pvc`
- **Retenção**: 7 dias

### Restore
```bash
kubectl run restore-mongo --image=mongo:6.0 --rm -it --restart=Never \
  --namespace smartcity \
  -- mongorestore --host mongodb.smartcity.svc.cluster.local \
  --username smartcity --password smartcity123 --authenticationDatabase admin \
  --db smartcity /backup/backup-directory
```

## 🔧 Configuração

### Recursos
- **CPU**: 250m request / 500m limit
- **Memória**: 512Mi request / 1Gi limit
- **Storage**: 3Gi para dados / 10Gi para backups

### Segurança
- ✅ Autenticação habilitada
- ✅ NetworkPolicy restritivo
- ✅ Usuários com permissões específicas
- ✅ Comunicação criptografada (TLS)

### Performance
- ✅ WiredTiger com compressão
- ✅ Journal habilitado
- ✅ Cache otimizado
- ✅ Conexões limitadas

## 🐛 Troubleshooting

### Pod não inicia
```bash
kubectl describe pod -n smartcity -l app=mongodb
kubectl logs -n smartcity -l app=mongodb
```

### Erro de conexão
```bash
# Verificar service
kubectl get svc -n smartcity mongodb

# Verificar endpoints
kubectl get endpoints -n smartcity mongodb

# Testar conectividade
kubectl run debug-mongo --image=mongo:6.0 --rm -it --restart=Never \
  --namespace smartcity -- nslookup mongodb.smartcity.svc.cluster.local
```

### Problemas de storage
```bash
kubectl get pvc -n smartcity
kubectl describe pvc -n smartcity mongodb-pvc
```

## 📈 Escalabilidade

### Aumentar Réplicas
```bash
kubectl scale statefulset mongodb --replicas=3 -n smartcity
```

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

## 🔄 Atualização

### Rolling Update
```bash
kubectl rollout restart statefulset/mongodb -n smartcity
```

### Atualizar Versão
```yaml
# Em kustomization.yaml
images:
  - name: mongo
    newTag: "7.0"
```

---

## 📞 Suporte

Para problemas ou dúvidas:
1. Verifique os logs: `kubectl logs -n smartcity -l app=mongodb`
2. Teste a conectividade: Use o comando de teste acima
3. Verifique recursos: `kubectl describe pod -n smartcity -l app=mongodb`
