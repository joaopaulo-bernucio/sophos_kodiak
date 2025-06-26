#!/bin/bash

set -e

show_help() {
    echo "Uso: $0 [OPÇÃO]"
    echo ""
    echo "Opções:"
    echo "  --unit        Executar apenas testes unitários"
    echo "  --widget      Executar apenas testes de widget"
    echo "  --integration Executar apenas testes de integração"
    echo "  --coverage    Executar todos os testes com cobertura"
    echo "  --help        Mostrar esta ajuda"
    echo ""
    echo "Sem argumentos: Executa todos os testes"
}

case "${1:-all}" in
    --help|-h)
        show_help
        exit 0
        ;;
    --unit)
        TEST_TYPE="unit"
        ;;
    --widget)
        TEST_TYPE="widget"
        ;;
    --integration)
        TEST_TYPE="integration"
        ;;
    --coverage)
        TEST_TYPE="coverage"
        ;;
    all|"")
        TEST_TYPE="all"
        ;;
    *)
        echo "❌ Opção inválida: $1"
        show_help
        exit 1
        ;;
esac

echo "🧪 Executando Testes do Sophos Kodiak Mobile"
echo "=============================================="

if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter não está instalado ou não está no PATH"
    exit 1
fi

echo ""
echo "📦 Instalando dependências..."
flutter pub get

echo ""
echo "� Instalando dependências..."
flutter pub get

run_unit_tests() {
    echo ""
    echo "🧪 Executando Testes Unitários..."
    echo "  → Testando modelos..."
    flutter test test/unit/models/ --reporter compact

    echo "  → Testando serviços..."
    flutter test test/unit/services/ --reporter compact
}

run_widget_tests() {
    echo ""
    echo "🔧 Executando Smoke Tests..."
    flutter test test/widget/widget_test.dart

    echo ""
    echo "🎨 Executando Testes de Widget..."
    echo "  → Testando aplicação principal..."
    flutter test test/widget/app_test.dart --reporter compact

    echo "  → Testando páginas..."
    flutter test test/widget/pages/ --reporter compact
}

run_integration_tests() {
    echo ""
    echo "🔄 Executando Testes de Integração..."
    flutter test integration_test/ --reporter compact
}

run_coverage_tests() {
    echo ""
    echo "📊 Gerando Relatório de Cobertura..."
    echo "  → Executando todos os testes com cobertura..."
    flutter test --coverage --reporter compact

    process_coverage_report
}

process_coverage_report() {
    if [ -f "coverage/lcov.info" ]; then
        echo "  → Cobertura gerada em coverage/lcov.info"
        if command -v genhtml &> /dev/null; then
            genhtml coverage/lcov.info -o coverage/html --quiet
            echo "  → Relatório HTML gerado em coverage/html/"
            echo "  → Abra coverage/html/index.html no navegador para ver o relatório"
        else
            echo "  → genhtml não encontrado. Instale lcov para gerar relatório HTML:"
            echo "    sudo apt-get install lcov  (Ubuntu/Debian)"
            echo "    brew install lcov          (macOS)"
        fi

        if command -v lcov &> /dev/null; then
            echo "  → Resumo da cobertura:"
            lcov --summary coverage/lcov.info 2>/dev/null | grep -E "(lines|functions)" || echo "    Dados de cobertura processados com sucesso"
        fi
    else
        echo "  → ⚠️  Arquivo de cobertura não gerado"
        echo "    Verifique se todos os testes passaram corretamente"
    fi
}

case "$TEST_TYPE" in
    unit)
        run_unit_tests
        ;;
    widget)
        run_widget_tests
        ;;
    integration)
        run_integration_tests
        ;;
    coverage)
        run_coverage_tests
        ;;
    all)
        run_unit_tests
        run_widget_tests
        run_integration_tests
        run_coverage_tests
        ;;
esac

echo ""
echo "✅ Testes concluídos!"

UNIT_TESTS=$(find test/unit -name "*_test.dart" | wc -l)
WIDGET_TESTS=$(find test/widget -name "*_test.dart" | wc -l)
INTEGRATION_TESTS=$(find integration_test -name "*_test.dart" 2>/dev/null | wc -l || echo "0")
TOTAL_TESTS=$((UNIT_TESTS + WIDGET_TESTS + INTEGRATION_TESTS))

echo ""
echo "📊 Estatísticas dos Testes:"
echo "  • Testes Unitários: $UNIT_TESTS arquivos"
echo "  • Testes de Widget: $WIDGET_TESTS arquivos"
echo "  • Testes de Integração: $INTEGRATION_TESTS arquivos"
echo "  • Total de arquivos de teste: $TOTAL_TESTS"
echo ""
echo "📋 Resumo da Estrutura de Testes:"
echo "  • Testes Unitários: Models (User, ChatMessage) e Services (Auth, UserStorage)"
echo "  • Testes de Widget: App principal e páginas (Login, Charts)"
echo "  • Testes de Integração: Fluxos E2E completos"
echo "  • Helpers: Utilitários (TestData, WidgetTestHelpers) e dados de teste"
echo ""
echo "🚀 Para executar testes específicos:"
echo "  ./run_tests.sh --unit                            # Apenas unitários"
echo "  ./run_tests.sh --widget                          # Apenas widgets"
echo "  ./run_tests.sh --integration                     # Apenas integração"
echo "  ./run_tests.sh --coverage                        # Apenas cobertura"
echo "  flutter test test/unit/models/user_test.dart      # Teste específico do modelo User"
echo "  flutter test test/unit/models/chat_message_test.dart  # Teste específico do modelo ChatMessage"
echo "  flutter test test/widget/pages/login_page_test.dart   # Teste específico da página de login"
echo "  flutter test integration_test/authentication_flow_test.dart   # Teste específico de fluxo de autenticação"
