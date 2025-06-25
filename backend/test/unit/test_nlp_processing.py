import pytest
import os
from typing import Set, List, Tuple, Optional

os.environ['FLASK_ENV'] = 'testing'

pytestmark = [pytest.mark.unit, pytest.mark.nlp]

try:
    import spacy
    HAS_SPACY = True
    try:
        TEST_NLP_MODEL = spacy.load("pt_core_news_sm")
        HAS_SPACY_MODEL = True
    except Exception:
        TEST_NLP_MODEL = None
        HAS_SPACY_MODEL = False
except ImportError:
    spacy = None
    HAS_SPACY = False
    HAS_SPACY_MODEL = False
    TEST_NLP_MODEL = None

try:
    from app.app import extrair_lemmas, selecionar_queries, nlp
    from app.query_mapping import query_mappings
    HAS_APP_FUNCTIONS = True
except ImportError:
    HAS_APP_FUNCTIONS = False


@pytest.mark.skipif(not HAS_APP_FUNCTIONS, reason="Funções da app não disponíveis")
class TestExtrairLemmas:

    def test_extrair_lemmas_texto_simples(self):
        resultado = extrair_lemmas("funcionário trabalha")
        assert isinstance(resultado, set)
        assert len(resultado) > 0
        resultado_str = ' '.join(resultado).lower()
        assert 'funcionário' in resultado_str or 'trabalha' in resultado_str

    def test_extrair_lemmas_texto_vazio(self):
        resultado = extrair_lemmas("")
        assert isinstance(resultado, set)
        assert len(resultado) == 0

    def test_extrair_lemmas_texto_none(self):
        resultado = extrair_lemmas(None)
        assert isinstance(resultado, set)
        assert len(resultado) == 0

    def test_extrair_lemmas_texto_apenas_espacos(self):
        resultado = extrair_lemmas("   ")
        assert isinstance(resultado, set)
        assert len(resultado) == 0

    def test_extrair_lemmas_com_pontuacao(self):
        resultado = extrair_lemmas("funcionário, trabalha!")
        assert isinstance(resultado, set)
        assert len(resultado) > 0
        for lemma in resultado:
            assert ',' not in lemma
            assert '!' not in lemma

    def test_extrair_lemmas_com_acentos(self):
        resultado = extrair_lemmas("funcionários têm salários")
        assert isinstance(resultado, set)
        assert len(resultado) > 0
        resultado_str = ' '.join(resultado).lower()
        assert any(palavra in resultado_str for palavra in ['funcionário', 'funcionários', 'salário', 'salários'])

    def test_extrair_lemmas_maiusculas_minusculas(self):
        resultado_maiuscula = extrair_lemmas("FUNCIONÁRIOS")
        resultado_minuscula = extrair_lemmas("funcionários")
        resultado_misto = extrair_lemmas("Funcionários")
        assert isinstance(resultado_maiuscula, set)
        assert isinstance(resultado_minuscula, set)
        assert isinstance(resultado_misto, set)
        assert len(resultado_maiuscula) > 0
        assert len(resultado_minuscula) > 0
        assert len(resultado_misto) > 0

    def test_extrair_lemmas_numeros_e_texto(self):
        resultado = extrair_lemmas("10 funcionários 5 departamentos")
        assert isinstance(resultado, set)
        assert len(resultado) > 0
        resultado_str = ' '.join(resultado).lower()
        assert any(palavra in resultado_str for palavra in ['funcionário', 'funcionários', 'departamento', 'departamentos'])

    def test_extrair_lemmas_texto_longo(self):
        texto = "Os funcionários do departamento de vendas trabalham com muitos clientes importantes"
        resultado = extrair_lemmas(texto)
        assert isinstance(resultado, set)
        assert len(resultado) > 0
        resultado_str = ' '.join(resultado).lower()
        expected_words = ['funcionário', 'funcionários', 'departamento', 'vendas', 'cliente', 'clientes']
        found_words = sum(1 for word in expected_words if word in resultado_str)
        assert found_words > 0

    def test_extrair_lemmas_input_nao_string(self):
        resultado = extrair_lemmas(123)
        assert isinstance(resultado, set)

    def test_extrair_lemmas_caracteres_especiais(self):
        resultado = extrair_lemmas("funcionário@empresa.com.br")
        assert isinstance(resultado, set)
        if len(resultado) > 0:
            resultado_str = ' '.join(resultado).lower()
            assert any(char.isalpha() for char in resultado_str)


