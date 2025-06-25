import pytest
import json
import time

pytestmark = pytest.mark.smoke


class TestApplicationStartup:

    def test_application_can_be_imported(self):
        try:
            from app.app import app
            assert app is not None, "Aplicação Flask não foi criada"
        except ImportError as e:
            pytest.fail(f"Erro ao importar aplicação: {e}")
        except Exception as e:
            pytest.fail(f"Erro inesperado na importação: {e}")

    def test_flask_app_is_configured(self, app):
        assert app is not None, "Aplicação Flask não disponível"
        assert hasattr(app, 'config'), "Configuração da aplicação não disponível"
        assert app.config.get('TESTING') is True, "Modo de teste não ativado"

    def test_application_context_works(self, app):
        try:
            with app.app_context():
                from flask import current_app
                assert current_app.name == app.name, "Contexto da aplicação não funciona"
                assert hasattr(current_app, 'config'), "current_app deve ter configurações"
        except Exception as e:
            pytest.fail(f"Erro no contexto da aplicação: {e}")

    def test_test_client_available(self, client):
        assert client is not None, "Cliente de teste não disponível"
        try:
            response = client.get('/')
            assert response is not None, "Cliente de teste não responde"
        except Exception as e:
            pytest.fail(f"Erro no cliente de teste: {e}")

    def test_basic_dependencies_available(self):
        required_modules = ['flask', 'json', 'os', 'time', 'datetime']
        missing_modules = []
        for module in required_modules:
            try:
                __import__(module)
            except ImportError:
                missing_modules.append(module)
        assert len(missing_modules) == 0, f"Módulos básicos faltando: {missing_modules}"

    def test_environment_configuration_basic(self, env_vars):
        essential_vars = ['DB_HOST', 'DB_NAME', 'GEMINI_API_KEY']
        missing_vars = []
        for var in essential_vars:
            if not env_vars.get(var):
                missing_vars.append(var)
        assert len(missing_vars) == 0, f"Variáveis essenciais faltando: {missing_vars}"


class TestDatabaseConnectivity:

    def test_database_connection_possible(self, env_vars):
        try:
            import psycopg2

            conn = psycopg2.connect(
                host=env_vars['DB_HOST'],
                port=env_vars['DB_PORT'],
                dbname=env_vars['DB_NAME'],
                user=env_vars['DB_USER'],
                password=env_vars['DB_PASSWORD'],
                connect_timeout=10
            )

            cur = conn.cursor()
            cur.execute("SELECT 1;")
            result = cur.fetchone()

            assert result[0] == 1, "Query básica falhou"

            cur.close()
            conn.close()

        except ImportError:
            pytest.skip("psycopg2 não disponível")
        except Exception as e:
            pytest.fail(f"Erro de conectividade com banco: {e}")

    def test_database_basic_tables_exist(self, env_vars):
        try:
            import psycopg2

            conn = psycopg2.connect(
                host=env_vars['DB_HOST'],
                port=env_vars['DB_PORT'],
                dbname=env_vars['DB_NAME'],
                user=env_vars['DB_USER'],
                password=env_vars['DB_PASSWORD']
            )

            cur = conn.cursor()

            essential_tables = ['funcionarios', 'departamentos']

            tables_found = 0
            for table in essential_tables:
                cur.execute("""
                    SELECT EXISTS (
                        SELECT FROM information_schema.tables
                        WHERE table_name = %s
                    );
                """, (table,))

                if cur.fetchone()[0]:
                    tables_found += 1

            cur.close()
            conn.close()

            assert tables_found > 0, "Nenhuma tabela essencial encontrada"

        except ImportError:
            pytest.skip("psycopg2 não disponível")
        except Exception as e:
            pytest.fail(f"Erro crítico de banco: {e}")

    def test_database_read_operation(self, env_vars):
        try:
            import psycopg2

            conn = psycopg2.connect(
                host=env_vars['DB_HOST'],
                port=env_vars['DB_PORT'],
                dbname=env_vars['DB_NAME'],
                user=env_vars['DB_USER'],
                password=env_vars['DB_PASSWORD']
            )

            cur = conn.cursor()

            try:
                cur.execute("SELECT COUNT(*) FROM funcionarios;")
                count = cur.fetchone()[0]
                assert isinstance(count, int), "Resultado da contagem inválido"

            except psycopg2.Error:
                backup_queries = [
                    "SELECT COUNT(*) FROM departamentos;",
                    "SELECT 1;",
                ]

                query_worked = False
                for query in backup_queries:
                    try:
                        cur.execute(query)
                        cur.fetchone()
                        query_worked = True
                        break
                    except:
                        continue

                assert query_worked, "Nenhuma query básica funcionou"

            cur.close()
            conn.close()

        except ImportError:
            pytest.skip("psycopg2 não disponível")
        except Exception as e:
            pytest.fail(f"Erro em operação de leitura: {e}")


