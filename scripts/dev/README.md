# Scripts de Desenvolvimento - Smart City GitOps

Esta pasta contém scripts para configuração completa do ambiente de desenvolvimento local usando Minikube.

## 🚀 Uso Rápido (Recomendado)

### Deploy Completo do Ambiente
```bash
# Executa todo o fluxo de setup + deploy (RECOMENDADO)
./run.sh
```

Este comando irá executar automaticamente:
1. ✅ **Reset e inicialização do Minikube** (`diagnose-minikube.sh --reset`)
2. ✅ **Validação de pré-requisitos** (`install-prereqs.sh`)
3. ✅ **Setup do Rancher + Minikube** (`install-rancher-minikube.sh`)
4. ✅ **Configuração do Ingress** (`install-ingress.sh`)
5. ✅ **Configuração de certificados** (`install-cert.sh`)
6. ✅ **Deploy completo da infraestrutura** (`deploy/deploy-all.sh`)
7. ✅ **Atualização automática do /etc/hosts** (`update-hosts.sh`)

### Apenas Inicializar Minikube
```bash
# Para apenas inicializar o Minikube rapidamente
./init-minikube.sh

# Ou para diagnóstico completo e reset
./diagnose-minikube.sh --reset
```

### Atualizar /etc/hosts Manualmente
```bash
# Atualizar /etc/hosts com domínios necessários
sudo ./update-hosts.sh

# Ou executar apenas o diagnóstico
./diagnose-minikube.sh
```

### Testar Deployment
```bash
# Executar testes completos do deployment
./test-deployment.sh

# Verificar status dos pods
kubectl get pods --all-namespaces

# Verificar serviços
kubectl get svc --all-namespaces
```

## 🌐 DNS e Resolução de Nomes

O sistema utiliza domínios locais para acessar os serviços:

### Domínios Configurados Automaticamente
- **`argocd.dev.smartcity.local`** - Interface web do ArgoCD
- **`argocd-grpc.dev.smartcity.local`** - API GRPC do ArgoCD (para CLI)
- **`keycloak.dev.smartcity.local`** - Interface do Keycloak
- **`smartcity.local`** - Domínio base para outros serviços

### Como Funciona
1. **IP do Minikube** é detectado automaticamente
2. **Entradas são adicionadas** ao `/etc/hosts` durante o deploy
3. **Backup automático** é criado em `/etc/hosts.backup.smartcity`
4. **Verificação** garante que as entradas estão corretas

### Execução Automática
O script `update-hosts.sh` é executado automaticamente pelo `run.sh` após o deploy completo, não sendo necessário intervenção manual.

### Verificar Configuração
```bash
# Testar resolução DNS
ping argocd.dev.smartcity.local

# Verificar entradas no hosts
cat /etc/hosts | grep smartcity

# Testar conectividade HTTPS
curl -k https://argocd.dev.smartcity.local
```

## 📂 Estrutura de Scripts

### Scripts de Preparação do Ambiente
- **`diagnose-minikube.sh`** - Diagnóstica, limpa e reinicializa Minikube (--reset, --start)
- **`init-minikube.sh`** - Inicialização rápida do Minikube com parâmetros padrão
- **`update-hosts.sh`** - Atualiza /etc/hosts com domínios necessários (executado automaticamente)
- **`install-prereqs.sh`** - Valida pré-requisitos (kubectl, helm, minikube, openssl)
- **`install-rancher-minikube.sh`** - Instala Rancher Desktop + Minikube
- **`install-ingress.sh`** - Configura Ingress Controller
- **`install-cert.sh`** - Gera certificados self-signed e configura no cluster

### Scripts de Deploy (pasta `deploy/`)
- **`deploy-all.sh`** - 🎯 Deploy completo orquestrado
- **`deploy-pvcs.sh`** - Deploy apenas dos Persistent Volume Claims
- **`deploy-infra.sh`** - Deploy da infraestrutura (PostgreSQL, Redis, RabbitMQ, Keycloak)
- **`deploy-argocd.sh`** - Deploy do ArgoCD GitOps
- **`status.sh`** - Verifica status de todos os deployments
- **`cleanup.sh`** - Remove todos os deployments

### Script Principal
- **`run.sh`** - 🚀 **Orquestrador principal** - executa todo o fluxo

## 🔧 Uso Avançado

### Executar apenas componentes específicos
```bash
# Apenas pré-requisitos e certificados
./run.sh -c "install-prereqs.sh,install-cert.sh"

# Apenas o deploy da infraestrutura
./deploy/deploy-infra.sh

# Apenas o ArgoCD
./deploy/deploy-argocd.sh
```

### Deploy por etapas
```bash
# 1. Preparação do ambiente
./install-prereqs.sh
./install-rancher-minikube.sh
./install-cert.sh

# 2. Deploy da infraestrutura
./deploy/deploy-pvcs.sh      # Volumes persistentes
./deploy/deploy-infra.sh     # PostgreSQL, Redis, RabbitMQ, Keycloak
./deploy/deploy-argocd.sh    # ArgoCD GitOps

# 3. Verificar status
./deploy/status.sh
```