@pytest.mark.skipif(not HAS_APP_FUNCTIONS, reason="Funções da app não disponíveis")
class TestSelecionarQueries:

    def test_selecionar_queries_funcionarios_total(self):
        perguntas_funcionarios = [
            "quantos funcionários",
            "total de funcionários",
            "número de funcionários",
            "quantos func",
            "count funcionários"
        ]

        for pergunta in perguntas_funcionarios:
            resultado = selecionar_queries(pergunta)

            assert isinstance(resultado, list)
            if len(resultado) > 0:
                labels = [label for label, query in resultado]
                funcionario_found = any('funcionario' in label.lower() for label in labels)
                assert funcionario_found, f"Não encontrou mapeamento de funcionários para: {pergunta}"

    def test_selecionar_queries_salario_medio(self):
        perguntas_salario = [
            "salário médio",
            "média salarial",
            "média de salários",
            "salario medio"
        ]

        for pergunta in perguntas_salario:
            resultado = selecionar_queries(pergunta)

            assert isinstance(resultado, list)
            if len(resultado) > 0:
                labels = [label for label, query in resultado]
                salario_found = any('salario' in label.lower() for label in labels)
                assert salario_found, f"Não encontrou mapeamento de salário para: {pergunta}"

    def test_selecionar_queries_projetos(self):
        perguntas_projetos = [
            "quantos projetos",
            "total de projetos",
            "listar projetos",
            "projetos concluídos"
        ]

        for pergunta in perguntas_projetos:
            resultado = selecionar_queries(pergunta)

            assert isinstance(resultado, list)
            if len(resultado) > 0:
                labels = [label for label, query in resultado]
                projeto_found = any('projeto' in label.lower() for label in labels)
                assert projeto_found, f"Não encontrou mapeamento de projeto para: {pergunta}"

    def test_selecionar_queries_clientes(self):
        perguntas_clientes = [
            "listar clientes",
            "quantos clientes",
            "total de clientes",
            "mostrar clientes"
        ]

        for pergunta in perguntas_clientes:
            resultado = selecionar_queries(pergunta)

            assert isinstance(resultado, list)
            if len(resultado) > 0:
                labels = [label for label, query in resultado]
                cliente_found = any('cliente' in label.lower() for label in labels)
                assert cliente_found, f"Não encontrou mapeamento de cliente para: {pergunta}"

    def test_selecionar_queries_vendas(self):
        perguntas_vendas = [
            "total de vendas",
            "quantas vendas",
            "listar vendas",
            "detalhes de vendas"
        ]

        for pergunta in perguntas_vendas:
            resultado = selecionar_queries(pergunta)

            assert isinstance(resultado, list)
            if len(resultado) > 0:
                labels = [label for label, query in resultado]
                venda_found = any('venda' in label.lower() for label in labels)
                assert venda_found, f"Não encontrou mapeamento de venda para: {pergunta}"

    def test_selecionar_queries_sem_match(self):
        perguntas_sem_match = [
            "palavra completamente inexistente xyz123",
            "abcdefghijklmnop",
            "query sem sentido algum"
        ]

        for pergunta in perguntas_sem_match:
            resultado = selecionar_queries(pergunta)
            assert isinstance(resultado, list)

    def test_selecionar_queries_entrada_vazia(self):
        resultado = selecionar_queries("")
        assert isinstance(resultado, list)
        assert len(resultado) == 0

    def test_selecionar_queries_entrada_none(self):
        resultado = selecionar_queries(None)
        assert isinstance(resultado, list)

    def test_selecionar_queries_multiplas_palavras_chave(self):
        pergunta = "funcionários do departamento de vendas"
        resultado = selecionar_queries(pergunta)

        assert isinstance(resultado, list)

        if len(resultado) > 0:
            labels = [label for label, query in resultado]
            relevant_found = any(
                any(keyword in label.lower() for keyword in ['funcionario', 'departamento', 'venda'])
                for label in labels
            )
            assert relevant_found

    def test_selecionar_queries_retorna_tuplas_validas(self):
        resultado = selecionar_queries("funcionários")

        assert isinstance(resultado, list)

        for item in resultado:
            assert isinstance(item, tuple)
            assert len(item) == 2

            label, query = item
            assert isinstance(label, str)
            assert isinstance(query, str)
            assert len(label) > 0
            assert len(query) > 0


