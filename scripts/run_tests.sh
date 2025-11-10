#!/bin/bash
set -euo pipefail

# ============================================================================
# RUN TESTS - Executar todos os testes B1 do Hadoop
# ============================================================================

ROOT_DIR="/home/edilberto/pspd/atividade-extraclasse-2-pspd"
HADOOP_DIR="$ROOT_DIR/hadoop"
RESULTS_DIR="$ROOT_DIR/resultados/B1"
CONFIG_DIR="$ROOT_DIR/config"
DATASET_SCRIPT="$ROOT_DIR/scripts/generate_dataset.sh"
WORDCOUNT_SCRIPT="$ROOT_DIR/scripts/run_wordcount.sh"

mkdir -p "$RESULTS_DIR"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${YELLOW}╔════════════════════════════════════════╗${NC}"
echo -e "${YELLOW}║   Executando Testes B1 - Hadoop       ║${NC}"
echo -e "${YELLOW}╚════════════════════════════════════════╝${NC}"
echo ""

# ============================================================================
# FUNÇÕES AUXILIARES
# ============================================================================

limpar_processos() {
  echo -e "${YELLOW}🧹 Limpando processos Java...${NC}"
  for node in worker1 worker2 master; do
    docker exec -u hadoop "hadoop-$node" bash -c 'pkill -9 java 2>/dev/null || true' 2>/dev/null || true
  done
  sleep 2
}

copiar_config() {
  local config_source="$1"
  local config_file="$2"
  local nodes="$3"
  
  echo -e "  📄 Copiando $config_file..."
  for node in $nodes; do
    docker cp "$config_source" "hadoop-$node:/home/hadoop/hadoop/etc/hadoop/$config_file"
    docker exec "hadoop-$node" chown hadoop:hadoop "/home/hadoop/hadoop/etc/hadoop/$config_file"
  done
}

limpar_datanodes() {
  echo -e "${YELLOW}🧹 Limpando dados dos DataNodes...${NC}"
  for worker in worker1 worker2; do
    docker exec "hadoop-$worker" bash -c "rm -rf /tmp/hadoop-hadoop/dfs/data/*" 2>/dev/null || true
  done
}

iniciar_cluster() {
  echo -e "${GREEN}▶ Formatando e iniciando HDFS/YARN...${NC}"
  docker exec hadoop-master bash -c "
    hdfs namenode -format -force -clusterId hadoop-cluster &&
    start-dfs.sh &&
    start-yarn.sh
  "
  sleep 10
  
  echo -e "${GREEN}▶ Criando diretórios HDFS...${NC}"
  docker exec hadoop-master bash -c "
    hdfs dfs -mkdir -p /user/hadoop/input &&
    hdfs dfs -mkdir -p /user/hadoop/output
  " 2>/dev/null || true
}

executar_teste() {
  local test_name="$1"
  local test_desc="$2"
  local config_file="$3"
  local config_target="$4"
  local test_dir="$RESULTS_DIR/$test_name"
  
  mkdir -p "$test_dir"
  
  echo ""
  echo -e "${GREEN}═══════════════════════════════════════${NC}"
  echo -e "${GREEN}  TESTE: $test_desc${NC}"
  echo -e "${GREEN}═══════════════════════════════════════${NC}"
  
  # Limpar processos e dados
  limpar_processos
  limpar_datanodes
  
  # Copiar configuração específica do teste
  copiar_config "$config_file" "$config_target" "master worker1 worker2"
  
  # Iniciar cluster
  iniciar_cluster
  
  # Gerar dataset
  echo -e "${YELLOW}📊 Gerando dataset...${NC}"
  bash "$DATASET_SCRIPT"
  
  # Executar WordCount
  echo -e "${YELLOW}🔄 Executando WordCount...${NC}"
  START_TIME=$(date +%s)
  
  if bash "$WORDCOUNT_SCRIPT" > "$test_dir/job_output.txt" 2>&1; then
    END_TIME=$(date +%s)
    ELAPSED=$((END_TIME - START_TIME))
    
    # Extrair métricas
    echo -e "${GREEN}✅ Teste concluído em ${ELAPSED}s${NC}"
    
    cat > "$test_dir/resumo.txt" <<EOF
==============================================
TESTE: $test_desc
==============================================

Configuração: $config_file
Tempo Total: ${ELAPSED}s
Status: SUCESSO

Métricas do Job:
EOF
    
    # Anexar output do job
    cat "$test_dir/job_output.txt" >> "$test_dir/resumo.txt"
    
  else
    echo -e "${RED}❌ Teste falhou!${NC}"
    echo "ERRO - Ver job_output.txt" > "$test_dir/resumo.txt"
  fi
  
  # Limpar output HDFS para próximo teste
  docker exec hadoop-master bash -c "hdfs dfs -rm -r -f /user/hadoop/output/*" 2>/dev/null || true
}

# ============================================================================
# EXECUTAR TODOS OS TESTES
# ============================================================================

echo -e "${YELLOW}⚙️  Verificando ambiente...${NC}"
if ! docker ps | grep -q hadoop-master; then
  echo -e "${RED}❌ Cluster não está rodando. Execute ./scripts/setup.sh primeiro!${NC}"
  exit 1
fi

# Teste 1: Memória YARN
executar_teste \
  "teste1_memoria" \
  "Alteração de Memória YARN (1024MB)" \
  "$CONFIG_DIR/teste1_memoria/yarn-site.xml" \
  "yarn-site.xml"

# Teste 2: Replicação HDFS
executar_teste \
  "teste2_replicacao" \
  "Alteração de Replicação HDFS (1 réplica)" \
  "$CONFIG_DIR/teste2_replicacao/hdfs-site.xml" \
  "hdfs-site.xml"

# Teste 3: Block Size
executar_teste \
  "teste3_blocksize" \
  "Alteração de Block Size (64MB)" \
  "$CONFIG_DIR/teste3_blocksize/hdfs-site.xml" \
  "hdfs-site.xml"

# Teste 4: Número de Reducers
executar_teste \
  "teste4_reducers" \
  "Alteração de Reducers (4 reducers)" \
  "$CONFIG_DIR/teste4_reducers/mapred-site.xml" \
  "mapred-site.xml"

# ============================================================================
# GERAR RELATÓRIO COMPARATIVO
# ============================================================================

echo ""
echo -e "${GREEN}═══════════════════════════════════════${NC}"
echo -e "${GREEN}  Gerando Relatório Comparativo${NC}"
echo -e "${GREEN}═══════════════════════════════════════${NC}"

cat > "$RESULTS_DIR/resumo_comparativo.txt" <<EOF
============================================
RESUMO COMPARATIVO - TESTES B1 HADOOP
============================================
Data: $(date '+%Y-%m-%d %H:%M:%S')

EOF

for test in teste1_memoria teste2_replicacao teste3_blocksize teste4_reducers; do
  if [ -f "$RESULTS_DIR/$test/resumo.txt" ]; then
    echo "---" >> "$RESULTS_DIR/resumo_comparativo.txt"
    head -20 "$RESULTS_DIR/$test/resumo.txt" >> "$RESULTS_DIR/resumo_comparativo.txt"
    echo "" >> "$RESULTS_DIR/resumo_comparativo.txt"
  fi
done

echo ""
echo -e "${GREEN}✅ Todos os testes concluídos!${NC}"
echo ""
echo -e "${YELLOW}Resultados salvos em:${NC} $RESULTS_DIR"
echo -e "${YELLOW}Resumo comparativo:${NC} $RESULTS_DIR/resumo_comparativo.txt"
echo ""
