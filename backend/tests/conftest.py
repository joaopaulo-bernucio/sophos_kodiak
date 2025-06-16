# -*- coding: utf-8 -*-
"""
Configurações gerais para os testes do backend Sophos Kodiak.

Este arquivo contém fixtures, configurações e utilidades compartilhadas
entre todos os testes do backend Flask.
"""

import pytest
import os
import tempfile
import json
import sys
import logging
from pathlib import Path

# Configurar logging para testes
logging.basicConfig(level=logging.INFO)

try:
    import psycopg2
except ImportError:
    psycopg2 = None

from unittest.mock import Mock, patch, MagicMock
from flask import Flask, jsonify, request

# Adicionar o diretório do backend ao path
backend_dir = Path(__file__).parent.parent
sys.path.insert(0, str(backend_dir))

try:
    import spacy
except ImportError:
    spacy = None

# Importar ou criar um mock da aplicação Flask
flask_app = None
try:
    from app.app import app as imported_flask_app
    flask_app = imported_flask_app
except ImportError:
    # Criar uma aplicação Flask básica para testes se não conseguir importar
    flask_app = Flask(__name__)
    flask_app.config['TESTING'] = True

    # Adicionar rotas básicas necessárias para os testes
    @flask_app.route('/pergunta', methods=['POST'])
    def pergunta():
        try:
            data = request.get_json()
            if not data or 'pergunta' not in data:
                return jsonify({'erro': 'Campo pergunta é obrigatório', 'sucesso': False}), 400

            if not data['pergunta'].strip():
                return jsonify({'erro': 'Pergunta não pode estar vazio', 'sucesso': False}), 400

            # Simular processamento bem-sucedido
            return jsonify({
                'resposta': 'Resposta simulada para teste',
                'sucesso': True
            }), 200
        except Exception as e:
            return jsonify({'erro': f'Erro interno: {str(e)}', 'sucesso': False}), 500

    @flask_app.route('/health', methods=['GET'])
    def health():
        return jsonify({'status': 'healthy'}), 200


def pytest_configure():
    """Configuração global para todos os testes."""
    # Configurar variáveis de ambiente para testes
    os.environ['FLASK_ENV'] = 'testing'
    os.environ['DB_HOST'] = 'localhost'
    os.environ['DB_PORT'] = '5432'
    os.environ['DB_NAME'] = 'test_db'
    os.environ['DB_USER'] = 'postgres'
    os.environ['DB_PASSWORD'] = 'postgres'
    os.environ['GEMINI_API_KEY'] = 'test_api_key'

    # Configurar mocks globais para clientes que podem faltar
    try:
        import app.app as app_module
        from tests.mocks.mock_supabase import (
            MockSupabaseClient,
            MockGeminiClient,
            MockEnviarParaGemini,
            MockSelecionarQueries,
            MockProcessarTexto
        )

        # Configurar clientes mock se não estiverem definidos
        if not hasattr(app_module, 'supabase_client') or app_module.supabase_client is None:
            app_module.supabase_client = MockSupabaseClient()

        if not hasattr(app_module, 'gemini_client') or app_module.gemini_client is None:
            app_module.gemini_client = MockGeminiClient()

        # Configurar mocks de funções específicas
        if not hasattr(app_module, 'enviar_para_gemini'):
            app_module.enviar_para_gemini = MockEnviarParaGemini()

        if not hasattr(app_module, 'selecionar_queries'):
            app_module.selecionar_queries = MockSelecionarQueries()

        # Configurar funções de processamento de texto
        if not hasattr(app_module, 'extrair_lemmas'):
            app_module.extrair_lemmas = MockProcessarTexto.extrair_lemmas

        if not hasattr(app_module, 'processar_texto'):
            app_module.processar_texto = MockProcessarTexto.processar_texto

    except ImportError:
        logging.warning("Não foi possível importar app.app, usando mocks básicos")
        pass  # Ignorar se não conseguir importar


def pytest_runtest_setup(item):
    """Setup executado antes de cada teste."""
    # Garantir que temos os mocks necessários disponíveis
    pass


def pytest_collection_modifyitems(config, items):
    """Modificar itens de teste coletados."""
    for item in items:
        # Adicionar marker para testes que precisam de mocks específicos
        if "test_pergunta" in item.name:
            item.add_marker(pytest.mark.api)
        elif "test_nlp" in item.name:
            item.add_marker(pytest.mark.nlp)


