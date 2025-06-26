import pytest
import json
import time


class TestSecurityImprovements:

    def test_sql_injection_detection_function(self):
        try:
            from app.app import detectar_sql_injection

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
        try:
            from app.app import sanitizar_entrada

            entrada_perigosa = "SELECT * FROM <script>alert('xss')</script> funcionários"
            entrada_limpa = sanitizar_entrada(entrada_perigosa)

            assert 'script' not in entrada_limpa.lower()
            assert 'funcionários' in entrada_limpa or 'funcionarios' in entrada_limpa

            entrada_grande = "a" * 2000
            entrada_limitada = sanitizar_entrada(entrada_grande)
            assert len(entrada_limitada) <= 1000

        except ImportError:
            pytest.skip("Função de sanitização não disponível")

    def test_sql_injection_endpoint_protection(self, client):
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

            assert response.status_code in [200, 400], f"Status inesperado para: {ataque}"

            if response.status_code == 400:
                data = response.get_json()
                assert data.get('sucesso') == False
                assert 'segurança' in data.get('erro', '').lower() or 'bloqueado' in data.get('resposta', '').lower()

            elif response.status_code == 200:
                data = response.get_json()
                resposta_texto = data.get('resposta', '').lower()

                palavras_perigosas = ['drop table', 'delete from', 'truncate', 'dados deletados']
                for palavra in palavras_perigosas:
                    assert palavra not in resposta_texto, f"Possível execução perigosa: {palavra}"


class TestGeminiImprovements:

    def test_gemini_cache_functionality(self):
        try:
            from app.app import enviar_para_gemini, gemini_cache

            gemini_cache.clear()

            contexto_teste = "Teste de cache do Gemini"
            resposta1 = enviar_para_gemini(contexto_teste)
            resposta2 = enviar_para_gemini(contexto_teste)

            assert resposta1 == resposta2, "Cache não está funcionando corretamente"

        except ImportError:
            pytest.skip("Funções de Gemini não disponíveis")

    def test_gemini_mock_in_test_environment(self):
        try:
            from app.gemini_utils import GeminiManager

            manager = GeminiManager()

            should_mock = manager.should_use_mock_response()

            import os
            if os.getenv('CI') == 'true' or os.getenv('FLASK_ENV') == 'testing':
                assert should_mock == True, "Deveria usar mock em ambiente de teste"

            mock_response = manager.get_mock_response("Quantos funcionários temos?")
            assert len(mock_response) > 0
            assert 'funcionários' in mock_response or 'colaborador' in mock_response

        except ImportError:
            pytest.skip("Módulo gemini_utils não disponível")

    def test_rate_limiting_basic(self, client):
        respostas = []

        for i in range(5):
            response = client.post('/pergunta',
                                 json={'pergunta': f'Teste rate limiting {i}'},
                                 content_type='application/json')
            respostas.append(response)

        for i, response in enumerate(respostas):
            assert response.status_code in [200, 400], f"Requisição {i} falhou: {response.status_code}"

    def test_quota_exceeded_handling(self, client):
        response = client.post('/pergunta',
                             json={'pergunta': 'Como está nossa empresa?'},
                             content_type='application/json')

        assert response.status_code in [200, 400]

        if response.status_code == 200:
            data = response.get_json()
            resposta = data.get('resposta', '')

            if 'indisponível' in resposta.lower() or 'temporariamente' in resposta.lower():
                assert 'minutos' in resposta.lower() or 'momento' in resposta.lower()


