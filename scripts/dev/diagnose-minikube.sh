#!/bin/bash

# diagnose-minikube.sh
# Script para diagnosticar e resolver problemas comuns do Minikube
# Também pode ser usado para limpar e reinicializar o Minikube completamente

set -e

# Parâmetros de configuração padrão do Minikube
MINIKUBE_DRIVER="docker"
MINIKUBE_CPUS="2"
MINIKUBE_MEMORY="6144mb"
MINIKUBE_DISK_SIZE="20gb"

usage() {
    cat <<EOF
Usage: $(basename "$0") [--reset] [--start] [-h]

Options:
  --reset    Remove completamente o cluster existente e cria um novo
  --start    Apenas inicia o Minikube se não estiver rodando
  -h         Mostra esta ajuda

Sem opções, executa apenas diagnóstico.
EOF
}

RESET_MODE=false
START_MODE=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --reset) RESET_MODE=true; shift;;
        --start) START_MODE=true; shift;;
        -h) usage; exit 0;;
        *) echo "Opção desconhecida: $1" >&2; usage; exit 1;;
    esac
done

echo "🔍 Diagnóstico do Minikube para Smart City GitOps"
echo "================================================="
echo ""

# Verificar se Minikube está instalado
echo "📋 1. Verificando instalação do Minikube..."
if command -v minikube &> /dev/null; then
    MINIKUBE_VERSION=$(minikube version | grep minikube | cut -d' ' -f3)
    echo "✅ Minikube instalado - versão: $MINIKUBE_VERSION"
else
    echo "❌ Minikube não está instalado"
    echo "💡 Instale com: curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64 && sudo install minikube-linux-amd64 /usr/local/bin/minikube"
    exit 1
fi

# Verificar Docker
echo ""
echo "📋 2. Verificando Docker..."
if command -v docker &> /dev/null; then
    if docker ps &> /dev/null; then
        echo "✅ Docker está rodando"
        echo "🔍 Containers Docker ativos:"
        docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
    else
        echo "❌ Docker não está acessível (permissões ou não está rodando)"
        echo "💡 Soluções:"
        echo "   - Adicionar usuário ao grupo docker: sudo usermod -aG docker \$USER"
        echo "   - Reiniciar Docker: sudo systemctl restart docker"
        echo "   - Login novamente após adicionar ao grupo docker"
    fi
else
    echo "❌ Docker não está instalado"
    exit 1
fi

# Status do Minikube
echo ""
echo "📋 3. Status atual do Minikube..."
if minikube status &> /dev/null; then
    echo "✅ Minikube está rodando"
    minikube status
else
    echo "⚠️ Minikube não está rodando"
    
    # Verificar se existe um cluster parado
    if minikube profile list &> /dev/null; then
        echo "🔍 Clusters Minikube disponíveis:"
        minikube profile list
    fi
fi

# Verificar recursos do sistema
echo ""
echo "📋 4. Recursos do sistema..."
echo "💾 Memória disponível:"
free -h | grep -E "^Mem|^Swap"
echo ""
echo "💻 CPU disponível:"
nproc --all
echo " cores detectados"

# Verificar espaço em disco
echo ""
echo "💽 Espaço em disco:"
df -h | grep -E "^/dev|^Filesystem" | head -2

# Verificar se há containers Minikube órfãos
echo ""
echo "📋 5. Verificando containers Minikube..."
MINIKUBE_CONTAINERS=$(docker ps -a | grep minikube || echo "Nenhum container minikube encontrado")
echo "$MINIKUBE_CONTAINERS"

# Limpar containers órfãos se houver
if docker ps -a | grep -q minikube; then
    echo ""
    echo "🧹 Containers minikube encontrados. Deseja limpar? (y/N)"
    read -n 1 -r
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo ""
        echo "🧹 Limpando containers minikube órfãos..."
        docker ps -a | grep minikube | awk '{print $1}' | xargs -r docker rm -f
        echo "✅ Containers limpos"
    fi
fi

# Verificar logs do Minikube se existir
echo ""
echo "📋 6. Verificando logs do Minikube..."
if minikube logs --length=10 2>/dev/null | head -5; then
    echo "✅ Logs acessíveis (mostrando apenas primeiras 5 linhas)"
    echo "💡 Para ver logs completos: minikube logs"
