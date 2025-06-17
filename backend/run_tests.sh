#!/bin/bash
# Script para executar testes do backend Sophos Kodiak de forma organizada

set -e

echo "🧪 TESTES DO BACKEND SOPHOS KODIAK"
echo "=================================="
echo ""

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Função para imprimir status
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
    print_status "Ativando ambiente virtual..."
    source .venv/bin/activate
    print_success "Ambiente virtual ativado"
elif [[ -f "venv/bin/activate" ]]; then
    print_status "Ativando ambiente virtual..."
    source venv/bin/activate
    print_success "Ambiente virtual ativado"
else
    print_warning "Ambiente virtual não encontrado, usando Python do sistema"
fi

# Verificar se pytest está disponível
if ! command -v pytest &> /dev/null; then
    print_error "pytest não encontrado. Instale com: pip install pytest"
    print_status "Tentando instalar pytest automaticamente..."
    if pip install pytest pytest-cov pytest-mock; then
        print_success "pytest instalado com sucesso"
    else
        print_error "Falha ao instalar pytest. Instale manualmente."
        exit 1
    fi
fi

# Função para executar testes com timing
run_tests() {
    local test_name="$1"
    local test_command="$2"
    local optional="$3"

    echo ""
    print_status "Executando: $test_name"
    echo "Comando: $test_command"
    echo "----------------------------------------"

    start_time=$(date +%s)

    if eval "$test_command"; then
        end_time=$(date +%s)
        duration=$((end_time - start_time))
        print_success "$test_name concluído em ${duration}s"
        return 0
    else
        end_time=$(date +%s)
        duration=$((end_time - start_time))
        if [[ "$optional" == "optional" ]]; then
            print_warning "$test_name falhou em ${duration}s (opcional)"
            return 0
        else
            print_error "$test_name falhou em ${duration}s"
            return 1
        fi
    fi
}

# Processar argumentos
QUICK_MODE=false
FULL_MODE=false
SMOKE_ONLY=false
CRITICAL_ONLY=false
SKIP_OPTIONAL=false
AUTO_DISCOVER=false
UNIT_ONLY=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --quick|-q)
            QUICK_MODE=true
            shift
            ;;
        --full|-f)
            FULL_MODE=true
            shift
            ;;
        --smoke|-s)
            SMOKE_ONLY=true
            shift
            ;;
        --critical|-c)
            CRITICAL_ONLY=true
            shift
            ;;
        --unit|-u)
            UNIT_ONLY=true
            shift
            ;;
        --skip-optional)
            SKIP_OPTIONAL=true
            shift
            ;;
        --auto-discover|-a)
            AUTO_DISCOVER=true
            shift
            ;;
        --help|-h)
            echo "Uso: $0 [opções]"
            echo ""
            echo "Opções:"
            echo "  --quick, -q          Execução rápida (smoke + críticos)"
            echo "  --full, -f           Execução completa (todos os testes)"
            echo "  --smoke, -s          Apenas smoke tests"
            echo "  --critical, -c       Apenas testes críticos"
            echo "  --unit, -u           Apenas testes unitários"
            echo "  --auto-discover, -a  Descobrir e executar todos os testes automaticamente"
            echo "  --skip-optional      Pular testes opcionais"
            echo "  --help, -h           Mostrar esta ajuda"
            echo ""
            echo "Exemplos:"
            echo "  $0 --quick          # Verificação rápida"
            echo "  $0 --full           # Teste completo"
            echo "  $0 --unit           # Apenas testes unitários"
            echo "  $0 --auto-discover  # Descobrir e executar todos automaticamente"
            echo "  $0 --smoke          # Apenas verificações básicas"
            exit 0
            ;;
        *)
            print_error "Opção desconhecida: $1"
            print_error "Use --help para ver opções disponíveis"
            exit 1
            ;;
    esac
done

# Determinar quais testes executar
if [[ "$AUTO_DISCOVER" == true ]]; then
    print_status "Modo: Descoberta Automática de Testes"
    TESTS_TO_RUN="auto_discover"
elif [[ "$SMOKE_ONLY" == true ]]; then
    print_status "Modo: Apenas Smoke Tests"
    TESTS_TO_RUN="smoke"
