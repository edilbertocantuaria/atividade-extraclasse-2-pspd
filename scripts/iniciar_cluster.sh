#!/bin/bash

# Cores para output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Iniciando o cluster Hadoop...${NC}"

# Mudar para o diretório do hadoop
cd /home/edilberto/pspd/atividade-extraclasse-2-pspd/hadoop

# Iniciar os contêineres
echo -e "${GREEN}Iniciando contêineres Docker...${NC}"
docker compose up -d

# Esperar um pouco para os contêineres iniciarem completamente
echo -e "${YELLOW}Aguardando os contêineres inicializarem...${NC}"
sleep 10

# Executar comandos no contêiner master
echo -e "${GREEN}Configurando o HDFS e YARN...${NC}"
docker exec hadoop-master bash -c "hdfs namenode -format && start-dfs.sh && start-yarn.sh"

echo -e "${GREEN}Cluster Hadoop iniciado com sucesso!${NC}"
echo -e "${YELLOW}Interfaces disponíveis em:${NC}"
echo -e "HDFS UI: ${GREEN}http://localhost:9870${NC}"
echo -e "YARN UI: ${GREEN}http://localhost:8088${NC}"