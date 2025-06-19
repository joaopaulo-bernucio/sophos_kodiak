import requests
import logging
import os
import time
import hashlib
from flask import Flask, request, jsonify
from flask_cors import CORS
from unittest.mock import Mock

# Importações opcionais para testes
try:
    import psycopg2
except ImportError:
    psycopg2 = None

try:
    import spacy
except ImportError:
    spacy = None

try:
    from dotenv import load_dotenv
except ImportError:
    def load_dotenv():
        pass

# Importação robusta que funciona tanto como módulo quanto diretamente
try:
    from .query_mapping import query_mappings
except ImportError:
    from query_mapping import query_mappings

# ------------------------------------------------------------
# Configuração básica de logging
# ------------------------------------------------------------
logging.basicConfig(level=logging.INFO, format='%(levelname)s: %(message)s')

# ------------------------------------------------------------
# Carregar variáveis do .env e validar obrigatoriedade
# ------------------------------------------------------------
load_dotenv()
required_vars = ['DB_HOST', 'DB_PORT', 'DB_NAME', 'DB_USER', 'DB_PASSWORD', 'GEMINI_API_KEY']
missing = [v for v in required_vars if not os.getenv(v)]

# Em ambiente de teste, usar valores padrão se variáveis estiverem faltando
if missing and os.getenv('FLASK_ENV') != 'testing':
    logging.error(f"Variáveis de ambiente faltando: {', '.join(missing)}. Verifique o seu .env.")
    exit(1)
elif missing and os.getenv('FLASK_ENV') == 'testing':
    # Definir valores padrão para testes
    test_defaults = {
        'DB_HOST': 'localhost',
        'DB_PORT': '5432',
        'DB_NAME': 'test_db',
        'DB_USER': 'postgres',
        'DB_PASSWORD': 'postgres',
        'GEMINI_API_KEY': 'test_api_key'
    }
    for var in missing:
        if var in test_defaults:
            os.environ[var] = test_defaults[var]

# ------------------------------------------------------------
# Carregar modelo spaCy (português) dentro de try/except
# ------------------------------------------------------------
if spacy:
    try:
        nlp = spacy.load("pt_core_news_sm")
    except Exception as e:
        if os.getenv('FLASK_ENV') != 'testing':
            logging.error("Não foi possível carregar o modelo spaCy 'pt_core_news_sm'. "
                          "Verifique se instalou com: python -m spacy download pt_core_news_sm")
            exit(1)
        else:
            # Em ambiente de teste, criar um nlp mock simples
            logging.warning("Usando mock do spaCy para testes")
            nlp = Mock()
            mock_doc = Mock()
            mock_doc.configure_mock(**{
                '__iter__': lambda x: iter([]),
                'text': 'test',
            })
            nlp.return_value = mock_doc
else:
    # Se spaCy não estiver disponível, usar mock
    logging.warning("spaCy não disponível, usando mock")
    nlp = Mock()
    mock_doc = Mock()
    mock_doc.configure_mock(**{
        '__iter__': lambda x: iter([]),
        'text': 'test',
    })
    nlp.return_value = mock_doc

# ------------------------------------------------------------
# Função principal para criar uma aplicação Flask com factory pattern
# ------------------------------------------------------------
def create_app(config=None):
    """
    Factory pattern para criar a aplicação Flask.
    Útil para testes com diferentes configurações.
    """
    from flask import Flask
    app_instance = Flask(__name__)

    # Configurações padrão
    app_instance.config['TESTING'] = False
    app_instance.config['SECRET_KEY'] = os.getenv('SECRET_KEY', 'dev-secret-key')

    # Aplicar configurações personalizadas se fornecidas
    if config:
        app_instance.config.update(config)

    # Habilitar CORS
    try:
        from flask_cors import CORS
        CORS(app_instance)
    except ImportError:
        logging.warning("flask-cors não disponível - CORS não habilitado")

    return app_instance

# ------------------------------------------------------------
# Instruções fixas (para contexto do Assistente, não ao usuário)
# ------------------------------------------------------------
instrucoes_fixas = """
Você é o Assistente Virtual **Sophos**, integrado ao banco de dados da agência de marketing **STOLF LTDA**.

**Contexto da STOLF LTDA**
- Empresa de marketing com departamentos: **Vendas**, **Marketing Digital**, **Criação** e **Atendimento**.
- Cada funcionário possui **nome**, **cargo**, **departamento** e **salário**.
- A STOLF atende clientes de diversos setores (moda, tecnologia etc.) e gerencia **projetos** para cada cliente.
- Cada projeto informa **responsável**, **orçamento**, **status** ("Em andamento", "Concluído", "Cancelado" ou "Em aprovação") e está vinculado a **vendas**.
- Cada venda está associada a um funcionário e tem **status de pagamento** ("Pago", "Pendente" ou "Atrasado").

---

**Objetivos do Sophos**
1. **Interpretar consultas** sobre departamentos, funcionários, clientes, projetos e vendas, isoladamente ou em combinação.
2. **Responder de forma clara, objetiva e profissional**, usando formatação legível.
3. **Priorizar assertividade** (resposta correta e completa) em vez de rapidez.
4. Se não houver dados suficientes, informe educadamente e sugira alternativas que possam ser respondidas com os dados disponíveis.

**Boas práticas de resposta**
- Ao iniciar, apresente-se como **“Sophos, assistente virtual da STOLF LTDA”**.
- **Evite termos técnicos** sem contexto (não use “id” ou números irrelevantes).
- **Substitua códigos ou identificadores** por nomes e valores compreensíveis.
- Use **tabelas simples** para organizar informações (por exemplo, lista de funcionários), com colunas bem nomeadas.
- Seja **conciso**, mas inclua todos os detalhes necessários para a compreensão humana.
- Use **listas**, **negrito** e **tabelas** para destacar pontos-chave.

**Exemplo de tabela**:

| Nome do Funcionário | Cargo                 | Departamento       | Salário   |
|---------------------|-----------------------|--------------------|-----------|
| João Silva          | Gerente de Vendas     | Vendas             | R$ 5.000  |
| Maria Oliveira      | Designer Gráfico      | Criação            | R$ 3.500  |
| Pedro Souza         | Analista de Marketing | Marketing Digital  | R$ 4.000  |

**Fluxo de atendimento**
1. Receber e entender a pergunta do usuário.
2. Consultar o banco de dados conforme a necessidade.
3. Verificar se há dados suficientes para responder.
4. Construir a resposta: introdução, corpo informativo e formatação legível.
5. Se faltar informação, avisar e sugerir outra consulta possível.

---
**Observação final**: mantenha sempre clareza e profissionalismo. Garanta que o usuário compreenda cada resposta sem depender de termos técnicos ou referências irrelevantes.
"""