elif [[ "$CRITICAL_ONLY" == true ]]; then
    print_status "Modo: Apenas Testes Críticos"
    TESTS_TO_RUN="critical"
elif [[ "$UNIT_ONLY" == true ]]; then
    print_status "Modo: Apenas Testes Unitários"
    TESTS_TO_RUN="unit"
elif [[ "$QUICK_MODE" == true ]]; then
    print_status "Modo: Execução Rápida (Smoke + Críticos)"
    TESTS_TO_RUN="quick"
elif [[ "$FULL_MODE" == true ]]; then
    print_status "Modo: Execução Completa"
    TESTS_TO_RUN="full"
else
    print_status "Modo: Execução Padrão (Smoke + Críticos + Unitários + Básicos)"
    TESTS_TO_RUN="default"
fi

echo ""

# Configurar pytest arguments base
PYTEST_ARGS="--tb=short -v"
if [[ "$SKIP_OPTIONAL" == true ]]; then
    PYTEST_ARGS="$PYTEST_ARGS -m 'not external'"
fi

# Executar testes baseado no modo
SUCCESS_COUNT=0
TOTAL_COUNT=0

case "$TESTS_TO_RUN" in
    smoke)
        TOTAL_COUNT=1
        run_tests "🚀 Smoke Tests" "pytest -m smoke $PYTEST_ARGS" && ((SUCCESS_COUNT++))
        ;;

    critical)
        TOTAL_COUNT=1
        run_tests "🔥 Testes Críticos" "pytest -m critical $PYTEST_ARGS" && ((SUCCESS_COUNT++))
        ;;

    unit)
        TOTAL_COUNT=2
        run_tests "🧠 Testes Unitários - NLP" "pytest tests/unit/test_nlp_processing.py $PYTEST_ARGS" && ((SUCCESS_COUNT++))
        run_tests "🗺️ Testes Unitários - Query Mapping" "pytest tests/unit/test_query_mapping.py $PYTEST_ARGS" && ((SUCCESS_COUNT++))
        ;;

    quick)
        TOTAL_COUNT=2
        run_tests "🚀 Smoke Tests" "pytest -m smoke $PYTEST_ARGS" && ((SUCCESS_COUNT++))
        run_tests "🔥 Testes Críticos" "pytest -m critical $PYTEST_ARGS" && ((SUCCESS_COUNT++))
        ;;

    default)
        TOTAL_COUNT=6
        run_tests "🚀 Smoke Tests" "pytest -m smoke $PYTEST_ARGS" && ((SUCCESS_COUNT++))
        run_tests "🔥 Testes Críticos" "pytest -m critical $PYTEST_ARGS" && ((SUCCESS_COUNT++))
        run_tests "🏗️ Infraestrutura" "pytest -m infrastructure $PYTEST_ARGS" "optional" && ((SUCCESS_COUNT++))
        run_tests "🌐 Endpoints API" "pytest -m api $PYTEST_ARGS" && ((SUCCESS_COUNT++))
        run_tests "🧠 Testes Unitários - NLP" "pytest tests/unit/test_nlp_processing.py $PYTEST_ARGS" && ((SUCCESS_COUNT++))
        run_tests "🗺️ Testes Unitários - Query Mapping" "pytest tests/unit/test_query_mapping.py $PYTEST_ARGS" && ((SUCCESS_COUNT++))
        ;;

    auto_discover)
        print_status "🔍 Descobrindo todos os arquivos de teste..."

        # Encontrar todos os arquivos de teste
        ALL_TEST_FILES=($(find tests/ -name "test_*.py" -type f | sort))

        if [[ ${#ALL_TEST_FILES[@]} -eq 0 ]]; then
            print_error "Nenhum arquivo de teste encontrado"
            exit 1
        fi

        print_status "Encontrados ${#ALL_TEST_FILES[@]} arquivos de teste:"
        for test_file in "${ALL_TEST_FILES[@]}"; do
            echo "  • $test_file"
        done
        echo ""

        TOTAL_COUNT=${#ALL_TEST_FILES[@]}

        # Executar cada arquivo de teste individualmente
        for test_file in "${ALL_TEST_FILES[@]}"; do
            test_name="📝 $(basename "$test_file" .py | sed 's/test_//' | tr '_' ' ' | sed 's/\b\w/\U&/g')"
            run_tests "$test_name" "pytest $test_file $PYTEST_ARGS" && ((SUCCESS_COUNT++))
        done
        ;;

    full)
        TOTAL_COUNT=12
        run_tests "🚀 Smoke Tests" "pytest -m smoke $PYTEST_ARGS" && ((SUCCESS_COUNT++))
        run_tests "🔥 Testes Críticos" "pytest -m critical $PYTEST_ARGS" && ((SUCCESS_COUNT++))
        run_tests "🏗️ Infraestrutura Básica" "pytest tests/test_infrastructure.py $PYTEST_ARGS" "optional" && ((SUCCESS_COUNT++))
        run_tests "🔒 Infraestrutura Crítica" "pytest tests/test_critical_infrastructure.py $PYTEST_ARGS" && ((SUCCESS_COUNT++))
        run_tests "📊 Qualidade dos Dados" "pytest tests/test_data_quality.py $PYTEST_ARGS" "optional" && ((SUCCESS_COUNT++))
        run_tests "🌐 Endpoints API" "pytest tests/test_endpoints.py $PYTEST_ARGS" && ((SUCCESS_COUNT++))
        run_tests "🎭 Cenários Reais" "pytest tests/test_real_scenarios.py $PYTEST_ARGS" "optional" && ((SUCCESS_COUNT++))
        run_tests "💨 Smoke Tests Específicos" "pytest tests/test_smoke.py $PYTEST_ARGS" && ((SUCCESS_COUNT++))
        run_tests "🧠 Testes Unitários - NLP" "pytest tests/unit/test_nlp_processing.py $PYTEST_ARGS" && ((SUCCESS_COUNT++))
        run_tests "🗺️ Testes Unitários - Query Mapping" "pytest tests/unit/test_query_mapping.py $PYTEST_ARGS" && ((SUCCESS_COUNT++))
        run_tests "📂 Todos os Testes Unitários" "pytest tests/unit/ $PYTEST_ARGS" && ((SUCCESS_COUNT++))
        run_tests "⚡ Performance" "pytest -m performance $PYTEST_ARGS" "optional" && ((SUCCESS_COUNT++))
        ;;
esac

# Verificar cobertura de arquivos de teste
echo ""
print_status "🔍 Verificando cobertura de arquivos de teste..."

# Listar todos os arquivos de teste disponíveis
TEST_FILES=(
    "tests/test_smoke.py"
    "tests/test_critical_infrastructure.py"
    "tests/test_infrastructure.py"
    "tests/test_data_quality.py"
    "tests/test_endpoints.py"
    "tests/test_real_scenarios.py"
    "tests/unit/test_nlp_processing.py"
    "tests/unit/test_query_mapping.py"
)

MISSING_TESTS=""
AVAILABLE_TESTS=""

for test_file in "${TEST_FILES[@]}"; do
    if [[ -f "$test_file" ]]; then
        AVAILABLE_TESTS="$AVAILABLE_TESTS $test_file"

        # Verificar se o arquivo foi executado no modo atual
        case "$TESTS_TO_RUN" in
            smoke)
                if [[ "$test_file" != "tests/test_smoke.py" ]]; then
                    MISSING_TESTS="$MISSING_TESTS $test_file"
                fi
                ;;
            critical)
                if [[ "$test_file" != "tests/test_critical_infrastructure.py" ]]; then
                    MISSING_TESTS="$MISSING_TESTS $test_file"
                fi
                ;;
            unit)
                if [[ "$test_file" != "tests/unit/test_nlp_processing.py" && "$test_file" != "tests/unit/test_query_mapping.py" ]]; then
                    MISSING_TESTS="$MISSING_TESTS $test_file"
                fi
                ;;
            quick)
                if [[ "$test_file" != "tests/test_smoke.py" && "$test_file" != "tests/test_critical_infrastructure.py" ]]; then
                    MISSING_TESTS="$MISSING_TESTS $test_file"
                fi
                ;;
            default)
                if [[ "$test_file" == "tests/test_data_quality.py" || "$test_file" == "tests/test_real_scenarios.py" ]]; then
                    MISSING_TESTS="$MISSING_TESTS $test_file"
                fi
                ;;
            full)
                # No modo full, todos devem estar cobertos
                ;;
        esac
    else
        print_warning "Arquivo de teste não encontrado: $test_file"
    fi
