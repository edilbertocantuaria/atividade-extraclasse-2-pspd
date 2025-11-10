#!/bin/bash
set -euo pipefail

# ============================================================================
# SCRIPT DE TESTES B1 - VERSÃO DEFINITIVA SEM SED
# ============================================================================
# Este script usa arquivos XML pré-configurados ao invés de modificá-los
# com sed, evitando erros de parsing XML.
# ============================================================================

ROOT_DIR="/home/edilberto/pspd/atividade-extraclasse-2-pspd"
HADOOP_DIR="$ROOT_DIR/hadoop"
SCRIPTS_DIR="$ROOT_DIR/scripts"
RESULTS_DIR="$ROOT_DIR/resultados/B1"
CONFIG_DIR="$ROOT_DIR/config"
DATASET_SCRIPT="$SCRIPTS_DIR/gerar_dataset_v2.sh"
WORDCOUNT_SCRIPT="$SCRIPTS_DIR/executar_wordcount_teste.sh"

mkdir -p "$RESULTS_DIR"

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'

# ============================================================================
# FUNÇÕES AUXILIARES
# ============================================================================

limpar_processos() {
  echo -e "${YELLOW}🧹 Limpando processos...${NC}"
  for node in worker1 worker2 master; do
    docker exec -u hadoop hadoop-$node bash -c 'pkill -9 java 2>/dev/null || true' 2>/dev/null || true
  done
  sleep 2
}

copiar_config() {
  local config_source="$1"
  local config_file="$2"
  local nodes="$3"
  
  echo "  Copiando $config_file..."
  for node in $nodes; do
    docker cp "$config_source" "hadoop-$node:/home/hadoop/hadoop/etc/hadoop/$config_file"
    docker exec hadoop-$node chown hadoop:hadoop "/home/hadoop/hadoop/etc/hadoop/$config_file"
  done
}

reiniciar_cluster() {
  echo -e "${YELLOW}🔄 Reiniciando cluster...${NC}"
  limpar_processos
  cd "$HADOOP_DIR"
  docker compose down -v
  docker compose up -d
  sleep 20
  
  echo "Formatando HDFS..."
  docker exec -u hadoop hadoop-master bash -c "hdfs namenode -format -force" 2>&1 | tail -5
  
  echo "Iniciando HDFS..."
  docker exec -u hadoop hadoop-master bash -c "start-dfs.sh" 2>&1 | tail -10
  sleep 10
  
  echo "Iniciando YARN..."
  docker exec -u hadoop hadoop-master bash -c "start-yarn.sh" 2>&1 | tail -10
  sleep 5
  
  echo "Verificando serviços..."
  docker exec -u hadoop hadoop-master bash -c "jps" || echo "⚠ Problema ao verificar processos"
  
  cd "$ROOT_DIR"
}

