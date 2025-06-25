import pytest
import os
import json
import sys
import logging
import time
from pathlib import Path
from flask import Flask

try:
    from dotenv import load_dotenv
    env_path = Path(__file__).parent.parent / '.env'
    if env_path.exists():
        load_dotenv(env_path)
        print(f"✅ Carregado .env de: {env_path}")
    else:
        print("⚠️  Arquivo .env não encontrado, usando variáveis de ambiente do sistema")
except ImportError:
    print("⚠️  python-dotenv não instalado, usando apenas variáveis de ambiente do sistema")

logging.basicConfig(level=logging.INFO)
backend_dir = Path(__file__).parent.parent
sys.path.insert(0, str(backend_dir))

def get_test_env_var(key, local_default, ci_default):
    if os.getenv('CI') or os.getenv('GITHUB_ACTIONS') or os.getenv('GITLAB_CI'):
        return os.getenv(key, ci_default)
    else:
        return os.getenv(key, local_default)

os.environ['FLASK_ENV'] = 'testing'
os.environ['USE_MOCK_GEMINI'] = 'true'
os.environ['DB_HOST'] = get_test_env_var('DB_HOST',
                                        local_default=os.getenv('DB_HOST', 'localhost'),
                                        ci_default='localhost')
os.environ['DB_PORT'] = get_test_env_var('DB_PORT',
                                        local_default=os.getenv('DB_PORT', '5432'),
                                        ci_default='5432')
os.environ['DB_NAME'] = get_test_env_var('DB_NAME',
                                        local_default=os.getenv('DB_NAME', 'test_db'),
                                        ci_default='test_db')
os.environ['DB_USER'] = get_test_env_var('DB_USER',
                                        local_default=os.getenv('DB_USER', 'postgres'),
                                        ci_default='postgres')
os.environ['DB_PASSWORD'] = get_test_env_var('DB_PASSWORD',
                                            local_default=os.getenv('DB_PASSWORD', 'postgres'),
                                            ci_default='postgres')
os.environ['GEMINI_API_KEY'] = get_test_env_var('GEMINI_API_KEY',
                                               local_default=os.getenv('GEMINI_API_KEY', 'test_gemini_api_key'),
                                               ci_default='fake_gemini_key_for_tests')

try:
    import spacy
except ImportError:
    spacy = None

try:
    import psycopg2
except ImportError:
    psycopg2 = None

genai = None
GOOGLE_GENAI_AVAILABLE = False
try:
    import google.generativeai as genai
    GOOGLE_GENAI_AVAILABLE = True
except ImportError:
    pass

psutil = None
PSUTIL_AVAILABLE = False
try:
    import psutil
    PSUTIL_AVAILABLE = True
except ImportError:
    pass

def pytest_collection_modifyitems(config, items):
    for item in items:
        if "test_pergunta" in item.name or "test_endpoint" in item.name:
            item.add_marker(pytest.mark.api)
        elif "test_nlp" in item.name or "test_query_mapping" in item.name:
            item.add_marker(pytest.mark.nlp)

@pytest.fixture(scope="session")
def nlp_model():
    if spacy is None:
        pytest.skip("spaCy não está disponível")
    try:
        nlp = spacy.load("pt_core_news_sm")
        return nlp
    except Exception:
        pytest.skip("Modelo spaCy pt_core_news_sm não está disponível")

@pytest.fixture
def app():
    try:
        from app.app import app as flask_app
        flask_app.config.update({
            'TESTING': True,
            'WTF_CSRF_ENABLED': False,
            'JSON_AS_ASCII': False,
            'JSON_SORT_KEYS': False
        })
        return flask_app
    except ImportError:
        pytest.skip("Não foi possível importar a aplicação Flask")

@pytest.fixture
def client(app):
    app.config.update({
        'TESTING': True,
        'WTF_CSRF_ENABLED': False,
        'JSON_AS_ASCII': False,
        'JSON_SORT_KEYS': False
    })
    with app.test_client() as client:
        with app.app_context():
            yield client

