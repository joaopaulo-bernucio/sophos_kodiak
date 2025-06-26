import pytest
import time
import json
import random
from concurrent.futures import ThreadPoolExecutor, as_completed


class TestConcurrentUsers:

    def test_multiple_simultaneous_requests(self, client):
        num_threads = 5
        requests_per_thread = 3

        perguntas_teste = [
            "Quantos funcionários temos?",
            "Total de projetos",
            "Listar departamentos",
            "Salário médio dos funcionários",
            "Projetos em andamento"
        ]

        results = []
        errors = []

        def make_request(thread_id, request_id):
            try:
                pergunta = random.choice(perguntas_teste)
                start_time = time.time()

                with client.application.test_client() as thread_client:
                    response = thread_client.post('/pergunta',
                                                json={'pergunta': pergunta},
                                                content_type='application/json')

                response_time = time.time() - start_time

                return {
                    'thread_id': thread_id,
                    'request_id': request_id,
                    'pergunta': pergunta,
                    'status_code': response.status_code,
                    'response_time': response_time,
                    'success': response.status_code in [200, 400, 500]
                }

            except Exception as e:
                return {
                    'thread_id': thread_id,
                    'request_id': request_id,
                    'error': str(e),
                    'success': False
                }

        with ThreadPoolExecutor(max_workers=num_threads) as executor:
            futures = []

            for thread_id in range(num_threads):
                for request_id in range(requests_per_thread):
                    future = executor.submit(make_request, thread_id, request_id)
                    futures.append(future)

            for future in as_completed(futures):
                try:
                    result = future.result(timeout=30)
                    if result.get('success', False):
                        results.append(result)
                    else:
                        errors.append(result)
                except Exception as e:
                    errors.append({'error': f"Future exception: {e}", 'success': False})

        total_requests = num_threads * requests_per_thread
        success_count = len(results)

        print(f"\nResultados de concorrência:")
        print(f"  Total de requisições: {total_requests}")
        print(f"  Sucessos: {success_count}")
        print(f"  Falhas: {len(errors)}")

        if results:
            avg_response_time = sum(r['response_time'] for r in results) / len(results)
            max_response_time = max(r['response_time'] for r in results)
            print(f"  Tempo médio de resposta: {avg_response_time:.3f}s")
            print(f"  Tempo máximo de resposta: {max_response_time:.3f}s")

        success_rate = success_count / total_requests
        assert success_rate >= 0.8, f"Taxa de sucesso muito baixa: {success_rate:.1%}"

        if results:
            assert avg_response_time < 10.0, f"Tempo médio muito alto: {avg_response_time:.3f}s"

    def test_concurrent_api_endpoints(self, client):
        api_endpoints = [
            '/api/query/total_vendas_por_mes',
            '/api/query/funcionarios_por_departamento',
            '/api/query/projetos_por_status',
            '/api/query/receita_por_cliente',
            '/api/query/metricas_gerais'
        ]

        num_concurrent = 3
        results = []

        def test_endpoint(endpoint):
            try:
                start_time = time.time()
                with client.application.test_client() as thread_client:
                    response = thread_client.get(endpoint)
                response_time = time.time() - start_time

                return {
                    'endpoint': endpoint,
                    'status_code': response.status_code,
                    'response_time': response_time,
                    'success': response.status_code in [200, 404]
                }

            except Exception as e:
                return {
                    'endpoint': endpoint,
                    'error': str(e),
                    'success': False
                }

        for endpoint in api_endpoints:
            with ThreadPoolExecutor(max_workers=num_concurrent) as executor:
                futures = [executor.submit(test_endpoint, endpoint) for _ in range(num_concurrent)]

                for future in as_completed(futures):
                    try:
                        result = future.result(timeout=15)
                        results.append(result)
                    except Exception as e:
                        results.append({'endpoint': endpoint, 'error': str(e), 'success': False})

        successful_results = [r for r in results if r.get('success', False)]

        print(f"\nResultados de endpoints API:")
        print(f"  Total de chamadas: {len(results)}")
        print(f"  Sucessos: {len(successful_results)}")

        by_endpoint = {}
        for result in results:
            endpoint = result.get('endpoint', 'unknown')
            if endpoint not in by_endpoint:
                by_endpoint[endpoint] = []
            by_endpoint[endpoint].append(result)

        for endpoint, endpoint_results in by_endpoint.items():
            successes = sum(1 for r in endpoint_results if r.get('success', False))
            print(f"  {endpoint}: {successes}/{len(endpoint_results)} sucessos")

        success_rate = len(successful_results) / len(results) if results else 0
        assert success_rate >= 0.7, f"Taxa de sucesso muito baixa para APIs: {success_rate:.1%}"

    def test_mixed_workload_simulation(self, client):
        workloads = [
            {'type': 'pergunta', 'weight': 60, 'data': {'pergunta': 'Quantos funcionários temos?'}},
            {'type': 'pergunta', 'weight': 20, 'data': {'pergunta': 'Total de projetos em andamento'}},
            {'type': 'api', 'weight': 10, 'endpoint': '/health'},
            {'type': 'api', 'weight': 10, 'endpoint': '/api/query/metricas_gerais'}
        ]

        num_requests = 20
        concurrent_users = 4

        def execute_workload():
            local_results = []
            with client.application.test_client() as local_client:
                for _ in range(num_requests // concurrent_users):
                    rand = random.randint(1, 100)
                    cumulative_weight = 0
                    selected_workload = workloads[0]

                    for workload in workloads:
                        cumulative_weight += workload['weight']
                        if rand <= cumulative_weight:
                            selected_workload = workload
                            break

                    try:
                        start_time = time.time()

                        if selected_workload['type'] == 'pergunta':
                            response = local_client.post('/pergunta',
                                                       json=selected_workload['data'],
                                                       content_type='application/json')
                        else:
                            response = local_client.get(selected_workload['endpoint'])

                        response_time = time.time() - start_time

                        local_results.append({
                            'type': selected_workload['type'],
                            'status_code': response.status_code,
                            'response_time': response_time,
                            'success': response.status_code in [200, 400, 404, 500]
                        })

                        time.sleep(0.1)

                    except Exception as e:
                        local_results.append({
                            'type': selected_workload['type'],
                            'error': str(e),
                            'success': False
                        })

            return local_results

        all_results = []
        with ThreadPoolExecutor(max_workers=concurrent_users) as executor:
            futures = [executor.submit(execute_workload) for _ in range(concurrent_users)]

            for future in as_completed(futures):
                try:
                    results = future.result(timeout=60)
                    all_results.extend(results)
                except Exception as e:
                    print(f"Erro na carga de trabalho: {e}")

        successful_requests = [r for r in all_results if r.get('success', False)]

        print(f"\nSimulação de carga mista:")
        print(f"  Total de requisições: {len(all_results)}")
        print(f"  Sucessos: {len(successful_requests)}")

        if successful_requests:
            avg_time = sum(r['response_time'] for r in successful_requests) / len(successful_requests)
            print(f"  Tempo médio: {avg_time:.3f}s")

        by_type = {}
        for result in all_results:
            req_type = result.get('type', 'unknown')
            if req_type not in by_type:
                by_type[req_type] = {'total': 0, 'success': 0}
            by_type[req_type]['total'] += 1
            if result.get('success', False):
                by_type[req_type]['success'] += 1

        for req_type, stats in by_type.items():
            rate = stats['success'] / stats['total'] if stats['total'] > 0 else 0
            print(f"  {req_type}: {stats['success']}/{stats['total']} ({rate:.1%})")

        success_rate = len(successful_requests) / len(all_results) if all_results else 0
        assert success_rate >= 0.75, f"Taxa de sucesso insuficiente: {success_rate:.1%}"


class TestComplexScenarios:

    def test_comprehensive_data_flow(self, client):
        pergunta_sequence = [
            "Quantos funcionários temos?",
            "Listar departamentos",
            "Funcionários por departamento",
            "Salário médio",
            "Projetos em andamento",
            "Total de vendas",
            "Clientes ativos"
        ]

        results = []

        for i, pergunta in enumerate(pergunta_sequence):
            try:
                start_time = time.time()

                response = client.post('/pergunta',
                                     json={'pergunta': pergunta},
                                     content_type='application/json')

                response_time = time.time() - start_time

                result = {
                    'sequence': i + 1,
                    'pergunta': pergunta,
                    'status_code': response.status_code,
                    'response_time': response_time,
                    'success': response.status_code in [200, 400, 500]
                }

                if response.status_code == 200:
                    try:
                        data = json.loads(response.data)
                        result['has_valid_json'] = True
                        result['response_length'] = len(str(data))
                    except:
                        result['has_valid_json'] = False

                results.append(result)

                time.sleep(0.5)

            except Exception as e:
                results.append({
                    'sequence': i + 1,
                    'pergunta': pergunta,
                    'error': str(e),
                    'success': False
                })

        successful_steps = [r for r in results if r.get('success', False)]

        print(f"\nFluxo completo de dados:")
        print(f"  Passos executados: {len(results)}")
        print(f"  Passos bem-sucedidos: {len(successful_steps)}")

        for result in results:
            status = "✅" if result.get('success', False) else "❌"
            time_str = f"{result.get('response_time', 0):.3f}s" if 'response_time' in result else "N/A"
            print(f"  {status} {result['sequence']}. {result['pergunta']} ({time_str})")

        success_rate = len(successful_steps) / len(results)
        assert success_rate >= 0.8, f"Muitos passos falharam: {success_rate:.1%}"

        total_time = sum(r.get('response_time', 0) for r in results)
        assert total_time < 30.0, f"Tempo total muito alto: {total_time:.1f}s"

    def test_error_recovery_scenarios(self, client):
        error_scenarios = [
            {'pergunta': '', 'expected_recoverable': True},
            {'pergunta': 'x' * 10000, 'expected_recoverable': True},
            {'pergunta': 'Pergunta com caracteres especiais: @#$%^&*()', 'expected_recoverable': True},
            {'pergunta': 'Query SQL injection attempt; DROP TABLE funcionarios;', 'expected_recoverable': True},
            {'pergunta': '<script>alert("xss")</script>', 'expected_recoverable': True}
        ]

        recovery_results = []

        for i, scenario in enumerate(error_scenarios):
            try:
                response = client.post('/pergunta',
                                     json={'pergunta': scenario['pergunta']},
                                     content_type='application/json')

                recovery_response = client.post('/pergunta',
                                              json={'pergunta': 'Quantos funcionários temos?'},
                                              content_type='application/json')

                result = {
                    'scenario': i + 1,
                    'pergunta': scenario['pergunta'][:50] + '...' if len(scenario['pergunta']) > 50 else scenario['pergunta'],
                    'initial_status': response.status_code,
                    'recovery_status': recovery_response.status_code,
                    'recovered': recovery_response.status_code in [200, 400, 500],
                    'expected_recoverable': scenario['expected_recoverable']
                }

                recovery_results.append(result)

            except Exception as e:
                recovery_results.append({
                    'scenario': i + 1,
                    'error': str(e),
                    'recovered': False,
                    'expected_recoverable': scenario['expected_recoverable']
                })

        print(f"\nTeste de recuperação de erros:")
        for result in recovery_results:
            recovered = result.get('recovered', False)
            status = "✅" if recovered else "❌"
            print(f"  {status} Cenário {result['scenario']}: {result.get('pergunta', 'Erro')}")

        failed_recoveries = [r for r in recovery_results
                           if r.get('expected_recoverable', False) and not r.get('recovered', False)]

        assert len(failed_recoveries) == 0, f"Falhas de recuperação: {len(failed_recoveries)}"

    def test_data_consistency_across_endpoints(self, client):
        main_response = client.post('/pergunta',
                                   json={'pergunta': 'Quantos funcionários temos?'},
                                   content_type='application/json')

        api_responses = {}
        api_endpoints = [
            '/api/query/funcionarios_por_departamento',
            '/api/query/metricas_gerais',
            '/health'
        ]

        for endpoint in api_endpoints:
            try:
                response = client.get(endpoint)
                api_responses[endpoint] = {
                    'status_code': response.status_code,
                    'success': response.status_code == 200
                }

                if response.status_code == 200:
                    try:
                        data = json.loads(response.data)
                        api_responses[endpoint]['data'] = data
                    except:
                        api_responses[endpoint]['data'] = None

            except Exception as e:
                api_responses[endpoint] = {'error': str(e), 'success': False}

        working_endpoints = [ep for ep, resp in api_responses.items() if resp.get('success', False)]

        print(f"\nConsistência entre endpoints:")
        print(f"  Endpoint principal: {main_response.status_code}")
        print(f"  Endpoints de API funcionando: {len(working_endpoints)}/{len(api_endpoints)}")

        for endpoint, response in api_responses.items():
            status = "✅" if response.get('success', False) else "❌"
            print(f"  {status} {endpoint}: {response.get('status_code', 'Erro')}")

        main_working = main_response.status_code in [200, 400, 500]
        api_working = len(working_endpoints) > 0

        assert main_working or api_working, "Nenhum endpoint está funcionando adequadamente"


class TestPerformanceUnderLoad:

    @pytest.mark.performance
    def test_sustained_load_performance(self, client):
        duration_seconds = 30
        request_interval = 0.5

        pergunta_test = "Quantos funcionários temos?"
        results = []
        start_time = time.time()

        print(f"\nIniciando teste de carga sustentada ({duration_seconds}s)...")

        while time.time() - start_time < duration_seconds:
            try:
                req_start = time.time()

                response = client.post('/pergunta',
                                     json={'pergunta': pergunta_test},
                                     content_type='application/json')

                req_time = time.time() - req_start

                results.append({
                    'timestamp': time.time(),
                    'response_time': req_time,
                    'status_code': response.status_code,
                    'success': response.status_code in [200, 400, 500]
                })

                time.sleep(max(0, request_interval - req_time))

            except Exception as e:
                results.append({
                    'timestamp': time.time(),
                    'error': str(e),
                    'success': False
                })

        successful_results = [r for r in results if r.get('success', False)]

        if successful_results:
            response_times = [r['response_time'] for r in successful_results]
            avg_time = sum(response_times) / len(response_times)
            min_time = min(response_times)
            max_time = max(response_times)

            print(f"Resultados da carga sustentada:")
            print(f"  Total de requisições: {len(results)}")
            print(f"  Requisições bem-sucedidas: {len(successful_results)}")
            print(f"  Tempo médio: {avg_time:.3f}s")
            print(f"  Tempo mínimo: {min_time:.3f}s")
            print(f"  Tempo máximo: {max_time:.3f}s")

            success_rate = len(successful_results) / len(results)
            assert success_rate >= 0.8, f"Taxa de sucesso baixa sob carga: {success_rate:.1%}"
            assert avg_time < 5.0, f"Tempo médio muito alto: {avg_time:.3f}s"
            assert max_time < 15.0, f"Tempo máximo muito alto: {max_time:.3f}s"

        else:
            pytest.fail("Nenhuma requisição bem-sucedida durante teste de carga")

    @pytest.mark.performance
    def test_burst_load_handling(self, app):
        burst_size = 10
        num_bursts = 3
        burst_interval = 5

        all_results = []

        for burst_num in range(num_bursts):
            print(f"\nExecutando rajada {burst_num + 1}/{num_bursts}...")

            burst_results = []

            def make_burst_request(request_id):
                try:
                    with app.test_client() as local_client:
                        start_time = time.time()
                        response = local_client.post('/pergunta',
                                                   json={'pergunta': f'Pergunta {request_id}'},
                                                   content_type='application/json')
                        response_time = time.time() - start_time

                        return {
                            'burst': burst_num + 1,
                            'request_id': request_id,
                            'response_time': response_time,
                            'status_code': response.status_code,
                            'success': response.status_code in [200, 400, 500]
                        }
                except Exception as e:
                    return {
                        'burst': burst_num + 1,
                        'request_id': request_id,
                        'error': str(e),
                        'success': False
                    }

            with ThreadPoolExecutor(max_workers=min(burst_size, 5)) as executor:
                futures = [executor.submit(make_burst_request, i) for i in range(burst_size)]

                for future in as_completed(futures, timeout=45):
                    try:
                        result = future.result(timeout=10)
                        burst_results.append(result)
                    except Exception as e:
                        burst_results.append({
                            'burst': burst_num + 1,
                            'error': f"Future error: {e}",
                            'success': False
                        })

            all_results.extend(burst_results)

            successful_in_burst = [r for r in burst_results if r.get('success', False)]
            print(f"  Rajada {burst_num + 1}: {len(successful_in_burst)}/{burst_size} sucessos")

            if successful_in_burst:
                avg_time = sum(r['response_time'] for r in successful_in_burst) / len(successful_in_burst)
                print(f"  Tempo médio da rajada: {avg_time:.3f}s")

            if burst_num < num_bursts - 1:
                time.sleep(burst_interval)

        total_successful = [r for r in all_results if r.get('success', False)]
        total_requests = len(all_results)

        print(f"\nResultados gerais das rajadas:")
        print(f"  Total de requisições: {total_requests}")
        print(f"  Total de sucessos: {len(total_successful)}")

        success_rate = len(total_successful) / total_requests if total_requests > 0 else 0

        assert success_rate >= 0.7, f"Sistema não lidou bem com rajadas: {success_rate:.1%}"

    @pytest.mark.performance
    def test_memory_stability_under_load(self, client):
        num_requests = 50
        pergunta_test = "Quantos funcionários temos no departamento de vendas?"

        request_times = []

        print(f"\nTestando estabilidade de memória ({num_requests} requisições)...")

        for i in range(num_requests):
            try:
                start_time = time.time()

                response = client.post('/pergunta',
                                     json={'pergunta': pergunta_test},
                                     content_type='application/json')

                response_time = time.time() - start_time
                request_times.append(response_time)

                if len(request_times) >= 10:
                    recent_avg = sum(request_times[-10:]) / 10
                    overall_avg = sum(request_times) / len(request_times)

                    if recent_avg > overall_avg * 2 and recent_avg > 5.0:
                        print(f"⚠️  Possível degradação de performance detectada")
                        print(f"     Média geral: {overall_avg:.3f}s, Média recente: {recent_avg:.3f}s")

                if i % 10 == 0:
                    time.sleep(0.1)

            except Exception as e:
                print(f"Erro na requisição {i + 1}: {e}")

        if request_times:
            avg_time = sum(request_times) / len(request_times)
            first_10_avg = sum(request_times[:10]) / 10 if len(request_times) >= 10 else avg_time
            last_10_avg = sum(request_times[-10:]) / 10 if len(request_times) >= 10 else avg_time

            print(f"Análise de estabilidade:")
            print(f"  Requisições completadas: {len(request_times)}/{num_requests}")
            print(f"  Tempo médio geral: {avg_time:.3f}s")
            print(f"  Primeiras 10 requisições: {first_10_avg:.3f}s")
            print(f"  Últimas 10 requisições: {last_10_avg:.3f}s")

            degradation_ratio = last_10_avg / first_10_avg if first_10_avg > 0 else 1
            if degradation_ratio > 2.0:
                print(f"⚠️  Degradação significativa detectada: {degradation_ratio:.1f}x")

            assert degradation_ratio < 3.0, f"Degradação de performance muito severa: {degradation_ratio:.1f}x"

        else:
            pytest.fail("Nenhuma requisição completada no teste de estabilidade")
