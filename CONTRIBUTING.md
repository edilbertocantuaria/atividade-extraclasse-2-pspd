# Guia de Contribuição

## 📐 Estrutura do Projeto

Mantenha a seguinte organização:

```
├── README.md              # Documentação principal - mantenha atualizado
├── docs/                  # Toda documentação técnica aqui
├── scripts/               # Apenas scripts essenciais
├── config/                # Configurações de teste (somente leitura)
├── hadoop/                # Setup Hadoop (infra)
├── spark/                 # Setup Spark (infra)
├── resultados/            # Outputs (não commitar grandes arquivos)
└── wordcount/             # Aplicação de exemplo
```

## ✅ Boas Práticas

### Scripts

**DO:**
```bash
#!/bin/bash
set -euo pipefail  # Sempre usar

# Cores para output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Documentação clara
echo -e "${YELLOW}Iniciando processo...${NC}"
```

**DON'T:**
```bash
#!/bin/bash
# Sem set -e
# Sem cores
# Sem mensagens claras
```

### Nomenclatura

**Arquivos:**
- Scripts: `snake_case.sh` (ex: `run_tests.sh`)
- Docs: `lowercase.md` (ex: `hadoop.md`)
- Configs: `kebab-case.xml` (ex: `yarn-site.xml`)

**Variáveis bash:**
```bash
GLOBAL_VAR="uppercase"
local_var="lowercase"
```

### Documentação

**Sempre documente:**
1. O que o script faz (cabeçalho)
2. Parâmetros esperados
3. Saída esperada
4. Exemplo de uso

**Exemplo:**
```bash
# ============================================================================
# SETUP - Inicializar cluster Hadoop
# ============================================================================
# Uso: ./scripts/setup.sh
# Saída: Cluster rodando em http://localhost:9870
# ============================================================================
```

## 🚫 O Que NÃO Fazer

### ❌ Não criar duplicatas
```bash
# RUIM
script.sh
script_v2.sh
script_novo.sh
script_final.sh
```

```bash
# BOM
script.sh  # Sempre melhore o original
```

### ❌ Não deixar markdowns soltos na raiz
```
# RUIM
/README.md
/LEIA_ME.md
/COMO_USAR.md
/INSTRUCOES.md

# BOM
/README.md
/docs/uso.md
/docs/instrucoes.md
```

### ❌ Não commitar arquivos temporários
```bash
# Usar .gitignore para:
*.log
*.tmp
*.backup
__pycache__/
.env
```

## 📝 Adicionando Novo Teste

### 1. Criar configuração

```bash
mkdir -p config/teste5_novo/
cp hadoop/master/yarn-site.xml config/teste5_novo/
# Editar configuração
```

### 2. Atualizar run_tests.sh

```bash
# Adicionar chamada ao teste
executar_teste \
  "teste5_novo" \
  "Descrição do Teste" \
  "$CONFIG_DIR/teste5_novo/yarn-site.xml" \
  "yarn-site.xml"
```

### 3. Documentar em docs/tests.md

```markdown
#### Teste 5: Nova Configuração

**Configuração Alterada:**
...

**Hipótese:**
...

**Métricas Observadas:**
...
```

## 📚 Adicionando Documentação

### Onde colocar:

- **Tutorial/Guia**: `docs/nome.md`
- **API/Referência**: `docs/api.md`
- **Troubleshooting**: Adicionar em `docs/hadoop.md` ou `docs/spark.md`

### Template de Doc:

```markdown
# Título do Documento

## 🎯 Objetivo

Breve descrição...

## 📋 Pré-requisitos

- Item 1
- Item 2

## 🚀 Passo a Passo

### 1. Primeiro Passo

```bash
comando aqui
```

### 2. Segundo Passo

...

## 📚 Referências

- [Link](url)
```

## 🔍 Code Review Checklist

Antes de commitar, verifique:

- [ ] Script tem `set -euo pipefail`
- [ ] Documentação atualizada
- [ ] Nomes de arquivos seguem padrão
- [ ] Não há duplicatas
- [ ] .gitignore cobre novos arquivos temp
- [ ] README.md reflete mudanças
- [ ] Scripts têm permissão de execução (`chmod +x`)

## 🧪 Testando Mudanças

```bash
# Sempre testar antes de commitar
./scripts/verify.sh      # Validar ambiente
./scripts/run_tests.sh   # Executar testes
./scripts/cleanup.sh     # Limpar
```

## 📦 Commits

### Mensagens claras:

```bash
# BOM
git commit -m "feat: adicionar teste de memória customizada"
git commit -m "docs: atualizar guia de troubleshooting Hadoop"
git commit -m "fix: corrigir script de limpeza de datanodes"
git commit -m "refactor: consolidar scripts duplicados"

# RUIM
git commit -m "update"
git commit -m "fix"
git commit -m "teste"
```

### Prefixos:

- `feat:` - Nova funcionalidade
- `fix:` - Correção de bug
- `docs:` - Documentação
- `refactor:` - Refatoração
- `test:` - Testes
- `chore:` - Manutenção

## 🆘 Problemas Comuns

### "Script não executa"
```bash
chmod +x scripts/nome.sh
```

### "Cluster não inicia"
```bash
./scripts/cleanup.sh
./scripts/setup.sh
```

### "Teste falha"
```bash
# Ver logs
docker logs hadoop-master
# Verificar ambiente
./scripts/verify.sh
```

## 💡 Dicas

1. **Use `verify.sh` frequentemente** - Detecta problemas cedo
2. **Leia os logs** - Docker logs são seus amigos
3. **Documente enquanto codifica** - Não deixe para depois
4. **Teste em ambiente limpo** - Use `cleanup.sh` antes de testar
5. **Mantenha commits pequenos** - Mais fácil de revisar

## 📞 Suporte

- Issues: GitHub Issues
- Documentação: [`docs/`](docs/)
- Exemplos: Veja scripts existentes em [`scripts/`](scripts/)

---

**Mantenha o código limpo! 🧹✨**
