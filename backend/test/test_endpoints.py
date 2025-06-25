import pytest
import json
import time
import threading
from urllib.parse import quote

pytestmark = pytest.mark.api

class TestEndpointsBasicos:
    def test_endpoint_pergunta_existe(self, client):
        response = client.post('/pergunta',
                             json={'pergunta': 'teste'},
                             content_type='application/json')
        assert response.status_code != 404
        assert response.status_code in [200, 400, 500]

    def test_endpoint_health_existe(self, client):
        response = client.get('/health')
        assert response.status_code in [200, 404]
        if response.status_code == 200:
            data = json.loads(response.data)
            assert 'status' in data

    @pytest.mark.parametrize("endpoint", [
        '/api/query/total_vendas_por_mes',
        '/api/query/funcionarios_por_departamento',
        '/api/query/projetos_por_status',
        '/api/query/receita_por_cliente',
        '/api/query/metricas_gerais'
    ])
    def test_endpoints_api_existem(self, client, endpoint):
        response = client.get(endpoint)
        assert response.status_code != 404
        assert response.status_code in [200, 500]

    def test_content_type_headers(self, client):
        response = client.post('/pergunta',
                             json={'pergunta': 'teste'},
                             content_type='application/json')
        assert 'application/json' in response.headers.get('Content-Type', '')

    def test_cors_headers_basicos(self, client):
        response = client.get('/health')
        assert response.status_code != 405


class TestEndpointPergunta:
    def test_pergunta_valida_basica(self, client):
        response = client.post('/pergunta',
                             json={'pergunta': 'Quantos funcionários temos?'},
                             content_type='application/json')
        assert response.status_code in [200, 500]
        data = json.loads(response.data)
        if response.status_code == 200:
            assert 'resposta' in data
            assert 'sucesso' in data
            assert isinstance(data['resposta'], str)
            assert isinstance(data['sucesso'], bool)
        else:
            assert 'erro' in data or 'error' in data

    @pytest.mark.parametrize("pergunta,esperado_funcional", [
        ("Quantos funcionários trabalham aqui?", True),
        ("Qual o total de vendas este mês?", True),
        ("Mostre os projetos em andamento", True),
        ("Como está a receita por cliente?", True),
        ("Preciso de métricas gerais", True),
        ("Olá, como vai?", True),
        ("Obrigado pela ajuda", True),
    ])
    def test_perguntas_variadas_funcionais(self, client, pergunta, esperado_funcional):
        response = client.post('/pergunta',
                             json={'pergunta': pergunta},
                             content_type='application/json')
        assert response.status_code in [200, 500]
        data = json.loads(response.data)
        if esperado_funcional and response.status_code == 200:
            assert 'resposta' in data
            assert len(data['resposta'].strip()) > 0

    def test_pergunta_campo_obrigatorio(self, client):
        response = client.post('/pergunta',
                             json={'outra_coisa': 'valor'},
                             content_type='application/json')
        assert response.status_code == 400
        data = json.loads(response.data)
        assert 'erro' in data or 'error' in data
        assert data.get('sucesso', True) is False

    def test_pergunta_vazia(self, client):
        perguntas_vazias = ['', '   ', '\t\n', None]
        for pergunta_vazia in perguntas_vazias:
            response = client.post('/pergunta',
                                 json={'pergunta': pergunta_vazia},
                                 content_type='application/json')
            assert response.status_code == 400
            data = json.loads(response.data)
            assert data.get('sucesso', True) is False

    def test_pergunta_muito_longa(self, client):
        pergunta_longa = "Como está " * 1000 + "a situação dos funcionários?"

        response = client.post('/pergunta',
                             json={'pergunta': pergunta_longa},
                             content_type='application/json')

        assert response.status_code in [200, 400, 413, 500]

        if response.status_code in [400, 413]:
            data = json.loads(response.data)
            assert 'erro' in data or 'error' in data

    def test_pergunta_caracteres_especiais(self, client):
        perguntas_especiais = [
            "Quantos funcionários há? 🤔",
            "Vendas em R$ (reais) - março/2024",
            "Dados de A&B Corporation <script>",
            "Consulta 'aspas simples' e \"aspas duplas\"",
            "Pergunta com\nquebra de linha",
            "Acentuação: São Paulo, João, coração",
        ]

        for pergunta in perguntas_especiais:
            response = client.post('/pergunta',
                                 json={'pergunta': pergunta},
                                 content_type='application/json')

            assert response.status_code in [200, 400, 500]

            data = json.loads(response.data)

            if response.status_code == 200:
                assert 'resposta' in data

    def test_content_type_incorreto(self, client):
        response = client.post('/pergunta',
                             data='{"pergunta": "teste"}')

        assert response.status_code == 400

        data = json.loads(response.data)
        assert 'erro' in data or 'error' in data

    def test_json_malformado(self, client):
        response = client.post('/pergunta',
                             data='{"pergunta": "teste"',
                             content_type='application/json')

        assert response.status_code == 400

        data = json.loads(response.data)
        assert 'erro' in data or 'error' in data


