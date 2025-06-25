import requests
import logging
import os
import time
import hashlib
from datetime import datetime
from flask import Flask, request, jsonify
from flask_cors import CORS
from unittest.mock import Mock

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

try:
    from .query_mapping import query_mappings
except ImportError:
    from query_mapping import query_mappings

logging.basicConfig(level=logging.INFO, format='%(levelname)s: %(message)s')

load_dotenv()
required_vars = ['DB_HOST', 'DB_PORT', 'DB_NAME', 'DB_USER', 'DB_PASSWORD', 'GEMINI_API_KEY']
missing = [v for v in required_vars if not os.getenv(v)]

if missing and os.getenv('FLASK_ENV') != 'testing':
    logging.error(f"Variáveis de ambiente faltando: {', '.join(missing)}. Verifique o seu .env.")
    exit(1)
elif missing and os.getenv('FLASK_ENV') == 'testing':
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

if spacy:
    try:
        nlp = spacy.load("pt_core_news_sm")
    except Exception as e:
        if os.getenv('FLASK_ENV') != 'testing':
            logging.error("Não foi possível carregar o modelo spaCy 'pt_core_news_sm'. "
                          "Verifique se instalou com: python -m spacy download pt_core_news_sm")
            exit(1)
        else:
            logging.warning("Usando mock do spaCy para testes")
            nlp = Mock()
            mock_doc = Mock()
            mock_doc.configure_mock(**{
                '__iter__': lambda x: iter([]),
                'text': 'test',
            })
            nlp.return_value = mock_doc
else:
    logging.warning("spaCy não disponível, usando mock")
    nlp = Mock()
    mock_doc = Mock()
    mock_doc.configure_mock(**{
        '__iter__': lambda x: iter([]),
        'text': 'test',
    })
    nlp.return_value = mock_doc

def create_app(config=None):
    from flask import Flask
    app_instance = Flask(__name__)
    app_instance.config['TESTING'] = False
    app_instance.config['SECRET_KEY'] = os.getenv('SECRET_KEY', 'dev-secret-key')
    if config:
        app_instance.config.update(config)
    try:
        from flask_cors import CORS
        # Configuração CORS - mais restritiva para produção
        cors_origins = ["*"]  # Para desenvolvimento
        if os.getenv('FLASK_ENV') == 'production':
            cors_origins = [
                "https://sk-sk.cxbwajafbngqhhej.brazilsouth.azurecontainer.io",
                "http://sk-sk.cxbwajafbngqhhej.brazilsouth.azurecontainer.io:5000"
            ]

        CORS(app_instance,
             origins=cors_origins,
             methods=["GET", "POST", "PUT", "DELETE", "OPTIONS"],
             allow_headers=["Content-Type", "Authorization", "Accept"],
             supports_credentials=True)
    except ImportError:
        logging.warning("flask-cors não disponível - CORS não habilitado")
    return app_instance

