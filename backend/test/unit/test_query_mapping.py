import pytest

pytestmark = pytest.mark.unit

from app.query_mapping import (
    QueryCategory,
    QueryMapping,
    QueryMappingManager,
    query_manager,
    query_mappings
)


class TestQueryMapping:

    def test_query_mapping_creation(self):
        mapping = QueryMapping(
            keywords=["test", "teste"],
            query_id="test-id",
            sql_query="SELECT * FROM test;",
            category=QueryCategory.LISTS,
            description="Teste de criação"
        )

        assert mapping.keywords == ["test", "teste"]
        assert mapping.query_id == "test-id"
        assert mapping.sql_query == "SELECT * FROM test;"
        assert mapping.category == QueryCategory.LISTS
        assert mapping.description == "Teste de criação"

    def test_query_mapping_immutable_attributes(self):
        mapping = QueryMapping(
            keywords=["funcionários"],
            query_id="func-test",
            sql_query="SELECT COUNT(*) FROM funcionarios;",
            category=QueryCategory.TOTALS,
            description="Teste funcionários"
        )

        assert hasattr(mapping, 'keywords')
        assert hasattr(mapping, 'query_id')
        assert hasattr(mapping, 'sql_query')
        assert hasattr(mapping, 'category')
        assert hasattr(mapping, 'description')


class TestQueryCategory:

    def test_all_categories_exist(self):
        expected_categories = [
            "totais", "listagens", "detalhes",
            "recentes", "estatisticas", "analises"
        ]

        for category_value in expected_categories:
            found = False
            for category in QueryCategory:
                if category.value == category_value:
                    found = True
                    break
            assert found, f"Categoria {category_value} não encontrada"

    def test_category_enum_values(self):
        assert QueryCategory.TOTALS.value == "totais"
        assert QueryCategory.LISTS.value == "listagens"
        assert QueryCategory.DETAILS.value == "detalhes"
        assert QueryCategory.RECENT.value == "recentes"
        assert QueryCategory.STATISTICS.value == "estatisticas"
        assert QueryCategory.ANALYTICS.value == "analises"


class TestQueryMappingManager:

    def test_manager_initialization(self):
        manager = QueryMappingManager()

        assert isinstance(manager.mappings, list)
        assert len(manager.mappings) > 0
        assert isinstance(manager._keyword_index, dict)
        assert len(manager._keyword_index) > 0

    def test_manager_has_required_mappings(self):
        manager = QueryMappingManager()

        essential_ids = [
            "funcionarios-total", "projetos-total", "clientes-total",
            "funcionarios-lista", "projetos-lista", "salario-medio"
        ]

        found_ids = [mapping.query_id for mapping in manager.mappings]

        for essential_id in essential_ids:
            assert essential_id in found_ids, f"Mapeamento essencial {essential_id} não encontrado"

    def test_find_query_exact_match(self):
        manager = QueryMappingManager()

        result = manager.find_query("quantos funcionários")
        assert result is not None
        assert result.query_id == "funcionarios-total"

        result = manager.find_query("listar funcionários")
        assert result is not None
        assert result.query_id == "funcionarios-lista"

    def test_find_query_case_insensitive(self):
        manager = QueryMappingManager()

        result_lower = manager.find_query("quantos funcionários")
        result_upper = manager.find_query("QUANTOS FUNCIONÁRIOS")
        result_mixed = manager.find_query("Quantos Funcionários")

        assert result_lower is not None
        assert result_upper is not None
        assert result_mixed is not None
        assert result_lower.query_id == result_upper.query_id == result_mixed.query_id

    def test_find_query_substring_match(self):
        manager = QueryMappingManager()

        result = manager.find_query("me diga quantos funcionários temos")
        assert result is not None
        assert result.query_id == "funcionarios-total"

        result = manager.find_query("funcionários")
        assert result is not None

    def test_find_query_best_match_scoring(self):
        manager = QueryMappingManager()

        result = manager.find_query("total de funcionários")
        assert result is not None
        assert result.query_id == "funcionarios-total"

    def test_find_query_no_match(self):
        manager = QueryMappingManager()

        result = manager.find_query("pergunta completamente irrelevante xyz123")
        assert result is None

    def test_get_queries_by_category(self):
        manager = QueryMappingManager()

        totals_queries = manager.get_queries_by_category(QueryCategory.TOTALS)
        assert len(totals_queries) > 0

        for query in totals_queries:
            assert query.category == QueryCategory.TOTALS
            assert "total" in query.query_id or "COUNT" in query.sql_query.upper()

    def test_get_all_keywords(self):
        manager = QueryMappingManager()

        keywords = manager.get_all_keywords()
        assert isinstance(keywords, list)
        assert len(keywords) > 0

        keywords_lower = [k.lower() for k in keywords]
        assert "quantos funcionários" in keywords_lower
        assert "listar funcionários" in keywords_lower

    def test_keyword_index_consistency(self):
        manager = QueryMappingManager()

        for mapping in manager.mappings:
            for keyword in mapping.keywords:
                assert keyword.lower() in manager._keyword_index
                assert manager._keyword_index[keyword.lower()] == mapping


