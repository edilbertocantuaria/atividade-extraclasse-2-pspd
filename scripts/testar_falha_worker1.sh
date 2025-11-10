#!/bin/bash
set -euo pipefail

INPUT_DIR="/user/hadoop/wordcount/input"
OUTPUT_DIR="/user/hadoop/wordcount/output_failover_test"
RESULT_DIR="/home/hadoop/failover_test"

echo "[Test] Starting WordCount with worker failure test..."

# Primeiro, limpar resultado anterior se existir
docker exec -u hadoop hadoop-master bash -c "hdfs dfs -rm -r -f $OUTPUT_DIR || true"

# Iniciar o job WordCount em background
docker exec -u hadoop hadoop-master bash -c "
  mkdir -p $RESULT_DIR
  echo '[Test] Starting MapReduce job...'
  time hadoop jar \$HADOOP_HOME/share/hadoop/mapreduce/hadoop-mapreduce-examples-*.jar \
    wordcount $INPUT_DIR $OUTPUT_DIR > $RESULT_DIR/wordcount.log 2>&1 &
  echo \$! > $RESULT_DIR/wordcount.pid
"

# Esperar 10 segundos para o job iniciar
echo "[Test] Waiting 10s for job to start..."
sleep 10

# Capturar o Application ID
APP_ID=$(docker exec -u hadoop hadoop-master bash -c "yarn application -list | grep wordcount | awk '{print \$1}'")
echo "[Test] Job running with Application ID: $APP_ID"

# Parar o worker1
echo "[Test] Stopping hadoop-worker1..."
docker stop hadoop-worker1

# Monitorar o progresso do job
echo "[Test] Monitoring job progress..."
while true; do
  STATUS=$(docker exec -u hadoop hadoop-master bash -c "yarn application -status $APP_ID | grep 'State' | awk '{print \$3}'")
  PROGRESS=$(docker exec -u hadoop hadoop-master bash -c "yarn application -status $APP_ID | grep 'Progress' | awk '{print \$3}'")
  echo "[Test] Status: $STATUS Progress: $PROGRESS"
  if [[ "$STATUS" == "FINISHED" || "$STATUS" == "FAILED" ]]; then
    break
  fi
  sleep 5
done

# Coletar resultados
echo "[Test] Collecting results..."
docker exec -u hadoop hadoop-master bash -c "
  yarn logs -applicationId $APP_ID > $RESULT_DIR/yarn_logs.txt
  echo 'Final Status:' > $RESULT_DIR/results.txt
  yarn application -status $APP_ID >> $RESULT_DIR/results.txt
  echo 'Output Stats:' >> $RESULT_DIR/results.txt
  hdfs dfs -ls $OUTPUT_DIR >> $RESULT_DIR/results.txt
"

# Reiniciar o worker1
echo "[Test] Restarting hadoop-worker1..."
docker start hadoop-worker1

echo "[Test] Test completed. Results in $RESULT_DIR"