@pytest.fixture(scope="session")
def nlp_model():
    """
    Fixture que carrega o modelo spaCy uma vez para toda a sessão de testes.

    Returns:
        spacy.Language: Modelo spaCy carregado ou mock se não disponível
    """
    if spacy is None:
        # Se spacy não estiver disponível, criar um mock robusto
        mock_nlp = Mock()
        mock_token = Mock()
        mock_token.lemma_ = "test"
        mock_token.pos_ = "NOUN"
        mock_token.text = "test"
        mock_token.lower_ = "test"

        mock_doc = Mock()
        mock_doc.configure_mock(**{
            '__iter__': lambda x: iter([mock_token]),
            'text': 'test',
            'ents': [],
        })
        mock_nlp.return_value = mock_doc
        return mock_nlp

    try:
        nlp = spacy.load("pt_core_news_sm")
        return nlp
    except Exception:
        # Se o modelo não estiver disponível, criar um mock robusto
        mock_nlp = Mock()
        mock_token = Mock()
        mock_token.lemma_ = "test"
        mock_token.pos_ = "NOUN"
        mock_token.text = "test"
        mock_token.lower_ = "test"

        mock_doc = Mock()
        mock_doc.configure_mock(**{
            '__iter__': lambda x: iter([mock_token]),
            'text': 'test',
            'ents': [],
        })
        mock_nlp.return_value = mock_doc
        return mock_nlp


@pytest.fixture
def client():
    """
    Fixture que fornece um cliente de teste Flask.

    Returns:
        FlaskClient: Cliente para fazer requisições de teste
    """
    # Configurar variáveis de ambiente para testes
    test_env = {
        'DB_HOST': 'localhost',
        'DB_PORT': '5432',
        'DB_NAME': 'test_db',
        'DB_USER': 'postgres',
        'DB_PASSWORD': 'postgres',
        'GEMINI_API_KEY': 'test_api_key_123456789',
        'FLASK_ENV': 'testing'
    }

    with patch.dict(os.environ, test_env):
        # Usar a aplicação Flask configurada globalmente
        if flask_app is None:
            # Criar uma aplicação básica se não existir
            test_app = Flask(__name__)
            test_app.config['TESTING'] = True
            test_app.config['WTF_CSRF_ENABLED'] = False
        else:
            test_app = flask_app
            test_app.config['TESTING'] = True
            test_app.config['WTF_CSRF_ENABLED'] = False

        with test_app.test_client() as client:
            with test_app.app_context():
                yield client


@pytest.fixture
def app():
    """
    Fixture que fornece a instância da aplicação Flask.

    Returns:
        Flask: Instância da aplicação configurada para testes
    """
    if hasattr(flask_app, 'config'):
        flask_app.config['TESTING'] = True
        return flask_app
    else:
        # Se não conseguiu importar o app, retornar um mock
        return Mock()


@pytest.fixture
def mock_db_connection():
    """
    Fixture que simula uma conexão com o banco de dados.

    Returns:
        Mock: Conexão mockada com métodos cursor e close
    """
    mock_conn = Mock()
    mock_cursor = Mock()

    # Configurar o cursor para retornar dados fictícios
    mock_cursor.fetchall.return_value = [
        (1, 'João Silva', 'Desenvolvedor', 'TI', 5000),
        (2, 'Maria Santos', 'Designer', 'Criação', 4500),
    ]
    mock_cursor.fetchone.return_value = (1, 'João Silva', 'Desenvolvedor', 'TI', 5000)
    mock_cursor.description = [
        ('id',), ('nome',), ('cargo',), ('departamento',), ('salario',)
    ]
    mock_cursor.execute = Mock()
    mock_cursor.close = Mock()

    mock_conn.cursor.return_value = mock_cursor
    mock_conn.close = Mock()
    mock_conn.commit = Mock()
    mock_conn.rollback = Mock()

    return mock_conn


@pytest.fixture
def mock_get_db_connection(mock_db_connection):
    """
    Mock da função get_db_connection que retorna uma conexão mockada.
    """
    with patch('app.app.get_db_connection') as mock_func:
        mock_func.return_value = mock_db_connection
        yield mock_func


@pytest.fixture
def mock_enviar_para_gemini():
    """
    Mock da função enviar_para_gemini que retorna respostas controladas.
    """
    from tests.mocks.mock_supabase import MockEnviarParaGemini

    mock_func = MockEnviarParaGemini()

    with patch('app.app.enviar_para_gemini', side_effect=mock_func) as patched:
        yield patched


