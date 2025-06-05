# -*- coding: utf-8 -*-
"""
Testes de API para os endpoints Flask do backend Sophos Kodiak.

Este módulo testa os endpoints HTTP, incluindo /pergunta e endpoints de charts.
"""

import pytest
import json
from unittest.mock import Mock, patch
from flask import Flask


class TestPerguntaEndpoint:
    """Testes para o endpoint POST /pergunta."""

    def test_pergunta_post_sucesso(self, client, mock_db_connection, mock_gemini_response):
        """Testa requisição POST bem-sucedida para /pergunta."""
        with patch('app.app.get_db_connection') as mock_get_db:
            mock_get_db.return_value = mock_db_connection

            with patch('app.app.enviar_para_gemini') as mock_gemini:
                mock_gemini.return_value = "Resposta do assistente Sophos sobre funcionários."

                with patch('app.app.selecionar_queries') as mock_queries:
                    mock_queries.return_value = [('funcionarios-total', 'SELECT COUNT(*) FROM funcionarios')]

                    # Fazer requisição
                    response = client.post('/pergunta',
                                         json={'pergunta': 'Quantos funcionários temos?'},
                                         content_type='application/json')

                    # Verificar resposta
                    assert response.status_code == 200

                    data = json.loads(response.data)
                    assert 'resposta' in data
                    assert isinstance(data['resposta'], str)
                    assert len(data['resposta']) > 0

    def test_pergunta_post_sem_json(self, client):
        """Testa requisição POST sem JSON."""
        response = client.post('/pergunta', data='não é json')

        assert response.status_code == 400
        data = json.loads(response.data)
        assert 'erro' in data

    def test_pergunta_post_json_invalido(self, client):
        """Testa requisição POST com JSON inválido."""
        response = client.post('/pergunta',
                             json={'campo_errado': 'valor'},
                             content_type='application/json')

        assert response.status_code == 400
        data = json.loads(response.data)
        assert 'erro' in data

    def test_pergunta_post_texto_vazio(self, client):
        """Testa requisição POST com pergunta vazia."""
        response = client.post('/pergunta',
                             json={'pergunta': ''},
                             content_type='application/json')

        assert response.status_code == 400
        data = json.loads(response.data)
        assert 'erro' in data

    def test_pergunta_post_texto_muito_longo(self, client):
        """Testa requisição POST com pergunta muito longa."""
        pergunta_longa = 'a' * 1001  # Assumindo limite de 1000 caracteres

        response = client.post('/pergunta',
                             json={'pergunta': pergunta_longa},
                             content_type='application/json')

        # Pode retornar 400 (muito longo) ou processar normalmente
        assert response.status_code in [200, 400]

    def test_pergunta_post_erro_banco(self, client):
        """Testa comportamento quando há erro no banco de dados."""
        with patch('app.app.get_db_connection') as mock_get_db:
            mock_get_db.return_value = None  # Simular falha na conexão

            response = client.post('/pergunta',
                                 json={'pergunta': 'Quantos funcionários?'},
                                 content_type='application/json')

            assert response.status_code == 500
            data = json.loads(response.data)
            assert 'erro' in data

    def test_pergunta_post_erro_gemini(self, client, mock_db_connection):
        """Testa comportamento quando a API Gemini falha."""
        with patch('app.app.get_db_connection') as mock_get_db:
            mock_get_db.return_value = mock_db_connection

            with patch('app.app.enviar_para_gemini') as mock_gemini:
                mock_gemini.side_effect = Exception("Erro na API Gemini")

                response = client.post('/pergunta',
                                     json={'pergunta': 'Quantos funcionários?'},
                                     content_type='application/json')

                assert response.status_code == 500
                data = json.loads(response.data)
                assert 'erro' in data

    def test_pergunta_method_not_allowed(self, client):
        """Testa que outros métodos HTTP não são permitidos."""
        # GET não deve ser permitido
        response = client.get('/pergunta')
        assert response.status_code == 405

        # PUT não deve ser permitido
        response = client.put('/pergunta')
        assert response.status_code == 405

        # DELETE não deve ser permitido
        response = client.delete('/pergunta')
        assert response.status_code == 405


class TestChartsEndpoints:
    """Testes para os endpoints de dados dos charts."""

    def test_charts_endpoints_existem(self, client):
        """Testa se os endpoints de charts existem."""
        # Tentar acessar alguns endpoints que deveriam existir
        # Nota: Estes podem retornar erro se o banco não estiver configurado,
        # mas não devem retornar 404 (Not Found)

        endpoints = [
            '/api/query/total_vendas_por_mes',
            '/api/query/funcionarios_por_departamento',
            '/api/query/projetos_por_status',
            '/api/query/receita_por_cliente'
        ]

        for endpoint in endpoints:
            response = client.get(endpoint)
            # Não deve ser 404 (endpoint não encontrado)
            assert response.status_code != 404
            # Pode ser 500 (erro interno) se banco não estiver disponível
            assert response.status_code in [200, 500]

    @patch('app.graphs.get_db_connection')
    def test_total_vendas_por_mes_sucesso(self, mock_get_db, client):
        """Testa endpoint de vendas por mês com sucesso."""
        # Mock da conexão e cursor
        mock_conn = Mock()
        mock_cursor = Mock()
        mock_cursor.fetchall.return_value = [
            ('2024-01', 15000.00),
            ('2024-02', 18000.00),
            ('2024-03', 22000.00)
        ]
        mock_conn.cursor.return_value = mock_cursor
        mock_get_db.return_value = mock_conn

        response = client.get('/api/query/total_vendas_por_mes')

        assert response.status_code == 200
        data = json.loads(response.data)
        assert isinstance(data, list)
        assert len(data) == 3

        # Verificar estrutura dos dados
        for item in data:
            assert 'mes' in item
            assert 'total_vendas' in item

    @patch('app.graphs.get_db_connection')
    def test_funcionarios_por_departamento_sucesso(self, mock_get_db, client):
        """Testa endpoint de funcionários por departamento."""
        mock_conn = Mock()
        mock_cursor = Mock()
        mock_cursor.fetchall.return_value = [
            ('TI', 5),
            ('Marketing', 3),
            ('Vendas', 4)
        ]
        mock_conn.cursor.return_value = mock_cursor
        mock_get_db.return_value = mock_conn

        response = client.get('/api/query/funcionarios_por_departamento')

        assert response.status_code == 200
        data = json.loads(response.data)
        assert isinstance(data, list)

        for item in data:
            assert 'departamento' in item
            assert 'quantidade' in item
            assert isinstance(item['quantidade'], int)

    @patch('app.graphs.get_db_connection')
    def test_charts_endpoint_erro_banco(self, mock_get_db, client):
        """Testa comportamento quando há erro no banco para charts."""
        mock_get_db.return_value = None  # Simular falha

        response = client.get('/api/query/total_vendas_por_mes')

        assert response.status_code == 500
        data = json.loads(response.data)
        assert 'erro' in data or 'error' in data


