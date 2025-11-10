#!/bin/bash
set -euo pipefail

# ============================================================================
# CLEANUP - Limpar ambiente Hadoop
# ============================================================================

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

HADOOP_DIR="/home/edilberto/pspd/atividade-extraclasse-2-pspd/hadoop"

echo -e "${YELLOW}╔════════════════════════════════════════╗${NC}"
echo -e "${YELLOW}║   Limpando Ambiente Hadoop             ║${NC}"
echo -e "${YELLOW}╚════════════════════════════════════════╝${NC}"
echo ""

cd "$HADOOP_DIR"

echo -e "${YELLOW}🧹 Parando contêineres...${NC}"
docker compose down -v

echo -e "${YELLOW}🧹 Removendo volumes órfãos...${NC}"
docker volume prune -f

echo -e "${YELLOW}🧹 Limpando processos Java (se houver)...${NC}"
for node in worker1 worker2 master; do
  docker exec -u hadoop "hadoop-$node" bash -c 'pkill -9 java 2>/dev/null || true' 2>/dev/null || true
done

echo ""
echo -e "${GREEN}✅ Ambiente limpo com sucesso!${NC}"
echo ""
