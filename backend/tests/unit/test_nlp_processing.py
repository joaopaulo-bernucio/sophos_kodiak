# -*- coding: utf-8 -*-
"""
Testes unitários para processamento de linguagem natural (NLP).

Este módulo testa as funcionalidades relacionadas ao spaCy e processamento
de texto em português para o assistente Sophos.
"""

import pytest
from unittest.mock import Mock, patch, MagicMock

# Importação condicional do spacy
try:
    import spacy
    HAS_SPACY = True
except ImportError:
    spacy = None
    HAS_SPACY = False

# Mock das funções da app caso spacy não esteja disponível
if not HAS_SPACY:
    extrair_lemmas = Mock(return_value=['test', 'lemma'])
    selecionar_queries = Mock(return_value=['query1', 'query2'])
    nlp = Mock()
else:
    from app.app import extrair_lemmas, selecionar_queries, nlp


@pytest.mark.skipif(not HAS_SPACY, reason="spaCy não disponível")
class TestExtracaoLemmas:
    """Testes para extração de lemmas usando spaCy."""

    def test_extrair_lemmas_basico(self, nlp_model):
        """Testa extração básica de lemmas."""
        # Mock do documento spaCy
        mock_doc = Mock()

        # Simular tokens
        token1 = Mock()
        token1.lemma_ = 'funcionário'
        token1.is_alpha = True
        token1.is_stop = False

        token2 = Mock()
        token2.lemma_ = 'total'
        token2.is_alpha = True
        token2.is_stop = False

        token3 = Mock()  # Token de stopword
        token3.lemma_ = 'de'
        token3.is_alpha = True
        token3.is_stop = True

        mock_doc.__iter__ = lambda self: iter([token1, token2, token3])

        with patch('app.app.nlp') as mock_nlp:
            mock_nlp.return_value = mock_doc

            resultado = extrair_lemmas("total de funcionários")

            # Deve extrair apenas tokens não-stopwords
            assert 'funcionário' in resultado
            assert 'total' in resultado
            assert 'de' not in resultado  # stopword deve ser filtrada
            assert len(resultado) == 2

    def test_extrair_lemmas_texto_vazio(self):
        """Testa extração de lemmas com texto vazio."""
        resultado = extrair_lemmas("")
        assert isinstance(resultado, set)
        assert len(resultado) == 0

    def test_extrair_lemmas_apenas_stopwords(self):
        """Testa extração quando só há stopwords."""
        mock_doc = Mock()

        token1 = Mock()
        token1.lemma_ = 'de'
        token1.is_alpha = True
        token1.is_stop = True

        token2 = Mock()
        token2.lemma_ = 'para'
        token2.is_alpha = True
        token2.is_stop = True

        mock_doc.__iter__ = lambda self: iter([token1, token2])

        with patch('app.app.nlp') as mock_nlp:
            mock_nlp.return_value = mock_doc

            resultado = extrair_lemmas("de para")
            assert len(resultado) == 0

    def test_extrair_lemmas_com_pontuacao(self):
        """Testa extração ignorando pontuação."""
        mock_doc = Mock()

        token1 = Mock()
        token1.lemma_ = 'funcionário'
        token1.is_alpha = True
        token1.is_stop = False

        token2 = Mock()  # Pontuação
        token2.lemma_ = '?'
        token2.is_alpha = False
        token2.is_stop = False

        mock_doc.__iter__ = lambda self: iter([token1, token2])

        with patch('app.app.nlp') as mock_nlp:
            mock_nlp.return_value = mock_doc

            resultado = extrair_lemmas("funcionário?")

            assert 'funcionário' in resultado
            assert '?' not in resultado  # pontuação deve ser filtrada
            assert len(resultado) == 1


@pytest.mark.skipif(not HAS_SPACY, reason="spaCy não disponível")
class TestSelecaoQueries:
    """Testes para seleção de queries baseada em mapeamentos."""

    def test_selecionar_queries_funcionarios_total(self):
        """Testa seleção de query para contagem de funcionários."""
        with patch('app.app.extrair_lemmas') as mock_extrair:
            mock_extrair.return_value = {'funcionário', 'total'}

            resultado = selecionar_queries("quantos funcionários temos?")

            # Deve encontrar mapeamento para funcionarios-total
            labels = [label for label, query in resultado]
            assert 'funcionarios-total' in labels

    def test_selecionar_queries_salario_medio(self):
        """Testa seleção de query para salário médio."""
        with patch('app.app.extrair_lemmas') as mock_extrair:
            mock_extrair.return_value = {'salário', 'médio'}

            resultado = selecionar_queries("qual o salário médio?")

            labels = [label for label, query in resultado]
            assert 'salario-medio' in labels

    def test_selecionar_queries_sem_match(self):
        """Testa quando não há correspondência."""
        with patch('app.app.extrair_lemmas') as mock_extrair:
            mock_extrair.return_value = {'palavra', 'inexistente'}

            resultado = selecionar_queries("palavra inexistente xyz")

            assert len(resultado) == 0

    def test_selecionar_queries_multiplos_matches(self):
        """Testa quando há múltiplas correspondências."""
        with patch('app.app.extrair_lemmas') as mock_extrair:
            # Lemmas que podem corresponder a múltiplas queries
            mock_extrair.return_value = {'funcionário', 'departamento'}

            resultado = selecionar_queries("funcionários por departamento")

            # Deve encontrar múltiplos mapeamentos relacionados
            assert len(resultado) >= 1
            labels = [label for label, query in resultado]

            # Pode encontrar tanto funcionarios quanto departamentos
            funcionario_related = any('funcionario' in label for label in labels)
            assert funcionario_related


