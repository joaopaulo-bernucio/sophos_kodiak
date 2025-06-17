# -*- coding: utf-8 -*-
"""
Utilitários para gerenciar uso da API Gemini em diferentes ambientes.

Este módulo fornece funcionalidades para:
- Reduzir uso da API em ambientes de teste
- Implementar cache inteligente
- Fornecer fallbacks quando a API não está disponível
"""
import os
import logging
from typing import Optional


class GeminiManager:
    """Gerenciador inteligente para uso da API Gemini."""

    def __init__(self):
        self.is_test_environment = os.getenv('FLASK_ENV') == 'testing' or os.getenv('CI') == 'true'
        self.api_key = os.getenv('GEMINI_API_KEY', '')
        self.is_mock_key = self.api_key in ['test_api_key', 'fake_gemini_key_for_tests', 'test_gemini_api_key']

    def should_use_mock_response(self) -> bool:
        """Determina se deve usar resposta mock ao invés da API real."""
        return (
            self.is_test_environment or
            self.is_mock_key or
            not self.api_key
        )

    def get_mock_response(self, pergunta: str) -> str:
        """Gera resposta mock baseada na pergunta."""
        pergunta_lower = pergunta.lower()

        # Respostas específicas para diferentes tipos de pergunta
        if any(palavra in pergunta_lower for palavra in ['funcionarios', 'funcionário', 'colaborador']):
            return ("Nossa empresa conta com uma equipe dedicada de profissionais "
                   "distribuídos em diferentes departamentos. Para informações "
                   "específicas sobre nossos funcionários, consulte nosso RH.")

        elif any(palavra in pergunta_lower for palavra in ['vendas', 'receita', 'faturamento']):
            return ("Nossos dados de vendas mostram um crescimento consistente. "
                   "Para relatórios detalhados de vendas, entre em contato com "
                   "nosso departamento comercial.")

        elif any(palavra in pergunta_lower for palavra in ['projeto', 'projetos']):
            return ("Trabalhamos com diversos projetos em diferentes estágios. "
                   "Para informações sobre projetos específicos, consulte nosso "
                   "gerente de projetos.")

        elif any(palavra in pergunta_lower for palavra in ['departamento', 'departamentos']):
            return ("Nossa empresa está organizada em diferentes departamentos "
                   "especializados para melhor atender nossos clientes.")

        else:
            return ("Olá! Sou o Sophos, assistente virtual da STOLF LTDA. "
                   "Como posso ajudá-lo hoje? Posso fornecer informações sobre "
                   "nossa empresa, serviços e dados organizacionais.")

    def get_fallback_response(self) -> str:
        """Resposta de fallback quando a API Gemini falha."""
        return ("Desculpe, estou temporariamente indisponível. "
               "Nossa equipe está trabalhando para resolver o problema. "
               "Tente novamente em alguns minutos ou entre em contato "
               "diretamente conosco para assistência imediata.")


# Instância global do gerenciador
gemini_manager = GeminiManager()


def obter_resposta_inteligente(pergunta: str, contexto: str) -> str:
    """
    Obtém resposta de forma inteligente, usando mock em testes
    e fallback quando necessário.
    """
    # Em ambiente de teste, usar sempre mock
    if gemini_manager.should_use_mock_response():
        logging.info("Usando resposta mock para ambiente de teste")
        return gemini_manager.get_mock_response(pergunta)

    # Em produção, tentar usar a API real com fallback
    try:
        from app.app import enviar_para_gemini
        return enviar_para_gemini(contexto)
    except Exception as e:
        logging.error(f"Erro ao usar API Gemini: {e}")
        return gemini_manager.get_fallback_response()


def reduzir_uso_api_em_testes():
    """
    Aplica configurações para reduzir uso da API em testes.
    """
    if os.getenv('CI') == 'true':
        # Em CI, forçar uso de mocks
        os.environ['GEMINI_API_KEY'] = 'test_gemini_api_key'
        logging.info("Configurado para usar mock da API Gemini em CI")
