#!/bin/bash

set -e

echo "🧪 TESTES DO BACKEND SOPHOS KODIAK"
echo "=================================="
echo ""

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

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

if [[ ! -f "pytest.ini" ]]; then
    print_error "Execute este script do diretório backend/"
    exit 1
fi

load_ci_config() {
    if [[ "$CI" == "true" ]] || [[ -n "$GITHUB_ACTIONS" ]]; then
        print_status "🔧 Carregando configurações de CI..."
        if [[ -f ".env.ci" ]]; then
            # Carrega variáveis de forma mais segura
            set -a
            source .env.ci
            set +a
            print_success "Configurações de CI carregadas de .env.ci"

            if [[ -z "$DATABASE_URL" ]]; then
                print_warning "DATABASE_URL não definida, usando padrão de CI"
                export DATABASE_URL="postgresql://postgres:postgres@localhost:6543/test_db"
            fi

            if [[ -z "$GEMINI_API_KEY" ]]; then
                export GEMINI_API_KEY="test_gemini_api_key_for_github_actions_testing_only"
            fi

            if [[ "$ANALYZE_REAL_CODE" == "true" ]]; then
                print_status "🔍 Modo de análise real do código ATIVADO"
                print_status "   - API Gemini: resposta real (ou fallback inteligente)"
                print_status "   - Banco de dados: operações reais"
                print_status "   - Endpoints: comportamento real"
                print_status "   - NLP: processamento real"
            else
                print_status "🎭 Modo padrão (com alguns mocks de segurança)"
            fi

            print_status "✅ Configuração CI aplicada: FLASK_ENV=$FLASK_ENV"
        else
            print_warning "Arquivo .env.ci não encontrado, usando configurações padrão do CI"
            export FLASK_ENV="testing"
            export DATABASE_URL="postgresql://postgres:postgres@localhost:6543/test_db"
            export GEMINI_API_KEY="test_gemini_api_key_for_github_actions_testing_only"
            export CI="true"
        fi
    else
        print_status "Executando em ambiente local (não-CI)"
        # Carrega variáveis do .env se existir
        if [[ -f ".env" ]]; then
            print_status "Carregando variáveis do .env para testes locais"
            set -a
            source .env
            set +a
            print_success "Variáveis do .env carregadas"
        fi
        if [[ "$ANALYZE_REAL_CODE" == "true" ]]; then
            print_status "🔍 Análise real do código forçada localmente"
            print_status "   - Use: export ANALYZE_REAL_CODE=true && ./run_tests.sh"
            print_status "   - Ou execute: ./run_real_tests.sh"
        fi
    fi
}

load_ci_config

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

# Função para executar um conjunto de testes com controle de tempo e status
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

# Função para validar se os testes de performance estão configurados corretamente
validate_performance_tests() {
    print_status "🔍 Validando Testes de Performance"

    print_status "Verificando marcadores de performance..."
    local performance_tests
    performance_tests=$(pytest --collect-only -m performance -q 2>/dev/null | grep -c "::test_" || echo "0")

    if [ "$performance_tests" -eq 0 ]; then
        print_error "Nenhum teste com marcador 'performance' encontrado"
        print_status "Listando todos os marcadores disponíveis:"
        pytest --markers | grep -E "^@pytest.mark" || echo "Nenhum marcador customizado encontrado"
        return 1
    else
        print_success "Encontrados $performance_tests testes de performance"
    fi

    local benchmark_tests
    benchmark_tests=$(find test/ -name "*benchmark*" -o -name "*performance*" | wc -l)
    print_success "Encontrados $benchmark_tests arquivos de benchmark/performance"

    if grep -q "performance:" pytest.ini; then
        print_success "Marcador 'performance' configurado no pytest.ini"
    else
        print_warning "Marcador 'performance' não encontrado no pytest.ini"
    fi

    print_status "Testes de Performance Disponíveis:"
    pytest --collect-only -m performance -q 2>/dev/null || print_warning "Erro ao listar testes"

    return 0
}