class TestGlobalQueryManager:

    def test_global_manager_exists(self):
        assert query_manager is not None
        assert isinstance(query_manager, QueryMappingManager)
        assert len(query_manager.mappings) > 0

    def test_global_manager_functionality(self):
        result = query_manager.find_query("quantos funcionários")
        assert result is not None
        assert result.query_id == "funcionarios-total"


class TestBackwardCompatibility:

    def test_query_mappings_list_exists(self):
        assert query_mappings is not None
        assert isinstance(query_mappings, list)
        assert len(query_mappings) > 0

    def test_query_mappings_structure(self):
        for mapping_tuple in query_mappings[:5]:
            assert isinstance(mapping_tuple, tuple)
            assert len(mapping_tuple) == 3

            keywords, query_id, sql_query = mapping_tuple
            assert isinstance(keywords, list)
            assert isinstance(query_id, str)
            assert isinstance(sql_query, str)


class TestQueryValidation:

    def test_all_queries_have_select(self):
        for mapping in query_manager.mappings:
            assert "SELECT" in mapping.sql_query.upper(), f"Query {mapping.query_id} não tem SELECT"

    def test_all_queries_end_with_semicolon(self):
        for mapping in query_manager.mappings:
            assert mapping.sql_query.strip().endswith(';'), f"Query {mapping.query_id} não termina com ';'"

    def test_queries_have_proper_table_names(self):
        expected_tables = [
            'funcionarios', 'projetos', 'clientes', 'vendas',
            'departamentos', 'contratos_marketing'
        ]

        all_queries_text = ' '.join([m.sql_query.lower() for m in query_manager.mappings])

        for table in expected_tables:
            assert table in all_queries_text, f"Tabela {table} não encontrada nas queries"

    def test_no_obvious_sql_injection_vulnerabilities(self):
        for mapping in query_manager.mappings:
            query = mapping.sql_query

            if 'WHERE' in query.upper():
                safe_constructs = [
                    'BETWEEN', 'IN (', '= ', 'LIKE', 'IS NULL', 'IS NOT NULL',
                    'CURRENT_DATE', 'INTERVAL', '>= ', '<= ', '> ', '< '
                ]

                has_safe_construct = any(construct in query.upper() for construct in safe_constructs)

                if not has_safe_construct:
                    quote_count = query.count("'")
                    assert quote_count % 2 == 0, f"Query {mapping.query_id} pode ter problema de SQL injection"


class TestSpecificMappings:

    @pytest.mark.parametrize("query_id,expected_keywords", [
        ("funcionarios-total", ["quantos funcionários", "total funcionários"]),
        ("projetos-total", ["quantos projetos", "total de projetos"]),
        ("clientes-lista", ["listar clientes", "mostrar clientes"]),
        ("salario-medio", ["salário médio", "média salarial"]),
    ])
    def test_specific_mappings_keywords(self, query_id, expected_keywords):
        mapping = None
        for m in query_manager.mappings:
            if m.query_id == query_id:
                mapping = m
                break

        assert mapping is not None, f"Mapeamento {query_id} não encontrado"

        for expected_keyword in expected_keywords:
            assert expected_keyword in mapping.keywords, \
                f"Keyword '{expected_keyword}' não encontrada em {query_id}"

    def test_funcionarios_total_mapping(self):
        result = query_manager.find_query("quantos funcionários")

        assert result is not None
        assert result.query_id == "funcionarios-total"
        assert result.category == QueryCategory.TOTALS
        assert "COUNT(*)" in result.sql_query.upper()
        assert "funcionarios" in result.sql_query.lower()

    def test_contratos_valor_total_mapping(self):
        result = query_manager.find_query("receita de contratos")

        assert result is not None
        assert result.query_id == "contratos-valor-total"
        assert result.category == QueryCategory.TOTALS
        assert "SUM(" in result.sql_query.upper()
        assert "contratos_marketing" in result.sql_query.lower()

    def test_vendas_detalhes_mapping(self):
        result = query_manager.find_query("detalhes de vendas")

        assert result is not None
        assert result.query_id == "vendas-detalhes"
        assert result.category == QueryCategory.DETAILS
        assert "JOIN" in result.sql_query.upper()


