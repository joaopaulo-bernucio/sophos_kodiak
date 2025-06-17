# -*- coding: utf-8 -*-
"""
Configurações gerais para os testes do backend Sophos Kodiak.

Este arquivo contém fixtures, configurações e utilidades compartilhadas
entre todos os testes do backend Flask.
"""

import pytest
import os
import json
import sys
import logging
import time
from pathlib import Path
from flask import Flask

# Carregar variáveis do arquivo .env (se existir)
try:
    from dotenv import load_dotenv
    # Tenta carregar .env do diretório backend
    env_path = Path(__file__).parent.parent / '.env'
    if env_path.exists():
        load_dotenv(env_path)
        print(f"✅ Carregado .env de: {env_path}")
    else:
        print("⚠️  Arquivo .env não encontrado, usando variáveis de ambiente do sistema")
except ImportError:
    print("⚠️  python-dotenv não instalado, usando apenas variáveis de ambiente do sistema")

# Configurar logging para testes
logging.basicConfig(level=logging.INFO)

# Adicionar o diretório do backend ao path
backend_dir = Path(__file__).parent.parent
sys.path.insert(0, str(backend_dir))

# Configurar ambiente de teste com fallbacks seguros
def get_test_env_var(key, local_default, ci_default):
    """
    Pega variável de ambiente com diferentes defaults para local vs CI.

    Args:
        key: Nome da variável de ambiente
        local_default: Valor padrão para desenvolvimento local
        ci_default: Valor padrão para CI/CD
    """
    # Se estamos em CI (GitHub Actions, GitLab CI, etc.)
    if os.getenv('CI') or os.getenv('GITHUB_ACTIONS') or os.getenv('GITLAB_CI'):
        return os.getenv(key, ci_default)
    else:
        return os.getenv(key, local_default)

# Configurar ambiente de teste
os.environ['FLASK_ENV'] = 'testing'
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


def pytest_collection_modifyitems(config, items):
    """Modificar itens de teste coletados."""
    for item in items:
        # Adicionar marker para testes de API
        if "test_pergunta" in item.name or "test_endpoint" in item.name:
            item.add_marker(pytest.mark.api)
        # Adicionar marker para testes de NLP
        elif "test_nlp" in item.name or "test_query_mapping" in item.name:
            item.add_marker(pytest.mark.nlp)


@pytest.fixture(scope="session")
def nlp_model():
    """
    Fixture que carrega o modelo spaCy uma vez para toda a sessão de testes.

    Returns:
        spacy.Language: Modelo spaCy carregado ou None se não disponível
    """
    if spacy is None:
        pytest.skip("spaCy não está disponível")

    try:
        nlp = spacy.load("pt_core_news_sm")
        return nlp
    except Exception:
        pytest.skip("Modelo spaCy pt_core_news_sm não está disponível")


@pytest.fixture
def app():
    """
    Fixture que fornece a instância da aplicação Flask.

    Returns:
        Flask: Instância da aplicação configurada para testes
    """
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
    """
    Fixture que fornece um cliente de teste Flask.

    Returns:
        FlaskClient: Cliente para fazer requisições de teste
    """
    with app.test_client() as client:
        with app.app_context():
            yield client


@pytest.fixture
def env_vars():
    """
    Fixture que configura variáveis de ambiente para testes.

    Returns:
        dict: Dicionário com as variáveis de ambiente configuradas
    """
    return {
        'DB_HOST': os.getenv('DB_HOST', 'localhost'),
        'DB_PORT': os.getenv('DB_PORT', '5432'),
        'DB_NAME': os.getenv('DB_NAME', 'test_db'),
        'DB_USER': os.getenv('DB_USER', 'postgres'),
        'DB_PASSWORD': os.getenv('DB_PASSWORD', 'postgres'),
        'GEMINI_API_KEY': os.getenv('GEMINI_API_KEY', 'test_api_key'),
        'FLASK_ENV': 'testing'
    }


# ============================================================
# Funções auxiliares para testes
# ============================================================

def assert_json_response(response, expected_status=200):
    """
    Função auxiliar para validar respostas JSON.

    Args:
        response: Resposta Flask
        expected_status: Status code esperado
    """
    assert response.status_code == expected_status, f"Status esperado {expected_status}, recebido {response.status_code}"
    assert 'application/json' in response.content_type, f"Content-Type esperado JSON, recebido {response.content_type}"

    try:
        data = json.loads(response.data)
        return data
    except json.JSONDecodeError as e:
        pytest.fail(f"Resposta não é JSON válido: {e}")


