# Atividade Extraclasse 2 - PSPD

[![Docker](https://img.shields.io/badge/Docker-20.10%2B-blue.svg)](https://www.docker.com/)
[![Hadoop](https://img.shields.io/badge/Hadoop-3.3.6-yellow.svg)](https://hadoop.apache.org/)
[![Spark](https://img.shields.io/badge/Spark-3.5.0-orange.svg)](https://spark.apache.org/)
[![License](https://img.shields.io/badge/License-Academic-green.svg)](LICENSE)

Projeto de estudo sobre processamento distribuído usando Hadoop e Spark em containers Docker.

> 🚀 **[GUIA COMPLETO DE EXECUÇÃO](como_executar.md)** - Instruções detalhadas passo a passo para executar todo o projeto do zero

## 📋 Índice

- [Visão Geral](#visão-geral)
- [Início Rápido](#início-rápido)
- [Requisitos](#requisitos)
- [Estrutura do Projeto](#estrutura-do-projeto)
- [Documentação](#documentação)

## 🎯 Visão Geral

Este projeto implementa e testa clusters Hadoop e Spark para análise de desempenho com diferentes configurações.

### Implementações

**B1 - Hadoop MapReduce**
- Cluster distribuído (1 master + 2 workers)
- 5 configurações diferentes testadas
- Testes de tolerância a falhas
- Testes de concorrência
- Dataset massivo (500MB+)

**B2 - Spark Streaming**
- Pipeline de processamento em tempo real
- Integração Kafka + Elasticsearch + Kibana
- Producer/Consumer autocontidos
- Dashboard de visualização

**Extensão ML (Opcional)**
- Análise de sentimentos com VADER
- Classificação automática de polaridade
- Visualizações enriquecidas no Kibana

## ⚡ Início Rápido

### B1 - Hadoop (3 comandos)
```bash
cd hadoop && docker-compose up -d
cd .. && ./scripts/run_all_tests.sh
cat resultados/B1/RELATORIO_FINAL_COMPLETO.md
```

### B2 - Spark (2 passos)
```bash
cd spark && docker-compose up -d
# Abrir spark/notebooks/B2_SPARK_STREAMING_COMPLETO.ipynb e executar células
```

> 📖 **Para instruções detalhadas**, consulte **[como_executar.md](como_executar.md)**

## ⚙️ Requisitos

- Docker 20.10+
- Docker Compose 2.0+
- Python 3.8+
- 8GB RAM disponível
- 20GB espaço em disco

## 🛠️ Estrutura do Projeto

```
atividade-extraclasse-2-pspd/
├── como_executar.md           # 📖 GUIA PRINCIPAL DE EXECUÇÃO
├── README.md                  # Este arquivo (visão geral)
├── STATUS_IMPLEMENTACAO.md    # Status das implementações B1/B2
│
├── hadoop/                    # B1: Cluster Hadoop
│   ├── docker-compose.yml
│   ├── Dockerfile
│   └── master/worker1/worker2/
│
├── spark/                     # B2: Spark Streaming
│   ├── docker-compose.yml     # Kafka + ES + Kibana
│   └── notebooks/
│       └── B2_SPARK_STREAMING_COMPLETO.ipynb  # Notebook principal (65 células)
│
├── scripts/                   # Scripts de teste e automação
│   ├── run_all_tests.sh       # Executar todos os testes B1
│   ├── test_fault_tolerance.sh
│   ├── test_concurrency.sh
│   └── collect_metrics.sh
│
├── config/                    # Configurações XML por teste
│   ├── teste1_memoria/
│   ├── teste2_replicacao/
│   ├── teste3_blocksize/
│   ├── teste4_reducers/
│   └── teste5_speculative/
│
├── resultados/B1/             # Resultados Hadoop
│   ├── RELATORIO_FINAL_COMPLETO.md
│   ├── teste0_baseline/
│   ├── teste1_memoria/
│   ├── teste2_replicacao/
│   ├── teste3_blocksize/
│   ├── teste4_reducers/
│   ├── teste5_speculative/
│   ├── teste_tolerancia_falhas/
│   └── teste_concorrencia/
│
├── resultados_spark/          # Resultados Spark
│   ├── IMPLEMENTACAO_B2_COMPLETA.md
│   ├── VALIDACAO_B2_DETALHADA.md
│   ├── EXTENSAO_ML_SENTIMENTOS.md
│   └── kibana_*.png           # Screenshots (pendente)
│
└── docs/                      # Documentação técnica adicional
    ├── hadoop.md
    ├── spark.md
    └── tests.md
```

## 📚 Documentação

### Documentação Principal
- **[como_executar.md](como_executar.md)** - 🚀 Guia completo de execução passo a passo (B1 + B2 + ML)
- **[STATUS_IMPLEMENTACAO.md](STATUS_IMPLEMENTACAO.md)** - Status e checklist das implementações

### Documentação B1 (Hadoop)
- **[resultados/B1/RELATORIO_FINAL_COMPLETO.md](resultados/B1/RELATORIO_FINAL_COMPLETO.md)** - Relatório consolidado dos testes
- **[docs/hadoop.md](docs/hadoop.md)** - Documentação técnica Hadoop

### Documentação B2 (Spark)
- **[resultados_spark/IMPLEMENTACAO_B2_COMPLETA.md](resultados_spark/IMPLEMENTACAO_B2_COMPLETA.md)** - Documentação detalhada da implementação
- **[resultados_spark/VALIDACAO_B2_DETALHADA.md](resultados_spark/VALIDACAO_B2_DETALHADA.md)** - Checklist de validação
- **[resultados_spark/EXTENSAO_ML_SENTIMENTOS.md](resultados_spark/EXTENSAO_ML_SENTIMENTOS.md)** - Documentação da extensão ML
- **[docs/spark.md](docs/spark.md)** - Documentação técnica Spark

## 📞 Suporte

Para executar o projeto, consulte primeiro **[como_executar.md](como_executar.md)**.

Para troubleshooting:
1. Verificar seção de troubleshooting em `como_executar.md`
2. Consultar logs dos containers: `docker logs <container-name>`
3. Verificar documentação técnica específica em `docs/`

## 📝 Licença

Projeto acadêmico - Disciplina de Programação para Sistemas Paralelos e Distribuídos.

## 👤 Autor

**Edilberto Cantuária**

---

**Última atualização**: 29/11/2025