### Dry Run (apenas simular)
```bash
./run.sh --dry-run
```

### Limpeza completa
```bash
./deploy/cleanup.sh
```

## 🌐 Após o Deploy

### URLs de Acesso (configurar no /etc/hosts)
```bash
# Obter IP do Minikube
minikube ip

# Adicionar ao /etc/hosts (substitua <MINIKUBE_IP>)
<MINIKUBE_IP> argocd.dev.smartcity.local
<MINIKUBE_IP> argocd-grpc.dev.smartcity.local
<MINIKUBE_IP> keycloak.dev.smartcity.local
```

### Credenciais Padrão (DEV)
- **ArgoCD**: admin / admin123
- **Keycloak**: admin / admin
- **PostgreSQL**: postgres / postgres
- **RabbitMQ**: admin / admin

### Serviços Disponíveis
- **ArgoCD UI**: https://argocd.dev.smartcity.local
- **ArgoCD GRPC**: argocd-grpc.dev.smartcity.local:443
- **Keycloak**: http://keycloak.dev.smartcity.local:8080

## 📊 Monitoramento e Troubleshooting

### Health Check Automático
```bash
# Verificação completa da saúde do sistema
./health-check.sh

# Executar testes detalhados
./test-deployment.sh
```

### Monitoramento Contínuo
```bash
# Ver logs em tempo real
kubectl logs -f deployment/argocd-server -n argocd

# Monitorar recursos
kubectl top pods --all-namespaces

# Ver status de todos os deployments
kubectl get deployments --all-namespaces

# Dashboard do Minikube
minikube dashboard
```

### Comandos de Troubleshooting
```bash
# Ver todos os pods com problemas
kubectl get pods --all-namespaces | grep -v Running

# Ver logs de um pod específico
kubectl logs <pod-name> -n <namespace>

# Descrever um pod para detalhes
kubectl describe pod <pod-name> -n <namespace>

# Ver eventos do cluster
kubectl get events --sort-by=.metadata.creationTimestamp

# Ver recursos utilizados
kubectl top nodes
kubectl top pods --all-namespaces
```

## 🛠️ Troubleshooting

### Verificar status dos pods
```bash
./deploy/status.sh
# ou
kubectl get pods --all-namespaces
```

### Logs dos serviços
```bash
# ArgoCD
kubectl logs -f deployment/argocd-server -n argocd

# Keycloak
kubectl logs -f deployment/keycloak -n smartcity

# PostgreSQL
kubectl logs -f statefulset/postgres -n smartcity
```

### Resetar ambiente
```bash
# Limpeza completa dos deployments
./deploy/cleanup.sh

# Reset completo do Minikube
./diagnose-minikube.sh --reset

# Deploy novamente
./run.sh

# Ou tudo em um comando (mais rápido)
./run.sh  # já faz reset automático do Minikube
```

## 🧪 Testes e Validação

### Teste Completo do Deployment
```bash
./test-deployment.sh
```

Este comando verifica:
- ✅ Status do Minikube
- ✅ Conectividade do kubectl
- ✅ Namespaces criados
- ✅ Pods rodando (ArgoCD + Infraestrutura)
- ✅ Serviços disponíveis
- ✅ Ingress configurado
- ✅ Resolução DNS
- ✅ Conectividade HTTPS

### Testes Individuais
```bash
# Testar apenas ArgoCD
kubectl get pods -n argocd

# Testar infraestrutura
kubectl get pods -n smartcity

# Testar resolução DNS
ping argocd.dev.smartcity.local

# Testar conectividade
curl -k https://argocd.dev.smartcity.local
```

### Health Check Completo
```bash
# Verificação geral da saúde do sistema
./health-check.sh
```

Este comando fornece um relatório completo incluindo:
- ✅ Status do Minikube
- ✅ Conectividade do kubectl
- ✅ Namespaces e pods
- ✅ Serviços e ingress
- ✅ Resolução DNS
- ✅ Conectividade HTTPS
- 📊 Status geral do sistema

## 📝 Notas Importantes

- ⚠️ **Ambiente de desenvolvimento apenas** - não usar em produção
- 🔐 **Senhas padrão** - alterar em ambientes não-dev
- 💾 **Dados persistentes** - usar PVCs para manter dados entre restarts
- 🔄 **Scripts idempotentes** - seguros para reexecução

## 🎯 GitOps com ArgoCD

Após o deploy, configure aplicações no ArgoCD:

1. Acesse https://argocd.dev.smartcity.local
2. Login: admin / admin123
3. Adicione repositórios Git
4. Crie Applications para deploy contínuo
5. Configure pipelines de CI/CD

---

Para mais detalhes, consulte os READMEs específicos em cada pasta.
