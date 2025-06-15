import os
import psycopg2
from flask import jsonify
from dotenv import load_dotenv
import logging
from datetime import datetime
import decimal

# Importar a instância do app principal
from app.app import app

load_dotenv()
logging.basicConfig(level=logging.INFO)

def get_db_connection():
    """
    Estabelece conexão com o banco de dados PostgreSQL.
    Inclui tratamento robusto de erros e configurações otimizadas.
    """
    try:
        conn = psycopg2.connect(
            host=os.getenv('DB_HOST'),
            port=os.getenv('DB_PORT', 5432),
            dbname=os.getenv('DB_NAME'),
            user=os.getenv('DB_USER'),
            password=os.getenv('DB_PASSWORD'),
            sslmode='require',  # Para segurança
            connect_timeout=10,  # Timeout de conexão
            application_name='kodiak_charts_api'  # Identifica a aplicação no DB
        )
        return conn
    except psycopg2.OperationalError as e:
        logging.error(f"Erro de conexão com o banco: {e}")
        return None
    except Exception as e:
        logging.error(f"Erro inesperado ao conectar ao banco: {e}")
        return None

@app.route('/api/graphs/health', methods=['GET'])
def health_check():
    """
    Endpoint de verificação de saúde da API.
    Inclui teste de conectividade com o banco de dados.
    """
    try:
        conn = get_db_connection()
        if conn:
            cur = conn.cursor()
            cur.execute("SELECT 1")
            cur.close()
            conn.close()
            return jsonify({
                "status": "healthy",
                "message": "API está funcionando",
                "database": "connected",
                "timestamp": datetime.now().isoformat()
            })
        else:
            return jsonify({
                "status": "unhealthy",
                "message": "Erro de conexão com o banco",
                "database": "disconnected",
                "timestamp": datetime.now().isoformat()
            }), 503
    except Exception as e:
        logging.error(f"Erro no health check: {e}")
        return jsonify({
            "status": "unhealthy",
            "message": str(e),
            "database": "error",
            "timestamp": datetime.now().isoformat()
        }), 500

@app.route('/api/graphs/total_vendas_por_mes', methods=['GET'])
def total_vendas_por_mes():
    """
    Retorna vendas agrupadas por mês com dados dos últimos 12 meses.
    Formato: {mes: 'YYYY-MM', total_vendas: valor}
    """
    query = """
        SELECT
            TO_CHAR(data_venda, 'YYYY-MM') AS mes,
            COALESCE(SUM(valor), 0) AS total_vendas,
            COUNT(*) AS num_vendas
        FROM vendas
        WHERE data_venda >= CURRENT_DATE - INTERVAL '12 months'
        GROUP BY TO_CHAR(data_venda, 'YYYY-MM')
        ORDER BY mes DESC
        LIMIT 12;
    """
    return executar_query_e_gerar_json(query, ['mes', 'total_vendas', 'num_vendas'])

@app.route('/api/graphs/funcionarios_por_departamento', methods=['GET'])
def funcionarios_por_departamento():
    """
    Retorna distribuição de funcionários por departamento.
    Inclui departamentos sem funcionários para análise completa.
    Formato: {departamento: nome, quantidade: número}
    """
    query = """
        SELECT
            d.nome AS departamento,
            COALESCE(COUNT(f.id), 0) AS quantidade,
            d.orcamento
        FROM departamentos d
        LEFT JOIN funcionarios f ON f.departamento_id = d.id
        GROUP BY d.id, d.nome, d.orcamento
        ORDER BY quantidade DESC, d.nome;
    """
    return executar_query_e_gerar_json(query, ['departamento', 'quantidade', 'orcamento'])

@app.route('/api/graphs/projetos_por_status', methods=['GET'])
def projetos_por_status():
    """
    Retorna distribuição de projetos por status com informações adicionais.
    Formato: {status: nome, quantidade: count, valor_total: soma}
    """
    query = """
        SELECT
            COALESCE(status, 'Não Definido') AS status,
            COUNT(*) AS quantidade,
            COALESCE(SUM(orcamento), 0) AS valor_total
        FROM projetos
        WHERE data_inicio >= CURRENT_DATE - INTERVAL '2 years'
        GROUP BY status
        ORDER BY quantidade DESC;
    """
    return executar_query_e_gerar_json(query, ['status', 'quantidade', 'valor_total'])