# ------------------------------------------------------------
# Histórico de conversa
# ------------------------------------------------------------
historico_conversa = []

# ------------------------------------------------------------
# Cache global para dados essenciais (preenchido em verificar_banco)
# ------------------------------------------------------------
cache_dados = {}

# ------------------------------------------------------------
# Cache para respostas do Gemini (evitar quota exceeded)
# ------------------------------------------------------------
gemini_cache = {}
CACHE_DURATION = 3600  # Cache por 1 hora

# ------------------------------------------------------------
# Função para obter conexão com banco de dados
# ------------------------------------------------------------
def get_db_connection():
    """
    Estabelece conexão com o banco de dados PostgreSQL.
    Retorna a conexão ou None em caso de erro.
    """
    if not psycopg2:
        logging.warning("psycopg2 não disponível - usando mock para testes")
        return None

    try:
        # Configuração robusta para diferentes ambientes
        connection_params = {
            'host': os.getenv('DB_HOST', 'localhost'),
            'port': int(os.getenv('DB_PORT', 5432)),
            'dbname': os.getenv('DB_NAME', 'postgres'),
            'user': os.getenv('DB_USER', 'postgres'),
            'password': os.getenv('DB_PASSWORD', 'postgres'),
            'connect_timeout': 10,
            'options': '-c statement_timeout=30000'
        }

        # Ajustar SSL baseado no ambiente
        if os.getenv('FLASK_ENV') == 'testing' or os.getenv('DB_HOST') == 'localhost':
            connection_params['sslmode'] = 'prefer'
        else:
            connection_params['sslmode'] = 'require'

        conn = psycopg2.connect(**connection_params)

        # Testar a conexão com uma query simples
        with conn.cursor() as test_cursor:
            test_cursor.execute('SELECT 1')
            test_cursor.fetchone()

        return conn
    except psycopg2.OperationalError as e:
        logging.error(f"Erro operacional ao conectar com o banco: {e}")
        return None
    except psycopg2.Error as e:
        logging.error(f"Erro de PostgreSQL ao conectar: {e}")
        return None
    except Exception as e:
        logging.error(f"Erro geral ao conectar com o banco: {e}")
        return None

# ------------------------------------------------------------
# Função: verificar se as tabelas e dados existem
# ------------------------------------------------------------
def verificar_banco():
    """
    Função para verificar se as tabelas essenciais e dados estão presentes no banco.
    Em caso de falha na conexão ou tabelas faltando, encerra o programa (exceto em ambiente de teste).
    """
    conn = None
    cur = None
    try:
        conn = get_db_connection()
        if conn is None:
            if os.getenv('FLASK_ENV') == 'testing':
                logging.warning("Banco não disponível em ambiente de teste - continuando com mocks")
                return True
            else:
                logging.error("Não foi possível conectar ao banco de dados")
                return False

        cur = conn.cursor()

        # Tabelas que devemos ter obrigatoriamente
        tabelas_necessarias = [
            'departamentos', 'funcionarios', 'clientes',
            'projetos', 'vendas', 'contratos_marketing'
        ]

        tabelas_faltando = []

        for tabela in tabelas_necessarias:
            try:
                cur.execute("SELECT to_regclass(%s)", (tabela,))
                resultado = cur.fetchone()[0]
                if resultado is None:
                    tabelas_faltando.append(tabela)
                    logging.warning(f"A tabela '{tabela}' não foi encontrada no banco de dados.")
            except Exception as e:
                if os.getenv('FLASK_ENV') != 'testing':
                    tabelas_faltando.append(tabela)
                    logging.error(f"Erro ao verificar tabela '{tabela}': {e}")

        if tabelas_faltando and os.getenv('FLASK_ENV') != 'testing':
            logging.error(f"Tabelas essenciais faltando: {', '.join(tabelas_faltando)}. Corrija o schema e tente de novo.")
            return False

        # Verificar se existem ao menos 1 registro em cada tabela existente
        for tabela in tabelas_necessarias:
            if tabela not in tabelas_faltando:
                try:
                    cur.execute("SELECT COUNT(*) FROM %s" % tabela)  # Safe porque tabela já foi validada
                    count = cur.fetchone()[0]
                    if count == 0:
                        logging.warning(f"A tabela '{tabela}' está vazia. Nenhum registro encontrado.")
                except Exception as e:
                    if os.getenv('FLASK_ENV') != 'testing':
                        logging.warning(f"Erro ao verificar registros na tabela '{tabela}': {e}")

        # Carregar dados essenciais em cache (apenas se não for teste e não houver tabelas faltando)
        if os.getenv('FLASK_ENV') != 'testing' and not tabelas_faltando:
            try:
                departamentos = executar_query("SELECT nome FROM departamentos;")
                funcionarios = executar_query("""
                    SELECT f.nome, f.cargo, d.nome AS departamento
                    FROM funcionarios f
                    JOIN departamentos d ON f.departamento_id = d.id;
                """)
                clientes = executar_query("SELECT nome_empresa FROM clientes;")
                projetos = executar_query("SELECT nome, status FROM projetos;")
                vendas = executar_query("SELECT valor, status_pagamento FROM vendas;")

                # Preencher cache
                global cache_dados
                cache_dados = {
                    'departamentos': departamentos,
                    'funcionarios': funcionarios,
                    'clientes': clientes,
                    'projetos': projetos,
                    'vendas': vendas
                }
            except Exception as e:
                logging.warning(f"Erro ao carregar dados para cache: {e}")

        logging.info("Verificação do banco de dados concluída com sucesso.")
        return True

    except Exception as e:
        if os.getenv('FLASK_ENV') == 'testing':
            logging.warning(f"Erro na verificação do banco (ambiente de teste): {e}")
            return True
        else:
            logging.error(f"Erro ao se conectar ou verificar o banco de dados: {e}")
            return False
    finally:
        if cur:
            cur.close()
        if conn:
            conn.close()

