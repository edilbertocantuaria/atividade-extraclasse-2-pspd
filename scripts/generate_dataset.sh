#!/bin/bash
set -euo pipefail

# ============================================================================
# GENERATE DATASET - Gerar dataset para testes WordCount
# ============================================================================

DATASET_SIZE=${1:-10000}  # Número de linhas (padrão: 10000)
OUTPUT_FILE="/tmp/dataset.txt"

echo "Gerando dataset com $DATASET_SIZE linhas..."

# Palavras para o dataset
WORDS=("hadoop" "mapreduce" "yarn" "hdfs" "spark" "distributed" "computing" "big" "data" "cluster" "node" "worker" "master" "java" "processing")

# Gerar arquivo
> "$OUTPUT_FILE"
for ((i=1; i<=DATASET_SIZE; i++)); do
  # Gerar linha com 5-15 palavras aleatórias
  num_words=$((5 + RANDOM % 11))
  line=""
  for ((j=1; j<=num_words; j++)); do
    word="${WORDS[$((RANDOM % ${#WORDS[@]}))]}"
    line="$line $word"
  done
  echo "$line" >> "$OUTPUT_FILE"
done

# Copiar para HDFS
echo "Copiando para HDFS..."
docker exec hadoop-master bash -c "
  hdfs dfs -rm -r -f /user/hadoop/input/* 2>/dev/null || true
  hdfs dfs -mkdir -p /user/hadoop/input
"

docker cp "$OUTPUT_FILE" hadoop-master:/tmp/dataset.txt
docker exec hadoop-master bash -c "hdfs dfs -put -f /tmp/dataset.txt /user/hadoop/input/"

echo "✅ Dataset gerado e copiado para HDFS: /user/hadoop/input/dataset.txt"
