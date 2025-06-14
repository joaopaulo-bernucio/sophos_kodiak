"""
Exemplo de teste de integração para o endpoint /pergunta.
Demonstra como testar o fluxo completo da API incluindo NLP e geração de resposta.
"""

import pytest
import json
from unittest.mock import patch, MagicMock
from app.app import app
from tests.mocks.mock_supabase import MockSupabaseClient, MockGeminiClient


@pytest.fixture
def client():
    """Cliente de teste Flask."""
    app.config['TESTING'] = True
    app.config['WTF_CSRF_ENABLED'] = False
    with app.test_client() as client:
        yield client


@pytest.fixture
def mock_supabase():
    """Mock do cliente Supabase."""
    mock_client = MockSupabaseClient()

    # Dados mock para usuários
    mock_client.set_mock_data('usuarios', [
        {'id': 1, 'nome': 'João Silva', 'email': 'joao@empresa.com', 'ativo': True},
        {'id': 2, 'nome': 'Maria Santos', 'email': 'maria@empresa.com', 'ativo': True},
        {'id': 3, 'nome': 'Pedro Oliveira', 'email': 'pedro@empresa.com', 'ativo': False},
    ])

    # Dados mock para vendas
    mock_client.set_mock_data('vendas', [
        {'id': 1, 'valor': 1500.00, 'data': '2024-01-15', 'usuario_id': 1},
        {'id': 2, 'valor': 2300.00, 'data': '2024-01-20', 'usuario_id': 2},
        {'id': 3, 'valor': 1800.00, 'data': '2024-02-05', 'usuario_id': 1},
    ])

    return mock_client


@pytest.fixture
def mock_gemini():
    """Mock do cliente Gemini."""
    mock_client = MockGeminiClient()

    # Configurar respostas baseadas em tipos de pergunta
    mock_client.set_response(
        'usuários',
        'SELECT COUNT(*) as total_usuarios FROM usuarios WHERE ativo = true'
    )

    mock_client.set_response(
        'vendas',
        'SELECT SUM(valor) as total_vendas FROM vendas WHERE data >= \'2024-01-01\''
    )

    mock_client.set_response(
        'vendas por mês',
        'SELECT DATE_TRUNC(\'month\', data) as mes, SUM(valor) as total FROM vendas GROUP BY mes ORDER BY mes'
    )

    return mock_client