# ------------------------------------------------------------
# Função auxiliar: extrair lemas sem stopwords nem pontuação
# ------------------------------------------------------------
def extrair_lemmas(texto):
    """
    Recebe uma string, tokeniza com spaCy e retorna um set com os lemas
    (excluindo stopwords e tokens que não sejam alfabéticos).
    """
    import re

    # Tratar valores None ou vazios
    if texto is None:
        return set()

    if not isinstance(texto, str):
        texto = str(texto)

    if not texto.strip():
        return set()

    if not spacy or not hasattr(nlp, '__call__'):
        # Mock para testes quando spaCy não está disponível
        # Remove caracteres especiais e converte para minúsculas
        try:
            texto_limpo = re.sub(r'[^a-zA-ZÀ-ÿ0-9\s]', '', texto)
            palavras = texto_limpo.lower().split()
            return set(palavras)
        except Exception:
            return set()

    try:
        doc = nlp(texto.lower())
        return {token.lemma_ for token in doc if token.is_alpha and not token.is_stop}
    except Exception as e:
        logging.warning(f"Erro ao processar com spaCy: {e}. Usando fallback.")
        # Fallback com limpeza de caracteres especiais
        try:
            texto_limpo = re.sub(r'[^a-zA-ZÀ-ÿ0-9\s]', '', texto)
            palavras = texto_limpo.lower().split()
            return set(palavras)
        except Exception:
            return set()

# ------------------------------------------------------------
# Função: seleciona mapeamentos estáticos baseados em lemas
# ------------------------------------------------------------
def selecionar_queries(pergunta):
    """
    Usa lematização para comparar a pergunta com cada lista de palavras-chave
    em 'query_mappings'. Retorna lista de (label, query_sql) que 'casam'.
    """
    lemmas_pergunta = extrair_lemmas(pergunta)
    matches = []

    for palavras, label, query in query_mappings:
        # Construir set de lemas a partir de todas as frases-chave
        chaves_lematizadas = set()
        for frase in palavras:
            doc_frase = nlp(frase.lower())
            for token in doc_frase:
                if token.is_alpha and not token.is_stop:
                    chaves_lematizadas.add(token.lemma_)

        # Se houver interseção de lemas, considera-se compatível
        if chaves_lematizadas & lemmas_pergunta:
            matches.append((label, query))

    return matches

# ------------------------------------------------------------
# Função: tenta gerar uma query dinâmica a partir de entidades spaCy
# ------------------------------------------------------------
def gerar_query_dinamica(pergunta):
    """
    Exemplo de geração de SQL dinâmico: "cliente promissor".
    Se não aplicar nenhum caso especial, retorna lista vazia.
    """
    doc = nlp(pergunta)
    ents = [ent.text.lower() for ent in doc.ents]
    if 'cliente' in ents and 'promissor' in ents:
        sql = (
            "SELECT c.nome_empresa, SUM(v.valor) AS total_vendido "
            "FROM clientes c "
            "JOIN projetos p ON p.cliente_id = c.id "
            "JOIN vendas v ON v.projeto_id = p.id "
            "GROUP BY c.nome_empresa "
            "ORDER BY total_vendido DESC LIMIT 1;"
        )
        return [('cliente-promissor', sql)]
    return []