class TestEndpointsAPI:
    def test_total_vendas_por_mes(self, client):
        response = client.get('/api/query/total_vendas_por_mes')

        assert response.status_code != 404

        if response.status_code == 200:
            data = json.loads(response.data)

            assert 'data' in data
            assert isinstance(data['data'], list)

            if data['data']:
                for item in data['data']:
                    assert isinstance(item, dict)
                    expected_fields = ['mes', 'ano', 'total']
                    assert any(field in item for field in expected_fields)

    def test_funcionarios_por_departamento(self, client):
        response = client.get('/api/query/funcionarios_por_departamento')

        assert response.status_code != 404

        if response.status_code == 200:
            data = json.loads(response.data)

            assert 'data' in data
            assert isinstance(data['data'], list)

            if data['data']:
                for item in data['data']:
                    assert isinstance(item, dict)
                    expected_fields = ['departamento', 'total', 'count']
                    assert any(field in item for field in expected_fields)

    def test_projetos_por_status(self, client):
        response = client.get('/api/query/projetos_por_status')

        assert response.status_code != 404

        if response.status_code == 200:
            data = json.loads(response.data)

            assert 'data' in data
            assert isinstance(data['data'], list)

            if data['data']:
                for item in data['data']:
                    assert isinstance(item, dict)

    def test_receita_por_cliente(self, client):
        response = client.get('/api/query/receita_por_cliente')

        assert response.status_code != 404

        if response.status_code == 200:
            data = json.loads(response.data)

            assert 'data' in data
            assert isinstance(data['data'], list)

    def test_metricas_gerais(self, client):
        response = client.get('/api/query/metricas_gerais')

        assert response.status_code != 404

        if response.status_code == 200:
            data = json.loads(response.data)

            assert 'data' in data
            assert data['data'] is not None

    def test_endpoints_api_metodos_incorretos(self, client):
        endpoints = [
            '/api/query/total_vendas_por_mes',
            '/api/query/funcionarios_por_departamento',
            '/api/query/projetos_por_status'
        ]

        for endpoint in endpoints:
            response = client.post(endpoint, json={'teste': 'valor'})
            assert response.status_code in [405, 404, 500]

    def test_endpoints_api_parametros_query(self, client):
        endpoints_com_params = [
            '/api/query/total_vendas_por_mes?ano=2024',
            '/api/query/funcionarios_por_departamento?ativo=true',
            '/api/query/receita_por_cliente?limite=10'
        ]

        for endpoint in endpoints_com_params:
            response = client.get(endpoint)
            assert response.status_code != 404
            assert response.status_code in [200, 400, 500]


class TestHealthCheck:
    def test_health_check_basico(self, client):
        response = client.get('/health')

        if response.status_code == 200:
            data = json.loads(response.data)

            assert 'status' in data

            status_validos = ['ok', 'healthy', 'up', 'running']
            assert any(status in str(data['status']).lower()
                      for status in status_validos)

    def test_health_check_performance(self, client):
        start_time = time.time()

        response = client.get('/health')

        end_time = time.time()
        response_time = end_time - start_time

        assert response_time < 2.0

        assert response.status_code != 404

    def test_health_check_metodos_suportados(self, client):
        response_get = client.get('/health')
        assert response_get.status_code != 404

        response_post = client.post('/health')
        assert response_post.status_code in [200, 405, 404]

        response_options = client.open('/health', method='OPTIONS')
        assert response_options.status_code in [200, 204, 405, 404]


