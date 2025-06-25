# 🧪 Testes do Backend Sophos Kodiak

Esta documentação descreve a estrutura abrangente de testes do backend, implementada com foco em **testes reais sem mocks** para garantir máxima confiabilidade e representatividade do comportamento em produção.

## 📁 Estrutura dos Testes

```
tests/
├── conftest.py                    # Configurações e fixtures compartilhadas
├── test_critical_infrastructure.py # Testes críticos de infraestrutura
├── test_infrastructure.py         # Testes gerais de infraestrutura
├── test_data_quality.py          # Testes de qualidade dos dados
├── test_real_scenarios.py        # Cenários reais de uso
├── test_smoke.py                 # Smoke tests básicos
├── test_endpoints.py             # Testes completos dos endpoints
└── unit/
    ├── test_query_mapping.py     # Testes do mapeamento de queries
    └── test_nlp_processing.py    # Testes de processamento NLP
```

## 🎯 Categorias de Testes

### 🔥 Critical Infrastructure (`test_critical_infrastructure.py`)
Testa componentes críticos que impedem o funcionamento da aplicação:
- ✅ Conectividade real com PostgreSQL
- ✅ Disponibilidade da API Gemini (quando configurada)
- ✅ Execução real de todas as queries SQL do sistema
- ✅ Integridade das tabelas e schema do banco

```bash
# Executar apenas testes críticos
pytest tests/test_critical_infrastructure.py -v

# Executar com mais detalhes
pytest tests/test_critical_infrastructure.py -v -s
```

### 🏗️ Infrastructure (`test_infrastructure.py`)
Verifica configuração e ambiente de execução:
- ✅ Configuração do Flask
- ✅ Variáveis de ambiente
- ✅ Conectividade de rede
- ✅ Dependências e permissões
- ✅ Configurações de segurança

```bash
# Executar testes de infraestrutura
pytest tests/test_infrastructure.py -v

# Apenas testes de configuração
pytest tests/test_infrastructure.py::TestEnvironmentConfiguration -v
```

### 📊 Data Quality (`test_data_quality.py`)
Garante qualidade e integridade dos dados:
- ✅ Estrutura das tabelas
- ✅ Integridade referencial
- ✅ Consistência dos dados
- ✅ Validação de tipos
- ✅ Regras de negócio

```bash
# Executar testes de qualidade
pytest tests/test_data_quality.py -v

# Apenas testes de estrutura
pytest tests/test_data_quality.py::TestDatabaseStructure -v
```

### 🎭 Real Scenarios (`test_real_scenarios.py`)
Simula uso real da aplicação:
- ✅ Múltiplos usuários simultâneos
- ✅ Sequências complexas de operações
- ✅ Carga sustentada e rajadas
- ✅ Recuperação de falhas
- ✅ Performance sob estresse

```bash
# Executar cenários reais
pytest tests/test_real_scenarios.py -v

# Apenas testes de concorrência
pytest tests/test_real_scenarios.py::TestConcurrentUsers -v
```

### 💨 Smoke Tests (`test_smoke.py`)
Verificações rápidas de funcionamento básico:
- ✅ Inicialização da aplicação
- ✅ Endpoints principais respondem
- ✅ Conectividade básica com banco
- ✅ Proteções de segurança básicas

```bash
# Executar smoke tests (rápido)
pytest tests/test_smoke.py -v

# Apenas verificações críticas
pytest tests/test_smoke.py::TestApplicationStartup -v
```

### 🌐 Endpoints (`test_endpoints.py`)
Testes completos dos endpoints da API:
- ✅ Funcionalidade básica
- ✅ Validação e sanitização
- ✅ Performance e confiabilidade
- ✅ Tratamento de erros
- ✅ Integração entre componentes

```bash
# Executar todos os testes de endpoints
pytest tests/test_endpoints.py -v

# Apenas testes básicos
pytest tests/test_endpoints.py::TestEndpointsBasicos -v
```

### 🧠 Unit Tests (`unit/`)
Testes unitários focados:
- ✅ Mapeamento de queries (`test_query_mapping.py`)
- ✅ Processamento NLP (`test_nlp_processing.py`)

```bash
# Executar testes unitários
pytest tests/unit/ -v

# Apenas testes de NLP
pytest tests/unit/test_nlp_processing.py -v
```

## 🏷️ Markers e Execução Seletiva

### Markers Disponíveis

| Marker | Descrição |
|--------|-----------|
| `critical` | Testes críticos de infraestrutura |
| `smoke` | Smoke tests básicos |
| `infrastructure` | Testes de infraestrutura |
| `data_quality` | Testes de qualidade dos dados |
| `real_scenarios` | Cenários reais de uso |
| `performance` | Testes de performance |
| `concurrent` | Testes de concorrência |
| `security` | Testes de segurança |
| `api` | Testes de endpoints |
| `nlp` | Testes de processamento NLP |

### Comandos de Execução

```bash
# 🚀 Execução rápida - Smoke tests
pytest -m smoke -v

# 🔥 Testes críticos antes de deploy
pytest -m critical -v

# 🏗️ Verificação completa de infraestrutura
pytest -m infrastructure -v

# 📊 Auditoria de qualidade dos dados
pytest -m data_quality -v

# ⚡ Testes de performance
pytest -m performance -v

# 🎭 Cenários reais de uso
pytest -m real_scenarios -v

# 🔒 Testes de segurança
pytest -m security -v

# 🌐 Testes de API
pytest -m api -v

# 🧠 Testes de NLP
pytest -m nlp -v

# 🔀 Testes de concorrência
pytest -m concurrent -v
```

### Combinações Úteis