@pytest.fixture
def env_vars():
    return {
        'DB_HOST': os.getenv('DB_HOST', 'localhost'),
        'DB_PORT': os.getenv('DB_PORT', '5432'),
        'DB_NAME': os.getenv('DB_NAME', 'test_db'),
        'DB_USER': os.getenv('DB_USER', 'postgres'),
        'DB_PASSWORD': os.getenv('DB_PASSWORD', 'postgres'),
        'GEMINI_API_KEY': os.getenv('GEMINI_API_KEY', 'test_api_key'),
        'FLASK_ENV': 'testing'
    }

def assert_json_response(response, expected_status=200):
    assert response.status_code == expected_status, f"Status esperado {expected_status}, recebido {response.status_code}"
    assert 'application/json' in response.content_type, f"Content-Type esperado JSON, recebido {response.content_type}"
    try:
        data = json.loads(response.data)
        return data
    except json.JSONDecodeError as e:
        pytest.fail(f"Resposta não é JSON válido: {e}")

def make_api_request(client, endpoint, method='GET', data=None, headers=None):
    if headers is None:
        headers = {'Content-Type': 'application/json'}
    if method.upper() == 'POST':
        if data:
            return client.post(endpoint, json=data, headers=headers)
        else:
            return client.post(endpoint, headers=headers)
    elif method.upper() == 'GET':
        return client.get(endpoint, headers=headers)
    elif method.upper() == 'PUT':
        return client.put(endpoint, json=data, headers=headers)
    elif method.upper() == 'DELETE':
        return client.delete(endpoint, headers=headers)
    else:
        raise ValueError(f"Método HTTP não suportado: {method}")

class TestDataFactory:
    @staticmethod
    def create_funcionario(id=1, nome="João Silva", departamento="TI"):
        return {
            'id': id,
            'nome': nome,
            'departamento': departamento,
            'cargo': 'Desenvolvedor',
            'salario': 5000
        }

    @staticmethod
    def create_pergunta_valida(texto="Quantos funcionários temos?"):
        return {'pergunta': texto}

    @staticmethod
    def create_pergunta_invalida(tipo='vazia'):
        if tipo == 'vazia':
            return {'pergunta': ''}
        elif tipo == 'sem_campo':
            return {'outro_campo': 'valor'}
        elif tipo == 'muito_longa':
            return {'pergunta': 'a' * 1001}
        else:
            return {}

    @staticmethod
    def create_resposta_sucesso(resposta="Resposta de teste"):
        return {
            'resposta': resposta,
            'sucesso': True
        }

    @staticmethod
    def create_resposta_erro(erro="Erro de teste"):
        return {
            'erro': erro,
            'sucesso': False
        }

pytest.mark.api = pytest.mark.api
pytest.mark.nlp = pytest.mark.nlp
pytest.mark.integration = pytest.mark.integration
pytest.mark.unit = pytest.mark.unit


@pytest.fixture
def fresh_query_manager():
    try:
        from app.query_mapping import QueryMappingManager
        return QueryMappingManager()
    except ImportError:
        pytest.skip("QueryMappingManager não disponível")

@pytest.fixture
def sample_query_mapping():
    try:
        from app.query_mapping import QueryMapping, QueryCategory
        return QueryMapping(
            keywords=["teste", "exemplo", "sample"],
            query_id="teste-exemplo",
            sql_query="SELECT * FROM teste WHERE exemplo = 'sample';",
            category=QueryCategory.LISTS,
            description="Mapeamento de exemplo para testes"
        )
    except ImportError:
        pytest.skip("QueryMapping não disponível")

