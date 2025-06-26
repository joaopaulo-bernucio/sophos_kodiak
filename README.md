# Sophos Kodiak

**Assistente Virtual Inteligente para Análise de Dados e Recursos Empresariais**

Sophos Kodiak é uma solução completa que combina um aplicativo móvel Flutter com um backend Python robusto para fornecer análises empresariais avançadas, visualizações de dados interativas e comunicação inteligente através de IA.

## 🚀 Funcionalidades Principais

### 📊 **Análise de Dados**
- Visualização interativa de gráficos e relatórios empresariais
- Dashboard personalizado com métricas em tempo real
- Exportação de relatórios e dados

### 🤖 **Assistente Virtual Inteligente**
- Chat interativo powered by Google Gemini API
- Respostas contextuais sobre dados empresariais
- Histórico de conversas persistente

### ⚙️ **Gerenciamento de Configurações**
- Interface intuitiva para edição de dados cadastrados
- Configurações personalizáveis do usuário
- Sincronização automática com o backend

### 🏠 **Hub Central**
- Dashboard principal de navegação
- Acesso rápido a todas as funcionalidades
- Interface responsiva e moderna

## 🏗️ Arquitetura do Sistema

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Flutter App   │───▶│  Python Backend │───▶│  Supabase DB    │
│   (Frontend)    │    │    (Flask)      │    │    (Cloud)      │
└─────────────────┘    └─────────────────┘    └─────────────────┘
        │                       │                       │
        │                       │                       │
        ▼                       ▼                       ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Mobile UI     │    │  Azure Container│    │  PostgreSQL     │
│  (4 páginas)    │    │   (Produção)    │    │   Database      │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

### **Frontend (Flutter)**
- **Home Page**: Hub principal de navegação
- **Charts Page**: Visualizações e relatórios de dados
- **Chatbot Page**: Interface de comunicação com IA
- **Settings Page**: Gerenciamento de configurações

### **Backend (Python)**
- Framework Flask para APIs RESTful
- Integração com Google Gemini API
- Processamento de dados empresariais
- Autenticação e autorização

### **Banco de Dados**
- Supabase PostgreSQL hospedado na nuvem
- Sincronização em tempo real
- Backup automático e alta disponibilidade

## 🛠️ Tecnologias Utilizadas

### **Frontend**
- **Flutter** - Framework de desenvolvimento mobile
- **Dart** - Linguagem de programação
- **FL Chart** - Biblioteca de gráficos
- **HTTP** - Cliente para requisições API
- **Shared Preferences** - Armazenamento local

### **Backend**
- **Python 3.13+** - Linguagem de programação
- **Flask** - Framework web
- **PostgreSQL** - Banco de dados relacional
- **psycopg2** - Driver PostgreSQL
- **Google Gemini API** - Inteligência artificial

### **Infraestrutura**
- **Supabase** - Backend-as-a-Service
- **Azure Container** - Hospedagem do backend
- **GitHub Actions** - CI/CD (ver documentação específica)

## 📦 Instalação e Configuração

### **Pré-requisitos**
- Flutter SDK (versão 3.0+)
- Python 3.13+
- Git

### **1. Clone o Repositório**
```bash
git clone https://github.com/seu-usuario/sophos_kodiak.git
cd sophos_kodiak
```

### **2. Configuração do Backend**
```bash
cd backend

# Criar ambiente virtual
python -m venv venv
source venv/bin/activate  # Linux/Mac
# ou
venv\Scripts\activate     # Windows

# Instalar dependências
pip install -r requirements.txt

# Configurar variáveis de ambiente
cp .env.example .env
# Edite o arquivo .env com suas credenciais

# Executar o backend
python run.py
```

### **3. Configuração do Frontend**
```bash
cd mobile

# Instalar dependências
flutter pub get

# Executar o aplicativo
flutter run
```

### **4. Configuração do Banco de Dados**
1. Crie uma conta no [Supabase](https://supabase.com)
2. Configure as credenciais no arquivo `.env` do backend
3. Execute as migrações iniciais (se aplicável)

## 🚀 Execução

### **Desenvolvimento**
```bash
# Backend (Terminal 1)
cd backend && python run.py

# Frontend (Terminal 2)
cd mobile && flutter run
```

### **Produção**
O backend está configurado para deploy automático no Azure Container através do GitHub Actions.

## 📋 Variáveis de Ambiente

Crie um arquivo `.env` no diretório `backend/` com as seguintes variáveis:

```env
# Banco de Dados
SUPABASE_URL=your_supabase_url
SUPABASE_KEY=your_supabase_key
DATABASE_URL=your_database_url

# APIs Externas
GEMINI_API_KEY=your_gemini_api_key

# Configurações da Aplicação
FLASK_ENV=development
DEBUG=True
```

## 🧪 Testes

O projeto possui uma suíte completa de testes automatizados:

- **Backend**: Testes unitários, de integração e de performance em Python (pytest)
- **Frontend**: Testes de widget e integração em Flutter

Para mais detalhes sobre execução de testes, consulte:
- [`backend/test/README.md`](backend/test/README.md) - Documentação de testes do backend
- [`mobile/test/README.md`](mobile/test/README.md) - Documentação de testes do frontend

Ambos os ambientes suportam integração com **GitHub Actions** para CI/CD automatizado.

## 📱 Capturas de Tela

*Em desenvolvimento - capturas serão adicionadas em breve*

## 🤝 Contribuição

1. Faça um fork do projeto
2. Crie uma branch para sua feature (`git checkout -b feature/nova-feature`)
3. Commit suas mudanças (`git commit -am 'Adiciona nova feature'`)
4. Push para a branch (`git push origin feature/nova-feature`)
5. Abra um Pull Request

## 📄 Licença

Este projeto está licenciado sob a [MIT License](LICENSE).

## 📞 Suporte

Para dúvidas ou suporte, entre em contato através:
- Issues do GitHub
- Email: [seu-email@exemplo.com]

---

**Sophos Kodiak** - Inteligência empresarial ao alcance das suas mãos 🚀
