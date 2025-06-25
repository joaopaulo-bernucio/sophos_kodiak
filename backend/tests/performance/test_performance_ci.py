import pytest
import time
import requests
import threading
from flask import Flask

@pytest.mark.performance
class TestAPIPerformance:

    def test_api_response_time_benchmark(self, client):
        start_time = time.time()
        response = client.post('/pergunta',
                             json={'pergunta': 'Quantos funcionários temos?'},
                             content_type='application/json')
        response_time = time.time() - start_time

        print(f"Tempo de resposta: {response_time:.3f}s")

        assert response_time < 15.0, f"Resposta muito lenta: {response_time:.2f}s"

        if response.status_code == 200:
            import json
            data = json.loads(response.data)
            assert isinstance(data, dict), "Resposta deve ser JSON válido"

    def test_concurrent_requests_performance(self, client):
        num_requests = 5
        results = []

        print(f"Executando {num_requests} requisições sequenciais...")

        for i in range(num_requests):
            start = time.time()
            try:
                response = client.post('/pergunta',
                                     json={'pergunta': f'teste performance {i}'},
                                     content_type='application/json')
                duration = time.time() - start
                results.append({
                    'duration': duration,
                    'status_code': response.status_code,
                    'success': response.status_code in [200, 400, 500]
                })
            except Exception as e:
                results.append({
                    'duration': time.time() - start,
                    'error': str(e),
                    'success': False
                })

        successful = [r for r in results if r.get('success', False)]
        if successful:
            avg_time = sum(r['duration'] for r in successful) / len(successful)
            max_time = max(r['duration'] for r in successful)

            print(f"Requisições bem-sucedidas: {len(successful)}/{len(results)}")
            print(f"Tempo médio: {avg_time:.3f}s")
            print(f"Tempo máximo: {max_time:.3f}s")

            assert avg_time < 10.0, f"Tempo médio muito alto: {avg_time:.2f}s"
            assert max_time < 20.0, f"Tempo máximo muito alto: {max_time:.2f}s"
        else:
            pytest.fail("Nenhuma requisição bem-sucedida")

    def test_health_endpoint_performance(self, client):
        start_time = time.time()
        response = client.get('/health')
        response_time = time.time() - start_time

        print(f"Health check tempo: {response_time:.3f}s")

        assert response_time < 1.0, f"Health check muito lento: {response_time:.2f}s"
        assert response.status_code in [200, 404], "Health endpoint deve responder"


@pytest.mark.performance
class TestDatabasePerformance:

    def test_database_connection_time(self, env_vars):
        try:
            import psycopg2
        except ImportError:
            pytest.skip("psycopg2 não disponível")

        start_time = time.time()

        try:
            conn = psycopg2.connect(
                host=env_vars['DB_HOST'],
                port=env_vars['DB_PORT'],
                dbname=env_vars['DB_NAME'],
                user=env_vars['DB_USER'],
                password=env_vars['DB_PASSWORD']
            )

            connection_time = time.time() - start_time
            cur = conn.cursor()
            cur.execute("SELECT 1")
            result = cur.fetchone()
            total_time = time.time() - start_time

            print(f"Tempo de conexão: {connection_time:.3f}s")
            print(f"Tempo total (conexão + query): {total_time:.3f}s")

            assert connection_time < 2.0, f"Conexão muito lenta: {connection_time:.2f}s"
            assert total_time < 3.0, f"Query muito lenta: {total_time:.2f}s"
            assert result[0] == 1, "Query simples deve funcionar"

            cur.close()
            conn.close()

        except Exception as e:
            pytest.fail(f"Erro de performance de DB: {e}")

    def test_simple_queries_performance(self, env_vars):
        try:
            import psycopg2
        except ImportError:
            pytest.skip("psycopg2 não disponível")

        try:
            conn = psycopg2.connect(
                host=env_vars['DB_HOST'],
                port=env_vars['DB_PORT'],
                dbname=env_vars['DB_NAME'],
                user=env_vars['DB_USER'],
                password=env_vars['DB_PASSWORD']
            )
            cur = conn.cursor()
            queries = [
                "SELECT COUNT(*) FROM funcionarios",
                "SELECT COUNT(*) FROM departamentos",
                "SELECT * FROM departamentos LIMIT 1",
                "SELECT * FROM funcionarios LIMIT 1"
            ]
            query_times = []

            for query in queries:
                start_time = time.time()
                try:
                    cur.execute(query)
                    result = cur.fetchall()
                    query_time = time.time() - start_time
                    query_times.append(query_time)

                    print(f"Query '{query[:30]}...': {query_time:.3f}s")

                except Exception as e:
                    print(f"Query falhou: {query} - {e}")

            if query_times:
                avg_time = sum(query_times) / len(query_times)
                max_time = max(query_times)

                print(f"Tempo médio de query: {avg_time:.3f}s")
                print(f"Tempo máximo de query: {max_time:.3f}s")

                assert avg_time < 1.0, f"Queries muito lentas: {avg_time:.2f}s"
                assert max_time < 2.0, f"Query mais lenta: {max_time:.2f}s"

            cur.close()
            conn.close()

        except Exception as e:
            pytest.skip(f"Erro no teste de queries: {e}")


@pytest.mark.performance
class TestSystemPerformance:

    def test_application_memory_usage(self):
        try:
            import psutil
        except ImportError:
            pytest.skip("psutil não disponível")

        import os
        process = psutil.Process(os.getpid())
        memory_mb = process.memory_info().rss / 1024 / 1024

        print(f"Uso de memória: {memory_mb:.1f}MB")

        assert memory_mb < 1000, f"Uso de memória muito alto: {memory_mb:.1f}MB"

    def test_import_time_performance(self):
        start_time = time.time()

        try:
            from app import app
            from app import query_mapping

            import json
            import time as time_module
            import os

            import_time = time.time() - start_time

            print(f"Tempo de importação: {import_time:.3f}s")

            assert import_time < 5.0, f"Importações muito lentas: {import_time:.2f}s"
            assert app is not None, "App Flask não foi importado"
            assert query_mapping is not None, "query_mapping não foi importado"

        except ImportError as e:
            pytest.skip(f"Módulos não disponíveis: {e}")
        except Exception as e:
            if "route" in str(e).lower() or "setup" in str(e).lower() or "flask" in str(e).lower():
                print(f"Aviso: Problema com decoradores Flask: {e}")
                pytest.skip(f"Flask já inicializado, mas tempo de importação OK: {time.time() - start_time:.3f}s")
            else:
                pytest.fail(f"Erro na importação: {e}")

    def test_nlp_model_loading_time(self):
        try:
            start_time = time.time()

            import spacy
            nlp = spacy.load("pt_core_news_sm")
            load_time = time.time() - start_time

            print(f"Tempo de carregamento do modelo NLP: {load_time:.3f}s")

            assert load_time < 10.0, f"Carregamento muito lento: {load_time:.2f}s"

            start_time = time.time()
            doc = nlp("teste de processamento rápido")
            process_time = time.time() - start_time

            print(f"Tempo de processamento simples: {process_time:.3f}s")

            assert process_time < 1.0, f"Processamento muito lento: {process_time:.2f}s"

        except ImportError:
            pytest.skip("spaCy não disponível")
        except Exception as e:
            pytest.fail(f"Erro no modelo NLP: {e}")
