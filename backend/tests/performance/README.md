# Performance Tests

Este diretório contém testes específicos de performance para o projeto Sophos Kodiak.

## Estrutura

- `test_performance_ci.py` - Testes de performance para CI/CD
- `test_benchmarks.py` - Benchmarks usando pytest-benchmark
- `__init__.py` - Arquivo de inicialização do módulo

## Tipos de Testes

### 1. Testes de API Performance
- Tempo de resposta de endpoints
- Requisições concorrentes
- Health check performance

### 2. Testes de Database Performance
- Tempo de conexão com banco de dados
- Performance de queries simples
- Medição de latência

### 3. Testes de System Performance
- Uso de memória
- Tempo de importação de módulos
- Performance do modelo NLP

### 4. Benchmarks
- Medições precisas com pytest-benchmark
- Comparação de performance entre versões
- Baseline de performance

## Como Executar

### Todos os testes de performance:
```bash
pytest -m performance -v
```

### Apenas testes específicos:
```bash
pytest tests/performance/ -v
```

### Com benchmarks (se pytest-benchmark estiver disponível):
```bash
pytest tests/performance/test_benchmarks.py --benchmark-only
```

### Executar localmente:
```bash
./test_performance_local.sh
```

## Configuração CI/CD

Os testes de performance são executados automaticamente no GitHub Actions:

- **PRs**: Apenas testes básicos de baseline
- **Main branch**: Suite completa de performance + benchmarks

### Marcadores Pytest

- `@pytest.mark.performance` - Todos os testes de performance
- `@pytest.mark.benchmark` - Testes específicos de benchmark

## Dependências

- `pytest` - Framework de testes
- `pytest-benchmark` - Para benchmarks precisos (opcional)
- `psutil` - Para monitoramento de sistema
- `psycopg2` - Para testes de banco de dados

## Critérios de Performance

### API Response Time
- Endpoint principal: < 15 segundos (sistema completo com múltiplas queries)
- Health check: < 1 segundo
- Requisições sequenciais: < 10 segundos média

### Database Performance
- Conexão: < 2 segundos
- Queries simples: < 1 segundo média

### System Performance
- Uso de memória: < 1GB (CI/CD)
- Importação de módulos: < 5 segundos
- Carregamento modelo NLP: < 10 segundos

## Troubleshooting

### Testes Falhando
1. Verificar se todas as dependências estão instaladas
2. Verificar configuração do banco de dados
3. Executar `./validate_performance_tests.sh` para diagnóstico

### Performance Degradada
1. Verificar logs detalhados com `-v`
2. Usar `--durations=10` para identificar testes lentos
3. Comparar com baseline anterior

### CI/CD Issues
1. Verificar se marcadores estão configurados corretamente
2. Confirmar que pytest.ini tem configurações de performance
3. Validar configuração do PostgreSQL nos services

## Adicionando Novos Testes

1. Adicionar marcador `@pytest.mark.performance`
2. Seguir convenções de nomenclatura `test_*_performance`
3. Incluir prints informativos para CI/CD
4. Definir critérios claros de sucesso/falha
5. Considerar timeout apropriado

Exemplo:
```python
@pytest.mark.performance
def test_my_feature_performance(self, client):
    """Testa performance da minha feature."""
    start_time = time.time()

    # Seu código de teste aqui

    duration = time.time() - start_time
    print(f"Tempo de execução: {duration:.3f}s")

    assert duration < 2.0, f"Muito lento: {duration:.2f}s"
```
