# Script para Executar Todos os Testes - Sophos Kodiak

echo "🧪 Executando Testes do Sophos Kodiak Mobile"
echo "=============================================="

echo ""
echo "📦 Instalando dependências..."
flutter pub get

echo ""
echo "🔧 Executando Smoke Tests..."
flutter test test/widget_test.dart

echo ""
echo "🧪 Executando Testes Unitários..."
echo "  → Testando modelos..."
flutter test test/unit/models/

echo "  → Testando serviços..."
flutter test test/unit/services/

echo ""
echo "🎨 Executando Testes de Widget..."
flutter test test/widget/

echo ""
echo "🔄 Executando Testes de Integração..."
flutter test integration_test/

echo ""
echo "📊 Gerando Relatório de Cobertura..."
flutter test --coverage
if [ -f "coverage/lcov.info" ]; then
    echo "  → Cobertura gerada em coverage/lcov.info"
    if command -v genhtml &> /dev/null; then
        genhtml coverage/lcov.info -o coverage/html
        echo "  → Relatório HTML gerado em coverage/html/"
    else
        echo "  → genhtml não encontrado. Instale lcov para gerar relatório HTML"
    fi
else
    echo "  → Arquivo de cobertura não gerado"
fi

echo ""
echo "✅ Testes concluídos!"
echo ""
echo "📋 Resumo da Estrutura de Testes:"
echo "  • Testes Unitários: Models e Services"
echo "  • Testes de Widget: UI e Interações"
echo "  • Testes de Integração: Fluxos E2E"
echo "  • Helpers: Utilitários e Dados de Teste"
echo ""
echo "🚀 Para executar testes específicos:"
echo "  flutter test test/unit/                    # Apenas unitários"
echo "  flutter test test/widget/                  # Apenas widgets"
echo "  flutter test integration_test/             # Apenas integração"
echo "  flutter test test/unit/models/user_model_test.dart  # Teste específico"
