# -*- coding: utf-8 -*-
"""
Testes unitários para mapeamento de consultas (query_mapping.py).

Este módulo testa a funcionalidade de mapeamento entre perguntas em linguagem
natural e consultas SQL correspondentes.
"""

import pytest
from unittest.mock import Mock, patch
from app.query_mapping import query_mappings


class TestQueryMappings:
    """Testes para validação dos mapeamentos de consultas."""

    def test_structure_query_mappings(self):
        """Testa a estrutura básica dos mapeamentos."""
        assert isinstance(query_mappings, list)
        assert len(query_mappings) > 0

        # Verificar estrutura de cada mapeamento
        for mapping in query_mappings[:5]:  # Testar apenas os primeiros 5
            assert isinstance(mapping, (tuple, list))
            assert len(mapping) == 3

            palavras, label, query = mapping
            assert isinstance(palavras, list)
            assert isinstance(label, str)
            assert isinstance(query, str)
            assert len(palavras) > 0
            assert len(label) > 0
            assert len(query) > 0

    def test_funcionarios_total_mapping(self):
        """Testa mapeamento específico para total de funcionários."""
        # Procurar o mapeamento específico
        funcionarios_mapping = None
        for palavras, label, query in query_mappings:
            if label == 'funcionarios-total':
                funcionarios_mapping = (palavras, label, query)
                break

        assert funcionarios_mapping is not None
        palavras, label, query = funcionarios_mapping

        # Verificar palavras-chave
        assert 'quantos funcionários' in palavras
        assert 'total funcionários' in palavras
        assert 'número de funcionários' in palavras

        # Verificar query SQL
        assert 'SELECT COUNT(*)' in query.upper()
        assert 'funcionarios' in query.lower()

    def test_salario_medio_mapping(self):
        """Testa mapeamento para salário médio."""
        salario_mapping = None
        for palavras, label, query in query_mappings:
            if label == 'salario-medio':
                salario_mapping = (palavras, label, query)
                break

        assert salario_mapping is not None
        palavras, label, query = salario_mapping

        # Verificar palavras-chave
        assert 'salário médio' in palavras
        assert 'média salarial' in palavras

        # Verificar query SQL
        assert 'AVG(' in query.upper()
        assert 'salario' in query.lower()

    def test_projetos_status_mapping(self):
        """Testa mapeamento para projetos por status."""
        projetos_mapping = None
        for palavras, label, query in query_mappings:
            if label == 'projetos-por-status':
                projetos_mapping = (palavras, label, query)
                break

        assert projetos_mapping is not None
        palavras, label, query = projetos_mapping

        # Verificar palavras-chave
        assert 'projetos por status' in palavras
        assert 'quantos projetos por status' in palavras

        # Verificar query SQL
        assert 'GROUP BY status' in query or 'group by status' in query.lower()
        assert 'projetos' in query.lower()

    def test_unique_labels(self):
        """Testa se todos os labels são únicos."""
        labels = [label for _, label, _ in query_mappings]
        assert len(labels) == len(set(labels)), "Existem labels duplicados"

    def test_valid_sql_syntax(self):
        """Testa se as queries SQL têm sintaxe básica válida."""
        sql_keywords = ['SELECT', 'FROM', 'WHERE', 'GROUP BY', 'ORDER BY', 'COUNT', 'SUM', 'AVG']

        for palavras, label, query in query_mappings[:10]:  # Testar uma amostra
            query_upper = query.upper()

            # Deve conter pelo menos SELECT e FROM (ou COUNT)
            assert 'SELECT' in query_upper, f"Query {label} não contém SELECT"

            # Verificar se termina com ; (opcional, mas recomendado)
            if not query.strip().endswith(';'):
                # Avisar, mas não falhar o teste
                print(f"Warning: Query {label} não termina com ';'")


class TestQueryKeywords:
    """Testes para palavras-chave dos mapeamentos."""

    def test_funcionarios_keywords_coverage(self):
        """Testa cobertura de palavras-chave para funcionários."""
        funcionarios_keywords = []

        for palavras, label, query in query_mappings:
            if 'funcionario' in label:
                funcionarios_keywords.extend(palavras)

        # Verificar variedade de palavras-chave
        keywords_text = ' '.join(funcionarios_keywords).lower()

        assert 'funcionário' in keywords_text or 'funcionarios' in keywords_text
        assert 'quantos' in keywords_text or 'total' in keywords_text
        assert 'listar' in keywords_text or 'mostrar' in keywords_text

    def test_departamentos_keywords_coverage(self):
        """Testa cobertura de palavras-chave para departamentos."""
        departamentos_keywords = []

        for palavras, label, query in query_mappings:
            if 'departamento' in label:
                departamentos_keywords.extend(palavras)

        keywords_text = ' '.join(departamentos_keywords).lower()

        assert 'departamento' in keywords_text
        assert any(word in keywords_text for word in ['listar', 'mostrar', 'ver', 'exibir'])

    def test_vendas_keywords_coverage(self):
        """Testa cobertura de palavras-chave para vendas."""
        vendas_keywords = []

        for palavras, label, query in query_mappings:
            if 'venda' in label:
                vendas_keywords.extend(palavras)

        keywords_text = ' '.join(vendas_keywords).lower()

        assert 'venda' in keywords_text
        assert any(word in keywords_text for word in ['total', 'quantas', 'valor'])

    def test_keywords_no_empty_strings(self):
        """Testa se não há strings vazias nas palavras-chave."""
        for palavras, label, query in query_mappings:
            for palavra in palavras:
                assert isinstance(palavra, str)
                assert len(palavra.strip()) > 0, f"Palavra vazia encontrada em {label}"


