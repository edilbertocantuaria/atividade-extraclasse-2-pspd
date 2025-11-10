#!/bin/bash
set -euo pipefail

# ==========================
# CONFIGURAÇÕES GERAIS
# ==========================
ROOT_DIR="/home/edilberto/pspd/atividade-extraclasse-2-pspd"
HADOOP_DIR="$ROOT_DIR/hadoop"
SCRIPTS_DIR="$ROOT_DIR/scripts"
RESULTS_DIR="$ROOT_DIR/resultados/B1"
DATASET_SCRIPT="$SCRIPTS_DIR/gerar_dataset_v2.sh"
WORDCOUNT_SCRIPT="$SCRIPTS_DIR/executar_wordcount_teste.sh"
FALHA_SCRIPT="$SCRIPTS_DIR/testar_falha_worker1.sh"
VALIDAR_XML_SCRIPT="$SCRIPTS_DIR/validar_config_xml.sh"

mkdir -p "$RESULTS_DIR"

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'

# ==========================
# VALIDAÇÃO INICIAL
# ==========================
echo -e "${YELLOW}🔍 Validando arquivos de configuração XML...${NC}"
if bash "$VALIDAR_XML_SCRIPT"; then
  echo -e "${GREEN}✅ Arquivos XML validados com sucesso${NC}\n"
else
  echo -e "${RED}❌ Erro na validação dos arquivos XML${NC}"
  echo -e "${RED}   Corrija os erros antes de continuar${NC}"
  exit 1
fi

# ==========================
# FUNÇÕES AUXILIARES
# ==========================

limpar_processos() {
  echo -e "${YELLOW}🧹 Limpando processos do Hadoop...${NC}"
  
  # Forçar kill dos NodeManagers em todos os workers
  for node in worker1 worker2; do
    docker exec -u hadoop hadoop-$node bash -c 'pkill -9 -f "NodeManager" 2>/dev/null || true; pkill -9 -f "DataNode" 2>/dev/null || true; pkill -9 java 2>/dev/null || true' 2>/dev/null || true
  done
  
  # Limpar também no master
  docker exec -u hadoop hadoop-master bash -c 'pkill -9 -f "ResourceManager" 2>/dev/null || true; pkill -9 -f "NameNode" 2>/dev/null || true; pkill -9 -f "SecondaryNameNode" 2>/dev/null || true; pkill -9 java 2>/dev/null || true' 2>/dev/null || true
  
  sleep 2
  echo -e "${GREEN}✅ Processos limpos${NC}"
}

reiniciar_cluster() {
  echo -e "${YELLOW}🔄 Reiniciando cluster Hadoop...${NC}"
  
  # Limpar processos primeiro
  limpar_processos
  
  cd "$HADOOP_DIR"
  docker compose down -v --remove-orphans
  docker compose up -d
  sleep 15
  docker exec -u hadoop hadoop-master bash -c "hdfs namenode -format && start-dfs.sh && start-yarn.sh"
}

# Forçar JAVA_HOME em todos os contêineres Hadoop
for node in master worker1 worker2; do
  docker exec -u hadoop hadoop-$node bash -c '
    echo "export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64" >> ~/.bashrc
    echo "export PATH=$PATH:$JAVA_HOME/bin" >> ~/.bashrc
  '
done


