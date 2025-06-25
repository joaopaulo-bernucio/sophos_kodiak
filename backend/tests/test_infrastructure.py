import pytest
import os
import socket
import time
import threading
from datetime import datetime
from pathlib import Path

class TestEnvironmentConfiguration:
    def test_flask_environment_setup(self, app):
        assert app is not None
        assert app.config['TESTING'] is True
        essential_configs = ['JSON_AS_ASCII', 'WTF_CSRF_ENABLED']
        for config in essential_configs:
            assert config in app.config

    def test_environment_variables_presence(self, env_vars):
        required_env_vars = [
            'DB_HOST', 'DB_PORT', 'DB_NAME',
            'DB_USER', 'DB_PASSWORD', 'GEMINI_API_KEY'
        ]
        missing_vars = []
        for var in required_env_vars:
            if var not in env_vars or not env_vars[var]:
                missing_vars.append(var)
        assert len(missing_vars) == 0, f"Variáveis de ambiente faltando: {missing_vars}"

    def test_environment_variables_format(self, env_vars):
        try:
            port = int(env_vars['DB_PORT'])
            assert 1 <= port <= 65535, f"Porta inválida: {port}"
        except ValueError:
            pytest.fail(f"DB_PORT deve ser numérico: {env_vars['DB_PORT']}")
        assert len(env_vars['DB_HOST'].strip()) > 0, "DB_HOST não pode estar vazio"
        assert len(env_vars['DB_NAME'].strip()) > 0, "DB_NAME não pode estar vazio"

    def test_flask_application_factory(self):
        try:
            from app.app import create_app
            test_app = create_app()
            assert test_app is not None
            assert hasattr(test_app, 'config')
        except ImportError:
            pytest.skip("Função create_app não disponível")

    def test_logging_configuration(self):
        import logging
        root_logger = logging.getLogger()
        assert len(root_logger.handlers) > 0, "Sistema de logging não configurado"
        test_logger = logging.getLogger('test_infrastructure')
        test_logger.info("Teste de logging funcionando")

    def test_python_version_compatibility(self):
        import sys
        major, minor = sys.version_info[:2]
        assert major >= 3, f"Python {major}.{minor} não suportado"
        if major == 3:
            assert minor >= 7, f"Python 3.{minor} não suportado, mínimo 3.7"

class TestNetworkConnectivity:
    def test_database_host_reachable(self, env_vars):
        host = env_vars['DB_HOST']
        port = int(env_vars['DB_PORT'])
        if host == 'localhost' and os.getenv('CI'):
            pytest.skip("Teste de conectividade pulado em ambiente CI")
        try:
            sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            sock.settimeout(10)
            result = sock.connect_ex((host, port))
            sock.close()
            assert result == 0, f"Não foi possível conectar a {host}:{port}"
        except socket.gaierror as e:
            pytest.fail(f"Erro de resolução DNS para {host}: {e}")
        except Exception as e:
            pytest.fail(f"Erro de conectividade: {e}")

    def test_internet_connectivity(self):
        if os.getenv('OFFLINE_MODE'):
            pytest.skip("Modo offline ativado")
        import urllib.request
        test_urls = [
            'https://google.com',
            'https://generativelanguage.googleapis.com'
        ]
        reachable_urls = []
        for url in test_urls:
            try:
                urllib.request.urlopen(url, timeout=10)
                reachable_urls.append(url)
            except:
                continue
        assert len(reachable_urls) > 0, "Nenhuma conectividade com internet detectada"

    def test_dns_resolution(self):
        critical_domains = [
            'localhost',
            'google.com',
            'generativelanguage.googleapis.com'
        ]
        resolved_domains = []
        for domain in critical_domains:
            try:
                socket.gethostbyname(domain)
                resolved_domains.append(domain)
            except socket.gaierror:
                continue
        assert 'localhost' in resolved_domains, "Resolução DNS básica falhou"

