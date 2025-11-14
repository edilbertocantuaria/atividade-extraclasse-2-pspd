# Comandos Rápidos - Hadoop B1

## 🚀 Início Rápido (3 comandos)

```bash
cd /home/edilberto/pspd/atividade-extraclasse-2-pspd/hadoop
docker-compose up -d
cd .. && ./scripts/run_all_tests.sh
```

---

## 📦 Gerenciamento do Cluster

### Iniciar Cluster
```bash
cd /home/edilberto/pspd/atividade-extraclasse-2-pspd/hadoop
docker-compose up -d
```

### Parar Cluster
```bash
docker-compose down
```

### Ver Status
```bash
docker ps | grep hadoop
```

### Logs
```bash
# Master
docker logs hadoop-master -f

# Worker1
docker logs hadoop-worker1 -f

# Worker2
docker logs hadoop-worker2 -f
```

### Acessar Container
```bash
docker exec -it hadoop-master bash
```

---

## 🧪 Executar Testes

### Todos os Testes (Automático)
```bash
./scripts/run_all_tests.sh
```

### Gerar Dataset
```bash
# 500MB (padrão)
./scripts/generate_large_dataset.sh 500

# 1GB (para testes mais longos)
./scripts/generate_large_dataset.sh 1000

# 2GB (para testes muito longos)
./scripts/generate_large_dataset.sh 2000
```

### Teste de Tolerância a Falhas
```bash
./scripts/test_fault_tolerance.sh
# Duração: ~15-20 minutos
```

### Teste de Concorrência
```bash
./scripts/test_concurrency.sh
# Duração: ~10-15 minutos
```

### Coletar Métricas de um Job
```bash
# Primeiro execute um job e pegue o Application ID
./scripts/collect_metrics.sh application_1234567890123_0001 resultados/B1/meu_teste 500
```

---

## 📊 Monitoramento

### Interface Web YARN ResourceManager
```bash
# No navegador:
http://localhost:8088
```

### Interface Web HDFS NameNode
```bash
# No navegador:
http://localhost:9870
```

### Listar Aplicações YARN
```bash
docker exec hadoop-master yarn application -list
docker exec hadoop-master yarn application -list -appStates ALL
```

### Status de uma Aplicação
```bash
docker exec hadoop-master yarn application -status application_1234567890123_0001
```

### Ver Logs de uma Aplicação
```bash
docker exec hadoop-master yarn logs -applicationId application_1234567890123_0001
```

### Status do Cluster YARN
```bash
docker exec hadoop-master yarn node -list -all
```

### Relatório do HDFS
```bash
docker exec hadoop-master hdfs dfsadmin -report
```

### Verificar Saúde HDFS
```bash
docker exec hadoop-master hdfs dfsadmin -safemode get
docker exec hadoop-master hdfs fsck / -files -blocks -locations
```

---

## 💾 Gerenciamento HDFS

### Listar Arquivos
```bash
docker exec hadoop-master hdfs dfs -ls /
docker exec hadoop-master hdfs dfs -ls /user/hadoop/input
docker exec hadoop-master hdfs dfs -ls -h -R /user/hadoop
```

### Upload para HDFS
```bash
docker exec hadoop-master hdfs dfs -put /caminho/local /user/hadoop/input/
```

### Download do HDFS
```bash
docker exec hadoop-master hdfs dfs -get /user/hadoop/output/resultado /tmp/
docker cp hadoop-master:/tmp/resultado ./local/
```

### Ver Conteúdo de Arquivo
```bash
docker exec hadoop-master hdfs dfs -cat /user/hadoop/output/part-r-00000
docker exec hadoop-master hdfs dfs -cat /user/hadoop/output/part-r-00000 | head -20
```

### Deletar Arquivos
```bash
docker exec hadoop-master hdfs dfs -rm /user/hadoop/output/arquivo.txt
docker exec hadoop-master hdfs dfs -rm -r /user/hadoop/output/diretorio
```

### Espaço Utilizado
```bash
docker exec hadoop-master hdfs dfs -df -h
docker exec hadoop-master hdfs dfs -du -h /user/hadoop
```

---

## 🔧 Executar WordCount Manualmente

### Básico
```bash
docker exec hadoop-master bash -c "
  hdfs dfs -rm -r -f /user/hadoop/output/test
  hadoop jar /home/hadoop/hadoop/share/hadoop/mapreduce/hadoop-mapreduce-examples-3.3.6.jar \
    wordcount /user/hadoop/input /user/hadoop/output/test
"
```

### Com Medição de Tempo
```bash
docker exec hadoop-master bash -c "
  hdfs dfs -rm -r -f /user/hadoop/output/test
  time hadoop jar /home/hadoop/hadoop/share/hadoop/mapreduce/hadoop-mapreduce-examples-3.3.6.jar \
    wordcount /user/hadoop/input /user/hadoop/output/test
"
```

### Ver Top 10 Palavras
```bash
docker exec hadoop-master bash -c "
  hdfs dfs -cat /user/hadoop/output/test/part-r-00000 | sort -k2 -nr | head -10
"
```

---

## 🎛️ Controlar Workers

### Parar Worker
```bash
docker stop hadoop-worker1
# ou
docker stop hadoop-worker2
```

### Iniciar Worker
```bash
docker start hadoop-worker1
# ou
docker start hadoop-worker2
```

### Reiniciar Worker
```bash
docker restart hadoop-worker1
```

### Ver Status de Todos
```bash
docker ps --filter "name=hadoop-" --format "table {{.Names}}\t{{.Status}}"
```

---

## 📈 Análise de Resultados

