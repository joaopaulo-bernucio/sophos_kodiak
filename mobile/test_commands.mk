unit_tests:
	flutter test test/unit/

widget_tests:
	flutter test test/widget/

integration_tests:
	flutter test integration_test/

test_with_coverage:
	flutter test --coverage
	genhtml coverage/lcov.info -o coverage/html

test_models:
	flutter test test/unit/models/

test_services:
	flutter test test/unit/services/

test_pages:
	flutter test test/widget/pages/

test_all:
	flutter test
	flutter test integration_test/

clean_test_data:
	flutter clean
	flutter pub get
