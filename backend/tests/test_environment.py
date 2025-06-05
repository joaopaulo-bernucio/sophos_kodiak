# -*- coding: utf-8 -*-
"""
Testes básicos para verificar se o ambiente de testes está funcionando.
"""

import pytest
from unittest.mock import Mock


def test_basic_functionality():
    """Teste básico para verificar se pytest está funcionando."""
    assert True


def test_mock_functionality():
    """Teste básico para verificar se mocks estão funcionando."""
    mock = Mock()
    mock.return_value = "test"
    assert mock() == "test"


class TestBasicClass:
    """Classe de teste básica."""

    def test_simple_assertion(self):
        """Teste simples de asserção."""
        assert 1 + 1 == 2

    def test_string_operations(self):
        """Teste de operações com strings."""
        test_string = "Sophos Kodiak"
        assert "Sophos" in test_string
        assert test_string.lower() == "sophos kodiak"

    def test_list_operations(self):
        """Teste de operações com listas."""
        test_list = ["funcionarios", "projetos", "vendas"]
        assert len(test_list) == 3
        assert "funcionarios" in test_list


def test_environment_setup():
    """Teste para verificar se o ambiente está configurado corretamente."""
    import os
    # Testa se consegue importar os módulos básicos
    assert os is not None

    # Testa se pytest está funcionando
    assert pytest is not None