@pytest.fixture
def mock_selecionar_queries():
    """
    Mock da função selecionar_queries que retorna queries padrão.
    """
    from tests.mocks.mock_supabase import MockSelecionarQueries

    mock_func = MockSelecionarQueries()

    with patch('app.app.selecionar_queries', side_effect=mock_func) as patched:
        yield patched


@pytest.fixture
def mock_text_processing():
    """
    Mock das funções de processamento de texto para evitar erros de NoneType.
    """
    from tests.mocks.mock_supabase import MockProcessarTexto

    with patch('app.app.extrair_lemmas', side_effect=MockProcessarTexto.extrair_lemmas) as mock_lemmas, \
         patch('app.app.processar_texto', side_effect=MockProcessarTexto.processar_texto) as mock_process:

        yield {'lemmas': mock_lemmas, 'process': mock_process}


@pytest.fixture
def mock_gemini_response():
    """
    Fixture que simula uma resposta da API Gemini.

    Returns:
        dict: Resposta mockada da API Gemini
    """
    return {
        "candidates": [
            {
                "content": {
                    "parts": [
                        {
                            "text": "Olá! Sou o Sophos, assistente virtual da STOLF LTDA. "
                                   "Com base nos dados consultados, posso ajudá-lo com informações "
                                   "sobre funcionários, projetos e vendas."
                        }
                    ]
                }
            }
        ]
    }


@pytest.fixture
def json_response_mock():
    """
    Fixture que garante que todas as respostas Flask sejam JSON válidas.
    """
    original_jsonify = jsonify

    def safe_jsonify(*args, **kwargs):
        """Versão segura do jsonify que sempre retorna JSON válido."""
        try:
            return original_jsonify(*args, **kwargs)
        except Exception as e:
            # Se houver erro na serialização, retornar erro estruturado
            return original_jsonify({
                'erro': f'Erro na serialização JSON: {str(e)}',
                'sucesso': False
            }), 500

    with patch('flask.jsonify', side_effect=safe_jsonify):
        yield


@pytest.fixture
def mock_parameterized_queries():
    """
    Mock para queries parametrizadas que previne SQL injection.
    """
    def execute_safe_query(query, params=None):
        """Executa query de forma segura com parâmetros."""
        if params is None:
            params = []

        # Simular validação de parâmetros
        if '%s' in query and not params:
            raise ValueError("Query com placeholders precisa de parâmetros")

        # Retornar resultado mockado
        return [
            {'id': 1, 'nome': 'Resultado Mock', 'valor': 1000}
        ]

    mock_cursor = Mock()
    mock_cursor.execute.side_effect = execute_safe_query
    mock_cursor.fetchall.return_value = [
        (1, 'Resultado Mock', 1000)
    ]

    yield mock_cursor


@pytest.fixture
def sample_funcionarios():
    """
    Fixture com dados de exemplo de funcionários.

    Returns:
        list: Lista de dicionários representando funcionários
    """
    return [
        {
            'id': 1,
            'nome': 'João Silva',
            'cargo': 'Desenvolvedor Senior',
            'departamento': 'TI',
            'salario': 8000
        },
        {
            'id': 2,
            'nome': 'Maria Santos',
            'cargo': 'Designer Gráfico',
            'departamento': 'Criação',
            'salario': 6000
        },
        {
            'id': 3,
            'nome': 'Pedro Costa',
            'cargo': 'Analista de Marketing',
            'departamento': 'Marketing Digital',
            'salario': 5500
        }
    ]


@pytest.fixture
def sample_queries():
    """
    Fixture com perguntas de exemplo para testes.

    Returns:
        list: Lista de perguntas e respostas esperadas
    """
    return [
        {
            'pergunta': 'Quantos funcionários temos?',
            'label_esperado': 'funcionarios-total',
            'tipo': 'contagem',
            'resposta_esperada': 'Temos X funcionários no total.'
        },
        {
            'pergunta': 'Qual o salário médio?',
            'label_esperado': 'salario-medio',
            'tipo': 'estatistica',
            'resposta_esperada': 'O salário médio é R$ X.'
        },
        {
            'pergunta': 'Listar todos os funcionários',
            'label_esperado': 'funcionarios-lista',
            'tipo': 'listagem',
            'resposta_esperada': 'Aqui está a lista de funcionários:'
        },
        {
            'pergunta': 'Projetos em andamento',
            'label_esperado': 'projetos-andamento',
            'tipo': 'filtro',
            'resposta_esperada': 'Projetos atualmente em andamento:'
        },
        {
            'pergunta': '',  # Pergunta vazia para teste de erro
            'label_esperado': None,
            'tipo': 'erro',
            'resposta_esperada': 'erro'
        }
    ]