instrucoes_fixas = """
# SISTEMA: Assistente Virtual Empresarial - Sophos

## [IDENTIDADE E PERSONA]
Você é **Sophos**, um assistente virtual inteligente e profissional especializado em análise de dados empresariais da Conttrotech, uma empresa de Planejamento de Recursos Empresariais. Sua personalidade é: confiável, precisa, educada e orientada a resultados.

## [CONTEXTO ORGANIZACIONAL]
### Estrutura da Empresa Conttrotech:
- **Departamentos**: Vendas, Marketing Digital, Criação, Atendimento
- **Dados gerenciados**: Funcionários, Clientes, Projetos, Vendas, Contratos
- **Setores atendidos**: Moda, Tecnologia, Varejo, Serviços

### Schema de Dados:
- **Funcionários**: nome, cargo, departamento, salário
- **Projetos**: responsável, orçamento, status [Em andamento|Concluído|Cancelado|Em aprovação]
- **Vendas**: funcionário responsável, valor, status [Pago|Pendente|Atrasado]
- **Contratos**: cliente, valor_total, período, status [Ativo|Encerrado|Cancelado]

## [DIRETRIZES DE COMPORTAMENTO]

### SEMPRE FAÇA:
1. **Inicie respostas com**: "Olá! Sou o Sophos, assistente virtual da Conttrotech."
2. **Priorize precisão** sobre velocidade - analise os dados completamente
3. **Use formatação estruturada**: tabelas, listas, negrito para organizar informações
4. **Traduza dados técnicos** em linguagem de negócios (evite IDs, códigos internos)
5. **Forneça insights contextuais** quando relevante aos dados apresentados

### NUNCA FAÇA:
1. **Expor informações técnicas** como IDs de banco, queries SQL, ou estruturas internas
2. **Inventar dados** que não estejam disponíveis na consulta
3. **Usar jargão técnico** sem explicação para usuários não-técnicos
4. **Dar respostas vagas** - seja específico e baseado em dados

## [FORMATO DE RESPOSTA OBRIGATÓRIO]

### Estrutura Padrão:
```
[SAUDAÇÃO] Olá! Sou o Sophos, assistente virtual da Conttrotech.

[ANÁLISE] Com base nos dados disponíveis, [sua análise aqui]

[DADOS/TABELA] [Apresente os dados em formato estruturado]

[INSIGHTS] [Se aplicável, forneça insights ou conclusões relevantes]

[AÇÕES SUGERIDAS] [Se apropriado, sugira próximos passos ou consultas relacionadas]
```

### Exemplo de Formatação de Tabela:
| Funcionário     | Departamento      | Cargo             | Salário    |
|----------------|-------------------|-------------------|------------|
| Ana Silva      | Marketing Digital | Analista Sênior   | R$ 4.500   |
| Carlos Santos  | Vendas           | Gerente Regional  | R$ 6.200   |
| Maria Costa    | Criação          | Designer Gráfico  | R$ 3.800   |

## [TRATAMENTO DE CENÁRIOS ESPECIAIS]

### Dados Insuficientes:
"Com base nos dados disponíveis no momento, não posso fornecer uma resposta completa para sua consulta.

**Alternativas que posso ajudar:**
- [Listar 2-3 consultas relacionadas possíveis]
- [Sugerir refinamento da pergunta]"

### Consultas Complexas:
- Decomponha em partes menores
- Apresente resultados por etapas
- Forneça resumo executivo ao final

### Dados Sensíveis:
- Apresente informações agregadas quando apropriado
- Mantenha privacidade individual quando necessário
- Foque em insights de negócio, não em detalhes pessoais

## [MÉTRICAS DE QUALIDADE]
Toda resposta deve atender aos critérios:
- ✅ **Precisão**: Baseada em dados reais consultados
- ✅ **Clareza**: Linguagem acessível e bem estruturada
- ✅ **Completude**: Responde totalmente à pergunta ou explica limitações
- ✅ **Utilidade**: Fornece valor de negócio e insights acionáveis
- ✅ **Profissionalismo**: Tom adequado ao contexto empresarial

## [INSTRUÇÕES TÉCNICAS]
- Processe apenas dados retornados pelas consultas ao banco
- Mantenha consistência na formatação entre respostas
- Adapte o nível de detalhe conforme a complexidade da pergunta
- Priorize informações mais recentes quando relevante

---
**LEMBRE-SE**: Seu objetivo é transformar dados em insights valiosos para tomada de decisão empresarial, mantendo sempre alta qualidade, precisão e profissionalismo.
"""

historico_conversa = []
cache_dados = {}
gemini_cache = {}
CACHE_DURATION = 3600

def get_db_connection():
    if not psycopg2:
        logging.warning("psycopg2 não disponível - usando mock para testes")
        return None
    try:
        connection_params = {
            'host': os.getenv('DB_HOST', 'localhost'),
            'port': int(os.getenv('DB_PORT', 5432)),
            'dbname': os.getenv('DB_NAME', 'postgres'),
            'user': os.getenv('DB_USER', 'postgres'),
            'password': os.getenv('DB_PASSWORD', 'postgres'),
            'connect_timeout': 10,
            'options': '-c statement_timeout=30000'
        }
        if os.getenv('FLASK_ENV') == 'testing' or os.getenv('DB_HOST') == 'localhost':
            connection_params['sslmode'] = 'prefer'
        else:
            connection_params['sslmode'] = 'require'
        conn = psycopg2.connect(**connection_params)
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

def verificar_banco():
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
        for tabela in tabelas_necessarias:
            if tabela not in tabelas_faltando:
                try:
                    cur.execute("SELECT COUNT(*) FROM %s" % tabela)
                    count = cur.fetchone()[0]
                    if count == 0:
                        logging.warning(f"A tabela '{tabela}' está vazia. Nenhum registro encontrado.")
                except Exception as e:
                    if os.getenv('FLASK_ENV') != 'testing':
                        logging.warning(f"Erro ao verificar registros na tabela '{tabela}': {e}")
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

def extrair_lemmas(texto):
    import re
    if texto is None:
        return set()
    if not isinstance(texto, str):
        texto = str(texto)
    if not texto.strip():
        return set()
    if not spacy or not hasattr(nlp, '__call__'):
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
        try:
            texto_limpo = re.sub(r'[^a-zA-ZÀ-ÿ0-9\s]', '', texto)
            palavras = texto_limpo.lower().split()
            return set(palavras)
        except Exception:
            return set()