class TestFileSystemAccess:
    def test_backend_directory_structure(self):
        backend_root = Path(__file__).parent.parent
        essential_dirs = [
            'app',
            'tests'
        ]
        essential_files = [
            'app/app.py',
            'app/query_mapping.py',
            'requirements.txt'
        ]
        missing_dirs = []
        for dir_name in essential_dirs:
            dir_path = backend_root / dir_name
            if not dir_path.exists() or not dir_path.is_dir():
                missing_dirs.append(dir_name)
        missing_files = []
        for file_name in essential_files:
            file_path = backend_root / file_name
            if not file_path.exists() or not file_path.is_file():
                missing_files.append(file_name)
        errors = []
        if missing_dirs:
            errors.append(f"Diretórios faltando: {missing_dirs}")
        if missing_files:
            errors.append(f"Arquivos faltando: {missing_files}")
        if errors:
            pytest.fail("; ".join(errors))

    def test_write_permissions(self):
        import tempfile
        try:
            with tempfile.NamedTemporaryFile(mode='w', delete=True) as tmp_file:
                tmp_file.write("teste de permissão")
                tmp_file.flush()
                assert os.path.exists(tmp_file.name)
        except Exception as e:
            pytest.fail(f"Erro de permissão de escrita: {e}")

    def test_read_application_files(self):
        backend_root = Path(__file__).parent.parent
        critical_files = [
            'app/app.py',
            'app/query_mapping.py'
        ]
        read_errors = []
        for file_name in critical_files:
            file_path = backend_root / file_name
            try:
                with open(file_path, 'r', encoding='utf-8') as f:
                    content = f.read()
                    assert len(content) > 0, f"Arquivo {file_name} está vazio"
            except Exception as e:
                read_errors.append(f"{file_name}: {e}")
        if read_errors:
            pytest.fail(f"Erros de leitura: {'; '.join(read_errors)}")

class TestDependencyAvailability:
    def test_core_dependencies(self):
        core_deps = [
            'flask',
            'psycopg2',
            'json',
            'os',
            'sys',
            'time',
            'datetime'
        ]
        missing_deps = []
        for dep in core_deps:
            try:
                __import__(dep)
            except ImportError:
                missing_deps.append(dep)
        assert len(missing_deps) == 0, f"Dependências principais faltando: {missing_deps}"

    def test_optional_dependencies(self):
        optional_deps = {
            'spacy': 'Processamento de linguagem natural',
            'google.generativeai': 'API Gemini',
            'flask_cors': 'CORS para Flask',
            'dotenv': 'Carregamento de variáveis de ambiente'
        }
        available_deps = {}
        for dep, description in optional_deps.items():
            try:
                __import__(dep)
                available_deps[dep] = True
            except ImportError:
                available_deps[dep] = False
        print(f"\nStatus de dependências opcionais:")
        for dep, available in available_deps.items():
            status = "✅" if available else "❌"
            desc = optional_deps[dep]
            print(f"  {status} {dep}: {desc}")

    def test_flask_extensions(self):
        flask_extensions = [
            'flask_cors'
        ]
        available_extensions = []
        for ext in flask_extensions:
            try:
                __import__(ext)
                available_extensions.append(ext)
            except ImportError:
                continue
        if 'flask_cors' not in available_extensions:
            print("⚠️  Aviso: flask_cors não disponível, CORS pode não funcionar")

class TestResourceUsage:
    def test_memory_usage_basic(self):
        try:
            import psutil
            process = psutil.Process()
            memory_info = process.memory_info()
            memory_mb = memory_info.rss / 1024 / 1024
            assert memory_mb < 1024, f"Uso de memória muito alto: {memory_mb:.1f}MB"
        except ImportError:
            pytest.skip("psutil não disponível para monitoramento de memória")

    def test_application_startup_time(self):
        start_time = time.time()
        try:
            from app.app import create_app
            app = create_app()
            startup_time = time.time() - start_time
            assert startup_time < 30.0, f"Inicialização muito lenta: {startup_time:.2f}s"
        except ImportError:
            pytest.skip("Função create_app não disponível")

    def test_concurrent_application_instances(self):
        try:
            from app.app import create_app
            instances = []
            for i in range(3):
                app = create_app()
                instances.append(app)
                assert app is not None
            for i, app1 in enumerate(instances):
                for j, app2 in enumerate(instances):
                    if i != j:
                        assert app1 is not app2, "Instâncias não são independentes"
        except ImportError:
            pytest.skip("Função create_app não disponível")