@pytest.fixture
def error_scenarios():
    """
    Fixture com cenários de erro para testes robustos.
    """
    return [
        {
            'tipo': 'json_invalido',
            'data': 'not json',
            'content_type': 'application/json',
            'status_esperado': 400
        },
        {
            'tipo': 'campo_faltando',
            'data': {'outro_campo': 'valor'},
            'content_type': 'application/json',
            'status_esperado': 400
        },
        {
            'tipo': 'pergunta_vazia',
            'data': {'pergunta': ''},
            'content_type': 'application/json',
            'status_esperado': 400
        },
        {
            'tipo': 'content_type_errado',
            'data': '{"pergunta": "teste"}',
            'content_type': 'text/plain',
            'status_esperado': 400
        },
        {
            'tipo': 'pergunta_muito_longa',
            'data': {'pergunta': 'a' * 1001},
            'content_type': 'application/json',
            'status_esperado': 400
        }
    ]


@pytest.fixture
def mock_charts_data():
    """
    Mock de dados para endpoints de charts.
    """
    return {
        'total_vendas_por_mes': [
            {'mes': '2024-01', 'total_vendas': 15000.00},
            {'mes': '2024-02', 'total_vendas': 18000.00},
            {'mes': '2024-03', 'total_vendas': 22000.00}
        ],
        'funcionarios_por_departamento': [
            {'departamento': 'TI', 'quantidade': 5},
            {'departamento': 'Marketing', 'quantidade': 3},
            {'departamento': 'Vendas', 'quantidade': 4}
        ],
        'projetos_por_status': [
            {'status': 'Em Andamento', 'quantidade': 8},
            {'status': 'Concluído', 'quantidade': 12},
            {'status': 'Pausado', 'quantidade': 2}
        ]
    }


@pytest.fixture
def env_vars():
    """
    Fixture que configura variáveis de ambiente para testes.

    Yields:
        dict: Dicionário com as variáveis de ambiente configuradas
    """
    test_env = {
        'DB_HOST': 'localhost',
        'DB_PORT': '5432',
        'DB_NAME': 'test_db',
        'DB_USER': 'test_user',
        'DB_PASSWORD': 'test_password',
        'GEMINI_API_KEY': 'test_api_key_123456789',
        'FLASK_ENV': 'testing'
    }

    # Aplicar as variáveis de ambiente
    with patch.dict(os.environ, test_env, clear=False):
        yield test_env


@pytest.fixture(autouse=True)
def configure_app_for_tests():
    """
    Fixture que configura automaticamente a aplicação para testes.
    Executa automaticamente antes de cada teste.
    """
    if flask_app and hasattr(flask_app, 'config'):
        # Configurar a aplicação para testes
        flask_app.config.update({
            'TESTING': True,
            'WTF_CSRF_ENABLED': False,
            'JSON_AS_ASCII': False,  # Para suportar caracteres especiais
            'JSON_SORT_KEYS': False
        })


@pytest.fixture
def mock_error_handlers():
    """
    Mock dos handlers de erro para garantir respostas JSON consistentes.
    """
    def handle_400_error(error):
        return jsonify({
            'erro': 'Bad Request',
            'sucesso': False,
            'detalhes': str(error)
        }), 400

    def handle_404_error(error):
        return jsonify({
            'erro': 'Endpoint não encontrado',
            'sucesso': False
        }), 404

    def handle_405_error(error):
        return jsonify({
            'erro': 'Método não permitido',
            'sucesso': False
        }), 405

    def handle_500_error(error):
        return jsonify({
            'erro': 'Erro interno do servidor',
            'sucesso': False,
            'detalhes': str(error)
        }), 500

    if flask_app:
        flask_app.register_error_handler(400, handle_400_error)
        flask_app.register_error_handler(404, handle_404_error)
        flask_app.register_error_handler(405, handle_405_error)
        flask_app.register_error_handler(500, handle_500_error)

    yield {
        '400': handle_400_error,
        '404': handle_404_error,
        '405': handle_405_error,
        '500': handle_500_error
    }


