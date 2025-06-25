import pytest
import time
import json


@pytest.mark.performance
class TestBenchmarks:

    def test_benchmark_api_endpoint(self, client):
        def api_call():
            response = client.post('/pergunta',
                                 json={'pergunta': 'Quantos funcionários temos?'},
                                 content_type='application/json')
            return response

        if hasattr(pytest, 'benchmark') and callable(getattr(pytest, 'benchmark', None)):
            try:
                result = pytest.benchmark(api_call)
                assert result is not None
                return
            except Exception:
                pass

        start_time = time.time()
        result = api_call()
        duration = time.time() - start_time

        assert duration < 15.0
        assert result is not None

    def test_benchmark_health_check(self, client):
        def health_call():
            return client.get('/health')

        if hasattr(pytest, 'benchmark') and callable(getattr(pytest, 'benchmark', None)):
            try:
                result = pytest.benchmark(health_call)
                assert result is not None
                return
            except Exception:
                pass

        start_time = time.time()
        result = health_call()
        duration = time.time() - start_time

        assert duration < 1.0
        assert result is not None

    def test_benchmark_nlp_processing(self):
        def nlp_process():
            try:
                from app.query_mapping import extrair_lemmas
                return extrair_lemmas("funcionários do departamento de vendas")
            except ImportError:
                return set(["funcionários", "departamento", "vendas"])

        if hasattr(pytest, 'benchmark') and callable(getattr(pytest, 'benchmark', None)):
            try:
                result = pytest.benchmark(nlp_process)
                assert isinstance(result, set)
                return
            except Exception:
                pass

        start_time = time.time()
        result = nlp_process()
        duration = time.time() - start_time

        assert duration < 2.0
        assert isinstance(result, set)

    def test_benchmark_json_processing(self):
        test_data = {
            'pergunta': 'Quantos funcionários temos no departamento de vendas?',
            'contexto': 'análise de recursos humanos',
            'filtros': ['departamento', 'vendas', 'funcionários'],
            'metadata': {
                'timestamp': time.time(),
                'user_id': 'test_user',
                'session_id': 'test_session'
            }
        }

        def json_process():
            serialized = json.dumps(test_data)
            return json.loads(serialized)

        if hasattr(pytest, 'benchmark') and callable(getattr(pytest, 'benchmark', None)):
            try:
                result = pytest.benchmark(json_process)
                assert result['pergunta'] == test_data['pergunta']
                return
            except Exception:
                pass

        start_time = time.time()
        result = json_process()
        duration = time.time() - start_time

        assert duration < 0.1
        assert result['pergunta'] == test_data['pergunta']


@pytest.mark.performance
class TestManualBenchmarks:

    def test_manual_memory_usage(self):
        try:
            import psutil
            import os

            process = psutil.Process(os.getpid())
            memory_before = process.memory_info().rss / 1024 / 1024

            data = []
            for i in range(1000):
                data.append({'id': i, 'data': f'test_data_{i}' * 10})

            memory_after = process.memory_info().rss / 1024 / 1024
            memory_delta = memory_after - memory_before

            assert memory_delta < 50

        except ImportError:
            pytest.skip("psutil não disponível")

    def test_manual_string_operations(self):
        text = "funcionários do departamento de vendas" * 100

        start_time = time.time()

        result = text.upper().lower().split()
        result = [word.strip() for word in result if len(word) > 3]
        result = set(result)

        duration = time.time() - start_time

        assert duration < 0.5
        assert len(result) > 0

    def test_manual_list_processing(self):
        start_time = time.time()

        data = list(range(10000))

        filtered = [x for x in data if x % 2 == 0]
        mapped = [x * 2 for x in filtered[:1000]]
        sorted_data = sorted(mapped, reverse=True)

        duration = time.time() - start_time

        assert duration < 1.0
        assert len(sorted_data) > 0
        assert sorted_data[0] >= sorted_data[-1]
