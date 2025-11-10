# 🚀 Como Executar os Testes B1 - VERSÃO DEFINITIVA

## ✅ SOLUÇÃO DEFINITIVA IMPLEMENTADA

### 🎯 Problema Raiz Resolvido

O erro **NÃO era só nos XMLs**, mas no **script que usava `sed`** para modificá-los!

**Solução:** Agora usamos **arquivos XML pré-configurados** ao invés de modificar com `sed`.

---

## 📋 Execução Rápida (Recomendado)

No terminal **WSL**:

```bash
cd ~/pspd/atividade-extraclasse-2-pspd
chmod +x *.sh scripts/*.sh
./executar_testes_limpo.sh
```

**Isso vai:**
1. ✅ Limpar processos presos
2. ✅ Validar todos os XMLs
3. ✅ Executar os 4 testes usando XMLs estáticos
4. ✅ Gerar relatórios consolidados

---

## 🔍 O Que Mudou (Versão 3.0)

### Antes (Problemático):
```bash
# Modificava XML com sed - criava tags duplicadas
sed -i "s|</configuration>|<property>...</property></configuration>|"
```

### Agora (Correto):
```bash
# Copia XML pré-configurado - sempre válido
docker cp config/teste1_memoria/yarn-site.xml hadoop-master:/home/hadoop/hadoop/etc/hadoop/
```

### Arquivos Pré-Configurados Criados:

```
config/
├── teste1_memoria/yarn-site.xml       ← memory-mb=1024
├── teste2_replicacao/hdfs-site.xml    ← replication=1
├── teste3_blocksize/hdfs-site.xml     ← blocksize=64MB
└── teste4_reducers/mapred-site.xml    ← reduces=4
```

## 📊 O que foi melhorado

### Scripts Modificados:

1. **`limpar_processos.sh`** (NOVO)
   - Mata todos os processos Java do Hadoop
   - Evita o erro "Unable to kill 161"
   
2. **`rodar_testes_b1.sh`**
   - Chama `limpar_processos()` antes de cada teste
   - Remove os comandos `stop-yarn.sh` e `stop-dfs.sh` problemáticos
   - Adiciona delays entre operações
   - Usa apenas `start-*` após limpar processos

3. **`executar_wordcount_teste.sh`**
   - Captura métricas detalhadas do MapReduce
   - Gera relatórios completos com:
     - Configurações do cluster
     - Tempo de execução
     - Uso de CPU/memória
     - Contadores do Hadoop
     - Top 10 palavras mais frequentes
     - Estatísticas do HDFS

## 📁 Estrutura de Resultados

Após a execução, você terá:

```
resultados/B1/
├── teste1_memoria/
│   ├── resumo.txt              ← Resumo completo
│   ├── relatorio.txt           ← Métricas detalhadas
│   ├── job_output.txt          ← Output do MapReduce
│   ├── yarn_logs.txt           ← Logs do YARN
│   └── ...
├── teste2_replicacao/
├── teste3_blocksize/
├── teste4_reducers/
├── teste5_falha_worker1/
├── relatorio_consolidado.txt   ← TODOS os testes juntos
└── resumo_comparativo.txt      ← Tabela comparativa
```

## 🔍 Verificar Resultados

```bash
# Ver resumo comparativo
cat resultados/B1/resumo_comparativo.txt

# Ver relatório completo
cat resultados/B1/relatorio_consolidado.txt

# Ver teste específico
cat resultados/B1/teste1_memoria/resumo.txt
```

## 🐛 Solução de Problemas

### Erro: "Unexpected close tag </configuration>"

Este erro indica XML mal formatado. **Solução:**

```bash
# 1. Validar todos os XMLs
./scripts/validar_config_xml.sh

# 2. Verificar qual arquivo tem erro
#    O erro mostrará o arquivo e a linha, ex:
#    [row,col,system-id]: [16,15,"file:/home/hadoop/hadoop/etc/hadoop/yarn-site.xml"]
#    Isso significa: linha 16, coluna 15, arquivo yarn-site.xml

# 3. Editar manualmente o arquivo problemático
#    Procure por tags <property> não fechadas ou duplicadas
#    Exemplo de erro comum:
#      <property>      ← Tag aberta
#      <property>      ← Tag duplicada (ERRO!)
#        <name>...</name>
#        <value>...</value>
#      </property>     ← Fecha apenas uma

# 4. Após corrigir, validar novamente
./scripts/validar_config_xml.sh
```

### Erro: "Unable to kill 161" ou processos presos

```bash
# Limpar manualmente todos os processos
./scripts/limpar_processos.sh

# Reiniciar cluster completamente
cd hadoop
docker compose down -v
docker compose up -d
sleep 10
cd ..
```

### Cluster não inicia após correções

```bash
# Reiniciar cluster completamente
cd ~/pspd/atividade-extraclasse-2-pspd/hadoop
docker compose down -v
docker compose up -d

# Aguardar containers iniciarem
sleep 10

# Validar XMLs
cd ..
./scripts/validar_config_xml.sh

# Executar novamente
./executar_testes_limpo.sh
```

### Validar XMLs instalando xmllint (opcional)

Para uma validação mais rigorosa:

```bash
# No WSL Ubuntu
sudo apt-get update
sudo apt-get install -y libxml2-utils

# Validar um arquivo específico
xmllint --noout hadoop/master/yarn-site.xml
```
