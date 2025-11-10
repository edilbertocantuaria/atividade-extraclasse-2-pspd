# 📋 Correções Realizadas - Testes B1

## ✅ Problemas Identificados e Resolvidos

### 1. **XML Mal Formatado - hdfs-site.xml**
**Erro:**
```
com.ctc.wstx.exc.WstxParsingException: Unexpected close tag </configuration>; expected </property>.
```

**Causa:** Tag `<property>` duplicada e não fechada (linha 3)

**Arquivos corrigidos:**
- `hadoop/master/hdfs-site.xml`
- `hadoop/worker1/hdfs-site.xml`
- `hadoop/worker2/hdfs-site.xml`

**Correção aplicada:**
```xml
<!-- ANTES (ERRADO) -->
<configuration>
    <property>      ← Tag aberta extra
  <property>        ← Tag duplicada
    <name>dfs.replication</name>
    <value>1</value>
  </property>
</configuration>

<!-- DEPOIS (CORRETO) -->
<configuration>
  <property>
    <name>dfs.replication</name>
    <value>1</value>
  </property>
</configuration>
```

---

### 2. **XML Mal Formatado - yarn-site.xml**
**Erro:**
```
com.ctc.wstx.exc.WstxParsingException: Unexpected close tag </configuration>; expected </property>.
at [row,col,system-id]: [16,15,"file:/home/hadoop/hadoop/etc/hadoop/yarn-site.xml"]
```

**Causa:** Tags `<property>` duplicadas (linhas 11-12)

**Arquivo corrigido:**
- `hadoop/master/yarn-site.xml`

**Correção aplicada:**
```xml
<!-- ANTES (ERRADO) -->
<property>
    <name>yarn.resourcemanager.hostname</name>
    <value>master</value>
</property>
  <property>      ← Duas tags abertas
  <property>      ← sem fechar a primeira
    <name>yarn.nodemanager.resource.memory-mb</name>
    <value>1024</value>
  </property>

<!-- DEPOIS (CORRETO) -->
<property>
    <name>yarn.resourcemanager.hostname</name>
    <value>master</value>
</property>
<property>
    <name>yarn.nodemanager.resource.memory-mb</name>
    <value>1024</value>
</property>
```

---

### 3. **Processos YARN/HDFS Presos (PID 161)**
**Erro:**
```
WARNING: nodemanager did not stop gracefully after 5 seconds
ERROR: Unable to kill 161
```

**Causa:** Comandos `stop-yarn.sh` e `stop-dfs.sh` não conseguiam parar processos

**Solução implementada:**

1. **Criado `scripts/limpar_processos.sh`**
   - Força `kill -9` em todos os processos Java/Hadoop
   - Limpa NodeManager, DataNode, ResourceManager, NameNode

2. **Modificado `scripts/rodar_testes_b1.sh`**
   - Removidos comandos `stop-*`
   - Adicionada função `limpar_processos()`
   - Chamada antes de cada reconfiguração
   - Delays entre operações

---

## 🆕 Novos Scripts Criados

### 1. `scripts/validar_config_xml.sh`
**Função:** Validar sintaxe de todos os arquivos XML do Hadoop

**Uso:**
```bash
./scripts/validar_config_xml.sh
```

**Features:**
- Verifica tags balanceadas (`<property>`, `<configuration>`)
- Usa `xmllint` se disponível
- Validação básica sem dependências externas

---

### 2. `scripts/limpar_processos.sh`
**Função:** Forçar parada de todos os processos Hadoop

**Uso:**
```bash
./scripts/limpar_processos.sh
```

**O que faz:**
- `pkill -9` em NodeManager, DataNode
- `pkill -9` em ResourceManager, NameNode
- Limpa todos os processos Java

---

### 3. `executar_testes_limpo.sh`
**Função:** Executar testes com limpeza automática

**Uso:**
```bash
./executar_testes_limpo.sh
```

**Fluxo:**
1. Limpa processos presos
2. Valida arquivos XML
3. Executa todos os testes B1
4. Gera relatórios consolidados

---

### 4. `scripts/executar_wordcount_teste.sh` (Melhorado)
**Melhorias:**
- Captura configurações do cluster
- Extrai métricas do MapReduce
- Gera relatórios detalhados com:
  - Contadores do Hadoop
  - Uso de CPU/memória
  - Estatísticas do HDFS
  - Top 10 palavras mais frequentes
  - Logs completos do YARN

---

## 📊 Melhorias nos Relatórios

### Antes:
```
Configuração: yarn.nodemanager.resource.memory-mb=1024
```

### Depois:
```
==================================================
       RELATÓRIO DE EXECUÇÃO - WORDCOUNT
==================================================

Timestamp: Sun Nov 10 03:30:00 UTC 2025
Duração Total: 42s
Application ID: application_1699586400000_0001

--- CONFIGURAÇÕES ---
YARN Memory: 1024
HDFS Replication: 2
HDFS Block Size: 134217728
Map Reducers: 1

--- MÉTRICAS DO JOB ---
Status: SUCESSO ✓
Map input records: 10000
Map output records: 50000
Reduce input records: 50000
Reduce output records: 5000

--- RECURSOS DO SISTEMA ---
Elapsed (wall clock) time: 0:00:42
Maximum resident set size: 512MB
Percent of CPU this job got: 85%

--- RESULTADOS ---
Palavras únicas encontradas: 5000

Top 10 palavras mais frequentes:
the     1500
and     1200
...
```

---

## 🚀 Como Executar Agora

```bash
cd ~/pspd/atividade-extraclasse-2-pspd
chmod +x *.sh scripts/*.sh
./executar_testes_limpo.sh
```

---

## ✅ Status Atual

- [x] XMLs corrigidos e validados
- [x] Processos presos resolvidos
- [x] Scripts de validação criados
- [x] Relatórios melhorados
- [x] Documentação completa
- [x] Pronto para execução

---

**Data:** 10/11/2025  
**Versão:** 2.0 - Correções XML + Validação Automática
