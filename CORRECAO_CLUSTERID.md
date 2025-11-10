# Correção Crítica: Incompatibilidade de ClusterID nos DataNodes

## Problema Identificado

**Erro:** `Incompatible clusterIDs` - DataNodes não conseguiam se conectar ao NameNode

```
java.io.IOException: Incompatible clusterIDs in /tmp/hadoop-hadoop/dfs/data: 
namenode clusterID = CID-19cbaf8b-fddc-4926-adfd-c8c8dccf675e
datanode clusterID = CID-66904f48-d7ee-47b2-9c67-abec472a078d
```

## Causa Raiz

Quando formatamos o NameNode com `hdfs namenode -format -force`, um novo **clusterID** é gerado. Porém, os DataNodes nos workers mantinham o clusterID antigo em `/tmp/hadoop-hadoop/dfs/data`, causando incompatibilidade.

## Solução Implementada

### 1. Script de Limpeza dos DataNodes

Criado: `scripts/limpar_datanodes.sh`

```bash
#!/bin/bash

echo "🧹 Limpando dados antigos dos DataNodes..."

for worker in worker1 worker2; do
    echo "Limpando dados do $worker..."
    docker exec hadoop-$worker bash -c "rm -rf /tmp/hadoop-hadoop/dfs/data/*"
    echo "✅ $worker limpo"
done
```

### 2. Integração nos Scripts Principais

**`scripts/rodar_testes_b1_v2.sh`:**
- Adicionada função `limpar_datanodes()` 
- Chamada após cada `hdfs namenode -format -force`
- Aumentado sleep de 10s para 15s após `start-dfs.sh`

**`corrigir_tudo.sh`:**
- Adicionado passo 4️⃣ para limpar DataNodes após reinicialização

### 3. Sequência Correta de Inicialização

```bash
# 1. Formatar NameNode (gera novo clusterID)
hdfs namenode -format -force

# 2. Limpar dados antigos dos DataNodes
limpar_datanodes

# 3. Iniciar HDFS (DataNodes se registram com novo clusterID)
start-dfs.sh

# 4. Aguardar estabilização (15 segundos)
sleep 15
```

## Validação da Correção

Após aplicar a correção:

```bash
# Antes (DataNodes NÃO iniciavam)
$ docker exec hadoop-worker1 jps
378 NodeManager
848 Jps

# Depois (DataNodes INICIANDO corretamente)
$ docker exec hadoop-worker1 jps  
378 NodeManager
990 DataNode  ← ✅ SUCESSO!
1064 Jps

# HDFS Report
$ hdfs dfsadmin -report
Live datanodes (2):  ← ✅ 2 DataNodes ativos!
```

## Impacto

✅ **Todos os 4 testes B1 agora devem executar corretamente:**
- Teste 1: Memória YARN
- Teste 2: Replicação HDFS  
- Teste 3: Block Size HDFS
- Teste 4: Número de Reducers

## Arquivos Modificados

- `scripts/limpar_datanodes.sh` (novo)
- `scripts/rodar_testes_b1_v2.sh` (atualizado)
- `corrigir_tudo.sh` (atualizado)

---

**Data:** 10/11/2025  
**Resolução:** Completa  
**Status:** ✅ Pronto para execução
