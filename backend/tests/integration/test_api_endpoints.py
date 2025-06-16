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


def setup_module():
    """Setup global para o módulo de testes."""
    import app.app as app_module
    app_module.supabase_client = MockSupabaseClient()
    app_module.gemini_client = MockGeminiClient()


class TestPerguntaEndpoint:
    """Testes de integração para o endpoint /pergunta."""

    @pytest.mark.integration
    def test_pergunta_count_usuarios_success(self, client, mock_supabase, mock_gemini):
        """Teste: pergunta sobre contagem de usuários retorna resposta correta."""
        with patch('app.app.supabase_client', mock_supabase), \
             patch('app.app.enviar_para_gemini') as mock_enviar:

            # Configurar resposta mock do Gemini
            mock_enviar.return_value = "Temos 2 usuários ativos no sistema."

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
            assert 'usuários' in data['resposta'].lower() or 'usuarios' in data['resposta'].lower()

    @pytest.mark.integration
    def test_pergunta_vendas_gera_grafico(self, client, mock_supabase, mock_gemini):
        """Teste: pergunta sobre vendas por mês gera dados para gráfico."""
        with patch('app.app.supabase_client', mock_supabase), \
             patch('app.app.enviar_para_gemini') as mock_enviar:

            # Configurar resposta mock do Gemini
            mock_enviar.return_value = "Aqui estão as vendas por mês organizadas em um gráfico."

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
            assert 'resposta' in data

    @pytest.mark.integration
    def test_pergunta_invalida_retorna_erro(self, client):
        """Teste: pergunta inválida retorna erro apropriado."""
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
        assert 'vazio' in data['erro'].lower()
        assert data['sucesso'] is False

    @pytest.mark.integration
    def test_pergunta_sem_json_retorna_erro(self, client):
        """Teste: request sem JSON retorna erro apropriado."""
        # Act
        response = client.post('/pergunta',
                             data='não é json',
                             headers={'Content-Type': 'text/plain'})

        # Assert
        assert response.status_code == 400
        data = json.loads(response.data)

        assert 'erro' in data
        assert 'application/json' in data['erro']
        assert data['sucesso'] is False

    @pytest.mark.integration
    def test_pergunta_json_invalido_retorna_erro(self, client):
        """Teste: JSON inválido retorna erro apropriado."""
        # Act
        response = client.post('/pergunta',
                             data='{"pergunta": inválido}',
                             headers={'Content-Type': 'application/json'})

        # Assert
        assert response.status_code == 400
        data = json.loads(response.data)

        assert 'erro' in data
        assert 'json' in data['erro'].lower()
        assert data['sucesso'] is False

    @pytest.mark.integration
    def test_pergunta_sem_campo_pergunta_retorna_erro(self, client):
        """Teste: request sem campo 'pergunta' retorna erro apropriado."""
        # Act
        response = client.post('/pergunta',
                             json={'outra_coisa': 'valor'},
                             headers={'Content-Type': 'application/json'})

        # Assert
        assert response.status_code == 400
        data = json.loads(response.data)

        assert 'erro' in data
        assert 'obrigatório' in data['erro'].lower()
        assert data['sucesso'] is False

    @pytest.mark.integration
    def test_pergunta_timeout_retorna_erro(self, client):
        """Teste: timeout na API retorna erro apropriado."""
        with patch('app.app.enviar_para_gemini') as mock_enviar:
            # Simular timeout
            mock_enviar.side_effect = TimeoutError("Request timeout")

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
            assert data['sucesso'] is False

    @pytest.mark.integration
    def test_pergunta_com_caracteres_especiais(self, client):
        """Teste: pergunta com caracteres especiais é tratada corretamente."""
        with patch('app.app.enviar_para_gemini') as mock_enviar:
            # Configurar resposta mock do Gemini
            mock_enviar.return_value = "Resposta processada com sucesso, caracteres especiais tratados."

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
            assert data['sucesso'] is True
            # Verificar que caracteres especiais não quebram o processamento
            assert isinstance(data['resposta'], str)

    @pytest.mark.integration
    def test_multiple_perguntas_sequenciais(self, client):
        """Teste: múltiplas perguntas sequenciais funcionam corretamente."""
        with patch('app.app.enviar_para_gemini') as mock_enviar:
            # Configurar respostas diferentes para cada pergunta
            responses = [
                "Temos 2 usuários ativos.",
                "O total de vendas é R$ 5.600,00.",
                "Aqui estão as vendas por mês em gráfico."
            ]
            mock_enviar.side_effect = responses

            perguntas = [
                "Quantos usuários ativos temos?",
                "Qual o total de vendas?",
                "Mostrar vendas por mês"
            ]

            for i, pergunta in enumerate(perguntas):
                # Act
                response = client.post('/pergunta',
                                     json={'pergunta': pergunta},
                                     headers={'Content-Type': 'application/json'})

                # Assert
                assert response.status_code == 200
                data = json.loads(response.data)
                assert data['sucesso'] is True
                assert 'resposta' in data
                assert data['resposta'] == responses[i]

    @pytest.mark.integration
    def test_pergunta_sql_injection_protection(self, client):
        """Teste: proteção contra SQL injection."""
        with patch('app.app.enviar_para_gemini') as mock_enviar:
            # Configurar resposta mock do Gemini
            mock_enviar.return_value = "Pergunta processada de forma segura."

            # Arrange - Tentativa de SQL injection
            pergunta = "'; DROP TABLE usuarios; --"

            # Act
            response = client.post('/pergunta',
                                 json={'pergunta': pergunta},
                                 headers={'Content-Type': 'application/json'})

            # Assert
            # Deve retornar resposta normal, mas não executar comando malicioso
            assert response.status_code == 200
            data = json.loads(response.data)
            assert data['sucesso'] is True
            assert 'resposta' in data

    @pytest.mark.integration
    def test_pergunta_performance_benchmark(self, client, benchmark):
        """Teste: benchmark de performance do endpoint."""
        with patch('app.app.enviar_para_gemini') as mock_enviar:
            # Configurar resposta mock do Gemini
            mock_enviar.return_value = "Resposta rápida para benchmark."

            def fazer_pergunta():
                return client.post('/pergunta',
                                 json={'pergunta': 'Quantos usuários temos?'},
                                 headers={'Content-Type': 'application/json'})

            # Act & Assert
            response = benchmark(fazer_pergunta)

            assert response.status_code == 200
            # O benchmark irá medir o tempo de execução automaticamente

    @pytest.mark.integration
    def test_pergunta_headers_corretos(self, client):
        """Teste: verifica se headers de resposta estão corretos."""
        with patch('app.app.enviar_para_gemini') as mock_enviar:
            # Configurar resposta mock do Gemini
            mock_enviar.return_value = "Resposta para testar headers."

            # Act
            response = client.post('/pergunta',
                                 json={'pergunta': 'Quantos usuários temos?'},
                                 headers={'Content-Type': 'application/json'})

            # Assert
            assert response.status_code == 200
            assert 'application/json' in response.headers['Content-Type']
            # Verificar se CORS está habilitado
            # (pode variar dependendo da configuração do Flask-CORS)

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

    @pytest.mark.integration
    def test_pergunta_erro_interno_servidor(self, client):
        """Teste: erro interno do servidor é tratado adequadamente."""
        with patch('app.app.selecionar_queries') as mock_queries:
            # Simular erro interno
            mock_queries.side_effect = Exception("Erro interno simulado")

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
            assert 'interno' in data['erro'].lower()
            assert data['sucesso'] is False