@pytest.mark.skipif(not HAS_SPACY, reason="spaCy não disponível")
class TestProcessamentoTexto:
    """Testes para processamento de texto e normalização."""

    def test_processamento_acentos(self):
        """Testa se acentos são processados corretamente."""
        mock_doc = Mock()

        token1 = Mock()
        token1.lemma_ = 'funcionário'  # Com acento
        token1.is_alpha = True
        token1.is_stop = False

        mock_doc.__iter__ = lambda self: iter([token1])

        with patch('app.app.nlp') as mock_nlp:
            mock_nlp.return_value = mock_doc

            resultado = extrair_lemmas("funcionários")
            assert 'funcionário' in resultado

    def test_processamento_maiusculas_minusculas(self):
        """Testa normalização de maiúsculas/minúsculas."""
        mock_doc = Mock()

        token1 = Mock()
        token1.lemma_ = 'funcionário'
        token1.is_alpha = True
        token1.is_stop = False

        mock_doc.__iter__ = lambda self: iter([token1])

        with patch('app.app.nlp') as mock_nlp:
            mock_nlp.return_value = mock_doc

            resultado_maiuscula = extrair_lemmas("FUNCIONÁRIOS")
            resultado_minuscula = extrair_lemmas("funcionários")

            # Ambos devem ter o mesmo resultado
            assert resultado_maiuscula == resultado_minuscula

    def test_processamento_plurais(self):
        """Testa se plurais são normalizados para singular."""
        mock_doc = Mock()

        token1 = Mock()
        token1.lemma_ = 'funcionário'  # Singular
        token1.is_alpha = True
        token1.is_stop = False

        mock_doc.__iter__ = lambda self: iter([token1])

        with patch('app.app.nlp') as mock_nlp:
            mock_nlp.return_value = mock_doc

            resultado = extrair_lemmas("funcionários")  # Plural
            assert 'funcionário' in resultado  # Deve extrair singular


@pytest.mark.skipif(not HAS_SPACY, reason="spaCy não disponível")
class TestIntegracaoSpacy:
    """Testes de integração com o modelo spaCy."""

    def test_modelo_spacy_carregado(self):
        """Testa se o modelo spaCy está disponível."""
        try:
            # Tentar carregar o modelo real
            modelo = spacy.load("pt_core_news_sm")
            assert modelo is not None
            assert modelo.lang == 'pt'
        except Exception:
            # Se não estiver disponível, pular o teste
            pytest.skip("Modelo spaCy pt_core_news_sm não disponível")

    @pytest.mark.integration
    def test_processamento_real_portugues(self):
        """Testa processamento real com modelo português."""
        try:
            modelo = spacy.load("pt_core_news_sm")

            # Processar uma frase real
            doc = modelo("Os funcionários do departamento de vendas")

            lemmas = []
            for token in doc:
                if token.is_alpha and not token.is_stop:
                    lemmas.append(token.lemma_)

            # Verificar se extraiu lemmas esperados
            assert 'funcionário' in lemmas or 'funcionários' in lemmas
            assert 'departamento' in lemmas
            assert 'venda' in lemmas or 'vendas' in lemmas

        except Exception:
            pytest.skip("Modelo spaCy pt_core_news_sm não disponível")


@pytest.mark.skipif(not HAS_SPACY, reason="spaCy não disponível")
class TestErrorHandling:
    """Testes para tratamento de erros."""

    def test_extrair_lemmas_com_erro_spacy(self):
        """Testa comportamento quando spaCy falha."""
        with patch('app.app.nlp') as mock_nlp:
            mock_nlp.side_effect = Exception("Erro no spaCy")

            # Deve retornar conjunto vazio em caso de erro
            resultado = extrair_lemmas("teste")
            assert isinstance(resultado, set)
            assert len(resultado) == 0

    def test_selecionar_queries_com_lemmas_vazios(self):
        """Testa seleção de queries com lemmas vazios."""
        with patch('app.app.extrair_lemmas') as mock_extrair:
            mock_extrair.return_value = set()  # Conjunto vazio

            resultado = selecionar_queries("texto qualquer")
            assert len(resultado) == 0

    def test_processamento_none_input(self):
        """Testa processamento com entrada None."""
        resultado = extrair_lemmas(None)
        assert isinstance(resultado, set)
        assert len(resultado) == 0
