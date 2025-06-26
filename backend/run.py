#!/usr/bin/env python3
import sys
import os
import logging

backend_dir = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, backend_dir)

from app.app import app
from app import graphs

def setup_logging():
    """Configura o sistema de logging se ainda não foi configurado."""
    if logging.getLogger().handlers:
        return

    log_level = os.environ.get('LOG_LEVEL', 'INFO').upper()
    logging.basicConfig(
        level=getattr(logging, log_level, logging.INFO),
        format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
    )

def is_production():
    """Verifica se a aplicação está rodando em ambiente de produção."""
    env_indicators = [
        os.environ.get('FLASK_ENV') == 'production',
        os.environ.get('ENVIRONMENT') == 'production',
        'azurecontainer' in os.environ.get('HOSTNAME', '').lower(),
        os.environ.get('PORT') is not None
    ]
    return any(env_indicators)

def main():
    """Função principal para inicializar o servidor."""
    setup_logging()

    port = int(os.environ.get('PORT', 5000))
    is_prod = is_production()
    debug = False if is_prod else os.environ.get('DEBUG', 'False').lower() == 'true'

    environment = 'production' if is_prod else 'development'
    logging.info(f"Iniciando servidor em modo {environment}")
    logging.info(f"Host: 0.0.0.0, Porta: {port}, Debug: {debug}")

    if is_prod:
        required_env_vars = [
            'DB_HOST', 'DB_PORT', 'DB_NAME',
            'DB_USER', 'DB_PASSWORD', 'GEMINI_API_KEY'
        ]
        missing_vars = [var for var in required_env_vars if not os.environ.get(var)]

        if missing_vars:
            logging.error(f"Variáveis de ambiente obrigatórias não encontradas: {missing_vars}")
            sys.exit(1)

        logging.info("Todas as variáveis de ambiente obrigatórias estão configuradas")

    try:
        app.run(
            debug=debug,
            host='0.0.0.0',
            port=port,
            threaded=True
        )
    except Exception as e:
        logging.error(f"Erro ao iniciar servidor: {e}")
        sys.exit(1)


if __name__ == '__main__':
    main()