class TestSecurityConfiguration:
    def test_debug_mode_disabled_in_production(self, app):
        if os.getenv('FLASK_ENV') == 'testing':
            pytest.skip("Ambiente de teste permite debug mode")
        assert not app.debug, "Debug mode habilitado em ambiente não-teste"

    def test_sensitive_data_not_in_logs(self):
        import logging
        log_capture = []

        class TestHandler(logging.Handler):
            def emit(self, record):
                log_capture.append(record.getMessage())

        test_handler = TestHandler()
        root_logger = logging.getLogger()
        root_logger.addHandler(test_handler)

        try:
            test_logger = logging.getLogger('test_security')
            test_logger.info("Teste de log sem dados sensíveis")
            for log_message in log_capture:
                sensitive_patterns = ['password', 'token', 'api_key', 'secret']
                for pattern in sensitive_patterns:
                    assert pattern.lower() not in log_message.lower(), \
                        f"Possível dados sensível no log: {pattern}"
        finally:
            root_logger.removeHandler(test_handler)

    def test_cors_configuration(self, app):
        try:
            if hasattr(app, 'extensions') and 'cors' in app.extensions:
                print("✅ CORS configurado")
            else:
                print("⚠️  CORS pode não estar configurado")
        except:
            pass

class TestMonitoringAndHealthChecks:
    def test_basic_health_endpoint(self, client):
        response = client.get('/health')
        assert response.status_code in [200, 404]
        if response.status_code == 200:
            assert 'application/json' in response.content_type
            import json
            data = json.loads(response.data)
            assert isinstance(data, dict)

    def test_monitoring_endpoints_response_time(self, client):
        endpoints = ['/health', '/api/graphs/health']
        for endpoint in endpoints:
            start_time = time.time()
            response = client.get(endpoint)
            response_time = time.time() - start_time
            if response.status_code == 200:
                assert response_time < 5.0, f"Health check {endpoint} muito lento: {response_time:.2f}s"

    def test_error_handling_infrastructure(self, app):
        error_handlers_exist = hasattr(app, 'error_handler_spec') and \
                              app.error_handler_spec is not None
        if not error_handlers_exist:
            print("⚠️  Aviso: Tratamento de erros pode não estar configurado")

    def test_application_context_management(self, app):
        with app.app_context():
            from flask import current_app
            assert current_app is not None
            assert current_app.name == app.name
            assert current_app.config['TESTING'] == app.config['TESTING']
        with app.test_request_context():
            from flask import request
            assert request is not None

class TestConfigurationValidation:
    def test_database_configuration_completeness(self, env_vars):
        db_config_keys = ['DB_HOST', 'DB_PORT', 'DB_NAME', 'DB_USER', 'DB_PASSWORD']
        for key in db_config_keys:
            value = env_vars.get(key)
            assert value is not None, f"Configuração {key} não definida"
            assert len(str(value).strip()) > 0, f"Configuração {key} está vazia"

    def test_api_configuration_completeness(self, env_vars):
        api_config_keys = ['GEMINI_API_KEY']
        for key in api_config_keys:
            value = env_vars.get(key)
            assert value is not None, f"Configuração {key} não definida"
            placeholder_values = ['test_api_key', 'fake_gemini_key_for_tests', 'test_gemini_api_key']
            if os.getenv('FLASK_ENV') != 'testing' and value in placeholder_values:
                pytest.fail(f"API key {key} parece ser placeholder em ambiente não-teste")

    def test_flask_secret_key_configuration(self, app):
        if os.getenv('FLASK_ENV') != 'testing':
            secret_key = app.config.get('SECRET_KEY')
            if secret_key:
                assert len(secret_key) >= 16, "SECRET_KEY muito curta"
            else:
                print("⚠️  Aviso: SECRET_KEY não configurada")

    def test_timezone_configuration(self):
        from datetime import datetime
        now = datetime.now()
        assert now is not None
        import time
        timezone_info = time.tzname
        assert timezone_info is not None, "Informação de timezone não disponível"