class TestQueryCategories:

    def test_totals_category_has_count_queries(self):
        totals = query_manager.get_queries_by_category(QueryCategory.TOTALS)

        assert len(totals) > 0

        count_or_sum_queries = 0
        for mapping in totals:
            if "COUNT" in mapping.sql_query.upper() or "SUM" in mapping.sql_query.upper():
                count_or_sum_queries += 1

        assert count_or_sum_queries > 0, "Categoria TOTALS deveria ter queries com COUNT ou SUM"

    def test_lists_category_has_listing_queries(self):
        lists = query_manager.get_queries_by_category(QueryCategory.LISTS)

        assert len(lists) > 0

        for mapping in lists:
            keywords_text = ' '.join(mapping.keywords).lower()
            has_listing_keyword = any(
                listing_word in keywords_text
                for listing_word in ["listar", "mostrar", "todos os", "lista de"]
            )
            assert has_listing_keyword, f"Mapping {mapping.query_id} na categoria LISTS deveria ter palavra-chave de listagem"

    def test_statistics_category_has_statistical_functions(self):
        statistics = query_manager.get_queries_by_category(QueryCategory.STATISTICS)

        assert len(statistics) > 0

        statistical_functions = ['AVG', 'SUM', 'MIN', 'MAX', 'STDDEV', 'GROUP BY']
        stats_queries_count = 0

        for mapping in statistics:
            query_upper = mapping.sql_query.upper()
            if any(func in query_upper for func in statistical_functions):
                stats_queries_count += 1

        assert stats_queries_count > 0, "Categoria STATISTICS deveria ter funções estatísticas"

    def test_all_mappings_have_valid_categories(self):
        valid_categories = set(QueryCategory)

        for mapping in query_manager.mappings:
            assert mapping.category in valid_categories, \
                f"Mapping {mapping.query_id} tem categoria inválida: {mapping.category}"


class TestKeywordCoverage:

    def test_funcionarios_keyword_variations(self):
        funcionarios_mappings = [
            m for m in query_manager.mappings
            if 'funcionario' in m.query_id
        ]

        assert len(funcionarios_mappings) > 0

        all_keywords = []
        for mapping in funcionarios_mappings:
            all_keywords.extend(mapping.keywords)

        keywords_text = ' '.join(all_keywords).lower()

        expected_variations = [
            'funcionário', 'funcionários', 'quantos', 'total', 'listar'
        ]

        for variation in expected_variations:
            assert variation in keywords_text, \
                f"Variação '{variation}' não encontrada para funcionários"

    def test_no_empty_keywords(self):
        for mapping in query_manager.mappings:
            for keyword in mapping.keywords:
                assert isinstance(keyword, str), f"Keyword não é string em {mapping.query_id}"
                assert len(keyword.strip()) > 0, f"Keyword vazia em {mapping.query_id}"

    def test_unique_query_ids(self):
        query_ids = [mapping.query_id for mapping in query_manager.mappings]
        unique_ids = set(query_ids)

        assert len(query_ids) == len(unique_ids), "Existem IDs de query duplicados"

    def test_reasonable_keyword_distribution(self):
        total_keywords = len(query_manager.get_all_keywords())
        total_mappings = len(query_manager.mappings)

        assert total_keywords > total_mappings, \
            "Deveria haver mais palavras-chave que mapeamentos"

        avg_keywords_per_mapping = total_keywords / total_mappings
        assert avg_keywords_per_mapping >= 2, \
            "Deveria haver pelo menos 2 palavras-chave por mapeamento em média"