class TestCoreEndpoints:

    def test_main_endpoint_responds(self, client):
        try:
            response = client.post('/pergunta',
                                 json={'pergunta': 'teste'},
                                 content_type='application/json')

            assert response is not None, "Endpoint principal não responde"
            assert response.status_code is not None, "Status code não retornado"

            assert 100 <= response.status_code <= 599, f"Status code inválido: {response.status_code}"

        except Exception as e:
            pytest.fail(f"Erro no endpoint principal: {e}")

    def test_health_endpoint_if_exists(self, client):
        try:
            response = client.get('/health')

            if response.status_code == 200:
                try:
                    data = json.loads(response.data)
                    assert isinstance(data, dict), "Health endpoint deve retornar objeto JSON"
                except json.JSONDecodeError:
                    pytest.fail("Health endpoint retornou JSON inválido")

            assert response.status_code in [200, 404], f"Status inesperado em /health: {response.status_code}"

        except Exception as e:
            pytest.fail(f"Erro no endpoint de health: {e}")

    def test_api_endpoints_accessibility(self, client):
        api_endpoints = [
            '/api/query/funcionarios_por_departamento',
            '/api/query/metricas_gerais'
        ]

        accessible_endpoints = 0

        for endpoint in api_endpoints:
            try:
                response = client.get(endpoint)

                if response.status_code in [200, 404]:
                    accessible_endpoints += 1

            except Exception:
                continue

        print(f"Endpoints de API acessíveis: {accessible_endpoints}/{len(api_endpoints)}")

    def test_endpoint_response_format(self, client):
        try:
            response = client.post('/pergunta',
                                 json={'pergunta': 'teste básico'},
                                 content_type='application/json')

            if response.status_code == 200:
                try:
                    data = json.loads(response.data)
                    assert isinstance(data, dict), "Resposta deve ser objeto JSON"

                except json.JSONDecodeError:
                    pytest.fail("Resposta 200 não é JSON válido")

            elif response.status_code == 400:
                try:
                    data = json.loads(response.data)
                    assert 'erro' in data or 'error' in data, "Resposta de erro deve ter campo de erro"

                except json.JSONDecodeError:
                    pytest.fail("Resposta de erro não é JSON válido")

        except Exception as e:
            pytest.fail(f"Erro ao verificar formato de resposta: {e}")