@pytest.fixture
def query_test_cases():
    try:
        from app.query_mapping import QueryCategory
        return [
            {
                "input": "quantos funcionários",
                "expected_id": "funcionarios-total",
                "expected_category": QueryCategory.TOTALS
            },
            {
                "input": "listar funcionários",
                "expected_id": "funcionarios-lista",
                "expected_category": QueryCategory.LISTS
            },
            {
                "input": "salário médio",
                "expected_id": "salario-medio",
                "expected_category": QueryCategory.STATISTICS
            },
            {
                "input": "detalhes de vendas",
                "expected_id": "vendas-detalhes",
                "expected_category": QueryCategory.DETAILS
            },
            {
                "input": "último projeto",
                "expected_id": "projeto-mais-recente",
                "expected_category": QueryCategory.RECENT
            }
        ]
    except ImportError:
        pytest.skip("QueryCategory não disponível")

@pytest.fixture
def expected_table_names():
    return [
        'funcionarios',
        'projetos',
        'clientes',
        'vendas',
        'departamentos',
        'contratos_marketing'
    ]

@pytest.fixture
def sql_security_test_cases():
    return [
        {
            "description": "Query básica segura",
            "query": "SELECT COUNT(*) FROM funcionarios;",
            "should_be_safe": True
        },
        {
            "description": "Query com WHERE usando comparação direta",
            "query": "SELECT * FROM funcionarios WHERE status = 'Ativo';",
            "should_be_safe": True
        },
        {
            "description": "Query com BETWEEN",
            "query": "SELECT * FROM vendas WHERE data_venda BETWEEN '2024-01-01' AND '2024-12-31';",
            "should_be_safe": True
        },
        {
            "description": "Query com CURRENT_DATE",
            "query": "SELECT * FROM projetos WHERE data_inicio = CURRENT_DATE;",
            "should_be_safe": True
        },
        {
            "description": "Query com JOIN",
            "query": """
                SELECT f.nome, d.nome
                FROM funcionarios f
                JOIN departamentos d ON f.departamento_id = d.id;
            """,
            "should_be_safe": True
        }
    ]

@pytest.fixture(scope="session")
def global_query_manager():
    try:
        from app.query_mapping import query_manager
        return query_manager
    except ImportError:
        pytest.skip("query_manager não disponível")


@pytest.fixture
def nlp_test_texts():
    return {
        'simples': [
            "funcionários",
            "projetos",
            "clientes",
            "vendas"
        ],
        'compostos': [
            "quantos funcionários",
            "total de projetos",
            "listar clientes",
            "salário médio"
        ],
        'complexos': [
            "Gostaria de saber quantos funcionários temos na empresa",
            "Você pode me mostrar o total de projetos concluídos?",
            "Qual é a lista de todos os clientes ativos no sistema?"
        ],
        'especiais': [
            "funcionário@empresa.com",
            "R$ 5.000,00",
            "10% dos funcionários",
            "vendas (último mês)"
        ],
        'acentuados': [
            "funcionário",
            "operação",
            "informação",
            "relatório",
            "estatísticas"
        ]
    }

@pytest.fixture
def expected_lemmas():
    return {
        "funcionários trabalham": {"funcionário", "trabalhar"},
        "projetos concluídos": {"projeto", "concluído"},
        "clientes ativos": {"cliente", "ativo"},
        "vendas mensais": {"venda", "mensal"},
        "salário médio": {"salário", "médio"}
    }

@pytest.fixture
def nlp_integration_cases():
    return [
        {
            "input": "quantos funcionários",
            "expected_category": "funcionario",
            "min_lemmas": 1
        },
        {
            "input": "total de projetos",
            "expected_category": "projeto",
            "min_lemmas": 1
        },
        {
            "input": "listar clientes ativos",
            "expected_category": "cliente",
            "min_lemmas": 2
        },
        {
            "input": "salário médio dos empregados",
            "expected_category": "salario",
            "min_lemmas": 2
        }
    ]

@pytest.fixture
def performance_test_data():
    return {
        'texto_curto': "funcionários",
        'texto_medio': "funcionários do departamento de vendas trabalham com clientes",
        'texto_longo': " ".join(["funcionários trabalham departamento vendas clientes projetos"] * 20),
        'repeticoes': 10,
        'timeout_maximo': 1.0
    }