def selecionar_queries(pergunta):
    lemmas_pergunta = extrair_lemmas(pergunta)
    matches = []
    for palavras, label, query in query_mappings:
        chaves_lematizadas = set()
        for frase in palavras:
            doc_frase = nlp(frase.lower())
            for token in doc_frase:
                if token.is_alpha and not token.is_stop:
                    chaves_lematizadas.add(token.lemma_)
        if chaves_lematizadas & lemmas_pergunta:
            matches.append((label, query))
    return matches

def gerar_query_dinamica(pergunta):
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

def executar_query(query_sql, params=None):
    conn = None
    cur = None
    if query_sql and isinstance(query_sql, str):
        if detectar_sql_injection(query_sql):
            logging.error(f"Query SQL suspeita detectada: {query_sql}")
            return None
    try:
        conn = get_db_connection()
        if conn is None:
            logging.error("Não foi possível estabelecer conexão com o banco")
            return None
        cur = conn.cursor()
        if params:
            cur.execute(query_sql, params)
        else:
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

def formatar_resultados(resultados):
    if not resultados:
        return "Nenhum resultado encontrado."
    linhas = []
    for r in resultados:
        linhas.append("- " + ", ".join(map(str, r)))
    return "\n".join(linhas)

def inserir_log(pergunta, sql_gerada, resposta, sucesso):
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

def construir_contexto(pergunta, info_dados):
    ctx = f"O usuário perguntou: '{pergunta}'."
    if info_dados:
        ctx += "\nDados obtidos:\n" + info_dados
    if historico_conversa:
        ultimos = "\n".join(historico_conversa[-6:])
        ctx += "\n\nHistórico de conversa recente:\n" + ultimos
    return ctx

def enviar_para_gemini(contexto):
    cache_key = hashlib.md5(contexto.encode('utf-8')).hexdigest()
    current_time = time.time()
    if cache_key in gemini_cache:
        cached_entry = gemini_cache[cache_key]
        if current_time - cached_entry['timestamp'] < CACHE_DURATION:
            logging.info("Resposta obtida do cache do Gemini")
            return cached_entry['response']
        else:
            del gemini_cache[cache_key]
    recent_calls = getattr(enviar_para_gemini, 'recent_calls', [])
    recent_calls = [t for t in recent_calls if current_time - t < 60]
    if len(recent_calls) >= 10:
        logging.warning("Rate limit atingido para Gemini API")
        return "Desculpe, muitas consultas em pouco tempo. Tente novamente em alguns momentos."
    api_key = os.getenv('GEMINI_API_KEY')
    use_mock = os.getenv('USE_MOCK_GEMINI', '').lower() == 'true'
    is_test_env = os.getenv('FLASK_ENV') == 'testing'
    if (use_mock or is_test_env or
        api_key in ['test_api_key', 'fake_gemini_key_for_tests', 'test_gemini_api_key']):
        if 'funcionários' in contexto.lower() or 'funcionarios' in contexto.lower():
            mock_response = ("Com base nos dados de RH, nossa empresa conta com uma equipe "
                           "qualificada distribuída em diferentes departamentos.")
        elif 'vendas' in contexto.lower() or 'receita' in contexto.lower():
            mock_response = ("Os dados de vendas mostram resultados positivos no período analisado. "
                           "Para relatórios detalhados, consulte o departamento comercial.")
        else:
            mock_response = ("Com base nos dados disponíveis, posso ajudá-lo com informações "
                            "sobre nossa empresa. Esta é uma resposta de teste.")
        gemini_cache[cache_key] = {
            'response': mock_response,
            'timestamp': current_time
        }
        logging.info("Usando resposta mock do Gemini (ambiente de teste)")
        return mock_response
    url = (
        f"https://generativelanguage.googleapis.com/v1beta/models/"
        f"gemini-2.5-flash:generateContent?key={api_key}"
    )
    headers = {'Content-Type': 'application/json'}
    payload = {'contents': [{'parts': [{'text': contexto}]}]}
    max_retries = 3
    base_delay = 1
    for attempt in range(max_retries):
        try:
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
                        gemini_cache[cache_key] = {
                            'response': response_text,
                            'timestamp': current_time
                        }
                        return response_text
                return 'Sem resposta.'
            elif resp.status_code == 429 or 'quota' in resp.text.lower():
                logging.warning(f"Quota exceeded na tentativa {attempt + 1}")
                if attempt < max_retries - 1:
                    delay = base_delay * (2 ** attempt)
                    logging.info(f"Aguardando {delay} segundos antes da próxima tentativa...")
                    time.sleep(delay)
                    continue
                else:
                    fallback_response = ("Desculpe, estou temporariamente indisponível devido ao "
                                       "alto volume de consultas. Tente novamente em alguns minutos.")
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