class TestBasicSecurity:

    def test_invalid_json_handled(self, client):
        try:
            response = client.post('/pergunta',
                                 data='{"pergunta": malformed json',
                                 content_type='application/json')

            assert response.status_code == 400, "JSON malformado deve retornar 400"

            try:
                data = json.loads(response.data)
                assert isinstance(data, dict), "Resposta de erro deve ser JSON válido"

            except json.JSONDecodeError:
                pytest.fail("Resposta de erro para JSON malformado não é JSON válido")

        except Exception as e:
            pytest.fail(f"Erro ao tratar JSON inválido: {e}")

    def test_missing_content_type_handled(self, client):
        try:
            response = client.post('/pergunta',
                                 data='{"pergunta": "teste"}')

            assert response.status_code in [400, 415], "Requisição sem Content-Type deve retornar erro"

        except Exception as e:
            pytest.fail(f"Erro ao tratar requisição sem Content-Type: {e}")

    def test_large_payload_handled(self, client):
        try:
            large_pergunta = "teste " * 10000

            response = client.post('/pergunta',
                                 json={'pergunta': large_pergunta},
                                 content_type='application/json')

            assert response.status_code is not None, "Servidor deve responder a payload grande"
            assert 100 <= response.status_code <= 599, "Status code deve ser válido"

        except Exception as e:
            pytest.fail(f"Erro ao tratar payload grande: {e}")

    def test_sql_injection_basic_protection(self, client):
        try:
            sql_injection_attempts = [
                "'; DROP TABLE funcionarios; --",
                "' OR '1'='1",
                "UNION SELECT * FROM funcionarios",
                "drop table funcionarios",
                "; DELETE FROM vendas WHERE 1=1; --"
            ]

            for attempt in sql_injection_attempts:
                response = client.post('/pergunta',
                                     json={'pergunta': attempt},
                                     content_type='application/json')

                assert response.status_code is not None, "Sistema deve responder a tentativa de SQL injection"

                if response.status_code in [200, 400]:
                    try:
                        data = response.get_json()
                        assert data is not None, "Resposta deve conter JSON válido"

                        response_text = str(data).lower()
                        sucesso = data.get('sucesso', True)

                        if response.status_code == 400 and not sucesso:
                            rejection_indicators = [
                                'segurança', 'security', 'bloqueado', 'blocked',
                                'não posso processar', 'cannot process',
                                'reformule sua pergunta', 'medidas de segurança'
                            ]

                            has_rejection_indicator = any(indicator in response_text for indicator in rejection_indicators)
                            assert has_rejection_indicator, f"Sistema deveria rejeitar SQL injection: {attempt}"
                            print(f"✅ Sistema bloqueou corretamente: {attempt[:30]}...")

                        elif response.status_code == 200:
                            response_content = data.get('resposta', '')

                            dangerous_results = [
                                'table dropped', 'tabela removida', 'dados deletados',
                                'delete from', 'drop table', 'truncate table'
                            ]

                            for dangerous in dangerous_results:
                                assert dangerous not in response_content.lower(), \
                                    f"Sistema pode ter executado comando perigoso: {dangerous}"

                            print(f"✅ Sistema respondeu de forma segura para: {attempt[:30]}...")

                    except Exception as json_error:
                        assert response.status_code != 500, f"Sistema crashou com SQL injection: {attempt}"

                assert response.status_code != 500, f"Sistema crashou com SQL injection: {attempt}"

            print("✅ Todos os testes de proteção contra SQL injection passaram")

        except Exception as e:
            pytest.fail(f"Erro no teste de SQL injection: {e}")


