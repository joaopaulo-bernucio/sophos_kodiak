# -*- coding: utf-8 -*-
"""
Testes específicos para as melhorias de segurança e quota da API Gemini.

Este módulo testa:
- Proteção contra SQL injection
- Cache e retry da API Gemini
- Rate limiting
- Respostas de fallback
"""
import pytest
import json
import time


class TestSecurityImprovements:
    """Testes das melhorias de segurança implementadas."""

    def test_sql_injection_detection_function(self):
        """Testa a função de detecção de SQL injection."""
        try:
            from app.app import detectar_sql_injection

            # Casos que devem ser detectados como maliciosos
            casos_maliciosos = [
                "'; DROP TABLE funcionarios; --",
                "' OR '1'='1",
                "UNION SELECT * FROM users",
                "drop table test",
                "; DELETE FROM vendas",
                "/* comment */ SELECT * FROM funcionarios",
                "SELECT * FROM information_schema.tables"
            ]

            for caso in casos_maliciosos:
                resultado = detectar_sql_injection(caso)
                assert resultado == True, f"Deveria detectar SQL injection em: {caso}"

            # Casos que devem ser considerados seguros
            casos_seguros = [
                "Quantos funcionários temos?",
                "Mostrar vendas do mês",
                "Listar departamentos",
                "Qual é o total de projetos?",
                "Informações sobre a empresa"
            ]

            for caso in casos_seguros:
                resultado = detectar_sql_injection(caso)
                assert resultado == False, f"Não deveria detectar SQL injection em: {caso}"

        except ImportError:
            pytest.skip("Função de detecção não disponível")

    def test_input_sanitization(self):
        """Testa a sanitização de entrada."""
        try:
            from app.app import sanitizar_entrada

            # Teste de caracteres perigosos
            entrada_perigosa = "SELECT * FROM <script>alert('xss')</script> funcionários"
            entrada_limpa = sanitizar_entrada(entrada_perigosa)

            # Deve remover caracteres perigosos mas manter conteúdo básico
            assert 'script' not in entrada_limpa.lower()
            assert 'funcionários' in entrada_limpa or 'funcionarios' in entrada_limpa

            # Teste de tamanho
            entrada_grande = "a" * 2000
            entrada_limitada = sanitizar_entrada(entrada_grande)
            assert len(entrada_limitada) <= 1000

        except ImportError:
            pytest.skip("Função de sanitização não disponível")

    def test_sql_injection_endpoint_protection(self, client):
        """Testa proteção do endpoint contra SQL injection."""
        # Tentar diferentes tipos de ataques
        ataques = [
            "'; DROP TABLE funcionarios; --",
            "' OR 1=1 --",
            "UNION SELECT password FROM users",
            "; DELETE FROM vendas WHERE 1=1"
        ]

        for ataque in ataques:
            response = client.post('/pergunta',
                                 json={'pergunta': ataque},
                                 content_type='application/json')

            # Deve ser bloqueado (400) ou responder de forma segura (200)
            assert response.status_code in [200, 400], f"Status inesperado para: {ataque}"

            if response.status_code == 400:
                data = response.get_json()
                assert data.get('sucesso') == False
                assert 'segurança' in data.get('erro', '').lower() or 'bloqueado' in data.get('resposta', '').lower()

            elif response.status_code == 200:
                data = response.get_json()
                resposta_texto = data.get('resposta', '').lower()

                # Não deve conter evidências de execução de SQL
                palavras_perigosas = ['drop table', 'delete from', 'truncate', 'dados deletados']
                for palavra in palavras_perigosas:
                    assert palavra not in resposta_texto, f"Possível execução perigosa: {palavra}"


