# -*- coding: utf-8 -*-
"""
Testes de infraestrutura crítica do backend Sophos Kodiak.

Este módulo testa componentes críticos da infraestrutura sem uso de mocks,
garantindo que todas as dependências fundamentais estejam funcionando corretamente.

Componentes testados:
- Conectividade real com banco de dados PostgreSQL
- Disponibilidade e funcionalidade da API Gemini
- Execução real de todas as queries SQL do sistema
- Integridade das tabelas e estrutura do banco

Uso:
    # Executar todos os testes críticos
    pytest tests/test_critical_infrastructure.py -v

    # Executar apenas testes de banco
    pytest tests/test_critical_infrastructure.py::TestDatabaseCritical -v

    # Executar com mais detalhes
    pytest tests/test_critical_infrastructure.py -v -s
"""

import pytest
import os
import time
import psycopg2
import requests
from datetime import datetime
from typing import Dict, List, Any

# Marcar todos os testes como críticos
pytestmark = pytest.mark.critical


class TestDatabaseCritical:
    """
    Testes críticos de conectividade e funcionalidade do banco de dados.
    """

    def test_database_connection_real(self, env_vars):
        """Testa conexão real com o banco PostgreSQL."""
        try:
            conn = psycopg2.connect(
                host=env_vars['DB_HOST'],
                port=env_vars['DB_PORT'],
                dbname=env_vars['DB_NAME'],
                user=env_vars['DB_USER'],
                password=env_vars['DB_PASSWORD'],
                connect_timeout=30
            )

            # Teste básico de funcionalidade
            cur = conn.cursor()
            cur.execute("SELECT version();")
            version = cur.fetchone()

            assert version is not None
            assert 'PostgreSQL' in version[0]

            cur.close()
            conn.close()

        except psycopg2.OperationalError as e:
            pytest.fail(f"Falha na conexão com o banco: {e}")
        except Exception as e:
            pytest.fail(f"Erro inesperado na conexão: {e}")

    def test_database_tables_exist(self, env_vars):
        """Verifica se todas as tabelas necessárias existem."""
        expected_tables = [
            'funcionarios',
            'departamentos',
            'projetos',
            'clientes',
            'vendas',
            'contratos_marketing'
        ]

        try:
            conn = psycopg2.connect(
                host=env_vars['DB_HOST'],
                port=env_vars['DB_PORT'],
                dbname=env_vars['DB_NAME'],
                user=env_vars['DB_USER'],
                password=env_vars['DB_PASSWORD']
            )

            cur = conn.cursor()

            # Verificar existência de cada tabela
            for table in expected_tables:
                cur.execute("""
                    SELECT EXISTS (
                        SELECT FROM information_schema.tables
                        WHERE table_schema = 'public'
                        AND table_name = %s
                    );
                """, (table,))

                exists = cur.fetchone()[0]
                assert exists, f"Tabela '{table}' não existe no banco de dados"

            cur.close()
            conn.close()

        except Exception as e:
            pytest.fail(f"Erro ao verificar tabelas: {e}")

    @pytest.mark.performance
    def test_database_performance_basic(self, env_vars):
        """Testa performance básica do banco de dados."""
        try:
            start_time = time.time()

            conn = psycopg2.connect(
                host=env_vars['DB_HOST'],
                port=env_vars['DB_PORT'],
                dbname=env_vars['DB_NAME'],
                user=env_vars['DB_USER'],
                password=env_vars['DB_PASSWORD']
            )

            connection_time = time.time() - start_time

            # Conexão deve ser rápida (menos de 5 segundos)
            assert connection_time < 5.0, f"Conexão muito lenta: {connection_time:.2f}s"

            # Teste de query simples
            cur = conn.cursor()
            query_start = time.time()
            cur.execute("SELECT 1;")
            result = cur.fetchone()
            query_time = time.time() - query_start

            assert result[0] == 1
            assert query_time < 1.0, f"Query simples muito lenta: {query_time:.2f}s"

            cur.close()
            conn.close()

        except Exception as e:
            pytest.fail(f"Erro no teste de performance: {e}")

    def test_database_concurrent_connections(self, env_vars):
        """Testa múltiplas conexões simultâneas."""
        import threading
        import queue

        results = queue.Queue()
        num_connections = 5

        def test_connection(thread_id):
            try:
                conn = psycopg2.connect(
                    host=env_vars['DB_HOST'],
                    port=env_vars['DB_PORT'],
                    dbname=env_vars['DB_NAME'],
                    user=env_vars['DB_USER'],
                    password=env_vars['DB_PASSWORD']
                )

                cur = conn.cursor()
                cur.execute("SELECT %s as thread_id;", (thread_id,))
                result = cur.fetchone()[0]

                cur.close()
                conn.close()

                results.put((thread_id, True, result))

            except Exception as e:
                results.put((thread_id, False, str(e)))

        # Criar e iniciar threads
        threads = []
        for i in range(num_connections):
            thread = threading.Thread(target=test_connection, args=(i,))
            threads.append(thread)
            thread.start()

        # Aguardar conclusão
        for thread in threads:
            thread.join(timeout=10)

        # Verificar resultados
        success_count = 0
        while not results.empty():
            thread_id, success, data = results.get()
            if success:
                success_count += 1
                assert data == thread_id
            else:
                pytest.fail(f"Thread {thread_id} falhou: {data}")

        assert success_count == num_connections, f"Apenas {success_count}/{num_connections} conexões bem-sucedidas"