class TestApplicationModules:

    def test_query_mapping_module_loads(self):
        try:
            from app.query_mapping import query_manager
            assert query_manager is not None, "Query manager não carregado"
            assert hasattr(query_manager, 'mappings'), "Query manager não tem mappings"

        except ImportError:
            pytest.skip("Módulo query_mapping não disponível")
        except Exception as e:
            pytest.fail(f"Erro ao carregar query_mapping: {e}")

    def test_basic_nlp_functionality(self):
        try:
            from app.app import extrair_lemmas

            result = extrair_lemmas("teste funcionários")
            assert isinstance(result, set), "extrair_lemmas deve retornar set"

        except ImportError:
            pytest.skip("Funções de NLP não disponíveis")
        except Exception as e:
            pytest.fail(f"Erro na funcionalidade de NLP: {e}")

    def test_basic_query_selection(self):
        try:
            from app.app import selecionar_queries

            result = selecionar_queries("funcionários")
            assert isinstance(result, list), "selecionar_queries deve retornar lista"

        except ImportError:
            pytest.skip("Função selecionar_queries não disponível")
        except Exception as e:
            pytest.fail(f"Erro na seleção de queries: {e}")

    def test_optional_dependencies_status(self):
        optional_deps = {
            'spacy': 'Processamento de linguagem natural',
            'google.generativeai': 'API Gemini',
            'flask_cors': 'CORS para Flask'
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

        essential_available = available_deps.get('flask_cors', False)
        if not essential_available:
            print("⚠️  Aviso: Algumas funcionalidades podem estar limitadas")


class TestPerformanceBaseline:

    @pytest.mark.performance
    def test_application_startup_time(self):
        try:
            start_time = time.time()

            from app.app import create_app
            app = create_app()

            startup_time = time.time() - start_time

            assert startup_time < 10.0, f"Inicialização muito lenta: {startup_time:.2f}s"
            print(f"Tempo de inicialização: {startup_time:.3f}s")

        except ImportError:
            pytest.skip("Função create_app não disponível")
        except Exception as e:
            pytest.fail(f"Erro na medição de startup: {e}")

    @pytest.mark.performance
    def test_basic_endpoint_response_time(self, client):
        try:
            start_time = time.time()

            response = client.post('/pergunta',
                                 json={'pergunta': 'teste rápido'},
                                 content_type='application/json')

            response_time = time.time() - start_time

            assert response_time < 10.0, f"Resposta muito lenta: {response_time:.2f}s"

            print(f"Tempo de resposta básico: {response_time:.3f}s")

        except Exception as e:
            pytest.fail(f"Erro na medição de resposta: {e}")

    @pytest.mark.performance
    def test_memory_usage_baseline(self):
        try:
            import psutil

            process = psutil.Process()
            memory_mb = process.memory_info().rss / 1024 / 1024

            assert memory_mb < 500, f"Uso de memória muito alto: {memory_mb:.1f}MB"

            print(f"Uso de memória baseline: {memory_mb:.1f}MB")

        except ImportError:
            pytest.skip("psutil não disponível para monitoramento de memória")
        except Exception as e:
            pytest.fail(f"Erro na medição de memória: {e}")


class TestCriticalPaths:

    def test_complete_request_cycle(self, client):
        try:
            response = client.post('/pergunta',
                                 json={'pergunta': 'Quantos funcionários temos?'},
                                 content_type='application/json')

            assert response is not None, "Ciclo de requisição falhou"
            assert response.status_code is not None, "Status code não retornado"

            if response.status_code == 200:
                data = json.loads(response.data)
                assert isinstance(data, dict), "Resposta deve ser objeto JSON"

            print(f"Ciclo completo de requisição: {response.status_code}")

        except Exception as e:
            pytest.fail(f"Erro no ciclo completo de requisição: {e}")

    def test_error_handling_path(self, client):
        try:
            response = client.post('/pergunta',
                                 json={'pergunta': ''},
                                 content_type='application/json')

            assert response.status_code == 400, "Pergunta vazia deve retornar 400"

            data = json.loads(response.data)
            assert isinstance(data, dict), "Erro deve ser retornado como JSON"
            assert 'erro' in data or 'error' in data, "Deve conter campo de erro"

            print("Caminho de tratamento de erros: OK")

        except Exception as e:
            pytest.fail(f"Erro no caminho de tratamento de erros: {e}")

    def test_integration_basic_flow(self):
        try:
            from app.app import extrair_lemmas, selecionar_queries

            texto = "funcionários departamento"
            lemmas = extrair_lemmas(texto)
            queries = selecionar_queries(texto)

            assert isinstance(lemmas, set), "Extração de lemmas falhou"
            assert isinstance(queries, list), "Seleção de queries falhou"

            print("Fluxo básico de integração: OK")

        except ImportError:
            pytest.skip("Módulos de integração não disponíveis")
        except Exception as e:
            pytest.fail(f"Erro no fluxo de integração: {e}")
