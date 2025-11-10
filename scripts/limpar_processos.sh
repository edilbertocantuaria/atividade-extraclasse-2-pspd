#!/bin/bash

echo "🧹 Limpando processos do Hadoop..."

# Forçar kill dos NodeManagers em todos os workers
for node in worker1 worker2; do
    echo "Limpando processos no $node..."
    docker exec -u hadoop hadoop-$node bash -c '
        # Matar todos os processos Java do Hadoop
        pkill -9 -f "NodeManager" 2>/dev/null || true
        pkill -9 -f "DataNode" 2>/dev/null || true
        pkill -9 java 2>/dev/null || true
        echo "Processos limpos em $(hostname)"
    ' 2>/dev/null || true
done

# Limpar também no master
echo "Limpando processos no master..."
docker exec -u hadoop hadoop-master bash -c '
    pkill -9 -f "ResourceManager" 2>/dev/null || true
    pkill -9 -f "NameNode" 2>/dev/null || true
    pkill -9 -f "SecondaryNameNode" 2>/dev/null || true
    pkill -9 java 2>/dev/null || true
    echo "Processos limpos em $(hostname)"
' 2>/dev/null || true

sleep 2

echo "✅ Processos limpos!"
echo ""
