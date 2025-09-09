#!/bin/bash
# Script para testar conectividade externa do PostgreSQL

set -e

# Configurações
EXTERNAL_HOST="postgres.dev.smartcity.local"
EXTERNAL_PORT="5432"
DB_USER="smartcity"
DB_NAME="smartcity"
DB_PASSWORD="smartcity123"

echo "🔍 Testando conectividade externa do PostgreSQL..."
echo "Host: $EXTERNAL_HOST:$EXTERNAL_PORT"
echo "Database: $DB_NAME"
echo "User: $DB_USER"
echo

# Teste 1: Verificar se a porta está aberta
echo "1️⃣ Testando conectividade de rede..."
if nc -z -w5 $EXTERNAL_HOST $EXTERNAL_PORT 2>/dev/null; then
    echo "✅ Porta $EXTERNAL_PORT está aberta em $EXTERNAL_HOST"
else
    echo "❌ Porta $EXTERNAL_PORT não está acessível em $EXTERNAL_HOST"
    echo "   Verifique se o LoadBalancer está funcionando e o DNS está configurado"
    exit 1
fi

# Teste 2: Verificar certificado SSL (se disponível)
echo
echo "2️⃣ Testando certificado SSL..."
if openssl s_client -connect $EXTERNAL_HOST:$EXTERNAL_PORT -servername $EXTERNAL_HOST </dev/null 2>/dev/null | openssl x509 -noout -dates 2>/dev/null; then
    echo "✅ Certificado SSL válido"
else
    echo "⚠️  Certificado SSL não encontrado ou inválido"
fi

# Teste 3: Tentar conexão com banco de dados
echo
echo "3️⃣ Testando conexão com banco de dados..."
export PGPASSWORD="$DB_PASSWORD"

if psql -h $EXTERNAL_HOST -p $EXTERNAL_PORT -U $DB_USER -d $DB_NAME -c "SELECT version();" >/dev/null 2>&1; then
    echo "✅ Conexão com banco de dados estabelecida com sucesso"

    # Teste 4: Executar query simples
    echo
    echo "4️⃣ Executando query de teste..."
    psql -h $EXTERNAL_HOST -p $EXTERNAL_PORT -U $DB_USER -d $DB_NAME -c "SELECT current_database(), current_user, now();" -t
    echo "✅ Query executada com sucesso"
else
    echo "❌ Falha na conexão com banco de dados"
    echo "   Verifique as credenciais e configurações de rede"
    exit 1
fi

echo
echo "🎉 Todos os testes passaram! PostgreSQL está acessível externamente."
echo
echo "📋 Informações de conexão:"
echo "   Host: $EXTERNAL_HOST:$EXTERNAL_PORT"
echo "   Database: $DB_NAME"
echo "   User: $DB_USER"
echo "   Connection String: postgresql://$DB_USER:$DB_PASSWORD@$EXTERNAL_HOST:$EXTERNAL_PORT/$DB_NAME"