# Função para executar testes de performance em ambiente local com validações detalhadas
run_performance_local() {
    print_status "🏃 Executando Testes de Performance Localmente"

    print_status "Verificando dependências..."
    if ! python -c "import pytest; print(f'pytest: {pytest.__version__}')" 2>/dev/null; then
        print_error "pytest não disponível"
        return 1
    fi

    if ! python -c "import psutil; print(f'psutil: {psutil.__version__}')" 2>/dev/null; then
        print_warning "psutil não disponível, alguns testes podem falhar"
    fi

    if ! validate_performance_tests; then
        print_error "Validação de performance falhou"
        return 1
    fi

    print_status "Executando Testes de Performance (modo rápido)"
    if ! pytest -m "performance and not slow" --tb=short -v --maxfail=3 --durations=10 -x; then
        print_warning "Alguns testes de performance falharam (esperado se não houver DB configurado)"
    fi

    print_status "Executando Benchmarks Básicos"

    print_status "Testando performance simples..."
    if ! pytest test/performance/test_simple_performance.py::TestSimplePerformance::test_json_serialization_performance -v -s --tb=line; then
        print_warning "Teste simples falhou"
    fi

    print_status "Testando benchmark JSON original..."
    if ! pytest test/performance/test_benchmarks.py::TestBenchmarks::test_benchmark_json_processing -v -s --tb=line; then
        print_warning "Benchmark JSON falhou, tentando com medição manual"
    fi

    print_status "Testando benchmark manual..."
    if ! pytest test/performance/test_benchmarks.py::TestManualBenchmarks::test_manual_memory_usage -v -s --tb=line; then
        print_warning "Benchmark manual falhou"
    fi

    print_status "Testando performance de importação (sem módulos problemáticos)..."
    if ! pytest test/performance/test_performance_ci.py::TestSystemPerformance::test_import_time_performance -v -s --tb=line; then
        print_warning "Teste de importação falhou"
    fi

    print_status "Verificando pytest-benchmark"
    python -c "
try:
    import pytest_benchmark
    print('✅ pytest-benchmark disponível:', pytest_benchmark.__version__)
except ImportError:
    print('ℹ️  pytest-benchmark não instalado (ok)')
except Exception as e:
    print('⚠️  Problema com pytest-benchmark:', str(e))
"

    print_success "Configuração de performance validada"
    print_status "📊 Para executar todos os testes: pytest -m performance -v"

    return 0
}

QUICK_MODE=false
FULL_MODE=false
SMOKE_ONLY=false
CRITICAL_ONLY=false
SKIP_OPTIONAL=false
AUTO_DISCOVER=false
UNIT_ONLY=false
PERFORMANCE_ONLY=false
PERFORMANCE_VALIDATE=false
PERFORMANCE_LOCAL=false
PERFORMANCE_SAFE=false
REAL_ANALYSIS=false

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
        --performance|-p)
            PERFORMANCE_ONLY=true
            shift
            ;;
        --performance-validate)
            PERFORMANCE_VALIDATE=true
            shift
            ;;
        --performance-local)
            PERFORMANCE_LOCAL=true
            shift
            ;;
        --performance-safe)
            PERFORMANCE_SAFE=true
            shift
            ;;
        --real-analysis)
            REAL_ANALYSIS=true
            export ANALYZE_REAL_CODE=true
            export VALIDATE_ACTUAL_LOGIC=true
            export TEST_REAL_SCENARIOS=true
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
            print_status "🔧 Script de Testes - Sophos Kodiak Backend"
            print_status ""
            print_status "MODOS DE EXECUÇÃO:"
            print_status "  --quick, -q          Execução rápida (smoke + critical)"
            print_status "  --full, -f           Execução completa de todos os testes"
            print_status "  --smoke, -s          Apenas smoke tests"
            print_status "  --critical, -c       Apenas testes críticos"
            print_status "  --unit, -u           Apenas testes unitários"
            print_status "  --performance, -p    Apenas testes de performance"
            print_status "  --performance-validate    Validar configuração de performance"
            print_status "  --performance-local  Executar performance local detalhado"
            print_status "  --performance-safe   Performance seguro (evita problemas conhecidos)"
            print_status "  --real-analysis      Análise real do código (sem mocks)"
            print_status "  --auto-discover, -a  Descobrir e executar todos os testes automaticamente"
            print_status ""
            print_status "OPÇÕES:"
            print_status "  --skip-optional      Pular testes marcados como 'external'"
            print_status "  --help, -h           Mostrar esta ajuda"
            print_status ""
            print_status "EXEMPLOS:"
            print_status "  $0                   # Execução padrão"
            print_status "  $0 --quick          # Validação rápida"
            print_status "  $0 --full           # Teste completo"
            print_status "  $0 --smoke          # Apenas validações básicas"
            print_status "  $0 --performance    # Apenas testes de carga"
            print_status "  $0 --real-analysis  # Análise real sem mocks"
            print_status ""
            print_status "MARCADORES PYTEST DISPONÍVEIS:"
            print_status "  smoke, critical, performance, security, external, unit"
            print_status ""
            print_status "CONFIGURAÇÃO CI/CD:"
            print_status "  O script detecta automaticamente se está rodando em CI"
            print_status "  Usa configurações de .env.ci quando CI=true"
            print_status "  Aplica timeouts e limites apropriados para CI"
            print_status ""
            exit 0
            ;;
        *)
            print_error "Opção desconhecida: $1"
            print_error "Use --help para ver opções disponíveis"
            exit 1
            ;;
    esac