class TestSQLQueriesExecution:
    """
    Testes de execução real de todas as queries SQL do sistema.
    """

    def test_all_query_mappings_execute(self, env_vars):
        """Executa todas as queries SQL dos mapeamentos para validar sintaxe."""
        try:
            from app.query_mapping import query_manager

            conn = psycopg2.connect(
                host=env_vars['DB_HOST'],
                port=env_vars['DB_PORT'],
                dbname=env_vars['DB_NAME'],
                user=env_vars['DB_USER'],
                password=env_vars['DB_PASSWORD']
            )

            failed_queries = []

            for mapping in query_manager.mappings:
                # Usar uma nova transação para cada query
                try:
                    with conn:
                        with conn.cursor() as cur:
                            # Executar query (apenas validação de sintaxe)
                            cur.execute(mapping.sql_query)
                            result = cur.fetchall()

                            # Query deve retornar algo ou pelo menos não dar erro
                            assert result is not None

                except Exception as e:
                    failed_queries.append({
                        'query_id': mapping.query_id,
                        'error': str(e),
                        'sql': mapping.sql_query
                    })

            conn.close()

            if failed_queries:
                error_details = "\n".join([
                    f"Query ID: {q['query_id']}\nSQL: {q['sql']}\nErro: {q['error']}\n"
                    for q in failed_queries
                ])
                pytest.fail(f"Queries com falha:\n{error_details}")

        except ImportError:
            pytest.skip("Módulo query_mapping não disponível")

    def test_api_endpoints_queries_execute(self, env_vars):
        """Testa execução das queries dos endpoints de API."""
        api_queries = {
            'total_vendas_por_mes': """
                SELECT
                    TO_CHAR(data_venda, 'YYYY-MM') AS mes,
                    COALESCE(SUM(valor), 0) AS total_vendas,
                    COUNT(*) AS num_vendas
                FROM vendas
                WHERE data_venda >= CURRENT_DATE - INTERVAL '12 months'
                GROUP BY TO_CHAR(data_venda, 'YYYY-MM')
                ORDER BY mes DESC
                LIMIT 12;
            """,
            'funcionarios_por_departamento': """
                SELECT
                    d.nome AS departamento,
                    COALESCE(COUNT(f.id), 0) AS quantidade,
                    d.orcamento
                FROM departamentos d
                LEFT JOIN funcionarios f ON f.departamento_id = d.id
                GROUP BY d.id, d.nome, d.orcamento
                ORDER BY quantidade DESC, d.nome;
            """,
            'projetos_por_status': """
                SELECT
                    COALESCE(status, 'Não Definido') AS status,
                    COUNT(*) AS quantidade,
                    COALESCE(SUM(orcamento), 0) AS valor_total
                FROM projetos
                WHERE data_inicio >= CURRENT_DATE - INTERVAL '2 years'
                GROUP BY status
                ORDER BY quantidade DESC;
            """
        }

        try:
            conn = psycopg2.connect(
                host=env_vars['DB_HOST'],
                port=env_vars['DB_PORT'],
                dbname=env_vars['DB_NAME'],
                user=env_vars['DB_USER'],
                password=env_vars['DB_PASSWORD']
            )

            cur = conn.cursor()
            failed_queries = []

            for query_name, sql in api_queries.items():
                try:
                    start_time = time.time()
                    cur.execute(sql)
                    result = cur.fetchall()
                    execution_time = time.time() - start_time

                    # Verificações básicas
                    assert result is not None
                    assert execution_time < 10.0, f"Query {query_name} muito lenta: {execution_time:.2f}s"

                except Exception as e:
                    failed_queries.append({
                        'query_name': query_name,
                        'error': str(e),
                        'sql': sql.strip()
                    })

            cur.close()
            conn.close()

            if failed_queries:
                error_details = "\n".join([
                    f"Query: {q['query_name']}\nSQL: {q['sql'][:100]}...\nErro: {q['error']}\n"
                    for q in failed_queries
                ])
                pytest.fail(f"Queries de API com falha:\n{error_details}")

        except Exception as e:
            pytest.fail(f"Erro ao testar queries de API: {e}")


