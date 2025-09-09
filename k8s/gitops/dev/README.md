# ArgoCD - GitOps para Smart City

Este diretório contém a configuração do ArgoCD para gerenciamento GitOps da infraestrutura e aplicações do Smart City.

## 📋 Visão Geral

O ArgoCD é uma ferramenta de entrega contínua declarativa para Kubernetes que utiliza Git como fonte da verdade. Neste projeto, utilizamos o ArgoCD para automatizar o deploy e gerenciamento dos componentes da Smart City.

## 🏗️ Estrutura do Diretório

```
k8s/gitops/dev/
├── argocd-apps/          # Aplicações ArgoCD
├── argocd-projects/      # Projetos ArgoCD
├── argocd-config/        # Configurações específicas do ArgoCD
└── README.md            # Este arquivo
```

## 🚀 Instalação do ArgoCD

### Pré-requisitos
- Kubernetes cluster rodando
- kubectl configurado
- Helm (opcional, mas recomendado)

### Método 1: Instalação via Helm
```bash
# Adicionar repositório do ArgoCD
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update

# Criar namespace
kubectl create namespace argocd

# Instalar ArgoCD
helm install argocd argo/argo-cd \
  --namespace argocd \
  --set server.service.type=LoadBalancer \
  --set server.ingress.enabled=true \
  --set server.ingress.className=nginx

# Verificar instalação
kubectl get pods -n argocd
```

### Método 2: Instalação via kubectl
```bash
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

## 🔐 Acesso ao ArgoCD

### Obter senha inicial
```bash
# Para instalação via Helm
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

# Para instalação via kubectl
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

### Port-forward para acesso local
```bash
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

Acesse: https://localhost:8080
- **Usuário**: admin
- **Senha**: [senha obtida acima]

## ⚙️ Configuração

### 1. Configurar Repositório
No painel do ArgoCD:
1. Vá para **Settings > Repositories**
2. Clique em **Connect Repo**
3. Selecione **Via HTTPS**
4. URL: `https://github.com/alessandrorsseixas/git-ops-smart-city-org`
5. Username: [seu usuário GitHub]
6. Password: [seu token GitHub]

### 2. Criar Projeto
```yaml
# argocd-project-smartcity.yaml
apiVersion: argoproj.io/v1alpha1
kind: AppProject
metadata:
  name: smartcity
  namespace: argocd
spec:
  description: Smart City Infrastructure Project
  sourceRepos:
    - '*'
  destinations:
    - namespace: '*'
      server: '*'
  clusterResourceWhitelist:
    - group: '*'
      kind: '*'
```

### 3. Criar Aplicações

#### Infraestrutura Base
```yaml
# argocd-app-infra.yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: smartcity-infra
  namespace: argocd
spec:
  project: smartcity
  source:
    repoURL: https://github.com/alessandrorsseixas/git-ops-smart-city-org
    path: k8s/infra/dev
    targetRevision: HEAD
  destination:
    server: https://kubernetes.default.svc
    namespace: smartcity
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

#### Aplicações
```yaml
# argocd-app-apps.yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: smartcity-apps
  namespace: argocd
spec:
  project: smartcity
  source:
    repoURL: https://github.com/alessandrorsseixas/git-ops-smart-city-org
    path: k8s/apps/dev
    targetRevision: HEAD
  destination:
    server: https://kubernetes.default.svc
    namespace: smartcity
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

## 🔄 Sincronização

### Sincronização Manual
```bash
# Via CLI
argocd app sync smartcity-infra
argocd app sync smartcity-apps

# Via kubectl
kubectl apply -f k8s/gitops/dev/argocd-apps/
```

### Sincronização Automática
As aplicações estão configuradas com `syncPolicy.automated` habilitado, o que significa:
- **Prune**: Remove recursos não presentes no Git
- **Self Heal**: Corrige automaticamente desvios da configuração desejada

## 📊 Monitoramento

### Status das Aplicações
```bash
# Ver status
argocd app list

# Detalhes de uma aplicação
argocd app get smartcity-infra

# Ver logs de sincronização
argocd app logs smartcity-infra
```

### Health Checks
```bash
# Verificar health de todas as aplicações
kubectl get applications -n argocd

# Verificar recursos sincronizados
kubectl get all -n smartcity
```

## 🛠️ Desenvolvimento

### Fluxo de Trabalho
1. **Desenvolvimento**: Faça mudanças nos manifestos YAML
2. **Commit**: Envie as mudanças para o repositório Git
3. **Sincronização**: ArgoCD detecta mudanças e sincroniza automaticamente
4. **Verificação**: Monitore o status no painel do ArgoCD

### Branches
- `main`: Produção
- `develop`: Desenvolvimento
- `feature/*`: Funcionalidades específicas

## 🔧 Troubleshooting

### Aplicação não sincroniza
```bash
# Verificar status detalhado
argocd app get smartcity-infra --hard-refresh

# Forçar sincronização
argocd app sync smartcity-infra --force

# Ver logs
kubectl logs -n argocd deployment/argocd-application-controller
```

### Problemas de autenticação
```bash
# Atualizar credenciais do repositório
argocd repo update https://github.com/alessandrorsseixas/git-ops-smart-city-org

# Verificar conexão
argocd repo list
```

### Recursos órfãos
```bash
# Listar recursos órfãos
kubectl get all -n smartcity

# Limpar manualmente se necessário
kubectl delete [resource] [name] -n smartcity
```

## 📈 Escalabilidade

### Múltiplos Ambientes
Para diferentes ambientes (dev, staging, prod), crie aplicações separadas:
```yaml
# Para produção
spec:
  source:
    targetRevision: main
  destination:
    namespace: smartcity-prod
```

### Clusters Múltiplos
Para deploy em múltiplos clusters:
```yaml
spec:
  destination:
    server: https://cluster2.example.com
    namespace: smartcity
```

## 🔒 Segurança

### RBAC
Configure permissões específicas:
```yaml
# argocd-rbac.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: argocd-rbac-cm
  namespace: argocd
data:
  policy.csv: |
    p, role:developer, applications, get, */*, allow
    p, role:developer, applications, sync, */*, allow
    g, alice@example.com, role:developer
```

### Secrets
Use Sealed Secrets ou External Secrets Operator para gerenciar secrets sensíveis.

## 📚 Referências

- [Documentação Oficial ArgoCD](https://argo-cd.readthedocs.io/)
- [ArgoCD GitHub](https://github.com/argoproj/argo-cd)
- [Helm Chart ArgoCD](https://github.com/argoproj/argo-helm)

## 📞 Suporte

Para problemas específicos:
1. Verifique os logs do ArgoCD: `kubectl logs -n argocd deployment/argocd-application-controller`
2. Consulte a documentação oficial
3. Abra uma issue no repositório do projeto

---

**Nota**: Este README é específico para o ambiente de desenvolvimento. Para produção, considere configurações adicionais de segurança e alta disponibilidade.