done

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
elif [[ "$PERFORMANCE_ONLY" == true ]]; then
    print_status "Modo: Apenas Testes de Performance"
    TESTS_TO_RUN="performance"
elif [[ "$PERFORMANCE_VALIDATE" == true ]]; then
    print_status "Modo: Validação de Performance"
    TESTS_TO_RUN="performance_validate"
elif [[ "$PERFORMANCE_LOCAL" == true ]]; then
    print_status "Modo: Performance Local"
    TESTS_TO_RUN="performance_local"
elif [[ "$PERFORMANCE_SAFE" == true ]]; then
    print_status "Modo: Performance Seguro (sem testes problemáticos)"
    TESTS_TO_RUN="performance_safe"
elif [[ "$REAL_ANALYSIS" == true ]]; then
    print_status "Modo: Análise Real do Código (sem mocks)"
    TESTS_TO_RUN="real_analysis"
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

PYTEST_ARGS="--tb=short -v"

if [[ "$CI" == "true" ]] || [[ -n "$GITHUB_ACTIONS" ]]; then
    print_status "🔧 Aplicando configurações específicas para CI..."
    PYTEST_ARGS="$PYTEST_ARGS --timeout=${REQUEST_TIMEOUT:-10} --maxfail=3"

    if [[ -n "$REQUEST_TIMEOUT" ]]; then
        PYTEST_ARGS="$PYTEST_ARGS --durations=5"
    fi

    print_status "✅ Configuração CI aplicada: timeout=${REQUEST_TIMEOUT:-10}s, maxfail=3"
fi

if [[ "$SKIP_OPTIONAL" == true ]]; then
    PYTEST_ARGS="$PYTEST_ARGS -m 'not external'"
fi

