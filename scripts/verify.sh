#!/bin/bash
set -euo pipefail

# ============================================================================
# VERIFY - Verificar configurações e ambiente
# ============================================================================

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

ROOT_DIR="/home/edilberto/pspd/atividade-extraclasse-2-pspd"

echo -e "${YELLOW}╔════════════════════════════════════════╗${NC}"
echo -e "${YELLOW}║   Verificando Ambiente                 ║${NC}"
echo -e "${YELLOW}╚════════════════════════════════════════╝${NC}"
echo ""

# Verificar Docker
echo -e "${YELLOW}🔍 Verificando Docker...${NC}"
if ! command -v docker &> /dev/null; then
  echo -e "${RED}❌ Docker não encontrado!${NC}"
  exit 1
fi
echo -e "${GREEN}✅ Docker instalado: $(docker --version)${NC}"

# Verificar Docker Compose
echo -e "${YELLOW}🔍 Verificando Docker Compose...${NC}"
if ! command -v docker compose &> /dev/null; then
  echo -e "${RED}❌ Docker Compose não encontrado!${NC}"
  exit 1
fi
echo -e "${GREEN}✅ Docker Compose instalado${NC}"

# Verificar contêineres Hadoop
echo -e "${YELLOW}🔍 Verificando contêineres Hadoop...${NC}"
if docker ps | grep -q hadoop-master; then
  echo -e "${GREEN}✅ Cluster Hadoop rodando${NC}"
  docker ps --format "table {{.Names}}\t{{.Status}}" | grep hadoop
else
  echo -e "${YELLOW}⚠️  Cluster Hadoop não está rodando${NC}"
  echo -e "   Execute: ./scripts/setup.sh"
fi

# Verificar arquivos de configuração
echo ""
echo -e "${YELLOW}🔍 Verificando arquivos XML de teste...${NC}"
CONFIGS=(
  "$ROOT_DIR/config/teste1_memoria/yarn-site.xml"
  "$ROOT_DIR/config/teste2_replicacao/hdfs-site.xml"
  "$ROOT_DIR/config/teste3_blocksize/hdfs-site.xml"
  "$ROOT_DIR/config/teste4_reducers/mapred-site.xml"
)

all_ok=true
for config in "${CONFIGS[@]}"; do
  if [ -f "$config" ]; then
    # Validar XML básico
    if xmllint --noout "$config" 2>/dev/null; then
      echo -e "${GREEN}✅ $(basename $(dirname $config))/$(basename $config)${NC}"
    else
      echo -e "${RED}❌ $(basename $(dirname $config))/$(basename $config) - XML inválido!${NC}"
      all_ok=false
    fi
  else
    echo -e "${RED}❌ $(basename $(dirname $config))/$(basename $config) - Não encontrado!${NC}"
    all_ok=false
  fi
done

# Verificar scripts
echo ""
echo -e "${YELLOW}🔍 Verificando scripts principais...${NC}"
SCRIPTS=(
  "$ROOT_DIR/scripts/setup.sh"
  "$ROOT_DIR/scripts/run_tests.sh"
  "$ROOT_DIR/scripts/cleanup.sh"
  "$ROOT_DIR/scripts/generate_dataset.sh"
  "$ROOT_DIR/scripts/run_wordcount.sh"
)

for script in "${SCRIPTS[@]}"; do
  if [ -f "$script" ] && [ -x "$script" ]; then
    echo -e "${GREEN}✅ $(basename $script)${NC}"
  else
    echo -e "${RED}❌ $(basename $script) - Não encontrado ou sem permissão de execução${NC}"
    all_ok=false
  fi
done

echo ""
if [ "$all_ok" = true ]; then
  echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
  echo -e "${GREEN}║   ✅ Ambiente OK - Pronto para uso!   ║${NC}"
  echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
  exit 0
else
  echo -e "${RED}╔════════════════════════════════════════╗${NC}"
  echo -e "${RED}║   ❌ Problemas encontrados!            ║${NC}"
  echo -e "${RED}╚════════════════════════════════════════╝${NC}"
  exit 1
fi
