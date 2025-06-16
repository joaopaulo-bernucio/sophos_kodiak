"""
Mock classes para testes do backend Flask.
Fornece implementações mock para Supabase, Gemini e outras dependências externas.
"""

from unittest.mock import Mock, MagicMock
import json
from typing import Dict, List, Any, Optional


class MockSupabaseClient:
    """Mock do cliente Supabase para testes."""

    def __init__(self):
        self.table_data: Dict[str, List[Dict]] = {}
        self.call_history: List[Dict] = []

    def table(self, table_name: str):
        """Retorna uma instância mock de tabela."""
        return MockTable(
            table_name=table_name,
            data=self.table_data.get(table_name, []),
            client=self
        )

    def set_mock_data(self, table_name: str, data: List[Dict]):
        """Define dados mock para uma tabela específica."""
        self.table_data[table_name] = data

    def get_call_history(self) -> List[Dict]:
        """Retorna histórico de chamadas para verificação."""
        return self.call_history.copy()

    def clear_call_history(self):
        """Limpa o histórico de chamadas."""
        self.call_history.clear()


class MockTable:
    """Mock de tabela do Supabase."""

    def __init__(self, table_name: str, data: List[Dict], client: MockSupabaseClient):
        self.table_name = table_name
        self.data = data
        self.client = client

    def select(self, columns: str = "*"):
        """Mock do método select."""
        self.client.call_history.append({
            'method': 'select',
            'table': self.table_name,
            'columns': columns
        })
        return MockQuery(self.data, self.client)

    def insert(self, data: Dict):
        """Mock do método insert."""
        self.client.call_history.append({
            'method': 'insert',
            'table': self.table_name,
            'data': data
        })
        # Simula inserção adicionando aos dados
        self.data.append(data)
        return MockQuery([data], self.client)

    def update(self, data: Dict):
        """Mock do método update."""
        self.client.call_history.append({
            'method': 'update',
            'table': self.table_name,
            'data': data
        })
        return MockQuery(self.data, self.client)

    def delete(self):
        """Mock do método delete."""
        self.client.call_history.append({
            'method': 'delete',
            'table': self.table_name
        })
        return MockQuery([], self.client)


class MockQuery:
    """Mock de query do Supabase."""

    def __init__(self, data: List[Dict], client: MockSupabaseClient):
        self.data = data
        self.client = client
        self.filters = []

    def eq(self, column: str, value: Any):
        """Mock do filtro eq (equals)."""
        self.filters.append(('eq', column, value))
        filtered_data = [
            row for row in self.data
            if row.get(column) == value
        ]
        return MockQuery(filtered_data, self.client)

    def neq(self, column: str, value: Any):
        """Mock do filtro neq (not equals)."""
        self.filters.append(('neq', column, value))
        filtered_data = [
            row for row in self.data
            if row.get(column) != value
        ]
        return MockQuery(filtered_data, self.client)

    def gt(self, column: str, value: Any):
        """Mock do filtro gt (greater than)."""
        self.filters.append(('gt', column, value))
        filtered_data = [
            row for row in self.data
            if row.get(column, 0) > value
        ]
        return MockQuery(filtered_data, self.client)

    def lt(self, column: str, value: Any):
        """Mock do filtro lt (less than)."""
        self.filters.append(('lt', column, value))
        filtered_data = [
            row for row in self.data
            if row.get(column, 0) < value
        ]
        return MockQuery(filtered_data, self.client)

    def limit(self, count: int):
        """Mock do método limit."""
        limited_data = self.data[:count]
        return MockQuery(limited_data, self.client)

    def order(self, column: str, desc: bool = False):
        """Mock do método order."""
        try:
            sorted_data = sorted(
                self.data,
                key=lambda x: x.get(column, 0),
                reverse=desc
            )
            return MockQuery(sorted_data, self.client)
        except (TypeError, KeyError):
            return MockQuery(self.data, self.client)

    def execute(self):
        """Executa a query e retorna resultado mock."""
        return MockResponse(self.data)