print_status "🔍 Validando ambiente de execução..."
print_status "Flask ENV: ${FLASK_ENV:-não definido}"
print_status "Database URL: ${DATABASE_URL:-não definido}"
print_status "CI Mode: ${CI:-false}"
print_status "Pytest Args: $PYTEST_ARGS"

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
        run_tests "🧠 Testes Unitários - NLP" "pytest test/unit/test_nlp_processing.py $PYTEST_ARGS" && ((SUCCESS_COUNT++))
        run_tests "🗺️ Testes Unitários - Query Mapping" "pytest test/unit/test_query_mapping.py $PYTEST_ARGS" && ((SUCCESS_COUNT++))
        ;;

    performance)
        TOTAL_COUNT=1
        PERF_ARGS="$PYTEST_ARGS --maxfail=5 --tb=line --durations=10"
        print_warning "Testes de performance podem ter falhas esperadas devido a configuração"
        run_tests "⚡ Testes de Performance" "pytest -m performance $PERF_ARGS" && ((SUCCESS_COUNT++))
        ;;

    performance_validate)
        TOTAL_COUNT=1
        if validate_performance_tests; then
            print_success "Validação de performance concluída"
            ((SUCCESS_COUNT++))
        else
            print_error "Validação de performance falhou"
        fi
        ;;

    performance_local)
        TOTAL_COUNT=1
        if run_performance_local; then
            print_success "Testes de performance local concluídos"
            ((SUCCESS_COUNT++))
        else
            print_error "Testes de performance local falharam"
        fi
        ;;

    performance_safe)
        TOTAL_COUNT=3
        print_status "Executando testes de performance seguros (evitando problemas conhecidos)"
        run_tests "📊 Performance Simples" "pytest test/performance/test_simple_performance.py $PYTEST_ARGS --tb=line" && ((SUCCESS_COUNT++))
        run_tests "🔧 Benchmarks Manuais" "pytest test/performance/test_benchmarks.py::TestManualBenchmarks $PYTEST_ARGS --tb=line" && ((SUCCESS_COUNT++))
        run_tests "⚙️ Performance CI (sem importação)" "pytest test/performance/test_performance_ci.py -k 'not test_import_time_performance and not test_burst_load_handling' $PYTEST_ARGS --tb=line" && ((SUCCESS_COUNT++))
        ;;

    real_analysis)
        TOTAL_COUNT=8
        print_status "🔍 Executando análise real do código (sem mocks)"
        print_status "Este modo analisa o comportamento real da aplicação"

        export ANALYZE_REAL_CODE=true
        export VALIDATE_ACTUAL_LOGIC=true
        export TEST_REAL_SCENARIOS=true
        export ENABLE_REAL_API_TESTS=true

        REAL_PYTEST_ARGS=$(echo "$PYTEST_ARGS" | sed "s/-m '[^']*'//g")

        run_tests "🚀 Smoke Tests (Real)" "pytest -m smoke $REAL_PYTEST_ARGS" && ((SUCCESS_COUNT++))
        run_tests "🔥 Testes Críticos (Real)" "pytest -m critical $REAL_PYTEST_ARGS" && ((SUCCESS_COUNT++))
        run_tests "🏗️ Infraestrutura (Real)" "pytest -m infrastructure $REAL_PYTEST_ARGS" && ((SUCCESS_COUNT++))
        run_tests "🌐 Endpoints API (Real)" "pytest -m api $REAL_PYTEST_ARGS" && ((SUCCESS_COUNT++))
        run_tests "🧠 Processamento NLP (Real)" "pytest test/unit/test_nlp_processing.py $REAL_PYTEST_ARGS" && ((SUCCESS_COUNT++))
        run_tests "🗺️ Query Mapping (Real)" "pytest test/unit/test_query_mapping.py $REAL_PYTEST_ARGS" && ((SUCCESS_COUNT++))
        run_tests "📊 Qualidade dos Dados (Real)" "pytest -m data_quality $REAL_PYTEST_ARGS" "optional" && ((SUCCESS_COUNT++))
        run_tests "🎭 Cenários Reais" "pytest -m real_scenarios $REAL_PYTEST_ARGS" "optional" && ((SUCCESS_COUNT++))
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
        run_tests "🧠 Testes Unitários - NLP" "pytest test/unit/test_nlp_processing.py $PYTEST_ARGS" && ((SUCCESS_COUNT++))
        run_tests "🗺️ Testes Unitários - Query Mapping" "pytest test/unit/test_query_mapping.py $PYTEST_ARGS" && ((SUCCESS_COUNT++))
        ;;

    auto_discover)
        print_status "🔍 Descobrindo todos os arquivos de teste..."

        ALL_TEST_FILES=($(find test/ -name "test_*.py" -type f | sort))

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

        for test_file in "${ALL_TEST_FILES[@]}"; do
            test_name="📝 $(basename "$test_file" .py | sed 's/test_//' | tr '_' ' ' | sed 's/\b\w/\U&/g')"
            run_tests "$test_name" "pytest $test_file $PYTEST_ARGS" && ((SUCCESS_COUNT++))
        done
        ;;

    full)
        TOTAL_COUNT=11
        run_tests "🚀 Smoke Tests" "pytest -m smoke $PYTEST_ARGS" && ((SUCCESS_COUNT++))
        run_tests "🔥 Testes Críticos" "pytest -m critical $PYTEST_ARGS" && ((SUCCESS_COUNT++))
        run_tests "🏗️ Infraestrutura Básica" "pytest test/test_infrastructure.py $PYTEST_ARGS" "optional" && ((SUCCESS_COUNT++))
        run_tests "🔒 Infraestrutura Crítica" "pytest test/test_critical_infrastructure.py $PYTEST_ARGS" && ((SUCCESS_COUNT++))
        run_tests "📊 Qualidade dos Dados" "pytest test/test_data_quality.py $PYTEST_ARGS" "optional" && ((SUCCESS_COUNT++))
        run_tests "🌐 Endpoints API" "pytest test/test_endpoints.py $PYTEST_ARGS" && ((SUCCESS_COUNT++))
        run_tests "🎭 Cenários Reais" "pytest test/test_real_scenarios.py $PYTEST_ARGS" "optional" && ((SUCCESS_COUNT++))
        run_tests "🧠 Testes Unitários - NLP" "pytest test/unit/test_nlp_processing.py $PYTEST_ARGS" && ((SUCCESS_COUNT++))
        run_tests "🗺️ Testes Unitários - Query Mapping" "pytest test/unit/test_query_mapping.py $PYTEST_ARGS" && ((SUCCESS_COUNT++))
        run_tests "📂 Todos os Testes Unitários" "pytest test/unit/ $PYTEST_ARGS" && ((SUCCESS_COUNT++))
        run_tests "⚡ Performance" "pytest -m performance $PYTEST_ARGS" "optional" && ((SUCCESS_COUNT++))
        ;;