class TestGeminiImprovements:
    """Testes das melhorias da API Gemini."""

    def test_gemini_cache_functionality(self):
        """Testa funcionalidade de cache do Gemini."""
        try:
            from app.app import enviar_para_gemini, gemini_cache

            # Limpar cache
            gemini_cache.clear()

            # Em ambiente de teste, deve usar mock
            contexto_teste = "Teste de cache do Gemini"
            resposta1 = enviar_para_gemini(contexto_teste)
            resposta2 = enviar_para_gemini(contexto_teste)

            # Deve ter a mesma resposta (cache funcionando)
            assert resposta1 == resposta2, "Cache não está funcionando corretamente"

        except ImportError:
            pytest.skip("Funções de Gemini não disponíveis")

    def test_gemini_mock_in_test_environment(self):
        """Verifica se ambiente de teste usa mock."""
        try:
            from app.gemini_utils import GeminiManager

            manager = GeminiManager()

            # Em ambiente de teste, deve usar mock
            should_mock = manager.should_use_mock_response()

            # Se estivermos em CI ou teste, deve usar mock
            import os
            if os.getenv('CI') == 'true' or os.getenv('FLASK_ENV') == 'testing':
                assert should_mock == True, "Deveria usar mock em ambiente de teste"

            # Testar resposta mock
            mock_response = manager.get_mock_response("Quantos funcionários temos?")
            assert len(mock_response) > 0
            assert 'funcionários' in mock_response or 'colaborador' in mock_response

        except ImportError:
            pytest.skip("Módulo gemini_utils não disponível")

    def test_rate_limiting_basic(self, client):
        """Testa rate limiting básico."""
        # Fazer várias requisições rápidas
        respostas = []

        for i in range(5):
            response = client.post('/pergunta',
                                 json={'pergunta': f'Teste rate limiting {i}'},
                                 content_type='application/json')
            respostas.append(response)

        # Todas devem responder (não ser bloqueadas imediatamente)
        for i, response in enumerate(respostas):
            assert response.status_code in [200, 400], f"Requisição {i} falhou: {response.status_code}"

    def test_quota_exceeded_handling(self, client):
        """Testa tratamento de quota exceeded."""
        # Este teste simula o comportamento quando quota é excedida
        # Em ambiente real, seria difícil reproduzir

        # Fazer requisição normal
        response = client.post('/pergunta',
                             json={'pergunta': 'Como está nossa empresa?'},
                             content_type='application/json')

        # Deve responder (mock ou real)
        assert response.status_code in [200, 400]

        if response.status_code == 200:
            data = response.get_json()
            resposta = data.get('resposta', '')

            # Se for resposta de quota exceeded, deve ser tratada graciosamente
            if 'indisponível' in resposta.lower() or 'temporariamente' in resposta.lower():
                assert 'minutos' in resposta.lower() or 'momento' in resposta.lower()


class TestPerformanceImprovements:
    """Testes das melhorias de performance."""

    def test_response_time_reasonable(self, client):
        """Verifica se tempo de resposta é razoável."""
        start_time = time.time()

        response = client.post('/pergunta',
                             json={'pergunta': 'Informações da empresa'},
                             content_type='application/json')

        end_time = time.time()
        response_time = end_time - start_time

        # Em ambiente de teste com mock, deve ser rápido
        assert response_time < 5.0, f"Tempo de resposta muito alto: {response_time:.2f}s"
        assert response.status_code in [200, 400]

    def test_concurrent_requests_handling(self, client):
        """Testa tratamento de requisições concorrentes."""
        import threading
        import queue

        results = queue.Queue()
        num_threads = 3

        def make_request(thread_id):
            try:
                response = client.post('/pergunta',
                                     json={'pergunta': f'Teste concorrência {thread_id}'},
                                     content_type='application/json')
                results.put((thread_id, response.status_code, True))
            except Exception as e:
                results.put((thread_id, None, False))

        # Executar requisições concorrentes
        threads = []
        for i in range(num_threads):
            thread = threading.Thread(target=make_request, args=(i,))
            threads.append(thread)
            thread.start()

        # Aguardar conclusão
        for thread in threads:
            thread.join(timeout=10)

        # Verificar resultados
        success_count = 0
        while not results.empty():
            thread_id, status_code, success = results.get()
            if success and status_code in [200, 400]:
                success_count += 1

        # Pelo menos a maioria deve ser bem-sucedida
        assert success_count >= num_threads * 0.7, f"Muitas falhas em requisições concorrentes: {success_count}/{num_threads}"


class TestErrorHandling:
    """Testes de tratamento de erros."""

    def test_invalid_json_handling(self, client):
        """Testa tratamento de JSON inválido."""
        response = client.post('/pergunta',
                             data='{"pergunta": "teste" invalid json}',
                             content_type='application/json')

        assert response.status_code == 400
        data = response.get_json()
        assert data.get('sucesso') == False
        assert 'json' in data.get('erro', '').lower()

    def test_empty_question_handling(self, client):
        """Testa tratamento de pergunta vazia."""
        response = client.post('/pergunta',
                             json={'pergunta': ''},
                             content_type='application/json')

        assert response.status_code == 400
        data = response.get_json()
        assert data.get('sucesso') == False
        assert 'vazio' in data.get('erro', '').lower()

    def test_missing_question_field(self, client):
        """Testa tratamento de campo pergunta ausente."""
        response = client.post('/pergunta',
                             json={'other_field': 'value'},
                             content_type='application/json')

        assert response.status_code == 400
        data = response.get_json()
        assert data.get('sucesso') == False
        assert 'obrigatório' in data.get('erro', '').lower()

    def test_large_payload_handling(self, client):
        """Testa tratamento de payload muito grande."""
        large_question = "a" * 5000  # Pergunta muito grande

        response = client.post('/pergunta',
                             json={'pergunta': large_question},
                             content_type='application/json')

        # Deve responder (pode ser 200 com pergunta sanitizada ou 400)
        assert response.status_code in [200, 400]

        if response.status_code == 200:
            data = response.get_json()
            # Se passou pela sanitização, pergunta foi limitada
            assert len(data.get('resposta', '')) > 0
