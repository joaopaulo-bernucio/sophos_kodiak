#!/usr/bin/env python3
"""
Script para executar o servidor Flask da aplicação Sophos Kodiak.
"""

import sys
import os

# Adiciona o diretório backend ao Python path
backend_dir = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, backend_dir)

from app.app import app
# Importar e registrar rotas de gráficos
from app import graphs

if __name__ == '__main__':
    port = int(os.environ.get('PORT', 5000))
    debug = os.environ.get('DEBUG', 'True').lower() == 'true'
    app.run(debug=debug, host='0.0.0.0', port=port)