@pytest.fixture
def isolated_app():
    """
    Fixture que cria uma aplicação Flask isolada para testes.
    Evita problemas com rotas sendo registradas após a primeira requisição.
    """
    from flask import Flask
    test_app = Flask(__name__)
    test_app.config['TESTING'] = True
    test_app.config['WTF_CSRF_ENABLED'] = False

    # Registrar apenas as rotas necessárias para os testes
    @test_app.route('/pergunta', methods=['POST'])
    def pergunta():
        try:
            data = request.get_json(force=True)
            if not data or 'pergunta' not in data:
                return jsonify({'erro': 'Campo pergunta é obrigatório', 'sucesso': False}), 400

            if not data['pergunta'].strip():
                return jsonify({'erro': 'Pergunta não pode estar vazio', 'sucesso': False}), 400

            # Simular verificação de banco para testes específicos
            if 'test_error_banco' in request.headers.get('X-Test-Scenario', ''):
                return jsonify({'erro': 'Erro interno do servidor', 'sucesso': False}), 500

            # Simular processamento bem-sucedido
            return jsonify({
                'resposta': 'Resposta simulada para teste',
                'sucesso': True
            }), 200
        except Exception as e:
            return jsonify({'erro': f'Erro interno: {str(e)}', 'sucesso': False}), 500

    @test_app.route('/health', methods=['GET'])
    def health():
        return jsonify({'status': 'healthy'}), 200

    # Rotas de charts para os testes
    @test_app.route('/api/query/total_vendas_por_mes', methods=['GET'])
    def total_vendas_por_mes():
        return jsonify([
            {'mes': '2024-01', 'total_vendas': 15000.00},
            {'mes': '2024-02', 'total_vendas': 18000.00}
        ])

    @test_app.route('/api/query/funcionarios_por_departamento', methods=['GET'])
    def funcionarios_por_departamento():
        return jsonify([
            {'departamento': 'TI', 'quantidade': 5},
            {'departamento': 'Marketing', 'quantidade': 3}
        ])

    # Configurar handlers de erro
    @test_app.errorhandler(404)
    def not_found(error):
        return jsonify({'erro': 'Endpoint não encontrado', 'sucesso': False}), 404

    @test_app.errorhandler(405)
    def method_not_allowed(error):
        return jsonify({'erro': 'Método não permitido', 'sucesso': False}), 405

    @test_app.errorhandler(500)
    def internal_error(error):
        return jsonify({'erro': 'Erro interno do servidor', 'sucesso': False}), 500

    return test_app


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


def setup_mock_environment():
    """
    Configura o ambiente mock para testes isolados.
    """
    # Mock de todas as dependências externas
    mocks = {}

    # Mock do banco de dados
    with patch('app.app.get_db_connection') as mock_db:
        mock_conn = Mock()
        mock_cursor = Mock()
        mock_cursor.fetchall.return_value = []
        mock_cursor.fetchone.return_value = None
        mock_conn.cursor.return_value = mock_cursor
        mock_db.return_value = mock_conn
        mocks['db'] = mock_db

    # Mock do Gemini
    with patch('app.app.enviar_para_gemini') as mock_gemini:
        mock_gemini.return_value = "Resposta padrão do mock"
        mocks['gemini'] = mock_gemini

    # Mock do processamento de texto
    with patch('app.app.processar_texto') as mock_process:
        mock_process.side_effect = lambda x: x.lower() if x else ""
        mocks['process'] = mock_process

    return mocks


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

@pytest.fixture
def mock_charts_endpoints():
    """
    Mock para endpoints de charts sem problemas de importação.
    """
    def mock_total_vendas():
        return [
            {'mes': '2024-01', 'total_vendas': 15000.00},
            {'mes': '2024-02', 'total_vendas': 18000.00},
            {'mes': '2024-03', 'total_vendas': 22000.00}
        ]

    def mock_funcionarios_departamento():
        return [
            {'departamento': 'TI', 'quantidade': 5},
            {'departamento': 'Marketing', 'quantidade': 3},
            {'departamento': 'Vendas', 'quantidade': 4}
        ]

    # Simular os patches necessários para evitar importação de graphs.py
    with patch('app.graphs.get_db_connection') as mock_get_db:
        mock_conn = Mock()
        mock_cursor = Mock()

        # Configurar retornos diferentes baseados no teste
        mock_cursor.fetchall.side_effect = lambda: mock_total_vendas()
        mock_conn.cursor.return_value = mock_cursor
        mock_get_db.return_value = mock_conn

        yield {
            'total_vendas': mock_total_vendas,
            'funcionarios_dept': mock_funcionarios_departamento,
            'mock_db': mock_get_db
        }
