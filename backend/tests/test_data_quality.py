# -*- coding: utf-8 -*-
"""
Testes de qualidade dos dados do backend Sophos Kodiak.

Este módulo verifica a integridade, consistência e qualidade dos dados
no banco de dados, garantindo que as informações estejam corretas e
utilizáveis pela aplicação.

Componentes testados:
- Existência e estrutura das tabelas
- Integridade referencial entre tabelas
- Consistência dos dados
- Validação de tipos de dados
- Verificação de constraints

Uso:
    # Executar todos os testes de qualidade
    pytest tests/test_data_quality.py -v

    # Executar apenas testes de estrutura
    pytest tests/test_data_quality.py::TestDatabaseStructure -v
"""

import pytest
import psycopg2
from datetime import datetime, date
from decimal import Decimal
from typing import List, Dict, Any, Tuple


class TestDatabaseStructure:
    """
    Testes para verificar estrutura das tabelas do banco.
    """

    def test_all_required_tables_exist(self, env_vars):
        """Verifica se todas as tabelas necessárias existem."""
        required_tables = [
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

            missing_tables = []
            for table in required_tables:
                cur.execute("""
                    SELECT EXISTS (
                        SELECT FROM information_schema.tables
                        WHERE table_schema = 'public'
                        AND table_name = %s
                    );
                """, (table,))

                exists = cur.fetchone()[0]
                if not exists:
                    missing_tables.append(table)

            cur.close()
            conn.close()

            assert len(missing_tables) == 0, f"Tabelas faltando: {missing_tables}"

        except Exception as e:
            pytest.fail(f"Erro ao verificar tabelas: {e}")

    def test_table_columns_structure(self, env_vars):
        """Verifica estrutura de colunas das tabelas principais."""
        expected_columns = {
            'funcionarios': {
                'id': 'integer',
                'nome': 'character varying',
                'cargo': 'character varying',
                'salario': 'numeric',
                'departamento_id': 'integer'
            },
            'departamentos': {
                'id': 'integer',
                'nome': 'character varying',
                'orcamento': 'numeric'
            },
            'projetos': {
                'id': 'integer',
                'nome': 'character varying',
                'status': 'character varying',
                'orcamento': 'numeric',
                'cliente_id': 'integer',
                'data_inicio': 'date'
            },
            'clientes': {
                'id': 'integer',
                'nome_empresa': 'character varying',
                'data_cadastro': 'date'
            },
            'vendas': {
                'id': 'integer',
                'valor': 'numeric',
                'data_venda': 'date',
                'projeto_id': 'integer'
            }
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

            structure_errors = []
            for table, columns in expected_columns.items():
                for column, expected_type in columns.items():
                    cur.execute("""
                        SELECT data_type
                        FROM information_schema.columns
                        WHERE table_name = %s AND column_name = %s;
                    """, (table, column))

                    result = cur.fetchone()
                    if not result:
                        structure_errors.append(f"{table}.{column}: coluna não existe")
                    else:
                        actual_type = result[0]
                        # Aceitar variações comuns de tipos
                        type_aliases = {
                            'character varying': ['varchar', 'text', 'character varying'],
                            'integer': ['integer', 'int4', 'serial'],
                            'numeric': ['numeric', 'decimal', 'money'],
                            'date': ['date', 'timestamp without time zone', 'timestamp with time zone']
                        }

                        valid_types = type_aliases.get(expected_type, [expected_type])
                        if actual_type not in valid_types:
                            structure_errors.append(
                                f"{table}.{column}: tipo {actual_type}, esperado {expected_type}"
                            )

            cur.close()
            conn.close()

            if structure_errors:
                pytest.fail(f"Problemas de estrutura:\n" + "\n".join(structure_errors))

        except Exception as e:
            pytest.fail(f"Erro ao verificar estrutura: {e}")

    def test_primary_keys_exist(self, env_vars):
        """Verifica se chaves primárias estão configuradas."""
        tables_with_pk = [
            'funcionarios', 'departamentos', 'projetos',
            'clientes', 'vendas', 'contratos_marketing'
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

            tables_without_pk = []
            for table in tables_with_pk:
                cur.execute("""
                    SELECT EXISTS (
                        SELECT 1 FROM information_schema.table_constraints
                        WHERE table_name = %s
                        AND constraint_type = 'PRIMARY KEY'
                    );
                """, (table,))

                has_pk = cur.fetchone()[0]
                if not has_pk:
                    tables_without_pk.append(table)

            cur.close()
            conn.close()

            if tables_without_pk:
                print(f"⚠️  Tabelas sem chave primária: {tables_without_pk}")

        except Exception as e:
            pytest.fail(f"Erro ao verificar chaves primárias: {e}")

    def test_foreign_keys_integrity(self, env_vars):
        """Verifica integridade das chaves estrangeiras."""
        expected_foreign_keys = [
            ('funcionarios', 'departamento_id', 'departamentos', 'id'),
            ('projetos', 'cliente_id', 'clientes', 'id'),
            ('vendas', 'projeto_id', 'projetos', 'id')
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

            fk_violations = []
            for child_table, child_col, parent_table, parent_col in expected_foreign_keys:
                # Verificar se há registros órfãos
                cur.execute(f"""
                    SELECT COUNT(*) FROM {child_table} c
                    LEFT JOIN {parent_table} p ON c.{child_col} = p.{parent_col}
                    WHERE c.{child_col} IS NOT NULL AND p.{parent_col} IS NULL;
                """)

                orphan_count = cur.fetchone()[0]
                if orphan_count > 0:
                    fk_violations.append(
                        f"{child_table}.{child_col} -> {parent_table}.{parent_col}: {orphan_count} órfãos"
                    )

            cur.close()
            conn.close()

            if fk_violations:
                pytest.fail(f"Violações de chave estrangeira:\n" + "\n".join(fk_violations))

        except Exception as e:
            pytest.fail(f"Erro ao verificar chaves estrangeiras: {e}")


class TestDataConsistency:
    """
    Testes para verificar consistência dos dados.
    """

    def test_funcionarios_data_consistency(self, env_vars):
        """Verifica consistência dos dados de funcionários."""
        try:
            conn = psycopg2.connect(
                host=env_vars['DB_HOST'],
                port=env_vars['DB_PORT'],
                dbname=env_vars['DB_NAME'],
                user=env_vars['DB_USER'],
                password=env_vars['DB_PASSWORD']
            )

            cur = conn.cursor()

            consistency_checks = []

            # Verificar se há funcionários sem nome
            cur.execute("SELECT COUNT(*) FROM funcionarios WHERE nome IS NULL OR TRIM(nome) = '';")
            nameless_count = cur.fetchone()[0]
            if nameless_count > 0:
                consistency_checks.append(f"{nameless_count} funcionários sem nome")

            # Verificar salários negativos ou zero
            cur.execute("SELECT COUNT(*) FROM funcionarios WHERE salario <= 0;")
            invalid_salary_count = cur.fetchone()[0]
            if invalid_salary_count > 0:
                consistency_checks.append(f"{invalid_salary_count} funcionários com salário inválido")

            # Verificar salários muito altos (acima de R$ 100.000)
            cur.execute("SELECT COUNT(*) FROM funcionarios WHERE salario > 100000;")
            high_salary_count = cur.fetchone()[0]
            if high_salary_count > 0:
                print(f"⚠️  {high_salary_count} funcionários com salário acima de R$ 100.000")

            cur.close()
            conn.close()

            if consistency_checks:
                pytest.fail(f"Problemas de consistência em funcionários:\n" + "\n".join(consistency_checks))

        except Exception as e:
            pytest.fail(f"Erro ao verificar consistência de funcionários: {e}")

    def test_projetos_data_consistency(self, env_vars):
        """Verifica consistência dos dados de projetos."""
        try:
            conn = psycopg2.connect(
                host=env_vars['DB_HOST'],
                port=env_vars['DB_PORT'],
                dbname=env_vars['DB_NAME'],
                user=env_vars['DB_USER'],
                password=env_vars['DB_PASSWORD']
            )

            cur = conn.cursor()

            consistency_checks = []

            # Verificar projetos sem nome
            cur.execute("SELECT COUNT(*) FROM projetos WHERE nome IS NULL OR TRIM(nome) = '';")
            nameless_count = cur.fetchone()[0]
            if nameless_count > 0:
                consistency_checks.append(f"{nameless_count} projetos sem nome")

            # Verificar status válidos
            cur.execute("""
                SELECT COUNT(*) FROM projetos
                WHERE status NOT IN ('Em andamento', 'Concluído', 'Cancelado', 'Em aprovação')
                AND status IS NOT NULL;
            """)
            invalid_status_count = cur.fetchone()[0]
            if invalid_status_count > 0:
                consistency_checks.append(f"{invalid_status_count} projetos com status inválido")

            # Verificar orçamentos negativos
            cur.execute("SELECT COUNT(*) FROM projetos WHERE orcamento < 0;")
            negative_budget_count = cur.fetchone()[0]
            if negative_budget_count > 0:
                consistency_checks.append(f"{negative_budget_count} projetos com orçamento negativo")

            # Verificar datas de início futuras (muito distantes)
            cur.execute("SELECT COUNT(*) FROM projetos WHERE data_inicio > CURRENT_DATE + INTERVAL '1 year';")
            future_date_count = cur.fetchone()[0]
            if future_date_count > 0:
                print(f"⚠️  {future_date_count} projetos com data de início muito futura")

            cur.close()
            conn.close()

            if consistency_checks:
                pytest.fail(f"Problemas de consistência em projetos:\n" + "\n".join(consistency_checks))

        except Exception as e:
            pytest.fail(f"Erro ao verificar consistência de projetos: {e}")

    def test_vendas_data_consistency(self, env_vars):
        """Verifica consistência dos dados de vendas."""
        try:
            conn = psycopg2.connect(
                host=env_vars['DB_HOST'],
                port=env_vars['DB_PORT'],
                dbname=env_vars['DB_NAME'],
                user=env_vars['DB_USER'],
                password=env_vars['DB_PASSWORD']
            )

            cur = conn.cursor()

            consistency_checks = []

            # Verificar valores negativos ou zero
            cur.execute("SELECT COUNT(*) FROM vendas WHERE valor <= 0;")
            invalid_value_count = cur.fetchone()[0]
            if invalid_value_count > 0:
                consistency_checks.append(f"{invalid_value_count} vendas com valor inválido")

            # Verificar datas de venda futuras
            cur.execute("SELECT COUNT(*) FROM vendas WHERE data_venda > CURRENT_DATE;")
            future_sales_count = cur.fetchone()[0]
            if future_sales_count > 0:
                consistency_checks.append(f"{future_sales_count} vendas com data futura")

            # Verificar datas muito antigas (antes de 2020)
            cur.execute("SELECT COUNT(*) FROM vendas WHERE data_venda < '2020-01-01';")
            old_sales_count = cur.fetchone()[0]
            if old_sales_count > 0:
                print(f"⚠️  {old_sales_count} vendas com data muito antiga (antes de 2020)")

            cur.close()
            conn.close()

            if consistency_checks:
                pytest.fail(f"Problemas de consistência em vendas:\n" + "\n".join(consistency_checks))

        except Exception as e:
            pytest.fail(f"Erro ao verificar consistência de vendas: {e}")

    def test_departamentos_data_consistency(self, env_vars):
        """Verifica consistência dos dados de departamentos."""
        try:
            conn = psycopg2.connect(
                host=env_vars['DB_HOST'],
                port=env_vars['DB_PORT'],
                dbname=env_vars['DB_NAME'],
                user=env_vars['DB_USER'],
                password=env_vars['DB_PASSWORD']
            )

            cur = conn.cursor()

            consistency_checks = []

            # Verificar departamentos sem nome
            cur.execute("SELECT COUNT(*) FROM departamentos WHERE nome IS NULL OR TRIM(nome) = '';")
            nameless_count = cur.fetchone()[0]
            if nameless_count > 0:
                consistency_checks.append(f"{nameless_count} departamentos sem nome")

            # Verificar nomes duplicados
            cur.execute("""
                SELECT nome, COUNT(*) as count
                FROM departamentos
                WHERE nome IS NOT NULL
                GROUP BY nome
                HAVING COUNT(*) > 1;
            """)
            duplicates = cur.fetchall()
            if duplicates:
                duplicate_names = [f"{name} ({count}x)" for name, count in duplicates]
                consistency_checks.append(f"Departamentos duplicados: {', '.join(duplicate_names)}")

            cur.close()
            conn.close()

            if consistency_checks:
                pytest.fail(f"Problemas de consistência em departamentos:\n" + "\n".join(consistency_checks))

        except Exception as e:
            pytest.fail(f"Erro ao verificar consistência de departamentos: {e}")


class TestDataTypes:
    """
    Testes para validar tipos de dados.
    """

    def test_numeric_fields_are_valid(self, env_vars):
        """Verifica se campos numéricos contêm valores válidos."""
        try:
            conn = psycopg2.connect(
                host=env_vars['DB_HOST'],
                port=env_vars['DB_PORT'],
                dbname=env_vars['DB_NAME'],
                user=env_vars['DB_USER'],
                password=env_vars['DB_PASSWORD']
            )

            cur = conn.cursor()

            numeric_checks = [
                ("funcionarios", "salario", "salários"),
                ("departamentos", "orcamento", "orçamentos de departamento"),
                ("projetos", "orcamento", "orçamentos de projeto"),
                ("vendas", "valor", "valores de venda")
            ]

            invalid_numerics = []
            for table, column, description in numeric_checks:
                # Verificar NaN, infinito ou valores muito grandes
                cur.execute(f"""
                    SELECT COUNT(*) FROM {table}
                    WHERE {column} IS NOT NULL
                    AND ({column} != {column} OR ABS({column}) > 1e15);
                """)

                invalid_count = cur.fetchone()[0]
                if invalid_count > 0:
                    invalid_numerics.append(f"{description}: {invalid_count} valores inválidos")

            cur.close()
            conn.close()

            if invalid_numerics:
                pytest.fail(f"Valores numéricos inválidos:\n" + "\n".join(invalid_numerics))

        except Exception as e:
            pytest.fail(f"Erro ao verificar tipos numéricos: {e}")

    def test_date_fields_are_valid(self, env_vars):
        """Verifica se campos de data contêm valores válidos."""
        try:
            conn = psycopg2.connect(
                host=env_vars['DB_HOST'],
                port=env_vars['DB_PORT'],
                dbname=env_vars['DB_NAME'],
                user=env_vars['DB_USER'],
                password=env_vars['DB_PASSWORD']
            )

            cur = conn.cursor()

            date_checks = [
                ("clientes", "data_cadastro", "datas de cadastro"),
                ("projetos", "data_inicio", "datas de início de projeto"),
                ("vendas", "data_venda", "datas de venda")
            ]

            invalid_dates = []
            for table, column, description in date_checks:
                # Verificar datas muito antigas (antes de 1900) ou muito futuras
                cur.execute(f"""
                    SELECT COUNT(*) FROM {table}
                    WHERE {column} IS NOT NULL
                    AND ({column} < '1900-01-01' OR {column} > '2100-01-01');
                """)

                invalid_count = cur.fetchone()[0]
                if invalid_count > 0:
                    invalid_dates.append(f"{description}: {invalid_count} datas inválidas")

            cur.close()
            conn.close()

            if invalid_dates:
                pytest.fail(f"Datas inválidas:\n" + "\n".join(invalid_dates))

        except Exception as e:
            pytest.fail(f"Erro ao verificar tipos de data: {e}")

    def test_string_fields_encoding(self, env_vars):
        """Verifica se campos de texto têm encoding correto."""
        try:
            conn = psycopg2.connect(
                host=env_vars['DB_HOST'],
                port=env_vars['DB_PORT'],
                dbname=env_vars['DB_NAME'],
                user=env_vars['DB_USER'],
                password=env_vars['DB_PASSWORD']
            )

            cur = conn.cursor()

            # Verificar se há caracteres de controle ou encoding inválido em campos de texto
            text_fields = [
                ("funcionarios", "nome"),
                ("funcionarios", "cargo"),
                ("departamentos", "nome"),
                ("projetos", "nome"),
                ("clientes", "nome_empresa")
            ]

            encoding_issues = []
            for table, column in text_fields:
                # Verificar caracteres de controle ASCII (0-31, exceto 9,10,13)
                cur.execute(f"""
                    SELECT COUNT(*) FROM {table}
                    WHERE {column} IS NOT NULL
                    AND {column} ~ '[\\x00-\\x08\\x0B\\x0C\\x0E-\\x1F]';
                """)

                invalid_count = cur.fetchone()[0]
                if invalid_count > 0:
                    encoding_issues.append(f"{table}.{column}: {invalid_count} com caracteres de controle")

            cur.close()
            conn.close()

            if encoding_issues:
                pytest.fail(f"Problemas de encoding:\n" + "\n".join(encoding_issues))

        except Exception as e:
            pytest.fail(f"Erro ao verificar encoding: {e}")


class TestBusinessRules:
    """
    Testes para regras de negócio específicas.
    """

    def test_salary_ranges_are_reasonable(self, env_vars):
        """Verifica se faixas salariais são razoáveis."""
        try:
            conn = psycopg2.connect(
                host=env_vars['DB_HOST'],
                port=env_vars['DB_PORT'],
                dbname=env_vars['DB_NAME'],
                user=env_vars['DB_USER'],
                password=env_vars['DB_PASSWORD']
            )

            cur = conn.cursor()

            # Verificar salários muito baixos (abaixo do salário mínimo aproximado)
            cur.execute("SELECT COUNT(*) FROM funcionarios WHERE salario < 1000;")
            low_salary_count = cur.fetchone()[0]

            # Verificar salários muito altos
            cur.execute("SELECT COUNT(*) FROM funcionarios WHERE salario > 50000;")
            high_salary_count = cur.fetchone()[0]

            # Calcular estatísticas salariais se há dados
            cur.execute("""
                SELECT
                    COUNT(*) as total,
                    MIN(salario) as min_salary,
                    MAX(salario) as max_salary,
                    AVG(salario) as avg_salary
                FROM funcionarios
                WHERE salario IS NOT NULL;
            """)

            stats = cur.fetchone()
            if stats and stats[0] > 0:
                total, min_sal, max_sal, avg_sal = stats

                print(f"\nEstatísticas salariais:")
                print(f"  Total de funcionários: {total}")
                print(f"  Salário mínimo: R$ {min_sal:,.2f}")
                print(f"  Salário máximo: R$ {max_sal:,.2f}")
                print(f"  Salário médio: R$ {avg_sal:,.2f}")

                if low_salary_count > 0:
                    print(f"  ⚠️  {low_salary_count} funcionários com salário abaixo de R$ 1.000")

                if high_salary_count > 0:
                    print(f"  ⚠️  {high_salary_count} funcionários com salário acima de R$ 50.000")

            cur.close()
            conn.close()

        except Exception as e:
            pytest.fail(f"Erro ao verificar faixas salariais: {e}")

    def test_project_budget_consistency(self, env_vars):
        """Verifica consistência entre orçamentos de projetos e vendas."""
        try:
            conn = psycopg2.connect(
                host=env_vars['DB_HOST'],
                port=env_vars['DB_PORT'],
                dbname=env_vars['DB_NAME'],
                user=env_vars['DB_USER'],
                password=env_vars['DB_PASSWORD']
            )

            cur = conn.cursor()

            # Verificar se vendas excedem significativamente o orçamento do projeto
            cur.execute("""
                SELECT
                    p.nome as projeto,
                    p.orcamento,
                    COALESCE(SUM(v.valor), 0) as total_vendas,
                    CASE
                        WHEN p.orcamento > 0 THEN
                            ROUND((COALESCE(SUM(v.valor), 0) / p.orcamento * 100)::numeric, 2)
                        ELSE NULL
                    END as percentual
                FROM projetos p
                LEFT JOIN vendas v ON v.projeto_id = p.id
                WHERE p.orcamento > 0
                GROUP BY p.id, p.nome, p.orcamento
                HAVING COALESCE(SUM(v.valor), 0) > p.orcamento * 1.5;
            """)

            over_budget = cur.fetchall()
            if over_budget:
                print(f"\n⚠️  Projetos com vendas significativamente acima do orçamento:")
                for projeto, orcamento, vendas, percentual in over_budget:
                    print(f"  {projeto}: Orçamento R$ {orcamento:,.2f}, Vendas R$ {vendas:,.2f} ({percentual}%)")

            cur.close()
            conn.close()

        except Exception as e:
            pytest.fail(f"Erro ao verificar consistência de orçamentos: {e}")

    def test_department_employee_distribution(self, env_vars):
        """Verifica distribuição de funcionários por departamento."""
        try:
            conn = psycopg2.connect(
                host=env_vars['DB_HOST'],
                port=env_vars['DB_PORT'],
                dbname=env_vars['DB_NAME'],
                user=env_vars['DB_USER'],
                password=env_vars['DB_PASSWORD']
            )

            cur = conn.cursor()

            # Verificar distribuição por departamento
            cur.execute("""
                SELECT
                    d.nome as departamento,
                    COUNT(f.id) as funcionarios,
                    AVG(f.salario) as salario_medio
                FROM departamentos d
                LEFT JOIN funcionarios f ON f.departamento_id = d.id
                GROUP BY d.id, d.nome
                ORDER BY funcionarios DESC;
            """)

            distribution = cur.fetchall()
            if distribution:
                print(f"\nDistribuição de funcionários por departamento:")
                for dept, count, avg_salary in distribution:
                    avg_sal_str = f"R$ {avg_salary:,.2f}" if avg_salary else "N/A"
                    print(f"  {dept}: {count} funcionários, salário médio {avg_sal_str}")

                # Verificar se há departamentos sem funcionários
                empty_depts = [dept for dept, count, _ in distribution if count == 0]
                if empty_depts:
                    print(f"  ⚠️  Departamentos sem funcionários: {', '.join(empty_depts)}")

            cur.close()
            conn.close()

        except Exception as e:
            pytest.fail(f"Erro ao verificar distribuição de funcionários: {e}")


class TestDataVolume:
    """
    Testes para verificar volume de dados.
    """

    def test_minimum_data_exists(self, env_vars):
        """Verifica se há dados mínimos para funcionamento da aplicação."""
        try:
            conn = psycopg2.connect(
                host=env_vars['DB_HOST'],
                port=env_vars['DB_PORT'],
                dbname=env_vars['DB_NAME'],
                user=env_vars['DB_USER'],
                password=env_vars['DB_PASSWORD']
            )

            cur = conn.cursor()

            # Contar registros em cada tabela principal
            tables_to_check = [
                'departamentos',
                'funcionarios',
                'clientes',
                'projetos',
                'vendas'
            ]

            empty_tables = []
            table_counts = {}

            for table in tables_to_check:
                cur.execute(f"SELECT COUNT(*) FROM {table};")
                count = cur.fetchone()[0]
                table_counts[table] = count

                if count == 0:
                    empty_tables.append(table)

            cur.close()
            conn.close()

            # Log contagens
            print(f"\nContagem de registros:")
            for table, count in table_counts.items():
                print(f"  {table}: {count} registros")

            # Avisar sobre tabelas vazias (não falha teste necessariamente)
            if empty_tables:
                print(f"⚠️  Tabelas vazias: {', '.join(empty_tables)}")
                print("   Isso pode ser normal em ambiente de teste/desenvolvimento")

        except Exception as e:
            pytest.fail(f"Erro ao verificar volume de dados: {e}")

    def test_data_growth_patterns(self, env_vars):
        """Verifica padrões de crescimento dos dados."""
        try:
            conn = psycopg2.connect(
                host=env_vars['DB_HOST'],
                port=env_vars['DB_PORT'],
                dbname=env_vars['DB_NAME'],
                user=env_vars['DB_USER'],
                password=env_vars['DB_PASSWORD']
            )

            cur = conn.cursor()

            # Verificar distribuição temporal de vendas (se houver dados)
            cur.execute("""
                SELECT
                    DATE_TRUNC('month', data_venda) as mes,
                    COUNT(*) as vendas_count,
                    SUM(valor) as vendas_total
                FROM vendas
                WHERE data_venda >= CURRENT_DATE - INTERVAL '12 months'
                GROUP BY DATE_TRUNC('month', data_venda)
                ORDER BY mes;
            """)

            monthly_sales = cur.fetchall()
            if monthly_sales:
                print(f"\nVendas por mês (últimos 12 meses):")
                for mes, count, total in monthly_sales:
                    print(f"  {mes.strftime('%Y-%m')}: {count} vendas, R$ {total:,.2f}")

            # Verificar distribuição de cadastro de clientes
            cur.execute("""
                SELECT
                    DATE_TRUNC('year', data_cadastro) as ano,
                    COUNT(*) as novos_clientes
                FROM clientes
                WHERE data_cadastro >= CURRENT_DATE - INTERVAL '5 years'
                GROUP BY DATE_TRUNC('year', data_cadastro)
                ORDER BY ano;
            """)

            yearly_clients = cur.fetchall()
            if yearly_clients:
                print(f"\nNovos clientes por ano:")
                for ano, count in yearly_clients:
                    print(f"  {ano.strftime('%Y')}: {count} novos clientes")

            cur.close()
            conn.close()

        except Exception as e:
            pytest.fail(f"Erro ao verificar padrões de crescimento: {e}")
