import requests
import psycopg2
import logging
import os
from dotenv import load_dotenv
import spacy
from flask import Flask, request, jsonify
from .query_mapping import query_mappings

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
if missing:
    logging.error(f"Variáveis de ambiente faltando: {', '.join(missing)}. Verifique o seu .env.")
    exit(1)

# ------------------------------------------------------------
# Carregar modelo spaCy (português) dentro de try/except
# ------------------------------------------------------------
try:
    nlp = spacy.load("pt_core_news_sm")
except Exception as e:
    logging.error("Não foi possível carregar o modelo spaCy 'pt_core_news_sm'. "
                  "Verifique se instalou com: python -m spacy download pt_core_news_sm")
    exit(1)

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
# Função: verificar se as tabelas e dados existem
# ------------------------------------------------------------
def verificar_banco():
    """
    Função para verificar se as tabelas essenciais e dados estão presentes no banco.
    Em caso de falha na conexão ou tabelas faltando, encerra o programa.
    """
    try:
        conn = psycopg2.connect(
            host=os.getenv('DB_HOST'),
            port=os.getenv('DB_PORT'),
            dbname=os.getenv('DB_NAME'),
            user=os.getenv('DB_USER'),
            password=os.getenv('DB_PASSWORD'),
            sslmode='require'
        )
        cur = conn.cursor()

        # Tabelas que devemos ter obrigatoriamente
        tabelas_necessarias = [
            'departamentos', 'funcionarios', 'clientes',
            'projetos', 'vendas', 'contratos_marketing'
        ]
        erro = False

        for tabela in tabelas_necessarias:
            cur.execute(f"SELECT to_regclass('{tabela}')")
            resultado = cur.fetchone()[0]
            if resultado is None:
                logging.error(f"A tabela '{tabela}' não foi encontrada no banco de dados.")
                erro = True

        if erro:
            logging.error("Uma ou mais tabelas essenciais estão faltando. Corrija o schema e tente de novo.")
            exit(1)

        # Verificar se existem ao menos 1 registro em cada tabela
        for tabela in tabelas_necessarias:
            cur.execute(f"SELECT COUNT(*) FROM {tabela}")
            count = cur.fetchone()[0]
            if count == 0:
                logging.warning(f"A tabela '{tabela}' está vazia. Nenhum registro encontrado.")

        # Carregar dados essenciais em cache
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

        logging.info("Verificação do banco de dados concluída com sucesso.")
    except Exception as e:
        logging.error(f"Erro ao se conectar ou verificar o banco de dados: {e}")
        exit(1)
    finally:
        if 'cur' in locals():
            cur.close()
        if 'conn' in locals():
            conn.close()

# ------------------------------------------------------------
# Função auxiliar: extrair lemas sem stopwords nem pontuação
# ------------------------------------------------------------
def extrair_lemmas(texto):
    """
    Recebe uma string, tokeniza com spaCy e retorna um set com os lemas
    (excluindo stopwords e tokens que não sejam alfabéticos).
    """
    doc = nlp(texto.lower())
    return {token.lemma_ for token in doc if token.is_alpha and not token.is_stop}

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
def executar_query(query_sql):
    """
    Abre conexão, executa a query e retorna os resultados como lista de tuplas.
    Em caso de erro, faz log e retorna None.
    """
    try:
        conn = psycopg2.connect(
            host=os.getenv('DB_HOST'),
            port=os.getenv('DB_PORT'),
            dbname=os.getenv('DB_NAME'),
            user=os.getenv('DB_USER'),
            password=os.getenv('DB_PASSWORD'),
            sslmode='require'
        )
        cur = conn.cursor()
        cur.execute(query_sql)
        rows = cur.fetchall()
        return rows
    except Exception as e:
        logging.error(f"Erro ao executar query: {e}\nQuery: {query_sql}")
        return None
    finally:
        if 'cur' in locals():
            cur.close()
        if 'conn' in locals():
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
    try:
        conn = psycopg2.connect(
            host=os.getenv('DB_HOST'),
            port=os.getenv('DB_PORT'),
            dbname=os.getenv('DB_NAME'),
            user=os.getenv('DB_USER'),
            password=os.getenv('DB_PASSWORD'),
            sslmode='require'
        )
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
        if 'cur' in locals():
            cur.close()
        if 'conn' in locals():
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
    """
    api_key = os.getenv('GEMINI_API_KEY')
    url = (
        f"https://generativelanguage.googleapis.com/v1beta/models/"
        f"gemini-2.0-flash:generateContent?key={api_key}"
    )
    headers = {'Content-Type': 'application/json'}
    payload = {'contents': [{'parts': [{'text': contexto}]}]}

    try:
        resp = requests.post(url, json=payload, headers=headers, timeout=30)
    except Exception as e:
        logging.error(f"Falha ao chamar a API Gemini: {e}")
        return "Erro ao obter resposta da API Gemini."

    if resp.status_code == 200:
        data = resp.json()
        candidates = data.get('candidates', [])
        if candidates:
            parts = candidates[0].get('content', {}).get('parts', [])
            if parts:
                return parts[0].get('text', 'Sem resposta.')
        return 'Sem resposta.'
    else:
        logging.error(f"Erro na API Gemini (status {resp.status_code}): {resp.text}")
        return "Erro ao obter resposta da API Gemini."

# ------------------------------------------------------------
# Inicializar app Flask
# ------------------------------------------------------------
app = Flask(__name__)

# ------------------------------------------------------------
# Endpoint Flask: /pergunta
# ------------------------------------------------------------
@app.route('/pergunta', methods=['POST'])
def responder_pergunta():
    data = request.get_json()
    pergunta = data.get('pergunta', '').strip()

    if not pergunta:
        return jsonify({
            'resposta': '',
            'sucesso': False,
            'erro': 'Campo "pergunta" está vazio.'
        }), 400

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

    # Inserir log antes de retornar
    inserir_log(pergunta, sql_concat, resposta, sucesso_sql)

    # Armazenar resposta no histórico
    historico_conversa.append(f"IA: {resposta}")

    return jsonify({
        'resposta': resposta,
        'sucesso': True,  # Sempre True se chegou até aqui sem erro
        'erro': None,     # Adiciona campo erro como None para sucesso
        'sucesso_sql': sucesso_sql,  # Mantém para informação adicional
        'sqls_usadas': sql_concat
    })

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
    # Verifica banco antes de iniciar o servidor
    verificar_banco()
    # Inicia o Flask para responder via HTTP
    app.run(host='0.0.0.0', port=5000)
    # main()