class TestPerguntaEndpoint:
    """Testes de integração para o endpoint /pergunta."""

    @pytest.mark.integration
    def test_pergunta_count_usuarios_success(self, client, mock_supabase, mock_gemini):
        """Teste: pergunta sobre contagem de usuários retorna resposta correta."""
        with patch('app.supabase_client', mock_supabase), \
             patch('app.gemini_client', mock_gemini):

            # Arrange
            pergunta = "Quantos usuários ativos temos no sistema?"

            # Act
            response = client.post('/pergunta',
                                 json={'pergunta': pergunta},
                                 headers={'Content-Type': 'application/json'})

            # Assert
            assert response.status_code == 200
            data = json.loads(response.data)

            assert 'resposta' in data
            assert 'sucesso' in data
            assert data['sucesso'] is True
            assert 'total_usuarios' in data['resposta'].lower() or 'usuários' in data['resposta'].lower()

    @pytest.mark.integration
    def test_pergunta_vendas_gera_grafico(self, client, mock_supabase, mock_gemini):
        """Teste: pergunta sobre vendas por mês gera dados para gráfico."""
        with patch('app.supabase_client', mock_supabase), \
             patch('app.gemini_client', mock_gemini):

            # Arrange
            pergunta = "Mostrar vendas por mês em um gráfico"

            # Act
            response = client.post('/pergunta',
                                 json={'pergunta': pergunta},
                                 headers={'Content-Type': 'application/json'})

            # Assert
            assert response.status_code == 200
            data = json.loads(response.data)

            assert data['sucesso'] is True
            assert 'chart_data' in data or 'dados' in data

            # Verificar se dados do gráfico estão presentes
            if 'chart_data' in data:
                chart_data = data['chart_data']
                assert 'tipo' in chart_data
                assert 'dados' in chart_data
                assert len(chart_data['dados']) > 0

    @pytest.mark.integration
    def test_pergunta_invalida_retorna_erro(self, client, mock_supabase, mock_gemini):
        """Teste: pergunta inválida retorna erro apropriado."""
        with patch('app.supabase_client', mock_supabase), \
             patch('app.gemini_client', mock_gemini):

            # Arrange
            pergunta = ""  # Pergunta vazia

            # Act
            response = client.post('/pergunta',
                                 json={'pergunta': pergunta},
                                 headers={'Content-Type': 'application/json'})

            # Assert
            assert response.status_code == 400
            data = json.loads(response.data)

            assert 'erro' in data
            assert 'pergunta é obrigatória' in data['erro'].lower()

    @pytest.mark.integration
    def test_pergunta_timeout_retorna_erro(self, client):
        """Teste: timeout na API retorna erro apropriado."""
        with patch('app.gemini_client') as mock_gemini:
            # Simular timeout
            mock_gemini.generate_content.side_effect = TimeoutError("Request timeout")

            # Arrange
            pergunta = "Quantos usuários temos?"

            # Act
            response = client.post('/pergunta',
                                 json={'pergunta': pergunta},
                                 headers={'Content-Type': 'application/json'})

            # Assert
            assert response.status_code == 500
            data = json.loads(response.data)

            assert 'erro' in data
            assert 'timeout' in data['erro'].lower()

    @pytest.mark.integration
    def test_pergunta_com_caracteres_especiais(self, client, mock_supabase, mock_gemini):
        """Teste: pergunta com caracteres especiais é tratada corretamente."""
        with patch('app.supabase_client', mock_supabase), \
             patch('app.gemini_client', mock_gemini):

            # Arrange
            pergunta = "Quantos usuários têm acentuação/símbolos? 100% válidos!"

            # Act
            response = client.post('/pergunta',
                                 json={'pergunta': pergunta},
                                 headers={'Content-Type': 'application/json'})

            # Assert
            assert response.status_code == 200
            data = json.loads(response.data)

            assert 'resposta' in data
            # Verificar que caracteres especiais não quebram o processamento
            assert isinstance(data['resposta'], str)

    @pytest.mark.integration
    def test_multiple_perguntas_sequenciais(self, client, mock_supabase, mock_gemini):
        """Teste: múltiplas perguntas sequenciais funcionam corretamente."""
        with patch('app.supabase_client', mock_supabase), \
             patch('app.gemini_client', mock_gemini):

            perguntas = [
                "Quantos usuários ativos temos?",
                "Qual o total de vendas?",
                "Mostrar vendas por mês"
            ]

            for pergunta in perguntas:
                # Act
                response = client.post('/pergunta',
                                     json={'pergunta': pergunta},
                                     headers={'Content-Type': 'application/json'})

                # Assert
                assert response.status_code == 200
                data = json.loads(response.data)
                assert data['sucesso'] is True
                assert 'resposta' in data

    @pytest.mark.integration
    def test_pergunta_sql_injection_protection(self, client, mock_supabase, mock_gemini):
        """Teste: proteção contra SQL injection."""
        with patch('app.supabase_client', mock_supabase), \
             patch('app.gemini_client', mock_gemini):

            # Arrange - Tentativa de SQL injection
            pergunta = "'; DROP TABLE usuarios; --"

            # Act
            response = client.post('/pergunta',
                                 json={'pergunta': pergunta},
                                 headers={'Content-Type': 'application/json'})

            # Assert
            # Deve retornar resposta normal ou erro, mas não executar comando malicioso
            assert response.status_code in [200, 400, 500]

            # Verificar que tabela ainda existe (dados mock ainda presentes)
            users_data = mock_supabase.table('usuarios').select().execute()
            assert len(users_data.data) > 0  # Dados ainda devem estar lá

    @pytest.mark.integration
    def test_pergunta_performance_benchmark(self, client, mock_supabase, mock_gemini, benchmark):
        """Teste: benchmark de performance do endpoint."""
        with patch('app.supabase_client', mock_supabase), \
             patch('app.gemini_client', mock_gemini):

            def fazer_pergunta():
                return client.post('/pergunta',
                                 json={'pergunta': 'Quantos usuários temos?'},
                                 headers={'Content-Type': 'application/json'})

            # Act & Assert
            response = benchmark(fazer_pergunta)

            assert response.status_code == 200
            # O benchmark irá medir o tempo de execução automaticamente

    @pytest.mark.integration
    def test_pergunta_headers_corretos(self, client, mock_supabase, mock_gemini):
        """Teste: verifica se headers de resposta estão corretos."""
        with patch('app.supabase_client', mock_supabase), \
             patch('app.gemini_client', mock_gemini):

            # Act
            response = client.post('/pergunta',
                                 json={'pergunta': 'Quantos usuários temos?'},
                                 headers={'Content-Type': 'application/json'})

            # Assert
            assert response.headers['Content-Type'] == 'application/json'
            assert 'Access-Control-Allow-Origin' in response.headers  # CORS

    @pytest.mark.integration
    def test_pergunta_metodos_http_nao_permitidos(self, client):
        """Teste: métodos HTTP não permitidos retornam erro apropriado."""
        # Test GET
        response = client.get('/pergunta')
        assert response.status_code == 405

        # Test PUT
        response = client.put('/pergunta')
        assert response.status_code == 405

        # Test DELETE
        response = client.delete('/pergunta')
        assert response.status_code == 405
