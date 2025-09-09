# Configuração DNS para PostgreSQL Externo
# Adicione estas entradas ao seu provedor de DNS

# Para acesso direto via LoadBalancer
# Substitua IP_LOADBALANCER pelo IP real do LoadBalancer
postgres.dev.smartcity.local. IN A IP_LOADBALANCER

# Para acesso via Ingress (se usar nginx-ingress)
# A entrada A deve apontar para o IP do LoadBalancer do nginx-ingress
# postgres.dev.smartcity.local. IN A IP_NGINX_INGRESS

# Exemplo de configuração no /etc/hosts (apenas para desenvolvimento local)
# 192.168.1.100 postgres.dev.smartcity.local

# Verificar configuração DNS
# nslookup postgres.dev.smartcity.local
# dig postgres.dev.smartcity.local

# Testar conectividade
# telnet postgres.dev.smartcity.local 5432
# nc -zv postgres.dev.smartcity.local 5432
