#!/bin/bash

echo "=== Configuração do Ambiente Sophos Kodiak ==="
echo

# Verifica se está sendo executado no diretório correto
if [ ! -f "run.py" ]; then
    echo "❌ Erro: Execute este script do diretório backend/"
    exit 1
fi

echo "📦 Verificando dependências Python..."

# Verifica se Python3 está instalado
if ! command -v python3 &> /dev/null; then
    echo "❌ Erro: Python3 não encontrado"
    echo "💡 Instale o Python3 antes de continuar"
    exit 1
fi

if [ -z "$VIRTUAL_ENV" ]; then
    echo "⚠️  Aviso: Nenhum ambiente virtual detectado"
    echo "💡 Recomendamos usar um ambiente virtual"
    echo
fi

echo "📥 Instalando dependências..."
if ! pip install -r requirements.txt; then
    echo "❌ Erro ao instalar dependências"
    echo "💡 Verifique se o arquivo requirements.txt existe e está correto"
    exit 1
fi

echo
echo "🔧 Verificando arquivo .env..."

if [ ! -f ".env" ]; then
    echo "❌ Arquivo .env não encontrado!"
    echo "💡 Crie um arquivo .env com as seguintes variáveis:"
    echo "   DB_HOST=seu_host_supabase"
    echo "   DB_PORT=6543"
    echo "   DB_NAME=postgres"
    echo "   DB_USER=seu_usuario"
    echo "   DB_PASSWORD=sua_senha"
    echo "   GEMINI_API_KEY=sua_chave_gemini"
    exit 1
fi

echo "🔍 Verificando variáveis de ambiente..."

# Função reutilizável para carregar variáveis de ambiente
load_env_vars() {
    python3 -c "
from dotenv import load_dotenv
import os
load_dotenv()
$1
"
}

load_env_vars "
required_vars = ['DB_HOST', 'DB_PORT', 'DB_NAME', 'DB_USER', 'DB_PASSWORD', 'GEMINI_API_KEY']
missing = []

for var in required_vars:
    if not os.getenv(var):
        missing.append(var)

if missing:
    print(f'❌ Variáveis faltando: {missing}')
    exit(1)
else:
    print('✅ Todas as variáveis estão definidas')
"

if [ $? -ne 0 ]; then
    exit 1
fi

echo
echo "🌐 Testando conectividade..."

load_env_vars "
import psycopg2

try:
    conn = psycopg2.connect(
        host=os.getenv('DB_HOST'),
        port=os.getenv('DB_PORT', 6543),
        dbname=os.getenv('DB_NAME'),
        user=os.getenv('DB_USER'),
        password=os.getenv('DB_PASSWORD'),
        sslmode='require',
        connect_timeout=10
    )
    cur = conn.cursor()
    cur.execute('SELECT 1')
    cur.close()
    conn.close()
    print('✅ Conexão com banco de dados: OK')
except Exception as e:
    print(f'❌ Erro de conexão com BD: {e}')
    exit(1)
"

if [ $? -ne 0 ]; then
    echo "💡 Verifique suas credenciais do Supabase"
    exit 1
fi

echo
echo "🚀 Configuração concluída com sucesso!"
echo
echo "📋 Próximos passos:"
echo "   1. Execute: python run.py"
echo "   2. No Flutter, use o IP: http://10.0.2.2:5000"
echo "   3. Teste a conectividade usando a página de teste no app"
echo
echo "🐛 Para debug:"
echo "   - Logs do Flask: terminal onde rodou python run.py"
echo "   - Teste endpoints: curl http://localhost:5000/health"
echo "   - Teste no emulador: usar a página 'Teste Rede' no app"
echo
