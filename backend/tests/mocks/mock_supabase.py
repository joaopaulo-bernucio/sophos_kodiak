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
    """Mock do cliente Google Gemini."""

    def __init__(self):
        self.responses = {}
        self.call_history = []
        self.default_response = {
            'candidates': [{
                'content': {
                    'parts': [{
                        'text': 'SELECT COUNT(*) FROM usuarios'
                    }]
                }
            }]
        }

    def set_response(self, prompt_key: str, response: str):
        """Define uma resposta específica para uma chave de prompt."""
        self.responses[prompt_key] = {
            'candidates': [{
                'content': {
                    'parts': [{
                        'text': response
                    }]
                }
            }]
        }

    def generate_content(self, prompt: str) -> Dict:
        """Mock do método generate_content."""
        self.call_history.append({
            'method': 'generate_content',
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


class MockDatabaseConnection:
    """Mock de conexão com banco de dados."""

    def __init__(self):
        self.queries_executed = []
        self.query_results = {}
        self.is_connected = True

    def execute(self, query: str, params: Optional[tuple] = None):
        """Executa uma query mock."""
        self.queries_executed.append({
            'query': query,
            'params': params
        })

        # Retorna resultado baseado na query
        query_lower = query.lower().strip()

        if 'select count' in query_lower:
            return MockCursor([{'count': 100}])
        elif 'select' in query_lower and 'vendas' in query_lower:
            return MockCursor([
                {'mes': '2024-01', 'total': 15000},
                {'mes': '2024-02', 'total': 18000},
                {'mes': '2024-03', 'total': 22000}
            ])
        elif 'select' in query_lower:
            return MockCursor([
                {'id': 1, 'nome': 'Produto A', 'preco': 100.0},
                {'id': 2, 'nome': 'Produto B', 'preco': 200.0}
            ])

        return MockCursor([])

    def commit(self):
        """Mock do método commit."""
        pass

    def rollback(self):
        """Mock do método rollback."""
        pass

    def close(self):
        """Mock do método close."""
        self.is_connected = False


class MockCursor:
    """Mock de cursor de banco de dados."""

    def __init__(self, data: List[Dict]):
        self.data = data
        self.index = 0

    def fetchone(self) -> Optional[Dict]:
        """Retorna próximo registro."""
        if self.index < len(self.data):
            result = self.data[self.index]
            self.index += 1
            return result
        return None

    def fetchall(self) -> List[Dict]:
        """Retorna todos os registros."""
        return self.data

    def fetchmany(self, size: int) -> List[Dict]:
        """Retorna vários registros."""
        result = self.data[self.index:self.index + size]
        self.index += size
        return result