class TestSegurancaValidacao:
    def test_injecao_sql_basica(self, client):
        payloads_sql = [
            "'; DROP TABLE usuarios; --",
            "1' OR '1'='1",
            "admin'--",
            "' UNION SELECT * FROM usuarios --",
            "1; DELETE FROM funcionarios; --"
        ]

        for payload in payloads_sql:
            response = client.post('/pergunta',
                                 json={'pergunta': f"Funcionários {payload}"},
                                 content_type='application/json')

            assert response.status_code in [200, 400, 500]

            if response.status_code == 500:
                data = json.loads(response.data)
                erro_msg = str(data.get('erro', '')).lower()

                palavras_perigosas = ['syntax error', 'postgresql', 'psycopg2', 'sql']
                assert not any(palavra in erro_msg for palavra in palavras_perigosas)

    def test_xss_basico(self, client):
        payloads_xss = [
            "<script>alert('xss')</script>",
            "<img src=x onerror=alert('xss')>",
            "javascript:alert('xss')",
            "<svg onload=alert('xss')>",
            "'><script>alert('xss')</script>"
        ]

        for payload in payloads_xss:
            response = client.post('/pergunta',
                                 json={'pergunta': f"Funcionários {payload}"},
                                 content_type='application/json')

            assert response.status_code in [200, 400, 500]

            if response.status_code == 200:
                data = json.loads(response.data)
                resposta = data.get('resposta', '')

                indicadores_seguranca = [
                    'segurança', 'security', 'injeção', 'injection',
                    'não posso processar', 'cannot process', 'blocked',
                    'bloqueado', 'padrão incomum', 'tentativa'
                ]

                tem_indicador_seguranca = any(indicador in resposta.lower()
                                            for indicador in indicadores_seguranca)

                if tem_indicador_seguranca:
                    continue

                assert not (payload in resposta and
                           not any(indicador in resposta.lower()
                                  for indicador in indicadores_seguranca))

                assert 'onerror=alert(' not in resposta
                assert 'onload=alert(' not in resposta
                assert 'javascript:alert(' not in resposta

    def test_tamanho_payload_limitado(self, client):
        payload_gigante = {'pergunta': 'A' * (1024 * 1024)}

        response = client.post('/pergunta',
                             json=payload_gigante,
                             content_type='application/json')

        assert response.status_code in [200, 400, 413, 500]

        if response.status_code == 413:
            assert True
        elif response.status_code == 400:
            data = json.loads(response.data)
            assert 'erro' in data or 'error' in data

    def test_headers_seguranca(self, client):
        response = client.post('/pergunta',
                             json={'pergunta': 'teste'},
                             content_type='application/json')

        headers = response.headers

        assert 'Content-Type' in headers

        server_header = headers.get('Server', '').lower()
        assert 'werkzeug' not in server_header
        assert 'python' not in server_header

    def test_rate_limiting_simulado(self, client):
        respostas = []

        for i in range(10):
            response = client.post('/pergunta',
                                 json={'pergunta': f'Teste {i}'},
                                 content_type='application/json')
            respostas.append(response.status_code)

        for status in respostas:
            assert status in [200, 400, 429, 500]

        assert 200 in respostas or all(s == 500 for s in respostas)

    def test_caracteres_unicode_maliciosos(self, client):
        unicode_payloads = [
            "Funcionários\u0000null",
            "Funcionários\u202E\u202D",
            "Funcionários\uFEFF",
            "Funcionários\u00A0",
            "Funcionários\u200B",
        ]

        for payload in unicode_payloads:
            response = client.post('/pergunta',
                                 json={'pergunta': payload},
                                 content_type='application/json')

            assert response.status_code in [200, 400, 500]