done

# Relatório de cobertura
echo ""
print_status "📋 Relatório de Cobertura de Testes:"
echo "Arquivos de teste disponíveis: $(echo $AVAILABLE_TESTS | wc -w)"

if [[ -n "$MISSING_TESTS" && "$TESTS_TO_RUN" != "full" ]]; then
    print_warning "Arquivos de teste não executados neste modo ($TESTS_TO_RUN):"
    for file in $MISSING_TESTS; do
        echo "  • $file"
    done
    echo ""
    print_status "💡 Use --full para executar todos os testes disponíveis"
else
    print_success "Todos os testes relevantes para o modo '$TESTS_TO_RUN' foram executados"
fi

# Verificar se há testes adicionais não catalogados
UNCATALOGUED_TESTS=$(find tests/ -name "test_*.py" -type f | grep -v -E "($(echo "${TEST_FILES[@]}" | tr ' ' '|'))" || true)

if [[ -n "$UNCATALOGUED_TESTS" ]]; then
    echo ""
    print_warning "Arquivos de teste encontrados que não estão no script:"
    echo "$UNCATALOGUED_TESTS" | while read -r test_file; do
        echo "  • $test_file"
    done
    print_status "💡 Considere adicionar estes testes ao script run_tests.sh"
fi

# Relatório final
echo ""
echo "========================================"
echo "📊 RELATÓRIO FINAL"
echo "========================================"

