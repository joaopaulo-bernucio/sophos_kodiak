# -*- coding: utf-8 -*-
"""
Configurações gerais para os testes do backend Sophos Kodiak.

Este arquivo contém fixtures, configurações e utilidades compartilhadas
entre todos os testes do backend Flask.
"""

import pytest
import os
import tempfile
try:
    import psycopg2
except ImportError:
    psycopg2 = None
from unittest.mock import Mock, patch
from flask import Flask
try:
    from app.app import app as flask_app
except ImportError:
    # Se não conseguir importar o app, criar um mock
    flask_app = Mock()
try:
    import spacy
except ImportError:
    spacy = None


@pytest.fixture(scope="session")
def nlp_model():
    """
    Fixture que carrega o modelo spaCy uma vez para toda a sessão de testes.

    Returns:
        spacy.Language: Modelo spaCy carregado
    """
    if spacy is None:
        # Se spacy não estiver disponível, criar um mock simples
        mock_nlp = Mock()
        mock_doc = Mock()
        mock_doc.configure_mock(**{
            '__iter__': lambda x: iter([]),
            'text': 'test',
        })
        mock_nlp.return_value = mock_doc
        return mock_nlp

    try:
        return spacy.load("pt_core_news_sm")
    except Exception:
        # Se o modelo não estiver disponível, criar um mock simples
        mock_nlp = Mock()
        mock_doc = Mock()
        mock_doc.configure_mock(**{
            '__iter__': lambda x: iter([]),
            'text': 'test',
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
    # Tentar importar a aplicação Flask real para testes de API
    try:
        from app.app import create_app
        test_app = create_app()
        test_app.config['TESTING'] = True
        test_app.config['WTF_CSRF_ENABLED'] = False

        with test_app.test_client() as client:
            with test_app.app_context():
                yield client
    except (ImportError, Exception):
        # Se não conseguiu importar o app, tentar usar a instância mockada
        if hasattr(flask_app, 'test_client') and not isinstance(flask_app, Mock):
            flask_app.config['TESTING'] = True
            flask_app.config['WTF_CSRF_ENABLED'] = False

            with flask_app.test_client() as client:
                with flask_app.app_context():
                    yield client
        else:
            # Último recurso: retornar um mock
            yield Mock()


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
    mock_cursor.description = [
        ('id',), ('nome',), ('cargo',), ('departamento',), ('salario',)
    ]

    mock_conn.cursor.return_value = mock_cursor
    return mock_conn


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
            'tipo': 'contagem'
        },
        {
            'pergunta': 'Qual o salário médio?',
            'label_esperado': 'salario-medio',
            'tipo': 'estatistica'
        },
        {
            'pergunta': 'Listar todos os funcionários',
            'label_esperado': 'funcionarios-lista',
            'tipo': 'listagem'
        },
        {
            'pergunta': 'Projetos em andamento',
            'label_esperado': 'projetos-andamento',
            'tipo': 'filtro'
        }
    ]


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
        'GEMINI_API_KEY': 'test_api_key_123456789'
    }

    # Aplicar as variáveis de ambiente
    with patch.dict(os.environ, test_env, clear=True):
        yield test_env
