import os
import logging

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

        respostas_mock = {
            'funcionarios': ("Nossa empresa conta com uma equipe dedicada de profissionais "
                           "distribuídos em diferentes departamentos. Para informações "
                           "específicas sobre nossos funcionários, consulte nosso RH."),
            'vendas': ("Nossos dados de vendas mostram um crescimento consistente. "
                      "Para relatórios detalhados de vendas, entre em contato com "
                      "nosso departamento comercial."),
            'projeto': ("Trabalhamos com diversos projetos em diferentes estágios. "
                       "Para informações sobre projetos específicos, consulte nosso "
                       "gerente de projetos."),
            'departamento': ("Nossa empresa está organizada em diferentes departamentos "
                           "especializados para melhor atender nossos clientes.")
        }

        palavras_funcionarios = ['funcionarios', 'funcionário', 'colaborador']
        palavras_vendas = ['vendas', 'receita', 'faturamento']
        palavras_projetos = ['projeto', 'projetos']
        palavras_departamentos = ['departamento', 'departamentos']

        if any(palavra in pergunta_lower for palavra in palavras_funcionarios):
            return respostas_mock['funcionarios']
        elif any(palavra in pergunta_lower for palavra in palavras_vendas):
            return respostas_mock['vendas']
        elif any(palavra in pergunta_lower for palavra in palavras_projetos):
            return respostas_mock['projeto']
        elif any(palavra in pergunta_lower for palavra in palavras_departamentos):
            return respostas_mock['departamento']
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
    """
    Obtém resposta inteligente usando Gemini API ou mock response.

    Args:
        pergunta: A pergunta do usuário
        contexto: Contexto adicional para a API

    Returns:
        Resposta gerada pela API ou mock response
    """
    if gemini_manager.should_use_mock_response():
        logging.info("Usando resposta mock para ambiente de teste")
        return gemini_manager.get_mock_response(pergunta)

    try:
        from app.app import enviar_para_gemini
        prompt_completo = f"Pergunta: {pergunta}\nContexto: {contexto}"
        return enviar_para_gemini(prompt_completo)
    except Exception as e:
        logging.error(f"Erro ao usar API Gemini: {e}")
        return gemini_manager.get_fallback_response()


def configurar_ambiente_teste():
    """
    Configura o ambiente para usar mock da API Gemini em testes e CI.
    Esta função pode ser chamada no início dos testes para garantir
    que não sejam feitas chamadas reais à API durante os testes.
    """
    if os.getenv('CI') == 'true' or os.getenv('FLASK_ENV') == 'testing':
        os.environ['GEMINI_API_KEY'] = 'test_gemini_api_key'
        logging.info("Configurado para usar mock da API Gemini em ambiente de teste")