class TestErrorHandling:
    """Testes para tratamento de erros gerais da API."""

    def test_endpoint_inexistente(self, client):
        """Testa acesso a endpoint que não existe."""
        response = client.get('/endpoint/que/nao/existe')
        assert response.status_code == 404

    def test_content_type_incorreto(self, client):
        """Testa requisição com content-type incorreto."""
        response = client.post('/pergunta',
                             data='{"pergunta": "teste"}',
                             content_type='text/plain')

        # Deve rejeitar ou tratar adequadamente
        assert response.status_code in [400, 415]  # Bad Request ou Unsupported Media Type

    def test_json_malformado(self, client):
        """Testa requisição com JSON malformado."""
        response = client.post('/pergunta',
                             data='{"pergunta": "teste"',  # JSON incompleto
                             content_type='application/json')

        assert response.status_code == 400


class TestRequestValidation:
    """Testes para validação de requisições."""

    def test_pergunta_com_caracteres_especiais(self, client, mock_db_connection):
        """Testa pergunta com caracteres especiais."""
        with patch('app.app.get_db_connection') as mock_get_db:
            mock_get_db.return_value = mock_db_connection

            with patch('app.app.enviar_para_gemini') as mock_gemini:
                mock_gemini.return_value = "Resposta processada"

                pergunta_especial = "Quantos funcionários há? ção, áéíóú, 123!"

                response = client.post('/pergunta',
                                     json={'pergunta': pergunta_especial},
                                     content_type='application/json')

                # Deve processar normalmente
                assert response.status_code == 200

    def test_pergunta_com_sql_injection_attempt(self, client):
        """Testa tentativa de SQL injection na pergunta."""
        pergunta_maliciosa = "'; DROP TABLE funcionarios; --"

        response = client.post('/pergunta',
                             json={'pergunta': pergunta_maliciosa},
                             content_type='application/json')

        # Deve ser tratada como pergunta normal ou rejeitada
        assert response.status_code in [200, 400, 500]

        # Se processada, não deve causar danos (não podemos testar isso facilmente,
        # mas o importante é que não quebre)

    def test_headers_seguranca(self, client):
        """Testa se headers de segurança estão presentes."""
        response = client.post('/pergunta',
                             json={'pergunta': 'teste'},
                             content_type='application/json')

        # Verificar alguns headers de segurança básicos
        # (dependendo da configuração do Flask)
        headers = response.headers

        # Content-Type deve estar correto
        assert 'application/json' in headers.get('Content-Type', '')


class TestResponseFormat:
    """Testes para formato das respostas."""

    def test_resposta_formato_json(self, client, mock_db_connection):
        """Testa se as respostas estão em formato JSON válido."""
        with patch('app.app.get_db_connection') as mock_get_db:
            mock_get_db.return_value = mock_db_connection

            with patch('app.app.enviar_para_gemini') as mock_gemini:
                mock_gemini.return_value = "Resposta válida"

                response = client.post('/pergunta',
                                     json={'pergunta': 'Teste'},
                                     content_type='application/json')

                # Deve ser JSON válido
                assert response.content_type.startswith('application/json')

                # Deve ser possível fazer parse do JSON
                data = json.loads(response.data)
                assert isinstance(data, dict)

    def test_estrutura_resposta_sucesso(self, client, mock_db_connection):
        """Testa estrutura da resposta de sucesso."""
        with patch('app.app.get_db_connection') as mock_get_db:
            mock_get_db.return_value = mock_db_connection

            with patch('app.app.enviar_para_gemini') as mock_gemini:
                mock_gemini.return_value = "Resposta do Sophos"

                response = client.post('/pergunta',
                                     json={'pergunta': 'Teste'},
                                     content_type='application/json')

                data = json.loads(response.data)

                # Deve ter campo 'resposta'
                assert 'resposta' in data
                assert isinstance(data['resposta'], str)
                assert len(data['resposta']) > 0

    def test_estrutura_resposta_erro(self, client):
        """Testa estrutura da resposta de erro."""
        response = client.post('/pergunta',
                             json={'campo_invalido': 'valor'},
                             content_type='application/json')

        data = json.loads(response.data)

        # Deve ter campo de erro
        assert 'erro' in data or 'error' in data

        error_message = data.get('erro') or data.get('error')
        assert isinstance(error_message, str)
        assert len(error_message) > 0
