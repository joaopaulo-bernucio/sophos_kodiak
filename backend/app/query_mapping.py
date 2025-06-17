"""
Mapeamento aprimorado de consultas em linguagem natural para SQL.
Este módulo resolve problemas de ambiguidade, duplicação e organização
encontrados na versão anterior.
"""

from typing import Dict, List, Tuple, Optional
from dataclasses import dataclass
from enum import Enum


class QueryCategory(Enum):
    """Categorias de consultas para melhor organização."""
    TOTALS = "totais"
    LISTS = "listagens"
    DETAILS = "detalhes"
    RECENT = "recentes"
    STATISTICS = "estatisticas"
    ANALYTICS = "analises"


@dataclass
class QueryMapping:
    """Classe para representar um mapeamento de consulta."""
    keywords: List[str]
    query_id: str
    sql_query: str
    category: QueryCategory
    description: str


class QueryMappingManager:
    """Gerenciador de mapeamentos de consultas com busca otimizada."""

    def __init__(self):
        self.mappings: List[QueryMapping] = []
        self._keyword_index: Dict[str, QueryMapping] = {}
        self._initialize_mappings()

    def _initialize_mappings(self):
        """Inicializa todos os mapeamentos de consultas."""

        # ===== TOTAIS E QUANTITATIVOS =====
        self._add_mapping(QueryMapping(
            keywords=[
                "quantos funcionários", "quantas funcionárias", "quantos funcionário", "quantas funcionária",
                "número de funcionários", "número funcionários", "número de func", "n° de funcionários",
                "total funcionários", "total de funcionários", "count funcionários", "contar funcionários"
            ],
            query_id="funcionarios-total",
            sql_query="SELECT COUNT(*) AS total_funcionarios FROM funcionarios;",
            category=QueryCategory.TOTALS,
            description="Conta o total de funcionários"
        ))

        self._add_mapping(QueryMapping(
            keywords=[
                "total de projetos", "quantos projetos", "quantos projeto", "número de projetos",
                "número projetos", "n° de projetos", "count projetos", "count de projetos", "total projetos"
            ],
            query_id="projetos-total",
            sql_query="SELECT COUNT(*) AS total_projetos FROM projetos;",
            category=QueryCategory.TOTALS,
            description="Conta o total de projetos"
        ))

        self._add_mapping(QueryMapping(
            keywords=[
                "total de contratos", "quantos contratos", "quantos contrato", "número de contratos",
                "número contratos", "n° de contratos", "count contratos", "contratos total", "total contratos"
            ],
            query_id="contratos-total",
            sql_query="SELECT COUNT(*) AS total_contratos FROM contratos_marketing;",
            category=QueryCategory.TOTALS,
            description="Conta o total de contratos"
        ))

        self._add_mapping(QueryMapping(
            keywords=[
                "total de vendas", "quantas vendas", "quantas venda", "quantidade de vendas",
                "quantidade vendas", "número de vendas", "número vendas", "n° de vendas",
                "count vendas", "vendas total"
            ],
            query_id="vendas-total",
            sql_query="SELECT COUNT(*) AS total_vendas FROM vendas;",
            category=QueryCategory.TOTALS,
            description="Conta o total de vendas"
        ))

        self._add_mapping(QueryMapping(
            keywords=[
                "total de departamentos", "quantos departamentos", "quantos departamento",
                "número de departamentos", "número departamentos", "n° de departamentos",
                "count departamentos", "departamentos total"
            ],
            query_id="departamentos-total",
            sql_query="SELECT COUNT(*) AS total_departamentos FROM departamentos;",
            category=QueryCategory.TOTALS,
            description="Conta o total de departamentos"
        ))

        self._add_mapping(QueryMapping(
            keywords=[
                "total de clientes", "quantos clientes", "quantos cliente", "número de clientes",
                "número clientes", "n° de clientes", "count clientes", "clientes total"
            ],
            query_id="clientes-total",
            sql_query="SELECT COUNT(*) AS total_clientes FROM clientes;",
            category=QueryCategory.TOTALS,
            description="Conta o total de clientes"
        ))

        # ===== VALORES E RECEITAS =====
        self._add_mapping(QueryMapping(
            keywords=[
                "receita de contratos", "receita contratos", "valor contratado", "valor de contratos",
                "faturamento de contratos", "receita contratada", "soma contratos", "total valor contratos",
                "receita total contratos"
            ],
            query_id="contratos-valor-total",
            sql_query="SELECT COALESCE(SUM(valor_total), 0) AS total_contratado FROM contratos_marketing;",
            category=QueryCategory.TOTALS,
            description="Soma o valor total de todos os contratos"
        ))

        self._add_mapping(QueryMapping(
            keywords=[
                "valor total de vendas", "receita total vendas", "soma valor vendas", "soma vendas",
                "receita vendas", "total valor vendas", "vendas receita total"
            ],
            query_id="vendas-valor-total",
            sql_query="SELECT COALESCE(SUM(valor), 0) AS total_valor_vendas FROM vendas;",
            category=QueryCategory.TOTALS,
            description="Soma o valor total de todas as vendas"
        ))

        # ===== LISTAGENS COMPLETAS =====
        self._add_mapping(QueryMapping(
            keywords=[
                "listar funcionários", "mostrar funcionários", "todos os funcionários", "nomes dos funcionários",
                "lista de funcionários", "ver funcionários", "exibir funcionários", "listar todos os funcionários",
                "exibir todos funcionários"
            ],
            query_id="funcionarios-lista",
            sql_query="SELECT id, nome, cargo, salario FROM funcionarios ORDER BY nome;",
            category=QueryCategory.LISTS,
            description="Lista todos os funcionários com informações básicas"
        ))

        self._add_mapping(QueryMapping(
            keywords=[
                "listar clientes", "mostrar clientes", "todos os clientes", "nomes dos clientes",
                "lista de clientes", "ver clientes", "exibir clientes", "listar todas as empresas",
                "nome das empresas que são clientes", "liste o nome das empresas", "empresas clientes",
                "clientes empresas", "lista de empresas clientes"
            ],
            query_id="clientes-lista",
            sql_query="SELECT id, nome_empresa, data_cadastro FROM clientes ORDER BY nome_empresa;",
            category=QueryCategory.LISTS,
            description="Lista todos os clientes com informações básicas"
        ))

        self._add_mapping(QueryMapping(
            keywords=[
                "listar projetos", "mostrar projetos", "todos os projetos", "lista de projetos",
                "ver projetos", "exibir projetos", "lista completa de projetos", "projetos todos"
            ],
            query_id="projetos-lista",
            sql_query="SELECT id, nome, status, data_inicio, data_termino FROM projetos ORDER BY data_inicio DESC;",
            category=QueryCategory.LISTS,
            description="Lista todos os projetos com informações básicas"
        ))

        self._add_mapping(QueryMapping(
            keywords=[
                "listar vendas", "mostrar vendas", "todas as vendas", "lista de vendas",
                "ver vendas", "exibir vendas", "vendas lista", "vendas todos"
            ],
            query_id="vendas-lista",
            sql_query="SELECT id, data_venda, valor, status_pagamento FROM vendas ORDER BY data_venda DESC;",
            category=QueryCategory.LISTS,
            description="Lista todas as vendas com informações básicas"
        ))

        self._add_mapping(QueryMapping(
            keywords=[
                "listar departamentos", "mostrar departamentos", "todos os departamentos",
                "lista de departamentos", "ver departamentos", "exibir departamentos",
                "departamentos lista", "departamentos todos"
            ],
            query_id="departamentos-lista",
            sql_query="SELECT id, nome, orcamento FROM departamentos ORDER BY nome;",
            category=QueryCategory.LISTS,
            description="Lista todos os departamentos"
        ))

        self._add_mapping(QueryMapping(
            keywords=[
                "listar contratos", "mostrar contratos", "todos os contratos", "contratos de marketing",
                "lista de contratos", "ver contratos", "exibir contratos", "contratos lista", "contratos todos"
            ],
            query_id="contratos-lista",
            sql_query="""
                SELECT cm.id, cm.descricao, cm.data_inicio, cm.data_termino, cm.valor_total, cm.status,
                       c.nome_empresa AS cliente
                FROM contratos_marketing cm
                JOIN clientes c ON cm.cliente_id = c.id
                ORDER BY cm.data_inicio DESC;
            """,
            category=QueryCategory.LISTS,
            description="Lista todos os contratos com informações do cliente"
        ))

        # ===== REGISTROS MAIS RECENTES =====
        self._add_mapping(QueryMapping(
            keywords=[
                "último projeto", "projeto mais recente", "última iniciativa", "projeto finalizado mais novo",
                "projeto recente", "projeto mais novo"
            ],
            query_id="projeto-mais-recente",
            sql_query="SELECT nome, data_termino FROM projetos ORDER BY data_termino DESC LIMIT 1;",
            category=QueryCategory.RECENT,
            description="Retorna o projeto mais recente"
        ))

        self._add_mapping(QueryMapping(
            keywords=[
                "últimos projetos", "projetos recentes"
            ],
            query_id="projetos-recentes",
            sql_query="SELECT nome, data_termino FROM projetos ORDER BY data_termino DESC LIMIT 5;",
            category=QueryCategory.RECENT,
            description="Retorna os 5 projetos mais recentes"
        ))

        self._add_mapping(QueryMapping(
            keywords=[
                "último contrato", "contrato mais recente", "contrato finalizado mais novo", "contrato recente"
            ],
            query_id="contrato-mais-recente",
            sql_query="SELECT descricao, data_termino FROM contratos_marketing ORDER BY data_termino DESC LIMIT 1;",
            category=QueryCategory.RECENT,
            description="Retorna o contrato mais recente"
        ))

        self._add_mapping(QueryMapping(
            keywords=[
                "últimos contratos", "contratos recentes"
            ],
            query_id="contratos-recentes",
            sql_query="SELECT descricao, data_termino FROM contratos_marketing ORDER BY data_termino DESC LIMIT 5;",
            category=QueryCategory.RECENT,
            description="Retorna os 5 contratos mais recentes"
        ))

        self._add_mapping(QueryMapping(
            keywords=[
                "último cliente", "cliente mais recente", "cliente cadastrado mais recente"
            ],
            query_id="cliente-mais-recente",
            sql_query="SELECT nome_empresa, data_cadastro FROM clientes ORDER BY data_cadastro DESC LIMIT 1;",
            category=QueryCategory.RECENT,
            description="Retorna o cliente mais recente"
        ))

        self._add_mapping(QueryMapping(
            keywords=[
                "últimos clientes", "clientes recentes"
            ],
            query_id="clientes-recentes",
            sql_query="SELECT nome_empresa, data_cadastro FROM clientes ORDER BY data_cadastro DESC LIMIT 5;",
            category=QueryCategory.RECENT,
            description="Retorna os 5 clientes mais recentes"
        ))

        # ===== DETALHES COM JOINS =====
        self._add_mapping(QueryMapping(
            keywords=[
                "detalhes de vendas", "vendas com detalhes", "vendas detalhadas", "informações de vendas",
                "info vendas", "vendas completas", "vendas detalhe"
            ],
            query_id="vendas-detalhes",
            sql_query="""
                SELECT v.id, v.data_venda, v.valor, v.status_pagamento,
                       p.nome AS projeto, f.nome AS funcionario
                FROM vendas v
                JOIN projetos p ON v.projeto_id = p.id
                JOIN funcionarios f ON v.funcionario_id = f.id
                ORDER BY v.data_venda DESC;
            """,
            category=QueryCategory.DETAILS,
            description="Mostra vendas com detalhes de projeto e funcionário"
        ))

        self._add_mapping(QueryMapping(
            keywords=[
                "detalhes de contratos", "contratos com detalhes", "contratos detalhados",
                "informações contratos", "info contratos", "contratos completos", "contratos detalhe"
            ],
            query_id="contratos-detalhes",
            sql_query="""
                SELECT cm.id, cm.descricao, cm.data_inicio, cm.data_termino, cm.valor_total, cm.status,
                       c.nome_empresa AS cliente
                FROM contratos_marketing cm
                JOIN clientes c ON cm.cliente_id = c.id
                ORDER BY cm.data_inicio DESC;
            """,
            category=QueryCategory.DETAILS,
            description="Mostra contratos com detalhes do cliente"
        ))

        self._add_mapping(QueryMapping(
            keywords=[
                "informações do projeto", "detalhes do projeto", "projeto detalhado", "info do projeto",
                "projeto completo", "projeto detalhes", "info projeto"
            ],
            query_id="projetos-detalhes",
            sql_query="""
                SELECT p.id, p.nome AS projeto, p.data_inicio, p.data_termino, p.status, p.orcamento,
                       c.nome_empresa AS cliente, f.nome AS responsavel
                FROM projetos p
                JOIN clientes c ON p.cliente_id = c.id
                JOIN funcionarios f ON p.responsavel_id = f.id
                ORDER BY p.data_inicio DESC;
            """,
            category=QueryCategory.DETAILS,
            description="Mostra projetos com detalhes de cliente e responsável"
        ))

        self._add_mapping(QueryMapping(
            keywords=[
                "funcionários e departamentos", "lista de funcionários com departamento",
                "funcionários departamentos", "funcionários com departamento", "lista funcionários departamento",
                "funcionários em departamento"
            ],
            query_id="funcionarios-departamentos",
            sql_query="""
                SELECT f.id, f.nome, f.cargo, d.nome AS departamento, f.salario
                FROM funcionarios f
                JOIN departamentos d ON f.departamento_id = d.id
                ORDER BY d.nome, f.nome;
            """,
            category=QueryCategory.DETAILS,
            description="Lista funcionários com seus departamentos"
        ))

        # ===== ESTATÍSTICAS DE VENDAS =====
        self._add_mapping(QueryMapping(
            keywords=[
                "média de vendas", "média de valor", "valor médio de vendas", "média vendas",
                "média valor vendas", "média dos valores de vendas"
            ],
            query_id="estatisticas-vendas",
            sql_query="""
                SELECT
                    COUNT(*) AS total_vendas,
                    COALESCE(AVG(valor), 0) AS media_valor,
                    COALESCE(STDDEV(valor), 0) AS desvio_valor,
                    COALESCE(MIN(valor), 0) AS valor_minimo,
                    COALESCE(MAX(valor), 0) AS valor_maximo
                FROM vendas;
            """,
            category=QueryCategory.STATISTICS,
            description="Estatísticas detalhadas das vendas"
        ))

        self._add_mapping(QueryMapping(
            keywords=[
                "vendas por funcionário", "vendas por funcionarios", "quem vendeu mais", "quem vendeu maior valor",
                "vendas por vendedor", "vendas por vendedores", "vendas vendedor"
            ],
            query_id="vendas-por-funcionario",
            sql_query="""
                SELECT f.nome,
                       COUNT(v.id) AS total_vendas,
                       COALESCE(SUM(v.valor), 0) AS valor_total_vendido
                FROM funcionarios f
                LEFT JOIN vendas v ON f.id = v.funcionario_id
                GROUP BY f.nome
                ORDER BY valor_total_vendido DESC;
            """,
            category=QueryCategory.STATISTICS,
            description="Vendas agrupadas por funcionário"
        ))

        # ===== CONTRATOS POR STATUS - RESOLVENDO CONFLITO =====
        self._add_mapping(QueryMapping(
            keywords=[
                "status de contratos", "contratos por status", "distribuição de contratos por status",
                "contratos pendentes", "contratos concluídos", "status contratos", "contratos encerrados",
                "contratos cancelados"
            ],
            query_id="contratos-por-status",
            sql_query="""
                SELECT status,
                       COUNT(*) AS total,
                       COALESCE(SUM(valor_total), 0) AS valor_total
                FROM contratos_marketing
                GROUP BY status
                ORDER BY total DESC;
            """,
            category=QueryCategory.STATISTICS,
            description="Distribuição de contratos por status"
        ))

        # ===== CONTRATOS ATIVOS - QUERY ESPECÍFICA =====
        self._add_mapping(QueryMapping(
            keywords=[
                "contratos ativos", "quantos contratos ativos", "total contratos ativos",
                "contratos em andamento", "contar contratos ativos", "quantidade contratos ativos"
            ],
            query_id="contratos-ativos-detalhes",
            sql_query="""
                SELECT cm.*, c.nome_empresa AS cliente
                FROM contratos_marketing cm
                JOIN clientes c ON cm.cliente_id = c.id
                WHERE cm.status = 'Ativo'
                ORDER BY cm.data_inicio DESC;
            """,
            category=QueryCategory.STATISTICS,
            description="Lista detalhada dos contratos ativos"
        ))

        # ===== PROJETOS POR STATUS =====
        self._add_mapping(QueryMapping(
            keywords=[
                "projetos por status", "quantos projetos por status", "projetos agrupados por status",
                "status de projetos", "contar projetos por status", "número de projetos por status"
            ],
            query_id="projetos-por-status",
            sql_query="""
                SELECT status,
                       COUNT(*) AS total,
                       COALESCE(SUM(orcamento), 0) AS orcamento_total
                FROM projetos
                GROUP BY status
                ORDER BY total DESC;
            """,
            category=QueryCategory.STATISTICS,
            description="Distribuição de projetos por status"
        ))

        # ===== PROJETOS ESPECÍFICOS POR STATUS =====
        self._add_mapping(QueryMapping(
            keywords=[
                "projetos concluídos", "projetos concluidos", "quantos projetos concluídos",
                "quantos projetos concluidos", "total projetos concluídos", "total projetos concluidos"
            ],
            query_id="projetos-concluidos",
            sql_query="SELECT COUNT(*) AS total_concluidos FROM projetos WHERE status = 'Concluído';",
            category=QueryCategory.STATISTICS,
            description="Conta projetos concluídos"
        ))

        self._add_mapping(QueryMapping(
            keywords=[
                "projetos andamento", "quantos projetos em andamento", "total projetos em andamento",
                "projetos ativos", "projetos que estão em andamento"
            ],
            query_id="projetos-em-andamento",
            sql_query="SELECT COUNT(*) AS total_andamento FROM projetos WHERE status = 'Em andamento';",
            category=QueryCategory.STATISTICS,
            description="Conta projetos em andamento"
        ))

        # ===== OUTRAS ESTATÍSTICAS =====
        self._add_mapping(QueryMapping(
            keywords=[
                "salário médio", "média salarial", "média de salários", "salário medio", "média salário"
            ],
            query_id="salario-medio",
            sql_query="""
                SELECT
                    COUNT(*) AS total_funcionarios,
                    COALESCE(AVG(salario), 0) AS salario_medio,
                    COALESCE(MIN(salario), 0) AS salario_minimo,
                    COALESCE(MAX(salario), 0) AS salario_maximo
                FROM funcionarios;
            """,
            category=QueryCategory.STATISTICS,
            description="Estatísticas salariais dos funcionários"
        ))

        self._add_mapping(QueryMapping(
            keywords=[
                "funcionários por departamento", "funcionarios por departamento",
                "quantos funcionários por departamento", "quantos funcionarios por departamento",
                "funcionários agrupados por departamento", "número de funcionários por departamento"
            ],
            query_id="funcionarios-por-departamento",
            sql_query="""
                SELECT d.nome AS departamento,
                       COUNT(f.id) AS total_funcionarios,
                       COALESCE(AVG(f.salario), 0) AS salario_medio_depto
                FROM departamentos d
                LEFT JOIN funcionarios f ON f.departamento_id = d.id
                GROUP BY d.nome
                ORDER BY total_funcionarios DESC;
            """,
            category=QueryCategory.STATISTICS,
            description="Funcionários agrupados por departamento com estatísticas"
        ))

    def _add_mapping(self, mapping: QueryMapping):
        """Adiciona um mapeamento e constrói o índice de palavras-chave."""
        self.mappings.append(mapping)
        for keyword in mapping.keywords:
            self._keyword_index[keyword.lower()] = mapping

    def find_query(self, user_input: str) -> Optional[QueryMapping]:
        """
        Encontra o mapeamento mais adequado para a entrada do usuário.

        Args:
            user_input: Texto de entrada do usuário

        Returns:
            QueryMapping correspondente ou None se não encontrado
        """
        user_input = user_input.lower().strip()

        # Busca exata primeiro
        if user_input in self._keyword_index:
            return self._keyword_index[user_input]

        # Busca por substring - encontra a melhor correspondência
        best_match = None
        best_score = 0

        for keyword, mapping in self._keyword_index.items():
            if keyword in user_input or user_input in keyword:
                # Calcula score baseado no comprimento da correspondência
                score = len(keyword) if keyword in user_input else len(user_input)
                if score > best_score:
                    best_score = score
                    best_match = mapping

        return best_match

    def get_queries_by_category(self, category: QueryCategory) -> List[QueryMapping]:
        """Retorna todas as consultas de uma categoria específica."""
        return [mapping for mapping in self.mappings if mapping.category == category]

    def get_all_keywords(self) -> List[str]:
        """Retorna todas as palavras-chave disponíveis."""
        return list(self._keyword_index.keys())


# Instância global para uso fácil
query_manager = QueryMappingManager()

# Mantém compatibilidade com o código existente
query_mappings = [(mapping.keywords, mapping.query_id, mapping.sql_query)
                 for mapping in query_manager.mappings]