### Ver Todos os Tempos de Execução
```bash
for dir in resultados/B1/teste*/; do
  test_name=$(basename "$dir")
  duration=$(cat "$dir/time_stats.txt" 2>/dev/null || echo "N/A")
  echo "$test_name: ${duration}s"
done
```

### Ver Relatório Final
```bash
cat resultados/B1/relatorio_final_completo.md
```

### Ver Relatório de Tolerância a Falhas
```bash
cat resultados/B1/teste_tolerancia_falhas/run_*/relatorio_tolerancia_falhas.md
```

### Ver Relatório de Concorrência
```bash
cat resultados/B1/teste_concorrencia/run_*/relatorio_concorrencia.md
```

### Ver Métricas CSV
```bash
# Ver todas as métricas
cat resultados/B1/teste*/metrics_summary.csv

# Consolidar em uma tabela
echo "Teste,Metric,Value,Unit"
for dir in resultados/B1/teste*/; do
  test_name=$(basename "$dir")
  if [ -f "$dir/metrics_summary.csv" ]; then
    tail -n +2 "$dir/metrics_summary.csv" | sed "s/^/$test_name,/"
  fi
done
```

### Comparar Tempos Graficamente (Python)
```bash
cat > /tmp/plot_results.py << 'EOF'
import matplotlib.pyplot as plt
import os

tests = []
times = []

for dir_name in sorted(os.listdir('resultados/B1')):
    if dir_name.startswith('teste'):
        time_file = f'resultados/B1/{dir_name}/time_stats.txt'
        if os.path.exists(time_file):
            with open(time_file) as f:
                tests.append(dir_name.replace('teste', 'T').replace('_', ' ').title())
                times.append(float(f.read().strip()))

plt.figure(figsize=(10, 6))
plt.bar(tests, times, color='steelblue')
plt.xlabel('Configuração', fontsize=12)
plt.ylabel('Duração (segundos)', fontsize=12)
plt.title('Comparação de Desempenho - Testes Hadoop', fontsize=14)
plt.xticks(rotation=45, ha='right')
plt.grid(axis='y', alpha=0.3)
plt.tight_layout()
plt.savefig('resultados/B1/comparison_chart.png', dpi=150)
print("Gráfico salvo: resultados/B1/comparison_chart.png")
EOF

python3 /tmp/plot_results.py
```

---

## 🧹 Limpeza

### Limpar Outputs HDFS
```bash
docker exec hadoop-master hdfs dfs -rm -r -f /user/hadoop/output/*
```

### Limpar Logs
```bash
docker exec hadoop-master bash -c "rm -rf /home/hadoop/hadoop/logs/*"
```

### Reset Completo (CUIDADO!)
```bash
./scripts/cleanup.sh
# ou manualmente:
docker-compose down -v
docker volume prune -f
```

---

## 🐛 Troubleshooting

### Cluster não responde
```bash
# Ver logs de erro
docker logs hadoop-master --tail 100

# Reiniciar serviços
docker exec hadoop-master bash -c "
  /home/hadoop/hadoop/sbin/stop-all.sh
  sleep 10
  /home/hadoop/hadoop/sbin/start-all.sh
"
```

### Job travado
```bash
# Listar jobs em execução
docker exec hadoop-master yarn application -list -appStates RUNNING

# Matar job
docker exec hadoop-master yarn application -kill application_1234567890123_0001
```

### HDFS em safe mode
```bash
# Verificar
docker exec hadoop-master hdfs dfsadmin -safemode get

# Forçar saída (CUIDADO!)
docker exec hadoop-master hdfs dfsadmin -safemode leave
```

### Sem espaço em disco
```bash
# Ver uso
docker exec hadoop-master df -h

# Limpar outputs
docker exec hadoop-master hdfs dfs -rm -r -f /user/hadoop/output/*

# Limpar Docker
docker system prune -a
```

### Workers não conectam
```bash
# Ver nós ativos
docker exec hadoop-master yarn node -list -all

# Reiniciar workers
docker restart hadoop-worker1 hadoop-worker2

# Ver logs de worker
docker logs hadoop-worker1 --tail 50
```

---

## 📱 Atalhos Úteis

### Ver Tudo de Uma Vez
```bash
echo "=== CLUSTER STATUS ==="
docker ps --filter "name=hadoop-" --format "table {{.Names}}\t{{.Status}}"
echo ""
echo "=== YARN NODES ==="
docker exec hadoop-master yarn node -list 2>/dev/null
echo ""
echo "=== HDFS SUMMARY ==="
docker exec hadoop-master hdfs dfs -df -h 2>/dev/null
echo ""
echo "=== RECENT APPS ==="
docker exec hadoop-master yarn application -list -appStates ALL 2>/dev/null | head -10
```

### Monitorar Job em Tempo Real
```bash
APP_ID="application_1234567890123_0001"
watch -n 5 "docker exec hadoop-master yarn application -status $APP_ID 2>/dev/null | grep -E 'State|Progress|Final'"
```

### Contar Palavras do Resultado
```bash
docker exec hadoop-master bash -c "
  hdfs dfs -cat /user/hadoop/output/*/part-r-* 2>/dev/null | \
  awk '{sum+=\$2} END {print \"Total palavras únicas:\", NR; print \"Total ocorrências:\", sum}'
"
```

---

## 📖 Referências Rápidas

- **Guia Completo**: `docs/GUIA_EXECUCAO_HADOOP.md`
- **Resumo de Implementação**: `RESUMO_IMPLEMENTACAO_B1.md`
- **README**: `README.md`

---

**Dica**: Adicione este arquivo aos favoritos para consulta rápida!
