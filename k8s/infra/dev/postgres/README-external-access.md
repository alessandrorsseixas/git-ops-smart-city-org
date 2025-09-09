# PostgreSQL External Access

Este documento explica como acessar o PostgreSQL externamente através do domínio `postgres.dev.smartcity.local`.

## Configuração

### Service Externo
- **Tipo**: LoadBalancer
- **Porta**: 5432
- **Domínio**: postgres.dev.smartcity.local

### Certificado SSL
- **Issuer**: Let's Encrypt (letsencrypt-prod)
- **Domínio**: postgres.dev.smartcity.local
- **Secret**: postgres-tls

## Como Usar

### 1. Conexão Direta via LoadBalancer
```bash
# Conectar via psql
psql -h postgres.dev.smartcity.local -p 5432 -U smartcity -d smartcity

# Ou via string de conexão
postgresql://smartcity:smartcity123@postgres.dev.smartcity.local:5432/smartcity
```

### 2. Conexão via Aplicações
```yaml
# Exemplo de configuração em aplicações Spring Boot
spring:
  datasource:
    url: jdbc:postgresql://postgres.dev.smartcity.local:5432/smartcity
    username: smartcity
    password: smartcity123
```

### 3. Ferramentas de Administração
- **pgAdmin**: Conecte usando o host `postgres.dev.smartcity.local`
- **DBeaver**: Use o mesmo host para conexões
- **Adminer**: Configure para usar o domínio externo

## Segurança

- ✅ SSL/TLS habilitado via Let's Encrypt
- ✅ Autenticação por senha obrigatória
- ✅ Network Policy configurada
- ✅ Acesso restrito ao namespace smartcity

## Monitoramento

O PostgreSQL está configurado com:
- Métricas do pg_stat_statements
- Logs detalhados de conexões
- Backup automático diário
- Health checks configurados

## Troubleshooting

### Verificar Status do Service
```bash
kubectl get svc postgres-external -n smartcity
kubectl describe svc postgres-external -n smartcity
```

### Verificar Ingress
```bash
kubectl get ingress postgres-ingress -n smartcity
kubectl describe ingress postgres-ingress -n smartcity
```

### Verificar Certificado
```bash
kubectl get certificate postgres-tls -n smartcity
kubectl describe certificate postgres-tls -n smartcity
```

### Logs do PostgreSQL
```bash
kubectl logs -f postgres-0 -n smartcity
```
