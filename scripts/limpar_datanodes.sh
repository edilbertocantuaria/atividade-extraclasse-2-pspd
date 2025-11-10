#!/bin/bash

echo "🧹 Limpando dados antigos dos DataNodes..."

# Limpar dados dos workers
for worker in worker1 worker2; do
    echo "Limpando dados do $worker..."
    docker exec hadoop-$worker bash -c "rm -rf /tmp/hadoop-hadoop/dfs/data/*"
    echo "✅ $worker limpo"
done

echo ""
echo "✅ DataNodes limpos e prontos para re-sincronizar com o NameNode!"