@pytest.fixture(scope="session")
def spacy_model_available():
    try:
        import spacy
        model = spacy.load("pt_core_news_sm")
        return True
    except Exception:
        return False

@pytest.fixture
def fallback_test_cases():
    return [
        {
            "input": "funcionários trabalham",
            "expected_type": set,
            "should_contain": ["funcionários", "trabalham"]
        },
        {
            "input": "projetos, clientes!",
            "expected_type": set,
            "should_not_contain": [",", "!"]
        },
        {
            "input": "R$ 1.000,00",
            "expected_type": set,
            "should_contain": ["r", "1", "000", "00"]
        }
    ]


@pytest.fixture(scope="session")
def database_connection(env_vars):
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
        cur.fetchone()
        cur.close()

        yield conn

        try:
            conn.close()
        except:
            pass

    except ImportError:
        pytest.skip("psycopg2 não disponível")
    except Exception as e:
        pytest.skip(f"Banco de dados não disponível: {e}")

@pytest.fixture
def real_query_execution(database_connection):
    def execute_query(sql, params=None):
        if database_connection is None:
            pytest.skip("Conexão com banco não disponível")

        cur = database_connection.cursor()
        try:
            cur.execute(sql, params)
            result = cur.fetchall()
            return result
        finally:
            cur.close()

    return execute_query

@pytest.fixture
def gemini_api_client(env_vars):
    if not GOOGLE_GENAI_AVAILABLE:
        pytest.skip("Biblioteca google-generativeai não disponível")

    api_key = env_vars.get('GEMINI_API_KEY')

    if not api_key or api_key in ['test_api_key', 'fake_gemini_key_for_tests', 'test_gemini_api_key']:
        pytest.skip("API key do Gemini não disponível para teste real")

    try:
        genai.configure(api_key=api_key)
        model = genai.GenerativeModel('gemini-2.5-flash')

        return model

    except Exception as e:
        pytest.skip(f"Erro ao configurar Gemini: {e}")

@pytest.fixture
def performance_monitor():
    import time

    start_time = time.time()
    start_memory = None

    if PSUTIL_AVAILABLE:
        try:
            process = psutil.Process()
            start_memory = process.memory_info().rss
        except Exception:
            pass

    yield {
        'start_time': start_time,
        'start_memory': start_memory
    }

    end_time = time.time()
    execution_time = end_time - start_time

    end_memory = None
    memory_diff = None
    if start_memory and PSUTIL_AVAILABLE:
        try:
            process = psutil.Process()
            end_memory = process.memory_info().rss
            memory_diff = end_memory - start_memory
        except Exception:
            pass

    print(f"\nPerformance: {execution_time:.3f}s", end="")
    if memory_diff is not None:
        print(f", Memória: {memory_diff/1024/1024:.1f}MB")
    else:
        print("")


@pytest.fixture
def concurrent_test_helper():
    import threading
    import queue
    from concurrent.futures import ThreadPoolExecutor, as_completed

    def run_concurrent_tasks(tasks, max_workers=5, timeout=30):
        results = []
        errors = []

        with ThreadPoolExecutor(max_workers=max_workers) as executor:
            futures = [executor.submit(task) for task in tasks]

            for future in as_completed(futures, timeout=timeout):
                try:
                    result = future.result()
                    results.append(result)
                except Exception as e:
                    errors.append(str(e))

        return {
            'results': results,
            'errors': errors,
            'success_count': len(results),
            'error_count': len(errors)
        }

    def create_load_test(client, endpoint, data, num_requests=10):
        def make_request():
            return client.post(endpoint, json=data, content_type='application/json')

        return [make_request for _ in range(num_requests)]

    return {
        'run_concurrent': run_concurrent_tasks,
        'create_load_test': create_load_test
    }

@pytest.fixture
def smoke_test_data():
    return {
        'valid_questions': [
            'Quantos funcionários temos?',
            'Total de projetos',
            'Listar departamentos'
        ],
        'invalid_questions': [
            '',
            None,
            'x' * 10000
        ],
        'malicious_inputs': [
            "'; DROP TABLE funcionarios; --",
            '<script>alert("xss")</script>',
            '../../etc/passwd'
        ],
        'test_endpoints': [
            '/health',
            '/pergunta',
            '/api/query/metricas_gerais'
        ]
    }