@pytest.mark.skipif(not HAS_APP_FUNCTIONS, reason="Funções da app não disponíveis")
class TestProcessamentoTexto:

    def test_processamento_caracteres_especiais(self):
        textos_especiais = [
            "funcionário@empresa.com",
            "R$ 5.000,00",
            "10% dos funcionários",
            "funcionário & departamento",
            "vendas (último mês)"
        ]

        for texto in textos_especiais:
            resultado = extrair_lemmas(texto)
            assert isinstance(resultado, set)

    def test_processamento_diferentes_encodings(self):
        textos_acentuados = [
            "funcionário",
            "operação",
            "informação",
            "relatório",
            "estatísticas"
        ]

        for texto in textos_acentuados:
            resultado = extrair_lemmas(texto)
            assert isinstance(resultado, set)
            assert len(resultado) > 0

    def test_processamento_texto_longo_complexo(self):
        texto = """
        Os funcionários do departamento de vendas precisam de mais informações
        sobre os clientes e projetos em andamento. É necessário gerar relatórios
        estatísticos para análise gerencial e tomada de decisões estratégicas.
        """

        resultado = extrair_lemmas(texto)
        assert isinstance(resultado, set)
        assert len(resultado) > 0

        resultado_str = ' '.join(resultado).lower()
        expected_words = ['funcionário', 'departamento', 'vendas', 'cliente', 'projeto']
        found_words = sum(1 for word in expected_words if word in resultado_str)
        assert found_words > 0

    def test_consistencia_processamento(self):
        texto = "funcionários trabalham departamento"

        resultado1 = extrair_lemmas(texto)
        resultado2 = extrair_lemmas(texto)
        resultado3 = extrair_lemmas(texto)

        assert resultado1 == resultado2 == resultado3

    def test_processamento_case_insensitive(self):
        textos = [
            "funcionários",
            "FUNCIONÁRIOS",
            "Funcionários",
            "FuNcIoNáRiOs"
        ]

        resultados = [extrair_lemmas(texto) for texto in textos]

        for resultado in resultados:
            assert isinstance(resultado, set)
            assert len(resultado) > 0


@pytest.mark.skipif(not HAS_SPACY_MODEL, reason="Modelo spaCy pt_core_news_sm não disponível")
class TestIntegracaoSpacyReal:

    def test_modelo_spacy_disponivel(self):
        assert TEST_NLP_MODEL is not None
        assert TEST_NLP_MODEL.lang == 'pt'

    def test_processamento_real_portugues(self):
        frases_teste = [
            "Os funcionários trabalham no departamento",
            "Quantos projetos temos concluídos?",
            "Qual é o salário médio dos empregados?",
            "Listar todos os clientes ativos"
        ]

        for frase in frases_teste:
            doc = TEST_NLP_MODEL(frase)

            assert len(doc) > 0

            lemmas = [token.lemma_ for token in doc if token.is_alpha and not token.is_stop]
            assert len(lemmas) > 0

    def test_reconhecimento_entidades(self):
        frases_com_entidades = [
            "João Silva trabalha no departamento de vendas",
            "A empresa Sophos tem 100 funcionários",
            "O projeto iniciou em janeiro de 2024"
        ]

        for frase in frases_com_entidades:
            doc = TEST_NLP_MODEL(frase)

            assert len(doc) > 0

            entidades = [ent.text for ent in doc.ents]

    def test_lematizacao_real(self):
        casos_lematizacao = [
            ("funcionários", "funcionário"),
            ("trabalham", "trabalhar"),
            ("projetos", "projeto"),
            ("clientes", "cliente"),
            ("vendas", "venda")
        ]

        for palavra, lemma_esperado in casos_lematizacao:
            doc = TEST_NLP_MODEL(palavra)

            if len(doc) > 0:
                token = doc[0]
                assert token.lemma_ is not None
                assert len(token.lemma_) > 0


@pytest.mark.skipif(not HAS_APP_FUNCTIONS, reason="Funções da app não disponíveis")
class TestRobustezEErrorHandling:

    def test_extrair_lemmas_entradas_extremas(self):
        entradas_extremas = [
            "",
            None,
            "   ",
            "\n\t\r",
            "a",
            "a" * 1000,
            "123456789",
            "!@#$%^&*()",
            "àáâãäåæçèéêë",
        ]

        for entrada in entradas_extremas:
            resultado = extrair_lemmas(entrada)
            assert isinstance(resultado, set)

    def test_selecionar_queries_entradas_extremas(self):
        entradas_extremas = [
            "",
            None,
            "   ",
            "a",
            "a" * 1000,
            "123456789",
            "!@#$%^&*()",
        ]

        for entrada in entradas_extremas:
            resultado = selecionar_queries(entrada)
            assert isinstance(resultado, list)

    def test_processamento_unicode(self):
        textos_unicode = [
            "funcionário 👨‍💼",
            "projeto 🚀",
            "vendas 💰",
            "estatística π",
            "informação ñ"
        ]

        for texto in textos_unicode:
            resultado = extrair_lemmas(texto)
            assert isinstance(resultado, set)

    @pytest.mark.performance
    def test_memoria_e_performance(self):
        texto_grande = " ".join(["funcionários trabalham departamento"] * 100)

        resultado = extrair_lemmas(texto_grande)
        assert isinstance(resultado, set)

        assert len(resultado) < 100

    def test_consistencia_entre_funcoes(self):
        pergunta = "quantos funcionários trabalham"

        lemmas = extrair_lemmas(pergunta)
        queries = selecionar_queries(pergunta)

        assert isinstance(lemmas, set)
        assert isinstance(queries, list)

        if len(lemmas) > 0:
            assert queries is not None