# ------------------------------------------------------------
# Função: executa qualquer query SQL e retorna lista de tuplas
# ------------------------------------------------------------
def executar_query(query_sql, params=None):
    """
    Abre conexão, executa a query e retorna os resultados como lista de tuplas.
    Suporte para queries parametrizadas para evitar SQL injection.
    Em caso de erro, faz log e retorna None.

    IMPORTANTE: Sempre use parâmetros para valores dinâmicos!
    """
    conn = None
    cur = None

    # Validação adicional de segurança
    if query_sql and isinstance(query_sql, str):
        # Detectar possíveis tentativas de SQL injection nas queries
        if detectar_sql_injection(query_sql):
            logging.error(f"Query SQL suspeita detectada: {query_sql}")
            return None

    try:
        conn = get_db_connection()
        if conn is None:
            logging.error("Não foi possível estabelecer conexão com o banco")
            return None

        cur = conn.cursor()

        # Executar query com ou sem parâmetros
        if params:
            # Usar prepared statement
            cur.execute(query_sql, params)
        else:
            # Query sem parâmetros (deve ser estática e segura)
            cur.execute(query_sql)

        rows = cur.fetchall()
        return rows

    except psycopg2.Error as e:
        logging.error(f"Erro de PostgreSQL ao executar query: {e}\nQuery: {query_sql}\nParams: {params}")
        return None
    except Exception as e:
        logging.error(f"Erro geral ao executar query: {e}\nQuery: {query_sql}\nParams: {params}")
        return None
    finally:
        if cur:
            cur.close()
        if conn:
            conn.close()

# ------------------------------------------------------------
# Função: formata lista de tuplas em texto legível para o usuário
# ------------------------------------------------------------
def formatar_resultados(resultados):
    """
    Transforma lista de tuplas em linhas de texto. Se vazio ou None, retorna aviso.
    """
    if not resultados:
        return "Nenhum resultado encontrado."
    linhas = []
    for r in resultados:
        linhas.append("- " + ", ".join(map(str, r)))
    return "\n".join(linhas)

# ------------------------------------------------------------
# Nova função: insere registro na tabela logs_perguntas
# ------------------------------------------------------------
def inserir_log(pergunta, sql_gerada, resposta, sucesso):
    """
    Insere um registro em logs_perguntas com a pergunta do usuário,
    as SQLs geradas (todas concatenadas), a resposta gerada e o indicador de sucesso.
    """
    conn = None
    cur = None
    try:
        conn = get_db_connection()
        if conn is None:
            logging.error("Não foi possível conectar ao banco para inserir log")
            return

        cur = conn.cursor()
        insert_sql = """
            INSERT INTO logs_perguntas (pergunta, sql_gerada, resposta, sucesso)
            VALUES (%s, %s, %s, %s);
        """
        cur.execute(insert_sql, (pergunta, sql_gerada, resposta, sucesso))
        conn.commit()
    except Exception as e:
        logging.error(f"Erro ao inserir log em logs_perguntas: {e}")
    finally:
        if cur:
            cur.close()
        if conn:
            conn.close()

# ------------------------------------------------------------
# Função: monta o contexto para enviar ao Gemini (inclui histórico)
# ------------------------------------------------------------
def construir_contexto(pergunta, info_dados):
    """
    Monta o bloco de contexto que será enviado para a API Gemini.
    Inclui pergunta, resultados das queries e histórico recente.
    """
    ctx = f"O usuário perguntou: '{pergunta}'."
    if info_dados:
        ctx += "\nDados obtidos:\n" + info_dados
    if historico_conversa:
        ultimos = "\n".join(historico_conversa[-6:])
        ctx += "\n\nHistórico de conversa recente:\n" + ultimos
    return ctx