class TestGeminiAPIIntegration:
    """
    Testes de integração real com a API Gemini (quando disponível).
    """

    def test_gemini_api_availability(self, env_vars):
        """Testa se a API Gemini está disponível e respondendo."""
        api_key = env_vars.get('GEMINI_API_KEY')

        # Pular teste se não tiver API key real
        if not api_key or api_key in ['test_api_key', 'fake_gemini_key_for_tests', 'test_gemini_api_key']:
            pytest.skip("API key do Gemini não disponível para teste real")

        try:
            import google.generativeai as genai

            genai.configure(api_key=api_key)
            model = genai.GenerativeModel('gemini-2.5-flash')

            # Teste simples
            response = model.generate_content("Teste de conectividade")

            assert response is not None
            assert hasattr(response, 'text')
            assert len(response.text) > 0

        except ImportError:
            pytest.skip("Biblioteca google-generativeai não disponível")
        except Exception as e:
            if "API_KEY" in str(e).upper() or "404" in str(e):
                pytest.skip(f"Problema com API key ou modelo: {e}")
            else:
                pytest.fail(f"Erro na API Gemini: {e}")

    @pytest.mark.performance
    def test_gemini_api_performance(self, env_vars):
        """Testa performance básica da API Gemini."""
        api_key = env_vars.get('GEMINI_API_KEY')

        if not api_key or api_key in ['test_api_key', 'fake_gemini_key_for_tests', 'test_gemini_api_key']:
            pytest.skip("API key do Gemini não disponível para teste real")

        try:
            import google.generativeai as genai

            genai.configure(api_key=api_key)
            model = genai.GenerativeModel('gemini-2.5-flash')

            # Teste de latência
            start_time = time.time()
            response = model.generate_content("Responda apenas: OK")
            response_time = time.time() - start_time

            assert response is not None
            assert response_time < 30.0, f"API Gemini muito lenta: {response_time:.2f}s"

        except ImportError:
            pytest.skip("Biblioteca google-generativeai não disponível")
        except Exception as e:
            if "API_KEY" in str(e).upper() or "404" in str(e):
                pytest.skip(f"Problema com API key ou modelo: {e}")
            else:
                pytest.fail(f"Erro na API Gemini: {e}")

    def test_gemini_api_context_handling(self, env_vars):
        """Testa se a API Gemini processa contexto adequadamente."""
        api_key = env_vars.get('GEMINI_API_KEY')

        if not api_key or api_key in ['test_api_key', 'fake_gemini_key_for_tests', 'test_gemini_api_key']:
            pytest.skip("API key do Gemini não disponível para teste real")

        try:
            import google.generativeai as genai

            genai.configure(api_key=api_key)
            model = genai.GenerativeModel('gemini-2.5-flash')

            # Teste com contexto simples similar ao usado na aplicação
            context = """
            Você é o Assistente Virtual Sophos da STOLF LTDA.
            Contexto: Empresa de marketing com funcionários e projetos.
            Pergunta do usuário: Quantos funcionários temos?
            Dados: Total de funcionários: 10
            """

            response = model.generate_content(context)

            assert response is not None
            assert len(response.text) > 10  # Resposta substantiva

            # Verificar se a resposta faz sentido no contexto
            response_lower = response.text.lower()
            assert any(word in response_lower for word in ['funcionário', 'funcionarios', '10', 'dez'])

        except ImportError:
            pytest.skip("Biblioteca google-generativeai não disponível")
        except Exception as e:
            if "API_KEY" in str(e).upper() or "404" in str(e):
                pytest.skip(f"Problema com API key ou modelo: {e}")
            else:
                pytest.fail(f"Erro na API Gemini: {e}")