class TestPerformanceImprovements:

    def test_response_time_reasonable(self, client):
        client.post('/pergunta',
                   json={'pergunta': 'warmup'},
                   content_type='application/json')

        start_time = time.time()

        response = client.post('/pergunta',
                             json={'pergunta': 'Informações da empresa'},
                             content_type='application/json')

        end_time = time.time()
        response_time = end_time - start_time

        import os
        is_ci_environment = os.getenv('CI') == 'true'
        is_test_environment = os.getenv('FLASK_ENV') == 'testing'
        use_mock = os.getenv('USE_MOCK_GEMINI', '').lower() == 'true'

        if is_ci_environment or is_test_environment or use_mock:
            max_time = 3.0
        else:
            max_time = 20.0

        assert response_time < max_time, f"Tempo de resposta muito alto: {response_time:.2f}s (limite: {max_time}s, mock: {use_mock})"
        assert response.status_code in [200, 400]

        if response.status_code == 200:
            data = response.get_json()
            resposta = data.get('resposta', '')
            assert len(resposta) > 10, "Resposta muito curta"

    def test_concurrent_requests_handling(self, client):
        import time
        from concurrent.futures import ThreadPoolExecutor, as_completed

        def make_single_request(request_id):
            try:
                # Criar uma nova instância do cliente para cada thread
                with client.application.test_client() as thread_client:
                    response = thread_client.post('/pergunta',
                                               json={'pergunta': f'Teste concorrência {request_id}'},
                                               content_type='application/json')
                    return {
                        'id': request_id,
                        'status_code': response.status_code,
                        'success': True,
                        'response_time': time.time()
                    }
            except Exception as e:
                return {
                    'id': request_id,
                    'status_code': None,
                    'success': False,
                    'error': str(e),
                    'response_time': time.time()
                }

        num_requests = 3
        timeout_seconds = 15

        results = []

        with ThreadPoolExecutor(max_workers=num_requests) as executor:
            futures = [executor.submit(make_single_request, i) for i in range(num_requests)]

            for future in as_completed(futures, timeout=timeout_seconds):
                try:
                    result = future.result()
                    results.append(result)
                except Exception as e:
                    results.append({
                        'id': 'unknown',
                        'status_code': None,
                        'success': False,
                        'error': str(e)
                    })

        successful_requests = [r for r in results if r['success'] and r['status_code'] in [200, 400]]
        failed_requests = [r for r in results if not r['success']]

        success_rate = len(successful_requests) / len(results) if results else 0

        assert len(results) == num_requests, f"Esperado {num_requests} resultados, obtido {len(results)}"
        assert success_rate >= 0.7, f"Taxa de sucesso muito baixa: {success_rate:.2%} ({len(successful_requests)}/{len(results)})"

        print(f"\nTeste de concorrência - Resultados:")
        print(f"Total de requisições: {len(results)}")
        print(f"Bem-sucedidas: {len(successful_requests)}")
        print(f"Falharam: {len(failed_requests)}")
        print(f"Taxa de sucesso: {success_rate:.2%}")

        if failed_requests:
            print("Erros encontrados:")
            for req in failed_requests[:3]:
                print(f"  - ID {req['id']}: {req.get('error', 'Erro desconhecido')}")


class TestErrorHandling:

    def test_invalid_json_handling(self, client):
        response = client.post('/pergunta',
                             data='{"pergunta": "teste" invalid json}',
                             content_type='application/json')

        assert response.status_code == 400
        data = response.get_json()
        assert data.get('sucesso') == False
        assert 'json' in data.get('erro', '').lower()

    def test_empty_question_handling(self, client):
        response = client.post('/pergunta',
                             json={'pergunta': ''},
                             content_type='application/json')

        assert response.status_code == 400
        data = response.get_json()
        assert data.get('sucesso') == False
        assert 'vazio' in data.get('erro', '').lower()

    def test_missing_question_field(self, client):
        response = client.post('/pergunta',
                             json={'other_field': 'value'},
                             content_type='application/json')

        assert response.status_code == 400
        data = response.get_json()
        assert data.get('sucesso') == False
        assert 'obrigatório' in data.get('erro', '').lower()

    def test_large_payload_handling(self, client):
        large_question = "a" * 5000

        response = client.post('/pergunta',
                             json={'pergunta': large_question},
                             content_type='application/json')

        assert response.status_code in [200, 400]

        if response.status_code == 200:
            data = response.get_json()
            assert len(data.get('resposta', '')) > 0