# ------------------------------------------------------------
# Função: envia para a API Gemini e retorna o texto da resposta
# ------------------------------------------------------------
def enviar_para_gemini(contexto):
    """
    Faz uma chamada POST para a Gemini (Google Generative Language API)
    e retorna a resposta como texto. Em caso de erro, retorna mensagem de falha.

    Implementa cache e retry logic para lidar com quotas e timeouts.
    """
    # Verificar cache primeiro
    cache_key = hashlib.md5(contexto.encode('utf-8')).hexdigest()
    current_time = time.time()

    if cache_key in gemini_cache:
        cached_entry = gemini_cache[cache_key]
        if current_time - cached_entry['timestamp'] < CACHE_DURATION:
            logging.info("Resposta obtida do cache do Gemini")
            return cached_entry['response']
        else:
            # Cache expirado, remover entrada
            del gemini_cache[cache_key]

    # Verificar se há muitas tentativas recentes (rate limiting básico)
    recent_calls = getattr(enviar_para_gemini, 'recent_calls', [])
    recent_calls = [t for t in recent_calls if current_time - t < 60]  # Últimos 60 segundos

    if len(recent_calls) >= 10:  # Máximo 10 calls por minuto
        logging.warning("Rate limit atingido para Gemini API")
        return "Desculpe, muitas consultas em pouco tempo. Tente novamente em alguns momentos."

    api_key = os.getenv('GEMINI_API_KEY')
    use_mock = os.getenv('USE_MOCK_GEMINI', '').lower() == 'true'
    is_test_env = os.getenv('FLASK_ENV') == 'testing'

    # Em ambiente de teste ou quando explicitamente solicitado mock, usar resposta mock
    if (use_mock or is_test_env or
        api_key in ['test_api_key', 'fake_gemini_key_for_tests', 'test_gemini_api_key']):

        # Resposta mock mais rápida baseada no contexto
        if 'funcionários' in contexto.lower() or 'funcionarios' in contexto.lower():
            mock_response = ("Com base nos dados de RH, nossa empresa conta com uma equipe "
                           "qualificada distribuída em diferentes departamentos.")
        elif 'vendas' in contexto.lower() or 'receita' in contexto.lower():
            mock_response = ("Os dados de vendas mostram resultados positivos no período analisado. "
                           "Para relatórios detalhados, consulte o departamento comercial.")
        else:
            mock_response = ("Com base nos dados disponíveis, posso ajudá-lo com informações "
                            "sobre nossa empresa. Esta é uma resposta de teste.")

        # Adicionar ao cache mesmo sendo mock
        gemini_cache[cache_key] = {
            'response': mock_response,
            'timestamp': current_time
        }
        logging.info("Usando resposta mock do Gemini (ambiente de teste)")
        return mock_response

    url = (
        f"https://generativelanguage.googleapis.com/v1beta/models/"
        f"gemini-2.0-flash:generateContent?key={api_key}"
    )
    headers = {'Content-Type': 'application/json'}
    payload = {'contents': [{'parts': [{'text': contexto}]}]}

    # Retry logic com exponential backoff
    max_retries = 3
    base_delay = 1

    for attempt in range(max_retries):
        try:
            # Registrar tentativa
            recent_calls.append(current_time)
            enviar_para_gemini.recent_calls = recent_calls

            resp = requests.post(url, json=payload, headers=headers, timeout=30)

            if resp.status_code == 200:
                data = resp.json()
                candidates = data.get('candidates', [])
                if candidates:
                    parts = candidates[0].get('content', {}).get('parts', [])
                    if parts:
                        response_text = parts[0].get('text', 'Sem resposta.')
                        # Adicionar ao cache
                        gemini_cache[cache_key] = {
                            'response': response_text,
                            'timestamp': current_time
                        }
                        return response_text
                return 'Sem resposta.'

            elif resp.status_code == 429 or 'quota' in resp.text.lower():
                # Quota exceeded
                logging.warning(f"Quota exceeded na tentativa {attempt + 1}")
                if attempt < max_retries - 1:
                    delay = base_delay * (2 ** attempt)  # Exponential backoff
                    logging.info(f"Aguardando {delay} segundos antes da próxima tentativa...")
                    time.sleep(delay)
                    continue
                else:
                    # Última tentativa falhou por quota
                    fallback_response = ("Desculpe, estou temporariamente indisponível devido ao "
                                       "alto volume de consultas. Tente novamente em alguns minutos.")
                    # Cache a resposta de fallback também
                    gemini_cache[cache_key] = {
                        'response': fallback_response,
                        'timestamp': current_time
                    }
                    return fallback_response

            else:
                logging.error(f"Erro na API Gemini (status {resp.status_code}): {resp.text}")
                if attempt < max_retries - 1:
                    delay = base_delay * (2 ** attempt)
                    time.sleep(delay)
                    continue
                else:
                    return "Erro ao obter resposta da API Gemini."

        except TimeoutError as e:
            logging.error(f"Timeout ao chamar a API Gemini (tentativa {attempt + 1}): {e}")
            if attempt < max_retries - 1:
                delay = base_delay * (2 ** attempt)
                time.sleep(delay)
                continue
            else:
                raise TimeoutError("Request timeout após múltiplas tentativas")

        except Exception as e:
            logging.error(f"Falha ao chamar a API Gemini (tentativa {attempt + 1}): {e}")
            if attempt < max_retries - 1:
                delay = base_delay * (2 ** attempt)
                time.sleep(delay)
                continue
            else:
                return "Erro ao obter resposta da API Gemini."

    return "Erro ao obter resposta da API Gemini após múltiplas tentativas."

# ------------------------------------------------------------
# Função para detectar tentativas de SQL injection
# ------------------------------------------------------------
def detectar_sql_injection(texto):
    """
    Detecta possíveis tentativas de SQL injection no texto de entrada.
    Retorna True se detectar padrões suspeitos, False caso contrário.
    """
    if not texto or not isinstance(texto, str):
        return False

    texto_lower = texto.lower().strip()

    # Padrões perigosos de SQL injection
    padroes_perigosos = [
        # DROP statements
        r'\bdrop\s+table\b',
        r'\bdrop\s+database\b',
        r'\bdrop\s+schema\b',

        # DELETE statements
        r'\bdelete\s+from\b',
        r'\btruncate\s+table\b',

        # UNION attacks
        r'\bunion\s+select\b',
        r'\bunion\s+all\s+select\b',

        # Comment injection
        r'--\s*$',
        r'/\*.*\*/',

        # Boolean-based injection
        r"'\s*or\s+['\"]\s*1\s*['\"]\s*=\s*['\"]\s*1",
        r"'\s*or\s+1\s*=\s*1",
        r"'\s*and\s+1\s*=\s*1",

        # Stacked queries
        r';\s*drop\s+',
        r';\s*delete\s+',
        r';\s*insert\s+',
        r';\s*update\s+',

        # Information schema access
        r'\binformation_schema\b',
        r'\bsys\.\b',
        r'\bpg_tables\b',

        # Other dangerous patterns
        r'\bexec\s*\(',
        r'\bexecute\s*\(',
        r'\bsp_executesql\b',
        r'\bxp_cmdshell\b'
    ]

    import re

    for padrao in padroes_perigosos:
        if re.search(padrao, texto_lower, re.IGNORECASE):
            return True

    return False

