# Configuração de Testes - Sophos Kodiak

# Executar todos os testes unitários
unit_tests:
	flutter test test/unit/

# Executar todos os testes de widget
widget_tests:
	flutter test test/widget/

# Executar todos os testes de integração
integration_tests:
	flutter test integration_test/

# Executar todos os testes com cobertura
test_with_coverage:
	flutter test --coverage
	genhtml coverage/lcov.info -o coverage/html

# Executar testes específicos por categoria
test_models:
	flutter test test/unit/models/

test_services:
	flutter test test/unit/services/

test_pages:
	flutter test test/widget/pages/

# Executar todos os testes
test_all:
	flutter test
	flutter test integration_test/

# Limpar dados de teste
clean_test_data:
	flutter clean
	flutter pub get