def make_api_request(client, endpoint, method='GET', data=None, headers=None):
    """
    Função auxiliar para fazer requisições API padronizadas.

    Args:
        client: Cliente Flask de teste
        endpoint: Endpoint da API
        method: Método HTTP
        data: Dados para enviar
        headers: Headers da requisição
    """
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
    """
    Factory para criar dados de teste padronizados.
    """

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


# ============================================================
# Markers para pytest
# ============================================================

# Registrar markers customizados
pytest.mark.api = pytest.mark.api  # Testes de API
pytest.mark.nlp = pytest.mark.nlp  # Testes de NLP
pytest.mark.integration = pytest.mark.integration  # Testes de integração
pytest.mark.unit = pytest.mark.unit  # Testes unitários


# ======================================
# FIXTURES PARA TESTES DE QUERY MAPPING
# ======================================

@pytest.fixture
def fresh_query_manager():
    """
    Fixture que retorna uma nova instância do QueryMappingManager.

    Útil para testes que precisam de um estado limpo do gerenciador,
    sem interferir na instância global.
    """
    try:
        from app.query_mapping import QueryMappingManager
        return QueryMappingManager()
    except ImportError:
        pytest.skip("QueryMappingManager não disponível")


@pytest.fixture
def sample_query_mapping():
    """
    Fixture que retorna um QueryMapping de exemplo para testes.
    """
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
    """
    Fixture que retorna casos de teste para validação de queries SQL.

    Returns:
        List[Dict]: Lista de casos de teste com estrutura:
        - input: entrada do usuário
        - expected_id: ID esperado do mapeamento
        - expected_category: categoria esperada
    """
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
    """
    Fixture que retorna os nomes de tabelas esperados no sistema.
    """
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
    """
    Fixture que retorna casos de teste para validação de segurança SQL.

    Returns:
        List[Dict]: Lista com estrutura:
        - description: descrição do teste
        - query: query SQL a ser testada
        - should_be_safe: se a query deveria ser considerada segura
    """
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
    """
    Fixture de sessão que retorna a instância global do query_manager.

    Scope 'session' significa que será criada uma vez por sessão de testes
    e reutilizada em todos os testes que a requisitarem.
    """
    try:
        from app.query_mapping import query_manager
        return query_manager
    except ImportError:
        pytest.skip("query_manager não disponível")


# ======================================
# FIXTURES PARA TESTES DE NLP
# ======================================

@pytest.fixture
def nlp_test_texts():
    """
    Fixture que retorna textos de teste para processamento NLP.

    Returns:
        Dict: Dicionário com categorias de textos de teste
    """
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
    """
    Fixture que retorna lemmas esperados para textos específicos.

    Returns:
        Dict: Mapeamento de texto para lemmas esperados
    """
    return {
        "funcionários trabalham": {"funcionário", "trabalhar"},
        "projetos concluídos": {"projeto", "concluído"},
        "clientes ativos": {"cliente", "ativo"},
        "vendas mensais": {"venda", "mensal"},
        "salário médio": {"salário", "médio"}
    }


@pytest.fixture
def nlp_integration_cases():
    """
    Fixture que retorna casos de teste para integração NLP.

    Returns:
        List[Dict]: Lista de casos de teste com estrutura:
        - input: texto de entrada
        - expected_category: categoria esperada
        - min_lemmas: número mínimo de lemmas esperados
    """
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
    """
    Fixture que retorna dados para testes de performance.

    Returns:
        Dict: Dados para testes de performance
    """
    return {
        'texto_curto': "funcionários",
        'texto_medio': "funcionários do departamento de vendas trabalham com clientes",
        'texto_longo': " ".join(["funcionários trabalham departamento vendas clientes projetos"] * 20),
        'repeticoes': 10,
        'timeout_maximo': 1.0  # 1 segundo
    }


@pytest.fixture(scope="session")
def spacy_model_available():
    """
    Fixture de sessão que verifica se o modelo spaCy está disponível.

    Returns:
        bool: True se o modelo está disponível, False caso contrário
    """
    try:
        import spacy
        model = spacy.load("pt_core_news_sm")
        return True
    except Exception:
        return False


@pytest.fixture
def fallback_test_cases():
    """
    Fixture que retorna casos de teste para fallback quando spaCy não está disponível.

    Returns:
        List[Dict]: Casos de teste para fallback
    """
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


# ======================================
# FIXTURES PARA NOVOS TESTES
# ======================================