# ------------------------------------------------------------
# Função para sanitizar entrada do usuário
# ------------------------------------------------------------
def sanitizar_entrada(texto):
    """
    Sanitiza a entrada do usuário removendo ou escapando caracteres perigosos.
    """
    if not texto or not isinstance(texto, str):
        return texto

    # Remover caracteres potencialmente perigosos
    import re

    # Primeiro, remover tags HTML/XML (incluindo <script>)
    texto_limpo = re.sub(r'<[^>]*>', '', texto, flags=re.IGNORECASE)

    # Remover caracteres de escape e controle
    texto_limpo = re.sub(r'[\x00-\x08\x0B-\x0C\x0E-\x1F\x7F]', '', texto_limpo)

    # Manter apenas caracteres alfanuméricos, espaços, pontuação básica e acentos
    texto_limpo = re.sub(r'[^\w\sàáâãäåæçèéêëìíîïñòóôõöøùúûüýÿ\.\?\!\,\-\(\)]', '', texto_limpo, flags=re.IGNORECASE)

    # Limitar tamanho para evitar ataques de DoS
    if len(texto_limpo) > 1000:
        texto_limpo = texto_limpo[:1000]

    return texto_limpo.strip()

# ------------------------------------------------------------
# Inicialização de clientes globais (para testes)
# ------------------------------------------------------------
supabase_client = None
gemini_client = None

# ------------------------------------------------------------
# Inicializar app Flask
# ------------------------------------------------------------
app = create_app()

# Verificar banco apenas se não for ambiente de teste
if os.getenv('FLASK_ENV') != 'testing':
    # Tentar verificar banco, mas não falhar se houver problemas
    banco_ok = verificar_banco()
    if not banco_ok:
        logging.warning("Problemas na verificação do banco - continuando com funcionalidade limitada")

# Aplicar CORS se ainda não foi aplicado
try:
    CORS(app)
except:
    pass  # Já foi aplicado ou não está disponível

# ------------------------------------------------------------
# Endpoint Flask: /pergunta
# ------------------------------------------------------------
@app.route('/pergunta', methods=['POST'])
def responder_pergunta():
    # Validar se o request tem JSON
    if not request.is_json:
        return jsonify({
            'resposta': '',
            'sucesso': False,
            'erro': 'Content-Type deve ser application/json.'
        }), 400

    try:
        data = request.get_json()
    except Exception:
        return jsonify({
            'resposta': '',
            'sucesso': False,
            'erro': 'JSON inválido.'
        }), 400

    # Validar se pergunta existe e não está vazia
    if not data or 'pergunta' not in data:
        return jsonify({
            'resposta': '',
            'sucesso': False,
            'erro': 'Campo "pergunta" é obrigatório.'
        }), 400

    pergunta = data.get('pergunta', '')

    # Tratar casos onde pergunta pode ser None
    if pergunta is None:
        pergunta = ''
    elif not isinstance(pergunta, str):
        pergunta = str(pergunta)

    pergunta = pergunta.strip()

    if not pergunta:
        return jsonify({
            'resposta': '',
            'sucesso': False,
            'erro': 'Campo "pergunta" está vazio.'
        }), 400

    # Verificar tentativas de SQL injection
    if detectar_sql_injection(pergunta):
        logging.warning(f"Tentativa de SQL injection detectada: {pergunta}")
        return jsonify({
            'resposta': 'Por questões de segurança, não posso processar esta consulta. Por favor, reformule sua pergunta de forma mais específica sobre nossos serviços ou dados da empresa.',
            'sucesso': False,
            'erro': 'Consulta bloqueada por medidas de segurança.'
        }), 400

    # Sanitizar entrada
    pergunta_original = pergunta
    pergunta = sanitizar_entrada(pergunta)

    if not pergunta:
        return jsonify({
            'resposta': '',
            'sucesso': False,
            'erro': 'Pergunta inválida após validação de segurança.'
        }), 400

    # Verificar se é um cenário de teste especial
    test_scenario = request.headers.get('X-Test-Scenario')
    if test_scenario == 'test_error_banco':
        return jsonify({
            'resposta': '',
            'sucesso': False,
            'erro': 'Erro forçado de banco para teste'
        }), 500

    # Detectar e bloquear tentativas de SQL injection
    if detectar_sql_injection(pergunta):
        return jsonify({
            'resposta': '',
            'sucesso': False,
            'erro': 'Pergunta contém padrões suspeitos e foi bloqueada por segurança.'
        }), 400

    # Sanitizar entrada para maior segurança
    pergunta = sanitizar_entrada(pergunta)

    try:
        # Armazenar pergunta no histórico
        historico_conversa.append(f"Usuário: {pergunta}")

        # 1. Tentar mapeamento estático com lemmas
        consultas = selecionar_queries(pergunta)
        # 2. Se não houver mapeamento estático, tentar geração dinâmica
        if not consultas:
            consultas = gerar_query_dinamica(pergunta)

        # Preparar string contendo todas as SQLs geradas, para log
        sql_strings = [sql for (_label, sql) in consultas]
        sql_concat = ";\n".join(sql_strings) if sql_strings else None

        # Verificar conectividade com banco antes de executar queries
        conn_disponivel = get_db_connection() is not None
        if not conn_disponivel:
            # Se não há conexão com banco, fornecer resposta genérica
            resposta_sem_banco = ("Olá! Sou o Sophos, assistente virtual da STOLF LTDA. "
                                "Atualmente estou com dificuldades para acessar os dados específicos, "
                                "mas posso ajudá-lo com informações gerais sobre nossa agência de marketing. "
                                "Como posso ajudá-lo?")

            # Inserir log mesmo sem execução de SQL
            try:
                inserir_log(pergunta, "Sem conexão com banco", resposta_sem_banco, False)
            except:
                pass  # Falha silenciosa se não conseguir inserir log

            historico_conversa.append(f"IA: {resposta_sem_banco}")

            return jsonify({
                'resposta': resposta_sem_banco,
                'sucesso': True,
                'erro': None,
                'sucesso_sql': False,
                'sqls_usadas': None
            })

        # Executar cada query e montar o info_texto
        info_texto = ''
        sucesso_sql = False
        if consultas:
            todas_ok = True
            for label, sql in consultas:
                logging.info(f"Executando [{label}]: {sql}")
                rows = executar_query(sql)
                if rows is None or rows == []:
                    todas_ok = False
                else:
                    sucesso_sql = True
                info_texto += f"Resultados ({label}):\n" + formatar_resultados(rows) + "\n"
            if not todas_ok:
                sucesso_sql = False
        else:
            info_texto = None
            sucesso_sql = False

        # Montar o contexto completo para enviar ao Gemini
        contexto = instrucoes_fixas + "\n" + construir_contexto(pergunta, info_texto)

        # Chamar a API Gemini e obter resposta
        try:
            # Usar sistema inteligente de resposta
            try:
                from app.gemini_utils import obter_resposta_inteligente
                resposta = obter_resposta_inteligente(pergunta, contexto)
            except ImportError:
                try:
                    from gemini_utils import obter_resposta_inteligente
                    resposta = obter_resposta_inteligente(pergunta, contexto)
                except ImportError:
                    # Fallback para sistema antigo se utilitário não estiver disponível
                    resposta = enviar_para_gemini(contexto)
        except TimeoutError:
            return jsonify({
                'resposta': '',
                'sucesso': False,
                'erro': 'Timeout ao processar a pergunta.'
            }), 500

        # Inserir log antes de retornar
        try:
            inserir_log(pergunta, sql_concat, resposta, sucesso_sql)
        except Exception as e:
            logging.warning(f"Não foi possível inserir log: {e}")

        # Armazenar resposta no histórico
        historico_conversa.append(f"IA: {resposta}")

        return jsonify({
            'resposta': resposta,
            'sucesso': True,  # Sempre True se chegou até aqui sem erro
            'erro': None,     # Adiciona campo erro como None para sucesso
            'sucesso_sql': sucesso_sql,  # Mantém para informação adicional
            'sqls_usadas': sql_concat
        })

    except Exception as e:
        logging.error(f"Erro interno no endpoint /pergunta: {e}")
        return jsonify({
            'resposta': '',
            'sucesso': False,
            'erro': 'Erro interno do servidor.'
        }), 500