run_wordcount_test() {
  local label="$1"
  local config_desc="$2"
  local output_dir="$RESULTS_DIR/${label}"
  mkdir -p "$output_dir"

  echo -e "${YELLOW}▶ Executando ${label}...${NC}"
  
  # Executar o teste e capturar a saída
  bash "$WORDCOUNT_SCRIPT" 2>&1 | tee "$output_dir/output.log"
  
  # Copiar resultados detalhados do último teste para o diretório específico
  LATEST_RESULT=$(ls -td ./resultados/execucao_* 2>/dev/null | head -1)
  if [ -n "$LATEST_RESULT" ] && [ -d "$LATEST_RESULT" ]; then
    echo "Copiando resultados detalhados..."
    cp -r "$LATEST_RESULT"/* "$output_dir/" 2>/dev/null || true
    rm -rf "$LATEST_RESULT"
  fi

  # Criar resumo consolidado
  {
    echo "=============================="
    echo "  TESTE: $label"
    echo "=============================="
    echo ""
    echo "Configuração testada: $config_desc"
    echo ""
    
    if [ -f "$output_dir/relatorio.txt" ]; then
      cat "$output_dir/relatorio.txt"
    else
      echo "⚠ Relatório detalhado não disponível"
    fi
  } > "$output_dir/resumo.txt"
  
  echo -e "${GREEN}✅ Teste ${label} concluído${NC}"
  echo -e "📄 Resultados em: $output_dir/resumo.txt\n"
}

# ==========================
# EXECUÇÃO SEQUENCIAL DOS TESTES
# ==========================
reiniciar_cluster

# TESTE 1 - MEMÓRIA
echo -e "${YELLOW}🧠 Teste 1 - Alteração de Memória${NC}"

# Limpar processos YARN antes de reconfigurar
limpar_processos

docker exec -u hadoop hadoop-master bash -c '
  YARN_SITE="/home/hadoop/hadoop/etc/hadoop/yarn-site.xml"
  sed -i "/<name>yarn.nodemanager.resource.memory-mb<\/name>/,/<\/property>/d" $YARN_SITE
  sed -i "s|</configuration>|  <property>\n    <name>yarn.nodemanager.resource.memory-mb</name>\n    <value>1024</value>\n  </property>\n</configuration>|" $YARN_SITE
  
  # Aguardar um pouco antes de reiniciar
  sleep 3
  start-yarn.sh
'

sleep 5
bash "$DATASET_SCRIPT"
run_wordcount_test "teste1_memoria" "yarn.nodemanager.resource.memory-mb=1024"

# TESTE 2 - REPLICAÇÃO
echo -e "${YELLOW}📦 Teste 2 - Fator de replicação${NC}"

# Limpar processos HDFS antes de reconfigurar
limpar_processos

for node in master worker1 worker2; do
  docker exec -u hadoop hadoop-$node bash -c '
    HDFS_SITE="/home/hadoop/hadoop/etc/hadoop/hdfs-site.xml"
    sed -i "/<name>dfs.replication<\/name>/,/<\/property>/d" $HDFS_SITE
    sed -i "s|</configuration>|  <property>\n    <name>dfs.replication</name>\n    <value>1</value>\n  </property>\n</configuration>|" $HDFS_SITE
  '
done

sleep 3
docker exec -u hadoop hadoop-master bash -c "start-dfs.sh"
sleep 5

bash "$DATASET_SCRIPT"
run_wordcount_test "teste2_replicacao" "dfs.replication=1"

# TESTE 3 - BLOCKSIZE
echo -e "${YELLOW}🧩 Teste 3 - Blocksize${NC}"

# Limpar processos HDFS antes de reconfigurar
limpar_processos

for node in master worker1 worker2; do
  docker exec -u hadoop hadoop-$node bash -c '
    HDFS_SITE="/home/hadoop/hadoop/etc/hadoop/hdfs-site.xml"
    sed -i "/<name>dfs.blocksize<\/name>/,/<\/property>/d" $HDFS_SITE
    sed -i "s|</configuration>|  <property>\n    <name>dfs.blocksize</name>\n    <value>67108864</value>\n  </property>\n</configuration>|" $HDFS_SITE
  '
done

sleep 3
docker exec -u hadoop hadoop-master bash -c "start-dfs.sh"
sleep 5

bash "$DATASET_SCRIPT"
run_wordcount_test "teste3_blocksize" "dfs.blocksize=64MB"

# TESTE 4 - REDUCERS
echo -e "${YELLOW}⚙️  Teste 4 - Número de reducers${NC}"
docker exec -u hadoop hadoop-master bash -c '
  MAPRED_SITE="/home/hadoop/hadoop/etc/hadoop/mapred-site.xml"
  sed -i "/<name>mapreduce.job.reduces<\/name>/,/<\/property>/d" $MAPRED_SITE
  sed -i "s|</configuration>|  <property>\n    <name>mapreduce.job.reduces</name>\n    <value>4</value>\n  </property>\n</configuration>|" $MAPRED_SITE
'
bash "$DATASET_SCRIPT"
run_wordcount_test "teste4_reducers" "mapreduce.job.reduces=4"

# TESTE 5 - TOLERÂNCIA A FALHAS
echo -e "${YELLOW}💥 Teste 5 - Falha controlada no worker1${NC}"
bash "$FALHA_SCRIPT" | tee "$RESULTS_DIR/teste5_falha_worker1/output.log"
echo "Configuração: desligamento do worker1 durante execução" > "$RESULTS_DIR/teste5_falha_worker1/resumo.txt"

# ==========================
# RESUMO FINAL
# ==========================
echo -e "${YELLOW}🧾 Gerando resumo final consolidado...${NC}"

{
  echo "========================================================================="
  echo "           RELATÓRIO CONSOLIDADO - TESTES HADOOP (B1)"
  echo "========================================================================="
  echo ""
  echo "Data de execução: $(date)"
  echo "Diretório de resultados: $RESULTS_DIR"
  echo ""
  
  for test_dir in "$RESULTS_DIR"/teste*; do
    if [ -d "$test_dir" ]; then
      test_name=$(basename "$test_dir")
      echo ""
      echo "========================================================================="
      echo "  $test_name"
      echo "========================================================================="
      
      if [ -f "$test_dir/resumo.txt" ]; then
        cat "$test_dir/resumo.txt"
      else
        echo "⚠ Resumo não disponível para este teste"
      fi
      echo ""
    fi
  done
  
  echo "========================================================================="
  echo "                         FIM DO RELATÓRIO"
  echo "========================================================================="
  
} > "$RESULTS_DIR/relatorio_consolidado.txt"

# Gerar também um resumo comparativo simplificado
{
  echo "RESUMO COMPARATIVO DOS TESTES"
  echo "=============================="
  echo ""
  printf "%-25s %-30s %-15s %-20s\n" "TESTE" "CONFIGURAÇÃO" "STATUS" "PALAVRAS ÚNICAS"
  echo "------------------------------------------------------------------------------------"
  
  for test_dir in "$RESULTS_DIR"/teste*; do
    if [ -d "$test_dir" ]; then
      test_name=$(basename "$test_dir")
      
      # Extrair configuração
      config=$(grep "Configuração testada:" "$test_dir/resumo.txt" 2>/dev/null | cut -d: -f2- | xargs || echo "N/A")
      
      # Extrair status
      if grep -q "Status: SUCESSO" "$test_dir/resumo.txt" 2>/dev/null; then
        status="✓ SUCESSO"
      else
        status="✗ FALHA"
      fi
      
      # Extrair número de palavras
      words=$(grep "Palavras únicas encontradas:" "$test_dir/resumo.txt" 2>/dev/null | grep -oP '\d+' || echo "0")
      
      printf "%-25s %-30s %-15s %-20s\n" "$test_name" "$config" "$status" "$words"
    fi
  done
  
} > "$RESULTS_DIR/resumo_comparativo.txt"

echo -e "${GREEN}✅ Todos os testes B1 concluídos!${NC}"
echo -e "📄 Relatório consolidado: ${YELLOW}$RESULTS_DIR/relatorio_consolidado.txt${NC}"
echo -e "📊 Resumo comparativo: ${YELLOW}$RESULTS_DIR/resumo_comparativo.txt${NC}"
echo ""
cat "$RESULTS_DIR/resumo_comparativo.txt"