else
    echo "⚠️ Não foi possível acessar logs do Minikube"
fi

# Sugestões de solução
echo ""
echo "🛠️ SOLUÇÕES RECOMENDADAS:"
echo "========================"
echo ""

if ! minikube status &> /dev/null; then
    echo "🚀 Para iniciar Minikube:"
    echo "   ./diagnose-minikube.sh --start"
    echo ""
    echo "🧹 Para limpar e recomeçar completamente:"
    echo "   ./diagnose-minikube.sh --reset"
    echo ""
    echo "🛠️ Comandos manuais (se necessário):"
    echo "   minikube start --driver=docker --cpus=2 --memory=4096mb --disk-size=20gb"
    echo ""
fi

echo "🔧 Comandos úteis para troubleshooting:"
echo "   minikube status           # Ver status atual"
echo "   minikube logs            # Ver logs do cluster"
echo "   minikube dashboard       # Abrir dashboard web"
echo "   minikube ip              # Obter IP do cluster"
echo "   minikube addons list     # Ver addons disponíveis"
echo "   minikube profile list    # Ver perfis/clusters"
echo ""

echo "🚨 Em caso de problemas persistentes:"
echo "   1. Reiniciar Docker: sudo systemctl restart docker"
echo "   2. Limpar tudo: minikube delete && docker system prune -f"
echo "   3. Reiniciar sistema"
echo "   4. Executar novamente: ./run.sh"
echo ""

# Executar ações baseadas nos parâmetros
if [ "$RESET_MODE" = true ]; then
    echo ""
    echo "🔄 MODO RESET: Removendo cluster existente e criando novo..."
    echo "=========================================================="
    
    # Parar e deletar cluster existente
    echo "🛑 Parando cluster existente..."
    minikube stop 2>/dev/null || echo "⚠️ Nenhum cluster para parar"
    
    echo "🗑️ Removendo cluster existente..."
    minikube delete 2>/dev/null || echo "⚠️ Nenhum cluster para remover"
    
    # Limpar containers Docker órfãos
    echo "🧹 Limpando containers Docker órfãos..."
    docker ps -a | grep minikube | awk '{print $1}' | xargs -r docker rm -f 2>/dev/null || echo "⚠️ Nenhum container órfão encontrado"
    
    # Criar novo cluster
    echo ""
    echo "🚀 Criando novo cluster Minikube..."
    echo "   Configuração: --driver=$MINIKUBE_DRIVER --cpus=$MINIKUBE_CPUS --memory=$MINIKUBE_MEMORY --disk-size=$MINIKUBE_DISK_SIZE"
    
    minikube start --driver=$MINIKUBE_DRIVER --cpus=$MINIKUBE_CPUS --memory=$MINIKUBE_MEMORY --disk-size=$MINIKUBE_DISK_SIZE || {
        echo "❌ Falha ao iniciar novo cluster Minikube"
        echo "💡 Verifique se Docker está funcionando: docker ps"
        exit 1
    }
    
    echo "✅ Novo cluster Minikube criado com sucesso!"
    
    # Mostrar status final
    echo ""
    echo "� Status do novo cluster:"
    minikube status
    echo ""
    echo "🌐 IP do cluster: $(minikube ip)"
    
elif [ "$START_MODE" = true ]; then
    echo ""
    echo "🚀 MODO START: Verificando e iniciando Minikube..."
    echo "================================================="
    
    if minikube status &> /dev/null; then
        echo "✅ Minikube já está rodando"
        minikube status
    else
        echo "🚀 Iniciando Minikube..."
        minikube start --driver=$MINIKUBE_DRIVER --cpus=$MINIKUBE_CPUS --memory=$MINIKUBE_MEMORY --disk-size=$MINIKUBE_DISK_SIZE || {
            echo "❌ Falha ao iniciar Minikube"
            echo "💡 Tente usar --reset para limpar e recriar"
            exit 1
        }
        echo "✅ Minikube iniciado com sucesso!"
    fi
    
    echo "🌐 IP do cluster: $(minikube ip)"
fi

echo ""
echo "✅ Diagnóstico concluído!"
if [ "$RESET_MODE" = false ] && [ "$START_MODE" = false ]; then
    echo "💡 Use --reset para limpar e recriar ou --start para apenas iniciar"
fi