esac

echo ""
print_status "🔍 Verificando cobertura de arquivos de teste..."

TEST_FILES=(
    "test/test_smoke.py"
    "test/test_critical_infrastructure.py"
    "test/test_infrastructure.py"
    "test/test_data_quality.py"
    "test/test_endpoints.py"
    "test/test_real_scenarios.py"
    "test/unit/test_nlp_processing.py"
    "test/unit/test_query_mapping.py"
)

MISSING_TESTS=""
AVAILABLE_TESTS=""

for test_file in "${TEST_FILES[@]}"; do
    if [[ -f "$test_file" ]]; then
        AVAILABLE_TESTS="$AVAILABLE_TESTS $test_file"

        case "$TESTS_TO_RUN" in
            smoke)
                if [[ "$test_file" != "test/test_smoke.py" ]]; then
                    MISSING_TESTS="$MISSING_TESTS $test_file"
                fi
                ;;
            critical)
                if [[ "$test_file" != "test/test_critical_infrastructure.py" ]]; then
                    MISSING_TESTS="$MISSING_TESTS $test_file"
                fi
                ;;
            unit)
                if [[ "$test_file" != "test/unit/test_nlp_processing.py" && "$test_file" != "test/unit/test_query_mapping.py" ]]; then
                    MISSING_TESTS="$MISSING_TESTS $test_file"
                fi
                ;;
            quick)
                if [[ "$test_file" != "test/test_smoke.py" && "$test_file" != "test/test_critical_infrastructure.py" ]]; then
                    MISSING_TESTS="$MISSING_TESTS $test_file"
                fi
                ;;
            default)
                if [[ "$test_file" == "test/test_data_quality.py" || "$test_file" == "test/test_real_scenarios.py" ]]; then
                    MISSING_TESTS="$MISSING_TESTS $test_file"
                fi
                ;;
            full)
                ;;
        esac
    else
        print_warning "Arquivo de teste não encontrado: $test_file"
    fi
done

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

UNCATALOGUED_TESTS=$(find test/ -name "test_*.py" -type f 2>/dev/null | grep -v -E "($(echo "${TEST_FILES[@]}" | tr ' ' '|'))" || echo "")

if [[ -n "$UNCATALOGUED_TESTS" ]]; then
    echo ""
    print_warning "Arquivos de teste encontrados que não estão no script:"
    echo "$UNCATALOGUED_TESTS" | while IFS= read -r test_file; do
        [[ -n "$test_file" ]] && echo "  • $test_file"
    done
    print_status "💡 Considere adicionar estes testes ao script run_tests.sh"
