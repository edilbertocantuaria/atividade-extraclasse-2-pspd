#!/bin/bash
set -euo pipefail

# ============================================================================
# RUN WORDCOUNT - Executar job MapReduce WordCount
# ============================================================================

HADOOP_EXAMPLES="/home/hadoop/hadoop/share/hadoop/mapreduce/hadoop-mapreduce-examples-3.3.6.jar"
INPUT_PATH="/user/hadoop/input"
OUTPUT_PATH="/user/hadoop/output/wordcount_$(date +%Y%m%d_%H%M%S)"

echo "Executando WordCount..."
echo "  Input: $INPUT_PATH"
echo "  Output: $OUTPUT_PATH"
echo ""

# Limpar output anterior se existir
docker exec hadoop-master bash -c "su - hadoop -c '/home/hadoop/hadoop/bin/hdfs dfs -rm -r -f $OUTPUT_PATH 2>/dev/null || true'"

# Executar WordCount
docker exec hadoop-master bash -c "su - hadoop -c '
  /home/hadoop/hadoop/bin/hadoop jar $HADOOP_EXAMPLES wordcount $INPUT_PATH $OUTPUT_PATH
'"

# Mostrar resultado
echo ""
echo "✅ WordCount concluído!"
echo ""
echo "Top 10 palavras mais frequentes:"
docker exec hadoop-master bash -c "su - hadoop -c '/home/hadoop/hadoop/bin/hdfs dfs -cat $OUTPUT_PATH/part-r-00000 2>/dev/null | sort -k2 -nr | head -10'"