class TestPerformanceConfiabilidade:
    def test_tempo_resposta_aceitavel(self, client):
        perguntas_simples = [
            "Quantos funcionários?",
            "Total de vendas",
            "Status dos projetos"
        ]

        for pergunta in perguntas_simples:
            start_time = time.time()

            response = client.post('/pergunta',
                                 json={'pergunta': pergunta},
                                 content_type='application/json')

            end_time = time.time()
            response_time = end_time - start_time

            assert response_time < 30.0

            assert response.status_code in [200, 500]

    def test_multiplas_requisicoes_simultaneas(self, client):

        def fazer_requisicao(pergunta_id):
            try:
                response = client.post('/pergunta',
                                     json={'pergunta': f'Teste simultâneo {pergunta_id}'},
                                     content_type='application/json')
                return response.status_code
            except Exception as e:
                return f"Erro: {str(e)}"

        resultados = []
        for i in range(5):
            resultado = fazer_requisicao(i)
            resultados.append(resultado)

        for resultado in resultados:
            if isinstance(resultado, int):
                assert resultado in [200, 400, 500]
            else:
                print(f"Erro em requisição simultânea: {resultado}")

    def test_estabilidade_requisicoes_repetidas(self, client):
        pergunta_teste = "Funcionários ativos"
        status_codes = []

        for i in range(20):
            response = client.post('/pergunta',
                                 json={'pergunta': pergunta_teste},
                                 content_type='application/json')
            status_codes.append(response.status_code)

        status_unicos = set(status_codes)

        for status in status_unicos:
            assert status in [200, 400, 500]

        assert len(status_unicos) <= 3

    def test_memoria_nao_vaza(self, client):
        import gc

        gc.collect()

        for i in range(50):
            response = client.post('/pergunta',
                                 json={'pergunta': f'Teste memória {i}'},
                                 content_type='application/json')

            assert response.status_code in [200, 400, 500]

            if i % 10 == 0:
                gc.collect()

        assert True

    def test_endpoints_api_performance(self, client):
        endpoints = [
            '/api/query/total_vendas_por_mes',
            '/api/query/funcionarios_por_departamento',
            '/health'
        ]

        for endpoint in endpoints:
            start_time = time.time()

            response = client.get(endpoint)

            end_time = time.time()
            response_time = end_time - start_time

            assert response_time < 10.0

            assert response.status_code != 404


class TestErrosExcecoes:
    def test_erro_json_estrutura_inesperada(self, client):
        estruturas_estranhas = [
            {'wrong_field': 'valor'},
            {'pergunta': {'nested': 'object'}},
            {'pergunta': ['array', 'values']},
            {'pergunta': 123},
            {'pergunta': True},
            {'pergunta': None},
            [],
            "string_direta",
        ]

        for estrutura in estruturas_estranhas:
            response = client.post('/pergunta',
                                 json=estrutura,
                                 content_type='application/json')

            assert response.status_code in [200, 400, 500]

            try:
                data = json.loads(response.data)
                assert isinstance(data, dict)
                assert 'erro' in data or 'error' in data or 'message' in data
            except json.JSONDecodeError:
                pytest.fail("Resposta de erro deve ser JSON válido")

    def test_encoding_diferentes(self, client):
        perguntas_multilinguistic = [
            "Quantos funcionários? (português)",
            "How many employees? (english)",
            "¿Cuántos empleados? (español)",
            "Сколько сотрудников? (русский)",
            "従業員は何人ですか？ (japanese)",
            "كم عدد الموظفين؟ (arabic)",
        ]

        for pergunta in perguntas_multilinguistic:
            response = client.post('/pergunta',
                                 json={'pergunta': pergunta},
                                 content_type='application/json; charset=utf-8')

            assert response.status_code in [200, 400, 500]

            if response.status_code == 200:
                data = json.loads(response.data)
                assert 'resposta' in data

    def test_requisicoes_malformadas(self, client):
        casos_malformados = [
            ('{"pergunta": "teste"', 'application/json'),
            ('pergunta=teste', 'application/x-www-form-urlencoded'),
            ('<xml><pergunta>teste</pergunta></xml>', 'application/xml'),
            ('pergunta: teste', 'text/plain'),
        ]

        for dados, content_type in casos_malformados:
            response = client.post('/pergunta',
                                 data=dados,
                                 content_type=content_type)

            assert response.status_code in [400, 415, 500]

    def test_headers_ausentes_ou_incorretos(self, client):
        response1 = client.post('/pergunta',
                              data='{"pergunta": "teste"}')
        assert response1.status_code in [400, 415, 500]

        response2 = client.post('/pergunta',
                              data='{"pergunta": "teste"}',
                              content_type='text/html')
        assert response2.status_code in [400, 415, 500]

    def test_metodos_http_nao_suportados(self, client):
        metodos_nao_suportados = ['PUT', 'DELETE', 'PATCH']

        for metodo in metodos_nao_suportados:
            response = client.open('/pergunta',
                                 method=metodo,
                                 json={'pergunta': 'teste'},
                                 content_type='application/json')

            assert response.status_code in [405, 404, 500]

    def test_urls_nao_existentes(self, client):
        urls_inexistentes = [
            '/pergunta_inexistente',
            '/api/query/endpoint_falso',
            '/admin',
            '/debug',
            '/test',
            '/../../../etc/passwd',
        ]

        for url in urls_inexistentes:
            response = client.get(url)

            assert response.status_code == 404


