import pytest
import time
import json
import sys
import os


@pytest.mark.performance
class TestSimplePerformance:

    def test_json_serialization_performance(self):
        test_data = {
            'pergunta': 'Quantos funcionários temos no departamento de vendas?',
            'contexto': 'análise de recursos humanos',
            'filtros': ['departamento', 'vendas', 'funcionários'],
            'metadata': {
                'timestamp': time.time(),
                'user_id': 'test_user',
                'session_id': 'test_session',
                'large_data': list(range(100))
            }
        }

        start_time = time.time()

        for _ in range(100):
            serialized = json.dumps(test_data)
            result = json.loads(serialized)

        duration = time.time() - start_time

        print(f"JSON serialization (100x): {duration:.6f}s")
        print(f"Média por operação: {duration/100:.8f}s")

        assert duration < 1.0, f"JSON muito lento: {duration:.6f}s"
        assert result['pergunta'] == test_data['pergunta']

    def test_string_processing_performance(self):
        text = "funcionários do departamento de vendas e marketing" * 50

        start_time = time.time()

        for _ in range(100):
            words = text.lower().split()
            filtered = [w for w in words if len(w) > 3]
            unique_words = set(filtered)
            result = len(unique_words)

        duration = time.time() - start_time

        print(f"String processing (100x): {duration:.6f}s")
        print(f"Média por operação: {duration/100:.8f}s")

        assert duration < 2.0, f"String processing muito lento: {duration:.6f}s"
        assert result > 0

    def test_list_operations_performance(self):
        start_time = time.time()

        data = list(range(1000))

        for _ in range(10):
            filtered = [x for x in data if x % 2 == 0]
            mapped = [x * 2 for x in filtered]
            sorted_data = sorted(mapped, reverse=True)
            result = sum(sorted_data[:10])

        duration = time.time() - start_time

        print(f"List operations (10x): {duration:.6f}s")
        print(f"Média por operação: {duration/10:.8f}s")

        assert duration < 1.0, f"List operations muito lento: {duration:.6f}s"
        assert result > 0

    def test_python_imports_performance(self):
        import importlib

        start_time = time.time()

        modules_to_test = [
            'json', 'time', 'os', 'sys', 're',
            'datetime', 'collections', 'itertools'
        ]

        for module_name in modules_to_test:
            try:
                module = importlib.import_module(module_name)
                _ = dir(module)
            except ImportError:
                pass

        duration = time.time() - start_time

        print(f"Python imports: {duration:.6f}s")
        print(f"Módulos testados: {len(modules_to_test)}")

        assert duration < 2.0, f"Imports muito lentos: {duration:.6f}s"

    def test_basic_computation_performance(self):
        start_time = time.time()

        result = 0
        for i in range(10000):
            result += i * 2
            result = result % 1000000

        text_result = ""
        for i in range(1000):
            text_result += f"item_{i}_"
            if len(text_result) > 5000:
                text_result = text_result[:1000]

        duration = time.time() - start_time

        print(f"Basic computations: {duration:.6f}s")
        print(f"Resultado numérico: {result}")
        print(f"Tamanho do texto: {len(text_result)}")

        assert duration < 1.0, f"Computações muito lentas: {duration:.6f}s"
        assert result >= 0
        assert len(text_result) > 0


@pytest.mark.performance
class TestMemoryUsage:

    def test_memory_usage_basic(self):
        import gc

        gc.collect()

        initial_objects = len(gc.get_objects())

        temp_data = []
        for i in range(1000):
            temp_data.append({
                'id': i,
                'data': f'test_string_{i}' * 10,
                'list': list(range(10))
            })

        after_objects = len(gc.get_objects())

        temp_data.clear()
        temp_data = None

        gc.collect()

        final_objects = len(gc.get_objects())

        print(f"Objetos iniciais: {initial_objects}")
        print(f"Objetos após criação: {after_objects}")
        print(f"Objetos finais: {final_objects}")
        print(f"Crescimento máximo: {after_objects - initial_objects}")
        print(f"Objetos remanescentes: {final_objects - initial_objects}")

        remaining_objects = final_objects - initial_objects
        assert remaining_objects < 100, f"Possível vazamento: {remaining_objects} objetos"

    def test_sys_info_performance(self):
        start_time = time.time()

        info = {
            'python_version': sys.version,
            'platform': sys.platform,
            'executable': sys.executable,
            'path_length': len(sys.path),
            'modules_count': len(sys.modules),
            'current_dir': os.getcwd(),
            'env_vars_count': len(os.environ)
        }

        duration = time.time() - start_time

        print(f"System info collection: {duration:.6f}s")
        for key, value in info.items():
            if isinstance(value, str) and len(value) > 50:
                print(f"{key}: {str(value)[:50]}...")
            else:
                print(f"{key}: {value}")

        assert duration < 0.5, f"System info muito lento: {duration:.6f}s"
        assert info['modules_count'] > 0