class TestQueryParameterization:
    """Testes para queries parametrizadas."""

    def test_queries_with_placeholders(self):
        """Testa queries que usam placeholders."""
        parametrized_queries = []

        for palavras, label, query in query_mappings:
            if '{' in query and '}' in query:
                parametrized_queries.append((label, query))

        assert len(parametrized_queries) > 0, "Deveria haver queries parametrizadas"

        # Verificar alguns tipos comuns de placeholders
        placeholders_found = set()
        for label, query in parametrized_queries:
            if '{id}' in query:
                placeholders_found.add('id')
            if '{nome}' in query:
                placeholders_found.add('nome')
            if '{start_date}' in query:
                placeholders_found.add('start_date')
            if '{end_date}' in query:
                placeholders_found.add('end_date')

        # Deve ter pelo menos alguns tipos de placeholders
        assert len(placeholders_found) > 0

    def test_date_range_queries(self):
        """Testa queries que usam intervalos de data."""
        date_queries = []

        for palavras, label, query in query_mappings:
            if '{start_date}' in query and '{end_date}' in query:
                date_queries.append((label, query))

        assert len(date_queries) > 0, "Deveria haver queries com intervalos de data"

        # Verificar estrutura das queries de data
        for label, query in date_queries:
            assert 'BETWEEN' in query.upper() or 'between' in query.lower()

    def test_id_based_queries(self):
        """Testa queries baseadas em ID."""
        id_queries = []

        for palavras, label, query in query_mappings:
            if '{id}' in query:
                id_queries.append((label, query))

        assert len(id_queries) > 0, "Deveria haver queries baseadas em ID"

        # Verificar se as queries de ID são específicas
        for label, query in id_queries:
            assert 'WHERE' in query.upper() or 'where' in query.lower()
            assert '= {id}' in query or '={id}' in query


class TestQueryCategories:
    """Testes para categorias de queries."""

    def test_counting_queries(self):
        """Testa queries de contagem."""
        counting_queries = []

        for palavras, label, query in query_mappings:
            if 'total' in label or 'COUNT' in query.upper():
                counting_queries.append(label)

        assert len(counting_queries) > 0

        # Verificar se há contagens para entidades principais
        labels_text = ' '.join(counting_queries)
        assert 'funcionarios' in labels_text
        assert 'projetos' in labels_text or 'projeto' in labels_text

    def test_listing_queries(self):
        """Testa queries de listagem."""
        listing_queries = []

        for palavras, label, query in query_mappings:
            if 'lista' in label or any('listar' in p for p in palavras):
                listing_queries.append(label)

        assert len(listing_queries) > 0

        # Verificar se há listagens para entidades principais
        labels_text = ' '.join(listing_queries)
        assert any(entity in labels_text for entity in ['funcionarios', 'clientes', 'projetos'])

    def test_statistical_queries(self):
        """Testa queries estatísticas."""
        statistical_queries = []

        for palavras, label, query in query_mappings:
            query_upper = query.upper()
            if any(func in query_upper for func in ['AVG', 'SUM', 'MIN', 'MAX', 'STDDEV']):
                statistical_queries.append(label)

        assert len(statistical_queries) > 0

        # Verificar se há estatísticas básicas
        labels_text = ' '.join(statistical_queries)
        assert 'salario' in labels_text or 'valor' in labels_text

    def test_join_queries(self):
        """Testa queries com JOINs."""
        join_queries = []

        for palavras, label, query in query_mappings:
            if 'JOIN' in query.upper():
                join_queries.append(label)

        assert len(join_queries) > 0, "Deveria haver queries com JOINs"

        # Verificar se os JOINs fazem sentido
        for label in join_queries[:5]:  # Verificar alguns
            found_query = None
            for _, l, q in query_mappings:
                if l == label:
                    found_query = q
                    break

            if found_query:
                # Deve ter pelo menos FROM e JOIN
                assert 'FROM' in found_query.upper()
                assert 'ON' in found_query.upper()


class TestQueryConsistency:
    """Testes de consistência entre mapeamentos."""

    def test_table_names_consistency(self):
        """Testa consistência nos nomes de tabelas."""
        table_names = set()

        for palavras, label, query in query_mappings:
            query_lower = query.lower()

            # Extrair nomes de tabelas comuns
            if 'funcionarios' in query_lower:
                table_names.add('funcionarios')
            if 'projetos' in query_lower:
                table_names.add('projetos')
            if 'clientes' in query_lower:
                table_names.add('clientes')
            if 'vendas' in query_lower:
                table_names.add('vendas')
            if 'departamentos' in query_lower:
                table_names.add('departamentos')

        # Verificar se as principais tabelas estão presentes
        expected_tables = ['funcionarios', 'projetos', 'clientes', 'vendas', 'departamentos']
        for table in expected_tables:
            assert table in table_names, f"Tabela {table} não encontrada nas queries"

    def test_column_names_consistency(self):
        """Testa consistência nos nomes de colunas."""
        # Verificar se colunas comuns aparecem consistentemente
        all_queries = ' '.join([query for _, _, query in query_mappings]).lower()

        # Colunas que devem aparecer
        expected_columns = ['id', 'nome', 'status', 'data_']

        for column in expected_columns:
            assert column in all_queries, f"Coluna {column} não encontrada"

    def test_no_obvious_sql_injection_vectors(self):
        """Testa se não há vetores óbvios de SQL injection."""
        for palavras, label, query in query_mappings:
            # Verificar se usa placeholders seguros
            if 'WHERE' in query.upper():
                # Se tem WHERE, deve usar placeholders ou valores hardcoded seguros
                assert '{' in query or '=' in query or 'LIKE' in query.upper()

                # Não deve ter concatenação direta óbvia
                assert '"' not in query or "'" not in query or query.count("'") % 2 == 0