@pytest.fixture
def data_quality_checker(database_connection):
    def check_table_exists(table_name):
        if not database_connection:
            return False

        cur = database_connection.cursor()
        try:
            cur.execute("""
                SELECT EXISTS (
                    SELECT FROM information_schema.tables
                    WHERE table_name = %s
                );
            """, (table_name,))
            return cur.fetchone()[0]
        finally:
            cur.close()

    def get_table_count(table_name):
        if not database_connection:
            return 0

        cur = database_connection.cursor()
        try:
            cur.execute(f"SELECT COUNT(*) FROM {table_name};")
            return cur.fetchone()[0]
        except:
            return 0
        finally:
            cur.close()

    def check_data_consistency(table_configs):
        results = {}

        for config in table_configs:
            table = config['table']
            checks = config.get('checks', [])

            results[table] = {
                'exists': check_table_exists(table),
                'count': get_table_count(table),
                'checks': {}
            }

            for check in checks:
                check_name = check['name']
                check_sql = check['sql']

                cur = database_connection.cursor()
                try:
                    cur.execute(check_sql)
                    result = cur.fetchone()[0]
                    results[table]['checks'][check_name] = result
                except Exception as e:
                    results[table]['checks'][check_name] = f"Erro: {e}"
                finally:
                    cur.close()

        return results

    return {
        'table_exists': check_table_exists,
        'table_count': get_table_count,
        'check_consistency': check_data_consistency
    }


@pytest.fixture
def real_scenarios_data():
    return {
        'user_interactions': [
            {
                'name': 'consulta_funcionarios',
                'steps': [
                    {'action': 'pergunta', 'data': 'Quantos funcionários temos?'},
                    {'action': 'pergunta', 'data': 'Funcionários por departamento'},
                    {'action': 'pergunta', 'data': 'Salário médio'}
                ]
            },
            {
                'name': 'consulta_projetos',
                'steps': [
                    {'action': 'pergunta', 'data': 'Total de projetos'},
                    {'action': 'pergunta', 'data': 'Projetos em andamento'},
                    {'action': 'api', 'endpoint': '/api/query/projetos_por_status'}
                ]
            }
        ],
        'stress_test_config': {
            'concurrent_users': 5,
            'requests_per_user': 10,
            'test_duration': 30,
            'request_interval': 0.5
        },
        'performance_thresholds': {
            'max_response_time': 10.0,
            'max_error_rate': 0.2,
            'max_memory_increase': 100
        }
    }

pytest.mark.critical = pytest.mark.critical
pytest.mark.smoke = pytest.mark.smoke
pytest.mark.infrastructure = pytest.mark.infrastructure
pytest.mark.data_quality = pytest.mark.data_quality
pytest.mark.real_scenarios = pytest.mark.real_scenarios
pytest.mark.performance = pytest.mark.performance
pytest.mark.concurrent = pytest.mark.concurrent
pytest.mark.security = pytest.mark.security

def pytest_configure(config):
    config.addinivalue_line(
        "markers", "critical: marca testes críticos de infraestrutura"
    )
    config.addinivalue_line(
        "markers", "smoke: marca smoke tests básicos"
    )
    config.addinivalue_line(
        "markers", "infrastructure: marca testes de infraestrutura"
    )
    config.addinivalue_line(
        "markers", "data_quality: marca testes de qualidade dos dados"
    )
    config.addinivalue_line(
        "markers", "real_scenarios: marca testes de cenários reais"
    )
    config.addinivalue_line(
        "markers", "performance: marca testes de performance"
    )
    config.addinivalue_line(
        "markers", "concurrent: marca testes de concorrência"
    )
    config.addinivalue_line(
        "markers", "security: marca testes de segurança"
    )
