#!/bin/bash
# Script para executar testes com análise real do código
# Este script desabilita todos os mocks para permitir análise real

echo "🔍 TESTE DE ANÁLISE REAL DO CÓDIGO SOPHOS KODIAK"
echo "================================================="
echo ""

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Verificar se estamos no diretório correto
if [[ ! -f "pytest.ini" ]]; then
    print_error "Execute este script do diretório backend/"
    exit 1
fi

# Ativar ambiente virtual se existir
if [[ -f ".venv/bin/activate" ]]; then
    print_status "💡 Ativando ambiente virtual..."
    source .venv/bin/activate
    print_success "Ambiente virtual ativado"
elif [[ -f "venv/bin/activate" ]]; then
    print_status "💡 Ativando ambiente virtual..."
    source venv/bin/activate
    print_success "Ambiente virtual ativado"
else
    print_warning "Ambiente virtual não encontrado, tentando python do sistema"
fi

# Verificar se pytest está disponível
if ! command -v pytest &> /dev/null; then
    print_error "pytest não encontrado. Instale com: pip install pytest"
    print_status "💡 Tentando instalar pytest automaticamente..."
    if pip install pytest pytest-cov pytest-mock; then
        print_success "pytest instalado com sucesso"
    else
        print_error "Falha ao instalar pytest. Instale manualmente."
        exit 1
    fi
fi

print_status "🔧 Configurando ambiente para análise real do código..."

# Configurar variáveis para testes reais (sem mocks)
export ANALYZE_REAL_CODE=true
export VALIDATE_ACTUAL_LOGIC=true
export TEST_REAL_SCENARIOS=true
export ENABLE_REAL_API_TESTS=true
export ENABLE_DATABASE_TESTS=true
export FLASK_ENV=testing

# NÃO usar mocks (comentar as linhas abaixo se quiser forçar mocks)
# export ENABLE_MOCK_RESPONSES=false
# export SKIP_EXTERNAL_APIS=false
# export USE_MEMORY_CACHE=false

print_success "Ambiente configurado para análise real"
print_status "Flask ENV: ${FLASK_ENV}"
print_status "Análise real: ${ANALYZE_REAL_CODE}"

echo ""
print_status "🧪 Executando testes para analisar código real..."

# Executar testes que analisam o código real
pytest -v \
    --tb=short \
    -m "not external" \
    --maxfail=10 \
    --durations=10 \
    --cov=app \
    --cov-report=html \
    --cov-report=term-missing \
    tests/

RESULT=$?

echo ""
if [[ $RESULT -eq 0 ]]; then
    print_success "✅ Análise real do código concluída com sucesso!"
    print_status "📊 Relatório de cobertura: htmlcov/index.html"
else
    print_error "❌ Alguns testes falharam durante a análise real"
fi

echo ""
echo "📋 O que foi analisado:"
echo "  • Lógica real de processamento NLP"
echo "  • Queries SQL reais executadas no banco"
echo "  • Comportamento real dos endpoints Flask"
echo "  • Integração real entre componentes"
echo "  • Validação de dados reais"
echo "  • Performance com cargas reais"

echo ""
echo "🎯 Próximos passos:"
echo "  • Revise o relatório de cobertura"
echo "  • Analise os logs dos testes para entender o comportamento"
echo "  • Execute testes específicos com: pytest tests/specific_test.py -v -s"

exit $RESULT