if [[ $SUCCESS_COUNT -eq $TOTAL_COUNT ]]; then
    print_success "Todos os testes passaram! ($SUCCESS_COUNT/$TOTAL_COUNT)"
    EXIT_CODE=0
else
    FAILED_COUNT=$((TOTAL_COUNT - SUCCESS_COUNT))
    print_error "$FAILED_COUNT de $TOTAL_COUNT grupos de teste falharam"
    EXIT_CODE=1
fi

echo ""
echo "🎯 Próximos passos recomendados:"

if [[ "$TESTS_TO_RUN" == "smoke" ]]; then
    echo "  • Execute testes críticos: $0 --critical"
    echo "  • Para verificação completa: $0 --full"
    echo "  • Para descoberta automática: $0 --auto-discover"
elif [[ "$TESTS_TO_RUN" == "critical" ]]; then
    echo "  • Execute verificação rápida: $0 --quick"
    echo "  • Para testes unitários: $0 --unit"
    echo "  • Para auditoria completa: $0 --full"
    echo "  • Para descoberta automática: $0 --auto-discover"
elif [[ "$TESTS_TO_RUN" == "unit" ]]; then
    echo "  • Execute verificação rápida: $0 --quick"
    echo "  • Para testes críticos: $0 --critical"
    echo "  • Para auditoria completa: $0 --full"
    echo "  • Para descoberta automática: $0 --auto-discover"
elif [[ "$TESTS_TO_RUN" == "quick" ]]; then
    echo "  • Execute suite completa: $0 --full"
    echo "  • Para testes unitários: $0 --unit"
    echo "  • Para descoberta automática: $0 --auto-discover"
    echo "  • Para auditoria de dados: pytest -m data_quality -v"
elif [[ "$TESTS_TO_RUN" == "default" ]]; then
    echo "  • Execute suite completa: $0 --full"
    echo "  • Para testes unitários apenas: $0 --unit"
    echo "  • Para descoberta automática: $0 --auto-discover"
    echo "  • Para testes de carga: pytest -m performance -v"
elif [[ "$TESTS_TO_RUN" == "auto_discover" ]]; then
    echo "  • Execute por categoria: $0 --smoke, $0 --critical, etc."
    echo "  • Para verificação rápida: $0 --quick"
    echo "  • Para suite organizada: $0 --full"
else
    echo "  • Para execução rápida: $0 --quick"
    echo "  • Para testes unitários: $0 --unit"
    echo "  • Para descoberta automática: $0 --auto-discover"
    echo "  • Para smoke tests: $0 --smoke"
fi

echo ""
echo "📖 Documentação: tests/README.md"
echo "🔧 Configuração: pytest.ini"
echo "🎯 Modo usado: $TESTS_TO_RUN"
echo "📊 Cobertura: htmlcov/index.html (após execução completa)"

exit $EXIT_CODE