class TestApplicationIntegrity:
    """
    Testes de integridade geral da aplicação.
    """

    def test_application_imports_correctly(self):
        """Verifica se todos os módulos principais são importáveis."""
        try:
            from app.app import app
            assert app is not None

        except ImportError as e:
            pytest.fail(f"Erro ao importar aplicação principal: {e}")

    def test_query_mapping_module_integrity(self):
        """Verifica integridade do módulo de mapeamento de queries."""
        try:
            from app.query_mapping import query_manager, QueryCategory, QueryMapping

            assert query_manager is not None
            assert len(query_manager.mappings) > 0

            # Verificar se todas as categorias existem
            for category in QueryCategory:
                queries_in_category = query_manager.get_queries_by_category(category)
                assert isinstance(queries_in_category, list)

        except ImportError as e:
            pytest.fail(f"Erro ao importar módulo query_mapping: {e}")

    def test_environment_variables_configuration(self, env_vars):
        """Verifica se as variáveis de ambiente estão configuradas adequadamente."""
        required_vars = ['DB_HOST', 'DB_PORT', 'DB_NAME', 'DB_USER', 'DB_PASSWORD', 'GEMINI_API_KEY']

        for var in required_vars:
            value = env_vars.get(var)
            assert value is not None, f"Variável de ambiente {var} não está configurada"
            assert len(str(value)) > 0, f"Variável de ambiente {var} está vazia"

    def test_critical_dependencies_available(self):
        """Verifica se dependências críticas estão disponíveis."""
        critical_imports = [
            ('psycopg2', 'Conexão com PostgreSQL'),
            ('flask', 'Framework web'),
            ('json', 'Processamento JSON'),
        ]

        for module_name, description in critical_imports:
            try:
                __import__(module_name)
            except ImportError:
                pytest.fail(f"Dependência crítica não disponível: {module_name} ({description})")

    def test_optional_dependencies_status(self):
        """Verifica status de dependências opcionais."""
        optional_imports = [
            ('spacy', 'Processamento de linguagem natural'),
            ('google.generativeai', 'API Gemini'),
            ('dotenv', 'Carregamento de variáveis de ambiente'),
        ]

        dependency_status = {}
        for module_name, description in optional_imports:
            try:
                __import__(module_name)
                dependency_status[module_name] = True
            except ImportError:
                dependency_status[module_name] = False

        # Log do status (não falha o teste)
        print(f"\nStatus das dependências opcionais:")
        for module, available in dependency_status.items():
            status = "✅ Disponível" if available else "❌ Não disponível"
            print(f"  {module}: {status}")

        # Pelo menos uma das dependências de NLP deve estar disponível
        nlp_available = dependency_status.get('spacy', False)
        if not nlp_available:
            print("⚠️  Aviso: spaCy não disponível, funcionalidade de NLP pode ser limitada")


