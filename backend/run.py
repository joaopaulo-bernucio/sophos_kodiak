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

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=5000)