@app.route('/api/graphs/receita_por_cliente', methods=['GET'])
def receita_por_cliente():
    """
    Retorna top clientes por receita com análise de performance.
    Formato: {cliente: nome_empresa, receita: soma, projetos_ativos: count}
    """
    query = """
        SELECT
            c.nome_empresa AS cliente,
            COALESCE(SUM(v.valor), 0) AS receita,
            COUNT(DISTINCT p.id) AS projetos_total,
            COUNT(DISTINCT CASE WHEN p.status = 'Em andamento' THEN p.id END) AS projetos_ativos
        FROM clientes c
        LEFT JOIN projetos p ON p.cliente_id = c.id
        LEFT JOIN vendas v ON v.projeto_id = p.id
        WHERE c.data_cadastro >= CURRENT_DATE - INTERVAL '3 years'
        GROUP BY c.id, c.nome_empresa
        HAVING COALESCE(SUM(v.valor), 0) > 0
        ORDER BY receita DESC
        LIMIT 10;
    """
    return executar_query_e_gerar_json(query, ['cliente', 'receita', 'projetos_total', 'projetos_ativos'])

# Endpoint adicional para métricas gerais
@app.route('/api/graphs/metricas_gerais', methods=['GET'])
def metricas_gerais():
    """
    Retorna métricas gerais do sistema para dashboard.
    """
    query = """
        SELECT
            (SELECT COUNT(*) FROM clientes WHERE data_cadastro >= CURRENT_DATE - INTERVAL '1 year') AS novos_clientes_ano,
            (SELECT COUNT(*) FROM projetos WHERE status = 'Em andamento') AS projetos_ativos,
            (SELECT COUNT(*) FROM funcionarios) AS total_funcionarios,
            (SELECT SUM(valor) FROM vendas WHERE data_venda >= CURRENT_DATE - INTERVAL '1 month') AS vendas_mes_atual,
            (SELECT SUM(valor) FROM vendas WHERE data_venda >= CURRENT_DATE - INTERVAL '1 year') AS vendas_ano_atual;
    """
    return executar_query_e_gerar_json(query, [
        'novos_clientes_ano', 'projetos_ativos', 'total_funcionarios',
        'vendas_mes_atual', 'vendas_ano_atual'
    ])

def executar_query_e_gerar_json(query, colunas):
    """
    Executa a query e converte o resultado em JSON array de objetos.
    Inclui tratamento robusto de tipos de dados e logging detalhado.

    Args:
        query (str): Query SQL para executar
        colunas (list): Lista com nomes das colunas para o JSON

    Returns:
        Response: JSON com dados ou erro
    """
    start_time = datetime.now()
    conn = get_db_connection()

    if not conn:
        logging.error("Falha na conexão com o banco de dados")
        return jsonify({
            "error": "Falha na conexão com o banco de dados",
            "code": "DB_CONNECTION_ERROR"
        }), 500

    try:
        cur = conn.cursor()
        cur.execute(query)
        resultados = cur.fetchall()

        dados = []
        for row in resultados:
            registro = {}
            for i, col in enumerate(colunas):
                valor = row[i] if i < len(row) else None

                # Tratamento específico de tipos de dados
                if valor is None:
                    registro[col] = None
                elif isinstance(valor, decimal.Decimal):
                    registro[col] = float(valor)
                elif isinstance(valor, (int, float)):
                    registro[col] = float(valor) if isinstance(valor, int) and col in ['total_vendas', 'receita', 'valor_total', 'orcamento'] else valor
                elif isinstance(valor, datetime):
                    registro[col] = valor.isoformat()
                else:
                    registro[col] = str(valor)

            dados.append(registro)

        # Log de performance
        execution_time = (datetime.now() - start_time).total_seconds()
        logging.info(f"Query executada com sucesso em {execution_time:.3f}s - {len(dados)} registros retornados")

        return jsonify({
            "data": dados,
            "count": len(dados),
            "execution_time": f"{execution_time:.3f}s",
            "timestamp": datetime.now().isoformat()
        })

    except psycopg2.Error as e:
        logging.error(f"Erro PostgreSQL: {e}")
        return jsonify({
            "error": "Erro na consulta ao banco de dados",
            "code": "DB_QUERY_ERROR",
            "details": str(e)
        }), 500
    except Exception as e:
        logging.error(f"Erro inesperado ao executar query: {e}")
        return jsonify({
            "error": "Erro interno do servidor",
            "code": "INTERNAL_ERROR",
            "details": str(e)
        }), 500
    finally:
        try:
            cur.close()
            conn.close()
        except:
            pass

# Tratamento de erros globais
@app.errorhandler(404)
def not_found(error):
    return jsonify({
        "error": "Endpoint não encontrado",
        "code": "NOT_FOUND",
        "timestamp": datetime.now().isoformat()
    }), 404

@app.errorhandler(500)
def internal_error(error):
    return jsonify({
        "error": "Erro interno do servidor",
        "code": "INTERNAL_ERROR",
        "timestamp": datetime.now().isoformat()
    }), 500

# As rotas de gráficos foram registradas na instância principal do Flask
# Este arquivo agora é um módulo que estende a aplicação principal
