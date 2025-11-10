#!/bin/bash
set -euo pipefail

# ============================================================================
# SETUP - Inicializar cluster Hadoop
# ============================================================================

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

HADOOP_DIR="/home/edilberto/pspd/atividade-extraclasse-2-pspd/hadoop"

echo -e "${YELLOW}╔════════════════════════════════════════╗${NC}"
echo -e "${YELLOW}║   Inicializando Cluster Hadoop         ║${NC}"
echo -e "${YELLOW}╚════════════════════════════════════════╝${NC}"
echo ""

# Mudar para o diretório do hadoop
cd "$HADOOP_DIR"

# Iniciar os contêineres
echo -e "${GREEN}▶ Iniciando contêineres Docker...${NC}"
docker compose up -d

# Esperar um pouco para os contêineres iniciarem completamente
echo -e "${YELLOW}⏳ Aguardando os contêineres inicializarem (10s)...${NC}"
sleep 10

# Executar comandos no contêiner master
echo -e "${GREEN}▶ Formatando HDFS...${NC}"
docker exec hadoop-master bash -c "hdfs namenode -format -force" 2>/dev/null || true

echo -e "${GREEN}▶ Iniciando HDFS e YARN...${NC}"
docker exec hadoop-master bash -c "start-dfs.sh && start-yarn.sh"

echo ""
echo -e "${GREEN}✅ Cluster Hadoop iniciado com sucesso!${NC}"
echo ""
echo -e "${YELLOW}Interfaces disponíveis:${NC}"
echo -e "  • HDFS UI: ${GREEN}http://localhost:9870${NC}"
echo -e "  • YARN UI: ${GREEN}http://localhost:8088${NC}"
echo ""