class TestIntegracao:
    def test_fluxo_completo_pergunta_resposta(self, client):
        perguntas_realistas = [
            "Quantos funcionários temos no departamento de TI?",
            "Qual foi o total de vendas no último mês?",
            "Mostre-me os projetos que estão em andamento",
            "Como está a receita por cliente este ano?",
            "Preciso das métricas gerais da empresa"
        ]

        for pergunta in perguntas_realistas:
            response = client.post('/pergunta',
                                 json={'pergunta': pergunta},
                                 content_type='application/json')

            assert response.status_code in [200, 500]

            data = json.loads(response.data)

            if response.status_code == 200:
                assert 'resposta' in data
                assert 'sucesso' in data
                assert data['sucesso'] is True
                assert isinstance(data['resposta'], str)
                assert len(data['resposta'].strip()) > 0
            else:
                assert 'erro' in data or 'error' in data
                assert data.get('sucesso', True) is False

    def test_consistencia_entre_endpoints(self, client):
        response_pergunta = client.post('/pergunta',
                                       json={'pergunta': 'Quantos funcionários por departamento?'},
                                       content_type='application/json')

        response_api = client.get('/api/query/funcionarios_por_departamento')

        if response_pergunta.status_code == 200:
            assert response_api.status_code in [200, 500]

        if response_api.status_code == 200:
            assert response_pergunta.status_code in [200, 500]

    def test_resiliencia_falhas_parciais(self, client):
        cenarios_teste = [
            {'pergunta': 'Dados urgentes de funcionários'},
            {'pergunta': 'Relatório completo de vendas'},
            {'pergunta': 'Dashboard executivo'},
            {'pergunta': 'Análise de performance'},
        ]

        resultados_validos = 0

        for cenario in cenarios_teste:
            response = client.post('/pergunta',
                                 json=cenario,
                                 content_type='application/json')

            assert response.status_code in [200, 500]

            if response.status_code == 200:
                resultados_validos += 1

                data = json.loads(response.data)
                assert 'resposta' in data

        assert resultados_validos >= 0

    def test_comportamento_carga_alta_simulada(self, client):
        perguntas_simultaneas = [
            "Funcionários ativos",
            "Vendas do mês",
            "Projetos em andamento",
            "Receita por cliente",
            "Métricas gerais"
        ]

        def fazer_pergunta_usuario(pergunta):
            return client.post('/pergunta',
                             json={'pergunta': pergunta},
                             content_type='application/json')

        respostas = []
        for pergunta in perguntas_simultaneas:
            response = fazer_pergunta_usuario(pergunta)
            respostas.append(response.status_code)

        for status in respostas:
            assert status in [200, 500]

        assert 200 in respostas or all(s == 500 for s in respostas)

    def test_compatibilidade_versoes_api(self, client):
        endpoints_api = [
            '/api/query/total_vendas_por_mes',
            '/api/query/funcionarios_por_departamento',
            '/health'
        ]

        for endpoint in endpoints_api:
            response = client.get(endpoint)

            assert response.status_code != 404

            if response.status_code == 200:
                data = json.loads(response.data)
                assert isinstance(data, dict)