run_test() {
  local label="$1"
  local config_desc="$2"
  local output_dir="$RESULTS_DIR/${label}"
  mkdir -p "$output_dir"

  echo -e "${YELLOW}▶ ${label}...${NC}"
  bash "$WORDCOUNT_SCRIPT" 2>&1 | tee "$output_dir/output.log"
  
  LATEST=$(ls -td ./resultados/execucao_* 2>/dev/null | head -1)
  if [ -n "$LATEST" ] && [ -d "$LATEST" ]; then
    cp -r "$LATEST"/* "$output_dir/" 2>/dev/null || true
    rm -rf "$LATEST"
  fi

  {
    echo "=============================="
    echo "  TESTE: $label"
    echo "=============================="
    echo "Configuração: $config_desc"
    echo ""
    [ -f "$output_dir/relatorio.txt" ] && cat "$output_dir/relatorio.txt" || echo "⚠ Não disponível"
  } > "$output_dir/resumo.txt"
  
  echo -e "${GREEN}✅ Concluído${NC}\n"
}

# ============================================================================
# EXECUÇÃO DOS TESTES
# ============================================================================

reiniciar_cluster

# Aguardar cluster estar totalmente pronto
echo "Aguardando cluster estabilizar..."
sleep 10

# Verificar HDFS está ativo
echo "Verificando HDFS..."
docker exec -u hadoop hadoop-master bash -c "hdfs dfsadmin -report" | head -20 || {
  echo "⚠ HDFS não está respondendo corretamente"
}

# TESTE 1 - MEMÓRIA
echo -e "${YELLOW}🧠 Teste 1 - Memória${NC}"
echo "  Parando YARN..."
docker exec -u hadoop hadoop-master bash -c "stop-yarn.sh" 2>/dev/null || limpar_processos
sleep 3

echo "  Atualizando configuração..."
copiar_config "$CONFIG_DIR/teste1_memoria/yarn-site.xml" "yarn-site.xml" "master worker1 worker2"
sleep 2

echo "  Iniciando YARN..."
docker exec -u hadoop hadoop-master bash -c "start-yarn.sh"
sleep 10

bash "$DATASET_SCRIPT"
run_test "teste1_memoria" "yarn.nodemanager.resource.memory-mb=1024"

# TESTE 2 - REPLICAÇÃO
echo -e "${YELLOW}📦 Teste 2 - Replicação${NC}"
echo "  Parando HDFS..."
docker exec -u hadoop hadoop-master bash -c "stop-dfs.sh" 2>/dev/null || limpar_processos
sleep 3

echo "  Atualizando configuração..."
copiar_config "$CONFIG_DIR/teste2_replicacao/hdfs-site.xml" "hdfs-site.xml" "master worker1 worker2"
sleep 2

echo "  Formatando e iniciando HDFS..."
docker exec -u hadoop hadoop-master bash -c "hdfs namenode -format -force && start-dfs.sh"
sleep 10

bash "$DATASET_SCRIPT"
run_test "teste2_replicacao" "dfs.replication=1"

# TESTE 3 - BLOCKSIZE  
echo -e "${YELLOW}🧩 Teste 3 - Blocksize${NC}"
echo "  Parando HDFS..."
docker exec -u hadoop hadoop-master bash -c "stop-dfs.sh" 2>/dev/null || limpar_processos
sleep 3

echo "  Atualizando configuração..."
copiar_config "$CONFIG_DIR/teste3_blocksize/hdfs-site.xml" "hdfs-site.xml" "master worker1 worker2"
sleep 2

echo "  Formatando e iniciando HDFS..."
docker exec -u hadoop hadoop-master bash -c "hdfs namenode -format -force && start-dfs.sh"
sleep 10

bash "$DATASET_SCRIPT"
run_test "teste3_blocksize" "dfs.blocksize=64MB"

# TESTE 4 - REDUCERS
echo -e "${YELLOW}⚙️  Teste 4 - Reducers${NC}"
echo "  Atualizando configuração..."
copiar_config "$CONFIG_DIR/teste4_reducers/mapred-site.xml" "mapred-site.xml" "master worker1 worker2"

bash "$DATASET_SCRIPT"
run_test "teste4_reducers" "mapreduce.job.reduces=4"

# ============================================================================
# RESUMO FINAL
# ============================================================================

{
  echo "========================================================================"
  echo "           RELATÓRIO - TESTES HADOOP (B1)"
  echo "========================================================================"
  echo "Data: $(date)"
  echo ""
  
  for dir in "$RESULTS_DIR"/teste*; do
    [ -d "$dir" ] || continue
    echo "========== $(basename "$dir") =========="
    [ -f "$dir/resumo.txt" ] && cat "$dir/resumo.txt" || echo "N/A"
    echo ""
  done
} > "$RESULTS_DIR/relatorio_consolidado.txt"

{
  echo "RESUMO COMPARATIVO"
  echo "==================" 
  printf "%-25s %-30s %-15s\n" "TESTE" "CONFIGURAÇÃO" "STATUS"
  echo "----------------------------------------------------------------------"
  
  for dir in "$RESULTS_DIR"/teste*; do
    [ -d "$dir" ] || continue
    name=$(basename "$dir")
    config=$(grep "Configuração:" "$dir/resumo.txt" 2>/dev/null | cut -d: -f2- | xargs || echo "N/A")
    status=$(grep -q "SUCESSO" "$dir/resumo.txt" 2>/dev/null && echo "✓ OK" || echo "✗ ERRO")
    printf "%-25s %-30s %-15s\n" "$name" "$config" "$status"
  done
} > "$RESULTS_DIR/resumo_comparativo.txt"

echo -e "${GREEN}✅ Testes concluídos!${NC}"
cat "$RESULTS_DIR/resumo_comparativo.txt"