class MockResponse:
    """Mock de resposta do Supabase."""

    def __init__(self, data: List[Dict]):
        self.data = data
        self.count = len(data)
        self.error = None

    def __iter__(self):
        return iter(self.data)

    def __len__(self):
        return len(self.data)


class MockGeminiClient:
    """Mock do cliente Gemini para testes."""

    def __init__(self):
        self.responses = {}
        self.call_history = []
        self.default_response = "Resposta padrão do mock Gemini."

    def set_response(self, key: str, response: str):
        """Define uma resposta específica para uma chave."""
        self.responses[key] = response

    def generate_response(self, prompt: str) -> str:
        """Gera resposta baseada no prompt."""
        self.call_history.append({
            'method': 'generate_response',
            'prompt': prompt
        })

        # Busca resposta baseada em palavras-chave no prompt
        for key, response in self.responses.items():
            if key.lower() in prompt.lower():
                return response

        return self.default_response

    def get_call_history(self) -> List[Dict]:
        """Retorna histórico de chamadas."""
        return self.call_history.copy()

    def clear_call_history(self):
        """Limpa histórico de chamadas."""
        self.call_history.clear()


class MockEnviarParaGemini:
    """Mock específico para a função enviar_para_gemini."""

    def __init__(self):
        self.responses = {
            'funcionários': 'Temos 10 funcionários ativos no sistema.',
            'vendas': 'O total de vendas é R$ 50.000,00.',
            'projetos': 'Há 5 projetos em andamento.',
            'default': 'Resposta padrão do assistente Sophos.'
        }
        self.call_count = 0
        self.last_call = None

    def __call__(self, data):
        """Simula a chamada da função."""
        self.call_count += 1
        self.last_call = data

        # Simular diferentes tipos de resposta baseado nos dados
        if isinstance(data, dict) and 'pergunta' in data:
            pergunta = data['pergunta'].lower()

            if 'funcionário' in pergunta or 'usuario' in pergunta:
                return self.responses['funcionários']
            elif 'venda' in pergunta:
                return self.responses['vendas']
            elif 'projeto' in pergunta:
                return self.responses['projetos']

        return self.responses['default']

    def set_response(self, key, response):
        """Define uma resposta específica."""
        self.responses[key] = response

    def reset(self):
        """Reseta o mock."""
        self.call_count = 0
        self.last_call = None


class MockSelecionarQueries:
    """Mock para a função selecionar_queries."""

    def __init__(self):
        self.queries = {
            'funcionários': [('funcionarios-total', 'SELECT COUNT(*) FROM funcionarios')],
            'vendas': [('vendas-total', 'SELECT SUM(valor) FROM vendas')],
            'projetos': [('projetos-andamento', 'SELECT COUNT(*) FROM projetos WHERE status = "Em Andamento"')],
            'default': [('query-generica', 'SELECT 1')]
        }
        self.call_count = 0

    def __call__(self, text):
        """Simula a seleção de queries."""
        self.call_count += 1

        if not text:
            return []

        text_lower = text.lower()

        if 'funcionário' in text_lower or 'usuario' in text_lower:
            return self.queries['funcionários']
        elif 'venda' in text_lower:
            return self.queries['vendas']
        elif 'projeto' in text_lower:
            return self.queries['projetos']

        return self.queries['default']


class MockProcessarTexto:
    """Mock para funções de processamento de texto."""

    @staticmethod
    def extrair_lemmas(text):
        """Mock da extração de lemmas."""
        if not text:
            return []

        # Simular extração básica de lemmas
        words = text.lower().split()
        lemmas = []

        for word in words:
            # Remover pontuação básica
            clean_word = word.strip('.,!?;:')
            if clean_word:
                lemmas.append(clean_word)

        return lemmas

    @staticmethod
    def processar_texto(text):
        """Mock do processamento de texto."""
        if text is None:
            return ""

        if hasattr(text, 'lower'):
            return text.lower().strip()

        return str(text).lower().strip()