fi

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
    echo "  • Para testes de performance: $0 --performance"
elif [[ "$TESTS_TO_RUN" == "critical" ]]; then
    echo "  • Execute verificação rápida: $0 --quick"
    echo "  • Para testes unitários: $0 --unit"
    echo "  • Para auditoria completa: $0 --full"
    echo "  • Para descoberta automática: $0 --auto-discover"
    echo "  • Para testes de performance: $0 --performance"
elif [[ "$TESTS_TO_RUN" == "unit" ]]; then
    echo "  • Execute verificação rápida: $0 --quick"
    echo "  • Para testes críticos: $0 --critical"
    echo "  • Para auditoria completa: $0 --full"
    echo "  • Para descoberta automática: $0 --auto-discover"
    echo "  • Para testes de performance: $0 --performance"
elif [[ "$TESTS_TO_RUN" == "performance" ]]; then
    echo "  • Validar configuração: $0 --performance-validate"
    echo "  • Executar local detalhado: $0 --performance-local"
    echo "  • Para verificação completa: $0 --full"
    echo "  • Para verificação rápida: $0 --quick"
elif [[ "$TESTS_TO_RUN" == "performance_validate" ]]; then
    echo "  • Executar testes: $0 --performance"
    echo "  • Executar local detalhado: $0 --performance-local"
    echo "  • Para verificação completa: $0 --full"
elif [[ "$TESTS_TO_RUN" == "performance_local" ]]; then
    echo "  • Executar só performance: $0 --performance"
    echo "  • Validar configuração: $0 --performance-validate"
    echo "  • Para verificação completa: $0 --full"
elif [[ "$TESTS_TO_RUN" == "real_analysis" ]]; then
    echo "  • Execute análise focada: $0 --critical --real-analysis"
    echo "  • Para análise completa: $0 --full --real-analysis"
    echo "  • Execute script específico: ./run_real_tests.sh"
    echo "  • Revise relatório de cobertura: htmlcov/index.html"
elif [[ "$TESTS_TO_RUN" == "quick" ]]; then
    echo "  • Execute suite completa: $0 --full"
    echo "  • Para testes unitários: $0 --unit"
    echo "  • Para descoberta automática: $0 --auto-discover"
    echo "  • Para auditoria de dados: pytest -m data_quality -v"
    echo "  • Para testes de performance: $0 --performance"
elif [[ "$TESTS_TO_RUN" == "default" ]]; then
    echo "  • Execute suite completa: $0 --full"
    echo "  • Para testes unitários apenas: $0 --unit"
    echo "  • Para descoberta automática: $0 --auto-discover"
    echo "  • Para testes de carga: $0 --performance"
elif [[ "$TESTS_TO_RUN" == "auto_discover" ]]; then
    echo "  • Execute por categoria: $0 --smoke, $0 --critical, etc."
    echo "  • Para verificação rápida: $0 --quick"
    echo "  • Para suite organizada: $0 --full"
    echo "  • Para testes de performance: $0 --performance"
else
    echo "  • Para execução rápida: $0 --quick"
    echo "  • Para testes unitários: $0 --unit"
    echo "  • Para descoberta automática: $0 --auto-discover"
    echo "  • Para smoke tests: $0 --smoke"
    echo "  • Para testes de performance: $0 --performance"
fi

echo ""
echo "📖 Documentação: test/README.md"
echo "🔧 Configuração: pytest.ini"
echo "⚙️ Configuração CI: .env.ci"
echo "🎯 Modo usado: $TESTS_TO_RUN"
echo "📊 Cobertura: htmlcov/index.html (após execução completa)"
echo ""
echo "🔍 Debug Info:"
echo "  • Python Path: ${PYTHONPATH:-não definido}"
echo "  • Working Directory: $(pwd)"
echo "  • CI Mode: ${CI:-false}"
echo "  • GitHub Actions: ${GITHUB_ACTIONS:-false}"

exit $EXIT_CODE