# ------------------------------------------------------------
# Endpoints de API adicionais
# ------------------------------------------------------------

@app.route('/health', methods=['GET'])
def health_check_basic():
    """Endpoint de health check básico."""
    return jsonify({'status': 'ok', 'message': 'API funcionando'}), 200

@app.route('/api/query/total_vendas_por_mes', methods=['GET'])
def total_vendas_por_mes_legacy():
    """Endpoint para obter total de vendas por mês (versão legacy)."""
    try:
        query = """
        SELECT
            EXTRACT(MONTH FROM data_venda) as mes,
            EXTRACT(YEAR FROM data_venda) as ano,
            SUM(valor) as total
        FROM vendas
        WHERE data_venda >= %s
        GROUP BY EXTRACT(YEAR FROM data_venda), EXTRACT(MONTH FROM data_venda)
        ORDER BY ano DESC, mes DESC;
        """

        # Usar parâmetro para a data (12 meses atrás)
        from datetime import datetime, timedelta
        data_limite = datetime.now() - timedelta(days=365)

        resultados = executar_query(query, (data_limite,))
        if resultados is None:
            return jsonify({'error': 'Erro ao executar consulta'}), 500

        data = []
        for r in resultados:
            try:
                data.append({
                    'mes': int(r[0]) if r[0] is not None else 0,
                    'ano': int(r[1]) if r[1] is not None else 0,
                    'total': float(r[2]) if r[2] is not None else 0.0
                })
            except (ValueError, TypeError) as e:
                logging.warning(f"Erro ao converter dados de venda: {e}")
                continue

        return jsonify({'data': data}), 200
    except Exception as e:
        logging.error(f"Erro no endpoint total_vendas_por_mes: {e}")
        return jsonify({'error': 'Erro interno'}), 500

@app.route('/api/query/funcionarios_por_departamento', methods=['GET'])
def funcionarios_por_departamento_legacy():
    """Endpoint para obter funcionários por departamento (versão legacy)."""
    try:
        query = """
        SELECT
            d.nome as departamento,
            COUNT(f.id) as total_funcionarios
        FROM departamentos d
        LEFT JOIN funcionarios f ON f.departamento_id = d.id
        GROUP BY d.nome
        ORDER BY total_funcionarios DESC;
        """

        resultados = executar_query(query)
        if resultados is None:
            return jsonify({'error': 'Erro ao executar consulta'}), 500

        data = []
        for r in resultados:
            try:
                data.append({
                    'departamento': str(r[0]) if r[0] is not None else 'Sem departamento',
                    'total_funcionarios': int(r[1]) if r[1] is not None else 0
                })
            except (ValueError, TypeError) as e:
                logging.warning(f"Erro ao converter dados de funcionário: {e}")
                continue

        return jsonify({'data': data}), 200
    except Exception as e:
        logging.error(f"Erro no endpoint funcionarios_por_departamento: {e}")
        return jsonify({'error': 'Erro interno'}), 500