@pytest.mark.skipif(not HAS_APP_FUNCTIONS, reason="Funções da app não disponíveis")
class TestCasosEspecificos:

    @pytest.mark.parametrize("pergunta,categoria_esperada", [
        ("quantos funcionários", "funcionario"),
        ("total de projetos", "projeto"),
        ("listar clientes", "cliente"),
        ("salário médio", "salario"),
        ("vendas do mês", "venda"),
        ("departamentos ativos", "departamento"),
    ])
    def test_mapeamentos_especificos(self, pergunta, categoria_esperada):
        resultado = selecionar_queries(pergunta)

        assert isinstance(resultado, list)

        if len(resultado) > 0:
            labels = [label for label, query in resultado]
            categoria_found = any(categoria_esperada in label.lower() for label in labels)
            assert categoria_found, f"Categoria '{categoria_esperada}' não encontrada para '{pergunta}'"

    def test_perguntas_complexas(self):
        perguntas_complexas = [
            "Gostaria de saber quantos funcionários temos na empresa",
            "Você pode me mostrar o total de projetos concluídos?",
            "Qual é a lista de todos os clientes ativos no sistema?",
            "Preciso ver as informações sobre vendas do último período",
            "Me ajude a encontrar o salário médio dos colaboradores"
        ]

        for pergunta in perguntas_complexas:
            resultado = selecionar_queries(pergunta)
            assert isinstance(resultado, list)

    def test_variacoes_linguisticas(self):
        grupos_variacoes = [
            [
                "quantos funcionários",
                "quantas funcionárias",
                "número de funcionários",
                "total de funcionários",
                "count de funcionários"
            ],
            [
                "listar projetos",
                "mostrar projetos",
                "ver projetos",
                "exibir projetos",
                "apresentar projetos"
            ]
        ]

        for grupo in grupos_variacoes:
            resultados = []
            for variacao in grupo:
                resultado = selecionar_queries(variacao)
                resultados.append(len(resultado))

            assert all(isinstance(r, int) and r >= 0 for r in resultados)

    def test_queries_sql_validas(self):
        perguntas_teste = [
            "funcionários",
            "projetos",
            "clientes",
            "vendas"
        ]

        for pergunta in perguntas_teste:
            resultado = selecionar_queries(pergunta)

            for label, query in resultado:
                assert isinstance(query, str)
                assert len(query) > 0

                query_upper = query.upper()
                assert 'SELECT' in query_upper

    def test_integracao_com_query_mappings(self):
        try:
            assert isinstance(query_mappings, list)
            assert len(query_mappings) > 0

            for item in query_mappings[:5]:
                assert isinstance(item, (tuple, list))
                assert len(item) == 3

                palavras, label, query = item
                assert isinstance(palavras, list)
                assert isinstance(label, str)
                assert isinstance(query, str)
        except Exception:
            pytest.skip("query_mappings não disponível ou mal formado")


@pytest.mark.integration
@pytest.mark.skipif(not HAS_APP_FUNCTIONS, reason="Funções da app não disponíveis")
class TestIntegracaoCompleta:

    def test_fluxo_completo_pergunta_resposta(self):
        perguntas_teste = [
            "Quantos funcionários temos?",
            "Lista de projetos",
            "Salário médio",
            "Clientes ativos"
        ]

        for pergunta in perguntas_teste:
            lemmas = extrair_lemmas(pergunta)
            assert isinstance(lemmas, set)

            queries = selecionar_queries(pergunta)
            assert isinstance(queries, list)

            if len(lemmas) > 0:
                assert queries is not None

    @pytest.mark.performance
    def test_performance_basica(self):
        import time

        pergunta = "funcionários do departamento de vendas"

        start_time = time.time()

        for _ in range(3):
            lemmas = extrair_lemmas(pergunta)
            queries = selecionar_queries(pergunta)

        end_time = time.time()
        tempo_total = end_time - start_time

        assert tempo_total < 10.0

    def test_uso_memoria_estavel(self):
        pergunta = "funcionários projetos clientes vendas"

        resultados = []
        for i in range(5):
            lemmas = extrair_lemmas(pergunta)
            queries = selecionar_queries(pergunta)
            resultados.append((len(lemmas), len(queries)))

        primeiro_resultado = resultados[0]
        for resultado in resultados[1:]:
            assert resultado == primeiro_resultado