class TestDataIntegrity:
    """
    Testes de integridade dos dados no banco.
    """

    def test_database_basic_data_consistency(self, env_vars):
        """Verifica consistência básica dos dados."""
        try:
            conn = psycopg2.connect(
                host=env_vars['DB_HOST'],
                port=env_vars['DB_PORT'],
                dbname=env_vars['DB_NAME'],
                user=env_vars['DB_USER'],
                password=env_vars['DB_PASSWORD']
            )

            cur = conn.cursor()

            # Verificar se referências estão consistentes (se houver dados)
            consistency_checks = [
                ("Funcionários-Departamentos", """
                    SELECT COUNT(*) FROM funcionarios f
                    LEFT JOIN departamentos d ON f.departamento_id = d.id
                    WHERE f.departamento_id IS NOT NULL AND d.id IS NULL
                """),
                ("Projetos-Clientes", """
                    SELECT COUNT(*) FROM projetos p
                    LEFT JOIN clientes c ON p.cliente_id = c.id
                    WHERE p.cliente_id IS NOT NULL AND c.id IS NULL
                """),
                ("Vendas-Projetos", """
                    SELECT COUNT(*) FROM vendas v
                    LEFT JOIN projetos p ON v.projeto_id = p.id
                    WHERE v.projeto_id IS NOT NULL AND p.id IS NULL
                """)
            ]

            inconsistencies = []
            for check_name, query in consistency_checks:
                cur.execute(query)
                count = cur.fetchone()[0]
                if count > 0:
                    inconsistencies.append(f"{check_name}: {count} registros inconsistentes")

            cur.close()
            conn.close()

            if inconsistencies:
                pytest.fail(f"Inconsistências encontradas:\n" + "\n".join(inconsistencies))

        except Exception as e:
            pytest.fail(f"Erro ao verificar integridade dos dados: {e}")

    def test_database_schema_integrity(self, env_vars):
        """Verifica integridade do schema do banco."""
        try:
            conn = psycopg2.connect(
                host=env_vars['DB_HOST'],
                port=env_vars['DB_PORT'],
                dbname=env_vars['DB_NAME'],
                user=env_vars['DB_USER'],
                password=env_vars['DB_PASSWORD']
            )

            cur = conn.cursor()

            # Verificar se as colunas essenciais existem
            essential_columns = {
                'funcionarios': ['id', 'nome', 'cargo', 'salario'],
                'departamentos': ['id', 'nome'],
                'projetos': ['id', 'nome', 'status', 'orcamento'],
                'clientes': ['id', 'nome_empresa'],
                'vendas': ['id', 'valor', 'data_venda']
            }

            missing_columns = []
            for table, columns in essential_columns.items():
                for column in columns:
                    cur.execute("""
                        SELECT EXISTS (
                            SELECT FROM information_schema.columns
                            WHERE table_name = %s AND column_name = %s
                        );
                    """, (table, column))

                    exists = cur.fetchone()[0]
                    if not exists:
                        missing_columns.append(f"{table}.{column}")

            cur.close()
            conn.close()

            if missing_columns:
                pytest.fail(f"Colunas essenciais faltando: {', '.join(missing_columns)}")

        except Exception as e:
            pytest.fail(f"Erro ao verificar schema: {e}")
