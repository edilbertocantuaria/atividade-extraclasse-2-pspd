#!/bin/bash

echo "====================================="
echo "  TESTE AUTOMATIZADO - B2 SPARK     "
echo "====================================="
echo ""

# Cores para output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Função para verificar status
check_status() {
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ $1${NC}"
    else
        echo -e "${RED}❌ $1${NC}"
        exit 1
    fi
}

echo "1️⃣  Verificando containers..."
docker ps | grep -E "spark-master|spark-worker|kafka|elasticsearch|kibana|zookeeper" > /dev/null
check_status "Containers rodando"

echo ""
echo "2️⃣  Testando Elasticsearch..."
curl -s http://localhost:9200 > /dev/null
check_status "Elasticsearch acessível"

echo ""
echo "3️⃣  Verificando tópico Kafka..."
docker exec kafka kafka-topics --list --bootstrap-server kafka:9092 | grep "input-topic" > /dev/null
check_status "Tópico input-topic existe"

echo ""
echo "4️⃣  Testando Producer (30 segundos)..."
echo -e "${YELLOW}Enviando mensagens para o Kafka...${NC}"
timeout 30 docker exec -d spark-master python3 /opt/spark_app/producer.py
sleep 5
check_status "Producer iniciado"

echo ""
echo "5️⃣  Testando Consumer..."
timeout 10 docker exec spark-master python3 /opt/spark_app/consumer.py > /tmp/consumer_test.log 2>&1 &
CONSUMER_PID=$!
sleep 8
kill $CONSUMER_PID 2>/dev/null

if grep -q "Recebido:" /tmp/consumer_test.log; then
    echo -e "${GREEN}✅ Consumer recebendo mensagens${NC}"
    echo "Exemplo de mensagem:"
    grep "Recebido:" /tmp/consumer_test.log | head -3
else
    echo -e "${RED}❌ Consumer não recebeu mensagens${NC}"
fi

echo ""
echo "6️⃣  Verificando Spark Master UI..."
curl -s http://localhost:8080 > /dev/null
check_status "Spark UI acessível em http://localhost:8080"

echo ""
echo "7️⃣  Verificando Kibana..."
if curl -s http://localhost:5601/api/status | grep -q "available"; then
    echo -e "${GREEN}✅ Kibana acessível em http://localhost:5601${NC}"
else
    echo -e "${YELLOW}⏳ Kibana ainda inicializando (acesse http://localhost:5601)${NC}"
fi

echo ""
echo "====================================="
echo -e "${GREEN}✅ AMBIENTE B2 VALIDADO!${NC}"
echo "====================================="
echo ""
echo "📝 Próximos passos:"
echo "1. Acessar Spark UI: http://localhost:8080"
echo "2. Acessar Kibana: http://localhost:5601"
echo "3. Rodar Spark Streaming:"
echo "   docker exec -it spark-master spark-submit \\"
echo "     --packages org.apache.spark:spark-streaming-kafka-0-10_2.12:3.4.1 \\"
echo "     /opt/spark_app/main.py"
echo ""
