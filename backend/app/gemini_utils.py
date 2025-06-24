import os
import logging
from typing import Optional

class GeminiManager:
    def __init__(self):
        self.is_test_environment = os.getenv('FLASK_ENV') == 'testing' or os.getenv('CI') == 'true'
        self.api_key = os.getenv('GEMINI_API_KEY', '')
        self.is_mock_key = self.api_key in ['test_api_key', 'fake_gemini_key_for_tests', 'test_gemini_api_key']

    def should_use_mock_response(self) -> bool:
        return (
            self.is_test_environment or
            self.is_mock_key or
            not self.api_key
        )

    def get_mock_response(self, pergunta: str) -> str:
        pergunta_lower = pergunta.lower()

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
        return ("Desculpe, estou temporariamente indisponível. "
               "Nossa equipe está trabalhando para resolver o problema. "
               "Tente novamente em alguns minutos ou entre em contato "
               "diretamente conosco para assistência imediata.")

gemini_manager = GeminiManager()

def obter_resposta_inteligente(pergunta: str, contexto: str) -> str:
    if gemini_manager.should_use_mock_response():
        logging.info("Usando resposta mock para ambiente de teste")
        return gemini_manager.get_mock_response(pergunta)

    try:
        from app.app import enviar_para_gemini
        return enviar_para_gemini(contexto)
    except Exception as e:
        logging.error(f"Erro ao usar API Gemini: {e}")
        return gemini_manager.get_fallback_response()


def reduzir_uso_api_em_testes():
    if os.getenv('CI') == 'true':
        os.environ['GEMINI_API_KEY'] = 'test_gemini_api_key'
        logging.info("Configurado para usar mock da API Gemini em CI")
