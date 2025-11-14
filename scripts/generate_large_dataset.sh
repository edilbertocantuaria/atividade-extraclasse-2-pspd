#!/bin/bash
set -euo pipefail

# ============================================================================
# GENERATE LARGE DATASET - Gerar dataset massivo para testes de longa duração
# ============================================================================
# Gera dataset que garante execução de 3-4+ minutos no cluster
# ============================================================================

DATASET_SIZE_MB=${1:-500}  # Tamanho em MB (padrão: 500MB = ~4-5min)
OUTPUT_DIR="/tmp/hadoop_large_dataset"
HDFS_INPUT_PATH="/user/hadoop/input"

echo "=================================================="
echo "Gerando dataset massivo: ${DATASET_SIZE_MB}MB"
echo "=================================================="

# Criar diretório temporário
mkdir -p "$OUTPUT_DIR"
rm -f "$OUTPUT_DIR"/*.txt

# Biblioteca de palavras expandida (500+ palavras)
WORDS=(
    # Tecnologia Big Data
    "hadoop" "mapreduce" "yarn" "hdfs" "spark" "distributed" "computing" 
    "cluster" "node" "worker" "master" "namenode" "datanode" "resourcemanager"
    "nodemanager" "jobtracker" "tasktracker" "hive" "pig" "hbase" "cassandra"
    "mongodb" "elasticsearch" "kafka" "storm" "flink" "beam" "airflow"
    
    # Conceitos de computação
    "algorithm" "data" "structure" "processing" "parallel" "concurrent"
    "synchronization" "thread" "process" "cache" "memory" "disk" "network"
    "bandwidth" "latency" "throughput" "scalability" "performance" "optimization"
    "partition" "replication" "fault" "tolerance" "consistency" "availability"
    
    # Programação
    "java" "python" "scala" "javascript" "golang" "rust" "cpp" "function"
    "class" "object" "interface" "method" "variable" "constant" "array" "list"
    "map" "reduce" "filter" "lambda" "closure" "iterator" "generator" "async"
    
    # Palavras comuns (aumentar variabilidade)
    "the" "and" "for" "are" "but" "not" "you" "all" "can" "her" "was" "one"
    "our" "out" "day" "get" "has" "him" "his" "how" "its" "may" "new" "now"
    "old" "see" "two" "who" "boy" "did" "car" "eat" "far" "fun" "let" "put"
    "run" "top" "toy" "try" "use" "big" "hot" "red" "blue" "green" "fast"
)

# Calcular número de arquivos (múltiplos arquivos para melhor paralelização)
NUM_FILES=10
FILE_SIZE_MB=$((DATASET_SIZE_MB / NUM_FILES))
LINES_PER_FILE=$((FILE_SIZE_MB * 1024 * 1024 / 100))  # ~100 bytes por linha

echo "Gerando $NUM_FILES arquivos com ~${FILE_SIZE_MB}MB cada..."
echo "~${LINES_PER_FILE} linhas por arquivo"
echo ""

# Gerar arquivos em paralelo
for file_idx in $(seq 1 $NUM_FILES); do
    (
        OUTPUT_FILE="$OUTPUT_DIR/dataset_part_$(printf "%03d" $file_idx).txt"
        echo "Gerando arquivo $file_idx/$NUM_FILES..."
        
        > "$OUTPUT_FILE"
        for ((i=1; i<=LINES_PER_FILE; i++)); do
            # Gerar linha com 8-20 palavras aleatórias
            num_words=$((8 + RANDOM % 13))
            line=""
            for ((j=1; j<=num_words; j++)); do
                word="${WORDS[$((RANDOM % ${#WORDS[@]}))]}"
                line="$line $word"
            done
            echo "$line" >> "$OUTPUT_FILE"
            
            # Progress indicator a cada 10000 linhas
            if ((i % 10000 == 0)); then
                echo "  Arquivo $file_idx: $i/$LINES_PER_FILE linhas"
            fi
        done
        
        echo "✓ Arquivo $file_idx completo: $(du -h "$OUTPUT_FILE" | cut -f1)"
    ) &
done

# Aguardar todos os processos
wait

# Estatísticas
TOTAL_SIZE=$(du -sh "$OUTPUT_DIR" | cut -f1)
TOTAL_FILES=$(ls -1 "$OUTPUT_DIR"/*.txt | wc -l)
TOTAL_LINES=$(wc -l "$OUTPUT_DIR"/*.txt | tail -1 | awk '{print $1}')
TOTAL_WORDS=$(wc -w "$OUTPUT_DIR"/*.txt | tail -1 | awk '{print $1}')

echo ""
echo "=================================================="
echo "Dataset gerado com sucesso!"
echo "=================================================="
echo "Total de arquivos: $TOTAL_FILES"
echo "Tamanho total: $TOTAL_SIZE"
echo "Total de linhas: $TOTAL_LINES"
echo "Total de palavras: $TOTAL_WORDS"
echo ""

# Copiar para HDFS
echo "Copiando para HDFS: $HDFS_INPUT_PATH"
echo ""

docker exec hadoop-master bash -c "su - hadoop -c '
  /home/hadoop/hadoop/bin/hdfs dfs -rm -r -f $HDFS_INPUT_PATH 2>/dev/null || true
  /home/hadoop/hadoop/bin/hdfs dfs -mkdir -p $HDFS_INPUT_PATH
'"

# Copiar todos os arquivos
for file in "$OUTPUT_DIR"/*.txt; do
    filename=$(basename "$file")
    echo "  Copiando $filename..."
    docker cp "$file" hadoop-master:/tmp/"$filename"
    docker exec hadoop-master bash -c "chown hadoop:hadoop /tmp/$filename"
    docker exec hadoop-master bash -c "su - hadoop -c '/home/hadoop/hadoop/bin/hdfs dfs -put /tmp/$filename $HDFS_INPUT_PATH/'"
    docker exec hadoop-master bash -c "rm /tmp/$filename"
done

# Verificar HDFS
echo ""
echo "Verificando arquivos no HDFS:"
docker exec hadoop-master bash -c "su - hadoop -c '/home/hadoop/hadoop/bin/hdfs dfs -ls -h $HDFS_INPUT_PATH'"

echo ""
echo "✅ Dataset massivo pronto para uso!"
echo ""
echo "Estimativa de tempo de execução: 3-5 minutos"
echo "Para executar: ./scripts/run_wordcount.sh"
