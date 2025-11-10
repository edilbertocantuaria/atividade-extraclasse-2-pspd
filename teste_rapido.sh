#!/bin/bash

echo "=========================================="
echo "  TESTE RÁPIDO - VERIFICAR DATANODES"
echo "=========================================="
echo ""

cd ~/pspd/atividade-extraclasse-2-pspd

echo "1️⃣ Reiniciando cluster..."
cd hadoop
docker compose down -v
docker compose up -d
sleep 20
cd ..

echo ""
echo "2️⃣ Formatando NameNode..."
docker exec -u hadoop hadoop-master bash -c "hdfs namenode -format -force" 2>&1 | tail -3

echo ""
echo "3️⃣ Limpando DataNodes..."
./scripts/limpar_datanodes.sh

echo ""
echo "4️⃣ Iniciando HDFS..."
docker exec -u hadoop hadoop-master bash -c "start-dfs.sh"
sleep 20

echo ""
echo "5️⃣ Verificando processos..."
echo "Master:"
docker exec hadoop-master jps
echo ""
echo "Worker1:"
docker exec hadoop-worker1 jps
echo ""
echo "Worker2:"
docker exec hadoop-worker2 jps

echo ""
echo "6️⃣ Verificando HDFS..."
docker exec -u hadoop hadoop-master bash -c "hdfs dfsadmin -report" | head -25

echo ""
echo "7️⃣ Testando upload de arquivo..."
docker exec -u hadoop hadoop-master bash -c "echo 'teste rapido' > /tmp/teste.txt"
docker exec -u hadoop hadoop-master bash -c "hdfs dfs -mkdir -p /user/hadoop/teste"
docker exec -u hadoop hadoop-master bash -c "hdfs dfs -put /tmp/teste.txt /user/hadoop/teste/"
docker exec -u hadoop hadoop-master bash -c "hdfs dfs -ls /user/hadoop/teste/"

echo ""
echo "=========================================="
echo "✅ TESTE CONCLUÍDO!"
echo "=========================================="