```bash
# Verificação pré-deploy (críticos + smoke)
pytest -m "critical or smoke" -v

# Testes completos exceto performance
pytest -m "not performance" -v

# Apenas testes que não precisam de recursos externos
pytest -m "not external" -v

# Testes rápidos (smoke + unitários)
pytest -m "smoke or unit" -v

# Auditoria completa de dados e infraestrutura
pytest -m "data_quality or infrastructure" -v
```

## 🔧 Configuração do Ambiente

### Variáveis de Ambiente Necessárias

```bash
# Banco de dados (obrigatório)
DB_HOST=localhost
DB_PORT=6543
DB_NAME=sophos_kodiak
DB_USER=postgres
DB_PASSWORD=senha

# API Gemini (para testes completos)
GEMINI_API_KEY=sua_api_key_real

# Configurações de teste
FLASK_ENV=testing

# Configurações opcionais
OFFLINE_MODE=false  # Pular testes que precisam de internet
CI=false           # Ajustar comportamento para CI/CD
```

### Dependências para Testes Completos

```bash
# Dependências obrigatórias
pip install pytest flask psycopg2-binary

# Dependências opcionais (para funcionalidades avançadas)
pip install spacy
pip install google-generativeai
pip install psutil  # Para monitoramento de recursos
pip install flask-cors

# Modelo spaCy para português (opcional)
python -m spacy download pt_core_news_sm
```

## 📊 Relatórios e Coverage

### Executar com Coverage

```bash
# Coverage básico
pytest --cov=app --cov-report=html

# Coverage detalhado
pytest --cov=app --cov-report=html --cov-report=term-missing --cov-fail-under=80

# Coverage apenas para testes críticos
pytest -m critical --cov=app --cov-report=html
```

### Relatórios de Performance

```bash
# Mostrar 10 testes mais lentos
pytest --durations=10

# Profile detalhado
pytest --profile

# Benchmark básico
pytest -m performance --benchmark-only
```

## 🎯 Estratégias de Teste

### 1. Desenvolvimento Local
```bash
# Desenvolvimento ativo - testes rápidos
pytest -m smoke -x -v

# Verificação antes de commit
pytest -m "critical or smoke" -v

# Teste completo local
pytest -v --maxfail=5
```

### 2. CI/CD Pipeline
```bash
# Stage 1: Smoke tests
pytest -m smoke --tb=line

# Stage 2: Testes críticos
pytest -m critical --tb=line

# Stage 3: Suite completa
pytest --tb=line --maxfail=10
```

### 3. Auditoria de Produção
```bash
# Verificação de infraestrutura
pytest -m infrastructure -v

# Auditoria de dados
pytest -m data_quality -v

# Teste de carga
pytest -m "performance or concurrent" -v
```

## 🚨 Troubleshooting

### Problemas Comuns

1. **Erro de conexão com banco**
   ```bash
   pytest tests/test_critical_infrastructure.py::TestDatabaseCritical::test_database_connection_real -v -s
   ```

2. **API Gemini indisponível**
   ```bash
   # Executar sem testes externos
   pytest -m "not external" -v
   ```

3. **Dependências opcionais faltando**
   ```bash
   # Verificar status das dependências
   pytest tests/test_smoke.py::TestApplicationModules::test_optional_dependencies_status -v -s
   ```

4. **Performance degradada**
   ```bash
   # Executar testes de performance isoladamente
   pytest -m performance --durations=0 -v
   ```

### Logs Detalhados

```bash
# Máximo de detalhes
pytest -v -s --tb=long --log-cli-level=DEBUG

# Apenas erros
pytest --tb=no -q

# Resumo executivo
pytest --tb=line --maxfail=1 -q
```

## 🔄 Integração Contínua

### GitHub Actions / GitLab CI

```yaml
# Exemplo de workflow
- name: Smoke Tests
  run: pytest -m smoke --tb=line

- name: Critical Tests
  run: pytest -m critical --tb=line

- name: Full Test Suite
  run: pytest --tb=line --cov=app --cov-report=xml
  if: github.event_name == 'push' && github.ref == 'refs/heads/main'
```

### Hooks Pre-commit

```bash
# .pre-commit-config.yaml
- repo: local
  hooks:
    - id: pytest-smoke
      name: pytest-smoke
      entry: pytest -m smoke
      language: system
      pass_filenames: false
```

## 📈 Métricas de Qualidade

### Objetivos de Coverage
- **Smoke tests**: Execução < 30s, 100% pass
- **Critical tests**: Execução < 2min, 100% pass
- **Full suite**: Coverage > 80%, 95%+ pass rate
- **Performance**: Response time < 10s, memory < 500MB

### Indicadores de Saúde
- ✅ Todos os smoke tests passando
- ✅ Conectividade com banco funcionando
- ✅ Endpoints principais respondendo
- ✅ Sem vazamentos de memória evidentes
- ✅ Performance dentro dos thresholds

---

## 🎉 Benefícios da Nova Estrutura

1. **🚫 Zero Mocks**: Testes refletem comportamento real
2. **⚡ Execução Inteligente**: Smoke tests para feedback rápido
3. **🔍 Cobertura Abrangente**: Infraestrutura, dados, cenários reais
4. **📊 Qualidade Garantida**: Verificações automáticas de integridade
5. **🎯 Facilidade de Uso**: Markers claros para execução seletiva
6. **📈 Monitoramento**: Métricas de performance e recursos
7. **🔒 Segurança**: Validações contra ataques comuns
8. **🏗️ Manutenibilidade**: Estrutura clara e documentada

Esta estrutura garante que o backend seja robusto, confiável e pronto para produção, com testes que realmente validam o comportamento esperado em cenários reais.