@pytest.fixture(scope="session")
def database_connection(env_vars):
    """
    Fixture que fornece conexão real com banco de dados para testes críticos.

    Returns:
        psycopg2.connection: Conexão com banco ou None se não disponível
    """
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

        # Testar conexão
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
    """
    Fixture que permite execução real de queries SQL.

    Returns:
        Callable: Função para executar queries
    """
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
    """
    Fixture que fornece cliente real da API Gemini quando disponível.

    Returns:
        object: Cliente Gemini ou None se não disponível
    """
    api_key = env_vars.get('GEMINI_API_KEY')

    # Pular se não tiver API key real
    if not api_key or api_key in ['test_api_key', 'fake_gemini_key_for_tests', 'test_gemini_api_key']:
        pytest.skip("API key do Gemini não disponível para teste real")

    try:
        import google.generativeai as genai

        genai.configure(api_key=api_key)
        model = genai.GenerativeModel('gemini-pro')

        return model

    except ImportError:
        pytest.skip("Biblioteca google-generativeai não disponível")
    except Exception as e:
        pytest.skip(f"Erro ao configurar Gemini: {e}")


@pytest.fixture
def performance_monitor():
    """
    Fixture para monitoramento básico de performance.

    Returns:
        Dict: Métricas de performance
    """
    import time

    start_time = time.time()
    start_memory = None

    try:
        import psutil
        process = psutil.Process()
        start_memory = process.memory_info().rss
    except ImportError:
        pass

    yield {
        'start_time': start_time,
        'start_memory': start_memory
    }

    # Calcular métricas finais
    end_time = time.time()
    execution_time = end_time - start_time

    end_memory = None
    memory_diff = None
    if start_memory:
        try:
            import psutil
            process = psutil.Process()
            end_memory = process.memory_info().rss
            memory_diff = end_memory - start_memory
        except ImportError:
            pass

    print(f"\nPerformance: {execution_time:.3f}s", end="")
    if memory_diff is not None:
        print(f", Memória: {memory_diff/1024/1024:.1f}MB")
    else:
        print("")


@pytest.fixture
def concurrent_test_helper():
    """
    Fixture que fornece utilitários para testes concorrentes.

    Returns:
        Dict: Funções auxiliares para concorrência
    """
    import threading
    import queue
    from concurrent.futures import ThreadPoolExecutor, as_completed

    def run_concurrent_tasks(tasks, max_workers=5, timeout=30):
        """
        Executa tarefas em paralelo.

        Args:
            tasks: Lista de funções para executar
            max_workers: Número máximo de threads
            timeout: Timeout em segundos

        Returns:
            List: Resultados das tarefas
        """
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
        """
        Cria teste de carga para um endpoint.

        Args:
            client: Cliente Flask de teste
            endpoint: URL do endpoint
            data: Dados para enviar
            num_requests: Número de requisições

        Returns:
            List: Funções de teste
        """
        def make_request():
            return client.post(endpoint, json=data, content_type='application/json')

        return [make_request for _ in range(num_requests)]

    return {
        'run_concurrent': run_concurrent_tasks,
        'create_load_test': create_load_test
    }


@pytest.fixture
def smoke_test_data():
    """
    Fixture que fornece dados padronizados para smoke tests.

    Returns:
        Dict: Dados de teste
    """
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
    """
    Fixture que fornece funções para verificação de qualidade dos dados.

    Returns:
        Dict: Funções de verificação
    """
    def check_table_exists(table_name):
        """Verifica se tabela existe."""
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
        """Obtém contagem de registros de uma tabela."""
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
        """
        Verifica consistência entre tabelas.

        Args:
            table_configs: Lista de configurações de verificação

        Returns:
            Dict: Resultados da verificação
        """
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
    """
    Fixture que fornece dados para testes de cenários reais.

    Returns:
        Dict: Dados e configurações para cenários
    """
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
            'max_memory_increase': 100  # MB
        }
    }


# ======================================
# MARKERS PARA CATEGORIZAÇÃO DE TESTES
# ======================================

# Registrar novos markers
pytest.mark.critical = pytest.mark.critical  # Testes críticos
pytest.mark.smoke = pytest.mark.smoke  # Smoke tests
pytest.mark.infrastructure = pytest.mark.infrastructure  # Testes de infraestrutura
pytest.mark.data_quality = pytest.mark.data_quality  # Testes de qualidade dos dados
pytest.mark.real_scenarios = pytest.mark.real_scenarios  # Cenários reais
pytest.mark.performance = pytest.mark.performance  # Testes de performance
pytest.mark.concurrent = pytest.mark.concurrent  # Testes de concorrência
pytest.mark.security = pytest.mark.security  # Testes de segurança


def pytest_configure(config):
    """Configurar pytest com novos markers."""
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
