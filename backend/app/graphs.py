import os
import psycopg2
from flask import Flask, jsonify
from dotenv import load_dotenv
import logging

load_dotenv()
logging.basicConfig(level=logging.INFO)

app = Flask(__name__)

def get_db_connection():
    try:
        conn = psycopg2.connect(
            host=os.getenv('DB_HOST'),
            port=os.getenv('DB_PORT'),
            dbname=os.getenv('DB_NAME'),
            user=os.getenv('DB_USER'),
            password=os.getenv('DB_PASSWORD'),
            sslmode='require'  # comente se não usar SSL
        )
        return conn
    except Exception as e:
        logging.error(f"Erro ao conectar ao banco: {e}")
        return None

@app.route('/api/query/total_vendas_por_mes', methods=['GET'])
def total_vendas_por_mes():
    """
    Retorna lista de {mes: 'YYYY-MM', total_vendas: valor}
    """
    query = """
        SELECT TO_CHAR(data_venda, 'YYYY-MM') AS mes, SUM(valor) AS total_vendas
        FROM vendas
        GROUP BY mes
        ORDER BY mes;
    """
    return executar_query_e_gerar_json(query, ['mes', 'total_vendas'])

@app.route('/api/query/funcionarios_por_departamento', methods=['GET'])
def funcionarios_por_departamento():
    """
    Retorna lista de {departamento: nome, quantidade: número de funcionários}
    """
    query = """
        SELECT d.nome AS departamento, COUNT(f.id) AS quantidade
        FROM departamentos d
        LEFT JOIN funcionarios f ON f.departamento_id = d.id
        GROUP BY d.nome
        ORDER BY quantidade DESC;
    """
    return executar_query_e_gerar_json(query, ['departamento', 'quantidade'])

@app.route('/api/query/projetos_por_status', methods=['GET'])
def projetos_por_status():
    """
    Retorna lista de {status: 'Em andamento'|'Concluído'|..., quantidade: count}
    """
    query = """
        SELECT status, COUNT(*) AS quantidade
        FROM projetos
        GROUP BY status
        ORDER BY quantidade DESC;
    """
    return executar_query_e_gerar_json(query, ['status', 'quantidade'])

@app.route('/api/query/receita_por_cliente', methods=['GET'])
def receita_por_cliente():
    """
    Retorna lista de {cliente: nome_empresa, receita: soma de vendas}
    """
    query = """
        SELECT c.nome_empresa AS cliente, SUM(v.valor) AS receita
        FROM clientes c
        JOIN projetos p ON p.cliente_id = c.id
        JOIN vendas v ON v.projeto_id = p.id
        GROUP BY c.nome_empresa
        ORDER BY receita DESC
        LIMIT 5;
    """
    return executar_query_e_gerar_json(query, ['cliente', 'receita'])

def executar_query_e_gerar_json(query, colunas):
    """
    Executa a query e converte o resultado em JSON array de objetos.
    Cada coluna mapeia para colunas[i]. Se falhar, retorna status 500.
    """
    conn = get_db_connection()
    if not conn:
        return jsonify({"error": "Falha na conexão"}), 500
    try:
        cur = conn.cursor()
        cur.execute(query)
        resultados = cur.fetchall()
        dados = []
        for row in resultados:
            registro = {}
            for i, col in enumerate(colunas):
                valor = row[i]
                if isinstance(valor, (float, int)):
                    registro[col] = float(valor)
                else:
                    registro[col] = valor
            dados.append(registro)
        return jsonify(dados)
    except Exception as e:
        logging.error(f"Erro ao executar query: {e}")
        return jsonify({"error": "Erro na consulta"}), 500
    finally:
        cur.close()
        conn.close()

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5001, debug=True)
