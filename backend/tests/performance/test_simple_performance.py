"""
Testes de performance simples que não dependem de fixtures complexas.
Estes testes sempre funcionam independente das dependências instaladas.
"""

import pytest
import time
import json
import sys
import os


@pytest.mark.performance
class TestSimplePerformance:
    """Testes de performance simples e confiáveis."""

    def test_json_serialization_performance(self):
        """Testa performance de serialização JSON."""
        test_data = {
            'pergunta': 'Quantos funcionários temos no departamento de vendas?',
            'contexto': 'análise de recursos humanos',
            'filtros': ['departamento', 'vendas', 'funcionários'],
            'metadata': {
                'timestamp': time.time(),
                'user_id': 'test_user',
                'session_id': 'test_session',
                'large_data': list(range(100))  # Adicionar mais dados
            }
        }

        start_time = time.time()

        # Serializar e deserializar múltiplas vezes
        for _ in range(100):
            serialized = json.dumps(test_data)
            result = json.loads(serialized)

        duration = time.time() - start_time

        print(f"JSON serialization (100x): {duration:.6f}s")
        print(f"Média por operação: {duration/100:.8f}s")

        assert duration < 1.0, f"JSON muito lento: {duration:.6f}s"
        assert result['pergunta'] == test_data['pergunta']

    def test_string_processing_performance(self):
        """Testa performance de processamento de strings."""
        text = "funcionários do departamento de vendas e marketing" * 50

        start_time = time.time()

        # Operações típicas de processamento de texto
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
        """Testa performance de operações com listas."""
        start_time = time.time()

        # Criar e processar listas
        data = list(range(1000))

        for _ in range(10):
            # Operações típicas
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
        """Testa performance de importações Python."""
        import importlib

        start_time = time.time()

        # Lista de módulos padrão para importar
        modules_to_test = [
            'json', 'time', 'os', 'sys', 're',
            'datetime', 'collections', 'itertools'
        ]

        for module_name in modules_to_test:
            try:
                module = importlib.import_module(module_name)
                # Acessar algo do módulo para garantir carregamento completo
                _ = dir(module)
            except ImportError:
                pass  # Módulo não disponível

        duration = time.time() - start_time

        print(f"Python imports: {duration:.6f}s")
        print(f"Módulos testados: {len(modules_to_test)}")

        assert duration < 2.0, f"Imports muito lentos: {duration:.6f}s"

    def test_basic_computation_performance(self):
        """Testa performance de computações básicas."""
        start_time = time.time()

        # Computações matemáticas simples
        result = 0
        for i in range(10000):
            result += i * 2
            result = result % 1000000

        # Operações com strings
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
    """Testes simples de uso de memória."""

    def test_memory_usage_basic(self):
        """Teste básico de uso de memória sem dependências externas."""
        # Usar recurso interno do Python para monitorar memória
        import gc

        # Forçar garbage collection
        gc.collect()

        # Criar estruturas de dados
        initial_objects = len(gc.get_objects())

        # Criar dados temporários
        temp_data = []
        for i in range(1000):
            temp_data.append({
                'id': i,
                'data': f'test_string_{i}' * 10,
                'list': list(range(10))
            })

        # Verificar crescimento de objetos
        after_objects = len(gc.get_objects())

        # Limpar dados
        temp_data.clear()
        temp_data = None

        # Forçar garbage collection
        gc.collect()

        final_objects = len(gc.get_objects())

        print(f"Objetos iniciais: {initial_objects}")
        print(f"Objetos após criação: {after_objects}")
        print(f"Objetos finais: {final_objects}")
        print(f"Crescimento máximo: {after_objects - initial_objects}")
        print(f"Objetos remanescentes: {final_objects - initial_objects}")

        # Verificar que não há vazamento excessivo
        remaining_objects = final_objects - initial_objects
        assert remaining_objects < 100, f"Possível vazamento: {remaining_objects} objetos"

    def test_sys_info_performance(self):
        """Coleta informações de sistema para baseline."""
        start_time = time.time()

        # Coletar informações do sistema
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