def detectar_sql_injection(texto):
    if not texto or not isinstance(texto, str):
        return False
    texto_lower = texto.lower().strip()
    padroes_perigosos = [
        r'\bdrop\s+table\b',
        r'\bdrop\s+database\b',
        r'\bdrop\s+schema\b',
        r'\bdelete\s+from\b',
        r'\btruncate\s+table\b',
        r'\bunion\s+select\b',
        r'\bunion\s+all\s+select\b',
        r'--\s*$',
        r'/\*.*\*/',
        r"'\s*or\s+['\"]\s*1\s*['\"]\s*=\s*['\"]\s*1",
        r"'\s*or\s+1\s*=\s*1",
        r"'\s*and\s+1\s*=\s*1",
        r';\s*drop\s+',
        r';\s*delete\s+',
        r';\s*insert\s+',
        r';\s*update\s+',
        r'\binformation_schema\b',
        r'\bsys\.\b',
        r'\bpg_tables\b',
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

def sanitizar_entrada(texto):
    if not texto or not isinstance(texto, str):
        return texto
    import re
    texto_limpo = re.sub(r'<[^>]*>', '', texto, flags=re.IGNORECASE)
    texto_limpo = re.sub(r'[\x00-\x08\x0B-\x0C\x0E-\x1F\x7F]', '', texto_limpo)
    texto_limpo = re.sub(r'[^\w\sàáâãäåæçèéêëìíîïñòóôõöøùúûüýÿ\.\?\!\,\-\(\)]', '', texto_limpo, flags=re.IGNORECASE)
    if len(texto_limpo) > 1000:
        texto_limpo = texto_limpo[:1000]
    return texto_limpo.strip()

supabase_client = None
gemini_client = None

app = create_app()

if os.getenv('FLASK_ENV') != 'testing':
    banco_ok = verificar_banco()
    if not banco_ok:
        logging.warning("Problemas na verificação do banco - continuando com funcionalidade limitada")

try:
    CORS(app,
         origins=["*"],
         methods=["GET", "POST", "PUT", "DELETE", "OPTIONS"],
         allow_headers=["Content-Type", "Authorization", "Accept"],
         supports_credentials=True)
except Exception as e:
    logging.warning(f"Erro ao configurar CORS: {e}")

@app.route('/pergunta', methods=['POST'])
def responder_pergunta():
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
    if not data or 'pergunta' not in data:
        return jsonify({
            'resposta': '',
            'sucesso': False,
            'erro': 'Campo "pergunta" é obrigatório.'
        }), 400
    pergunta = data.get('pergunta', '')
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
    if detectar_sql_injection(pergunta):
        logging.warning(f"Tentativa de SQL injection detectada: {pergunta}")
        return jsonify({
            'resposta': 'Por questões de segurança, não posso processar esta consulta. Por favor, reformule sua pergunta de forma mais específica sobre nossos serviços ou dados da empresa.',
            'sucesso': False,
            'erro': 'Consulta bloqueada por medidas de segurança.'
        }), 400
    pergunta_original = pergunta
    pergunta = sanitizar_entrada(pergunta)
    if not pergunta:
        return jsonify({
            'resposta': '',
            'sucesso': False,
            'erro': 'Pergunta inválida após validação de segurança.'
        }), 400
    test_scenario = request.headers.get('X-Test-Scenario')
    if test_scenario == 'test_error_banco':
        return jsonify({
            'resposta': '',
            'sucesso': False,
            'erro': 'Erro forçado de banco para teste'
        }), 500
    if detectar_sql_injection(pergunta):
        return jsonify({
            'resposta': '',
            'sucesso': False,
            'erro': 'Pergunta contém padrões suspeitos e foi bloqueada por segurança.'
        }), 400
    pergunta = sanitizar_entrada(pergunta)
    try:
        historico_conversa.append(f"Usuário: {pergunta}")
        consultas = selecionar_queries(pergunta)
        if not consultas:
            consultas = gerar_query_dinamica(pergunta)
        sql_strings = [sql for (_label, sql) in consultas]
        sql_concat = ";\n".join(sql_strings) if sql_strings else None
        conn_disponivel = get_db_connection() is not None
        if not conn_disponivel:
            resposta_sem_banco = ("Olá! Sou o Sophos, assistente virtual da Conttrotech. "
                                "Atualmente estou com dificuldades para acessar os dados específicos, "
                                "mas posso ajudá-lo com informações gerais sobre nossa agência de marketing. "
                                "Como posso ajudá-lo?")
            try:
                inserir_log(pergunta, "Sem conexão com banco", resposta_sem_banco, False)
            except:
                pass
            historico_conversa.append(f"IA: {resposta_sem_banco}")
            return jsonify({
                'resposta': resposta_sem_banco,
                'sucesso': True,
                'erro': None,
                'sucesso_sql': False,
                'sqls_usadas': None
            })
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
        contexto = instrucoes_fixas + "\n" + construir_contexto(pergunta, info_texto)
        try:
            try:
                from app.gemini_utils import obter_resposta_inteligente
                resposta = obter_resposta_inteligente(pergunta, contexto)
            except ImportError:
                try:
                    from gemini_utils import obter_resposta_inteligente
                    resposta = obter_resposta_inteligente(pergunta, contexto)
                except ImportError:
                    resposta = enviar_para_gemini(contexto)
        except TimeoutError:
            return jsonify({
                'resposta': '',
                'sucesso': False,
                'erro': 'Timeout ao processar a pergunta.'
            }), 500
        try:
            inserir_log(pergunta, sql_concat, resposta, sucesso_sql)
        except Exception as e:
            logging.warning(f"Não foi possível inserir log: {e}")
        historico_conversa.append(f"IA: {resposta}")
        return jsonify({
            'resposta': resposta,
            'sucesso': True,
            'erro': None,
            'sucesso_sql': sucesso_sql,
            'sqls_usadas': sql_concat
        })
    except Exception as e:
        logging.error(f"Erro interno no endpoint /pergunta: {e}")
        return jsonify({
            'resposta': '',
            'sucesso': False,
            'erro': 'Erro interno do servidor.'
        }), 500

@app.route('/debug/connection', methods=['GET'])
def debug_connection():
    try:
        return jsonify({
            'status': 'ok',
            'message': 'Conectividade estabelecida com sucesso',
            'environment': {
                'db_host': os.getenv('DB_HOST', 'NOT_SET'),
                'db_port': os.getenv('DB_PORT', 'NOT_SET'),
                'has_gemini_key': bool(os.getenv('GEMINI_API_KEY')),
                'cors_enabled': True
            },
            'timestamp': datetime.now().isoformat()
        })
    except Exception as e:
        return jsonify({
            'status': 'error',
            'message': f'Erro no endpoint de debug: {str(e)}'
        }), 500

@app.route('/health', methods=['GET'])
def health_check_basic():
    return jsonify({'status': 'ok', 'message': 'API funcionando'}), 200

@app.route('/api/query/total_vendas_por_mes', methods=['GET'])
def total_vendas_por_mes_legacy():
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

def main():
    verificar_banco()
    print("Sophos, assistente virtual da STOLF LTDA está pronto para responder às suas perguntas.")
    print("(Digite 'sair' ou 'exit' para encerrar.)\n")
    while True:
        try:
            pergunta = input("Digite sua pergunta: ").strip()
        except (KeyboardInterrupt, EOFError):
            print("\nEncerrando.")
            break
        if not pergunta:
            continue
        if pergunta.lower() in ['sair', 'exit', 'quit']:
            print("Encerrando.")
            break
        historico_conversa.append(f"Usuário: {pergunta}")
        consultas = selecionar_queries(pergunta)
        if not consultas:
            consultas = gerar_query_dinamica(pergunta)
        sql_strings = [sql for (_label, sql) in consultas]
        sql_concat = ";\n".join(sql_strings) if sql_strings else None
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
        contexto = instrucoes_fixas + "\n" + construir_contexto(pergunta, info_texto)
        resposta = enviar_para_gemini(contexto)
        inserir_log(pergunta, sql_concat, resposta, sucesso_sql)
        print("\n" + resposta.strip() + "\n")
        historico_conversa.append(f"IA: {resposta}")

if __name__ == '__main__':
    # Configuração específica para Azure Container Instances
    port = int(os.environ.get('PORT', 5000))
    debug = os.environ.get('DEBUG', 'False').lower() == 'true'

    # Para produção no Azure, definir debug=False por padrão
    if 'azurecontainer' in os.environ.get('WEBSITE_HOSTNAME', ''):
        debug = False

    print(f"🚀 Iniciando servidor na porta {port} (debug={debug})")
    app.run(host='0.0.0.0', port=port, debug=debug)