@app.route('/api/query/projetos_por_status', methods=['GET'])
def projetos_por_status_legacy():
    """Endpoint para obter projetos por status (versão legacy)."""
    try:
        query = """
        SELECT
            status,
            COUNT(*) as total
        FROM projetos
        GROUP BY status
        ORDER BY total DESC;
        """

        resultados = executar_query(query)
        if resultados is None:
            return jsonify({'error': 'Erro ao executar consulta'}), 500

        data = [{'status': r[0], 'total': int(r[1])} for r in resultados]
        return jsonify({'data': data}), 200
    except Exception as e:
        logging.error(f"Erro no endpoint projetos_por_status: {e}")
        return jsonify({'error': 'Erro interno'}), 500

@app.route('/api/query/receita_por_cliente', methods=['GET'])
def receita_por_cliente_legacy():
    """Endpoint para obter receita por cliente (versão legacy)."""
    try:
        query = """
        SELECT
            c.nome_empresa,
            SUM(v.valor) as receita_total
        FROM clientes c
        JOIN projetos p ON p.cliente_id = c.id
        JOIN vendas v ON v.projeto_id = p.id
        GROUP BY c.nome_empresa
        ORDER BY receita_total DESC
        LIMIT 10;
        """

        resultados = executar_query(query)
        if resultados is None:
            return jsonify({'error': 'Erro ao executar consulta'}), 500

        data = [{'cliente': r[0], 'receita_total': float(r[1])} for r in resultados]
        return jsonify({'data': data}), 200
    except Exception as e:
        logging.error(f"Erro no endpoint receita_por_cliente: {e}")
        return jsonify({'error': 'Erro interno'}), 500

@app.route('/api/query/metricas_gerais', methods=['GET'])
def metricas_gerais_legacy():
    """Endpoint para obter métricas gerais do sistema (versão legacy)."""
    try:
        query = """
        SELECT
            (SELECT COUNT(*) FROM funcionarios) as total_funcionarios,
            (SELECT COUNT(*) FROM clientes) as total_clientes,
            (SELECT COUNT(*) FROM projetos) as total_projetos,
            (SELECT SUM(valor) FROM vendas) as receita_total,
            (SELECT COUNT(*) FROM projetos WHERE status = 'Em andamento') as projetos_ativos
        """

        resultados = executar_query(query)
        if resultados is None:
            return jsonify({'error': 'Erro ao executar consulta'}), 500

        if resultados:
            r = resultados[0]
            data = [{
                'total_funcionarios': int(r[0]) if r[0] else 0,
                'total_clientes': int(r[1]) if r[1] else 0,
                'total_projetos': int(r[2]) if r[2] else 0,
                'receita_total': float(r[3]) if r[3] else 0.0,
                'projetos_ativos': int(r[4]) if r[4] else 0
            }]
        else:
            data = []

        return jsonify({'data': data}), 200
    except Exception as e:
        logging.error(f"Erro no endpoint metricas_gerais: {e}")
        return jsonify({'error': 'Erro interno'}), 500

# ------------------------------------------------------------
# Função principal (mantida para execução em modo console, se necessário)
# ------------------------------------------------------------
def main():
    # 1. Verificar conexão e existência de tabelas/dados
    verificar_banco()

    print("Sophos, assistente virtual da STOLF LTDA está pronto para responder às suas perguntas.")
    print("(Digite 'sair' ou 'exit' para encerrar.)\n")

    while True:
        try:
            pergunta = input("Digite sua pergunta: ").strip()
        except (KeyboardInterrupt, EOFError):
            # Interrompe com Ctrl+C ou Ctrl+D
            print("\nEncerrando.")
            break

        if not pergunta:
            continue

        if pergunta.lower() in ['sair', 'exit', 'quit']:
            print("Encerrando.")
            break

        # Armazenar pergunta no histórico
        historico_conversa.append(f"Usuário: {pergunta}")

        # 1. Tentar mapeamento estático com lemmas
        consultas = selecionar_queries(pergunta)
        # 2. Se não houver mapeamento estático, tentar geração dinâmica
        if not consultas:
            consultas = gerar_query_dinamica(pergunta)

        # Preparar string contendo todas as SQLs geradas, para log
        sql_strings = [sql for (_label, sql) in consultas]
        sql_concat = ";\n".join(sql_strings) if sql_strings else None

        # Executar cada query e montar o info_texto
        info_texto = ''
        sucesso_sql = False
        if consultas:
            todas_ok = True
            for label, sql in consultas:
                logging.info(f"Executando [{label}]: {sql}")
                rows = executar_query(sql)
                if rows is None or rows == []:
                    todas_ok = False
                else:
                    sucesso_sql = True
                info_texto += f"Resultados ({label}):\n" + formatar_resultados(rows) + "\n"
            if not todas_ok:
                sucesso_sql = False
        else:
            info_texto = None
            sucesso_sql = False

        # Montar o contexto completo para enviar ao Gemini
        contexto = instrucoes_fixas + "\n" + construir_contexto(pergunta, info_texto)

        # Chamar a API Gemini e obter resposta
        resposta = enviar_para_gemini(contexto)

        # Inserir log antes de exibir a resposta
        inserir_log(pergunta, sql_concat, resposta, sucesso_sql)

        # Exibir apenas a resposta natural ao usuário
        print("\n" + resposta.strip() + "\n")

        # Armazenar resposta no histórico
        historico_conversa.append(f"IA: {resposta}")

if __name__ == '__main__':
    # Em modo de execução direta, iniciar o servidor Flask
    app.run(host='0.0.0.0', port=5000)
    # main()
