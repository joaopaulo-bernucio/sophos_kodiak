# Guia de Resolução de Problemas - Sophos Kodiak

## Problemas de Conectividade Flutter → Flask

### ✅ Problemas Resolvidos

1. **URL malformada no ApiService**
   - **Problema**: URL sem protocolo `http://`
   - **Solução**: Alterado de `'10.0.2.2:5000'` para `'http://10.0.2.2:5000'`

2. **Variáveis de ambiente mal formatadas**
   - **Problema**: `.env` com espaços e aspas extras
   - **Solução**: Formatação correta sem espaços ao redor de `=`

3. **Configuração CORS insuficiente**
   - **Problema**: CORS básico não permitia todas as requisições
   - **Solução**: Configuração específica com origins, métodos e headers

### 🔧 Verificações de Diagnóstico

#### 1. Testar servidor Flask localmente
```bash
cd backend
curl -v http://localhost:5000/health
curl -v http://localhost:5000/debug/connection
```

#### 2. Verificar variáveis de ambiente
```bash
cd backend
python -c "from dotenv import load_dotenv; import os; load_dotenv(); print('DB_HOST:', os.getenv('DB_HOST'))"
```

#### 3. Testar do emulador Android
- Use a página "Teste Rede" no app
- Verifique logs no console do Flutter
- IP do host para emulador: `10.0.2.2:5000`

### 🚨 Problemas Comuns e Soluções

#### Problema: "Connection refused"
**Possíveis causas:**
- Servidor Flask não está rodando
- IP/porta incorretos
- Firewall bloqueando

**Soluções:**
1. Verificar se o Flask está rodando: `curl http://localhost:5000/health`
2. Usar IP correto do emulador: `10.0.2.2` (não `localhost`)
3. Verificar firewall do sistema

#### Problema: "CORS error"
**Sintomas:**
- Erro de CORS no navegador/app
- Request blocked

**Solução:**
- Verificar configuração CORS no Flask
- Confirmar headers corretos nas requests

#### Problema: "Timeout"
**Possíveis causas:**
- Servidor sobrecarregado
- Consultas SQL demoradas
- Conexão de rede lenta

**Soluções:**
1. Aumentar timeout nas requests
2. Otimizar consultas SQL
3. Verificar conectividade de rede

#### Problema: Erro de banco de dados
**Sintomas:**
- Erro 500 Internal Server Error
- Mensagens de erro do PostgreSQL

**Soluções:**
1. Verificar credenciais do Supabase
2. Testar conectividade: `python backend/setup_environment.sh`
3. Verificar logs do Flask

### 📱 Configuração do Emulador Android

#### IPs importantes:
- `10.0.2.2` - Acessa localhost do host machine
- `127.0.0.1` - Loopback do emulador (não funcionará)
- `localhost` - Loopback do emulador (não funcionará)

#### Para dispositivos físicos:
- Usar IP real da máquina (ex: `192.168.1.100:5000`)
- Permitir conexões externas no Flask: `app.run(host='0.0.0.0')`

### 🔍 Debugging Avançado

#### Logs do Flask:
```bash
cd backend
python run.py
# Logs aparecerão no terminal
```

#### Logs do Flutter:
```bash
cd mobile
flutter logs
# Para debug específico, adicione prints no código
```

#### Ferramentas úteis:
```bash
# Testar endpoints específicos
curl -X POST -H "Content-Type: application/json" -d '{"pergunta": "teste"}' http://localhost:5000/pergunta

# Verificar porta em uso
netstat -tulpn | grep :5000

# Verificar conectividade específica
telnet 10.0.2.2 5000  # Do emulador
```

### 🛠️ Script de Setup Automático

Execute o script de configuração para verificar tudo:
```bash
cd backend
./setup_environment.sh
```

### 📞 Contato para Suporte

Se os problemas persistirem:
1. Execute a página "Teste Rede" no app
2. Colete logs do Flask e Flutter
3. Verifique configurações de rede
4. Documente a mensagem de erro exata
