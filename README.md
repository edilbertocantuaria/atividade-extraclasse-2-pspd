# Atividade Extraclasse 2 - PSPD

[![Docker](https://img.shields.io/badge/Docker-20.10%2B-blue.svg)](https://www.docker.com/)
[![Hadoop](https://img.shields.io/badge/Hadoop-3.3.6-yellow.svg)](https://hadoop.apache.org/)
[![Spark](https://img.shields.io/badge/Spark-3.5.0-orange.svg)](https://spark.apache.org/)
[![License](https://img.shields.io/badge/License-Academic-green.svg)](LICENSE)

Projeto de estudo sobre processamento distribuído usando Hadoop e Spark em containers Docker.

> 📘 **Documentação Adicional**: [CHANGELOG](CHANGELOG.md) | [CONTRIBUTING](CONTRIBUTING.md) | [SUMMARY](SUMMARY.md)

## 📋 Índice

- [Visão Geral](#visão-geral)
- [Requisitos](#requisitos)
- [Instalação](#instalação)
- [Uso](#uso)
  - [Hadoop (B1)](#hadoop-b1)
  - [Spark (B2)](#spark-b2)
- [Arquitetura](#arquitetura)
- [Testes](#testes)
- [Resultados](#resultados)
- [Documentação](#documentação)

## 🎯 Visão Geral

Este projeto implementa e testa clusters Hadoop e Spark para análise de desempenho com diferentes configurações. Inclui:

- **Hadoop**: Cluster com 1 master + 2 workers para testes MapReduce
- **Spark**: Ambiente integrado com Kafka, Elasticsearch e Kibana
- **Testes automatizados**: Scripts para avaliar impacto de configurações
- **Análise de falhas**: Testes de resiliência e recuperação

## ⚙️ Requisitos

- Docker 20.10+
- Docker Compose 2.0+
- 8GB RAM disponível
- 20GB espaço em disco

## 🚀 Instalação

```bash
# Clone o repositório
git clone https://github.com/edilbertocantuaria/atividade-extraclasse-2-pspd.git
cd atividade-extraclasse-2-pspd

# Tornar scripts executáveis
chmod +x scripts/*.sh
```

## 💻 Uso

### Hadoop (B1)

#### Iniciar Cluster

```bash
./scripts/setup.sh
```

Interfaces disponíveis:
- **HDFS UI**: http://localhost:9870
- **YARN UI**: http://localhost:8088

#### Executar Testes

```bash
./scripts/run_tests.sh
```

Os testes avaliam o impacto de:
1. **Memória YARN** (1024MB vs padrão)
2. **Replicação HDFS** (1 vs 2 réplicas)
3. **Block Size** (64MB vs 128MB)
4. **Reducers** (1, 2, 4 reducers)

#### Limpar Ambiente

```bash
./scripts/cleanup.sh
```

### Spark (B2)

#### Iniciar Ambiente Spark

```bash
cd spark
docker compose up -d
```

Interfaces disponíveis:
- **Spark UI**: http://localhost:8080
- **Kibana**: http://localhost:5601
- **Jupyter**: http://localhost:8888

#### Executar Testes Spark

```bash
./spark/testar_ambiente.sh
```

## 🏗️ Arquitetura

### Hadoop Cluster

```
┌─────────────────┐
│  hadoop-master  │
│  - NameNode     │
│  - ResourceMgr  │
└────────┬────────┘
         │
    ┌────┴────┐
    │         │
┌───▼──┐  ┌──▼───┐
│worker1│  │worker2│
│DataNode│ │DataNode│
│NodeMgr │ │NodeMgr │
└───────┘  └───────┘
```

### Configurações Principais

| Componente | Arquivo | Configuração Principal |
|------------|---------|------------------------|
| HDFS | `hdfs-site.xml` | Replicação: 2, BlockSize: 128MB |
| YARN | `yarn-site.xml` | Memory: 2048MB por NodeManager |
| MapReduce | `mapred-site.xml` | Framework: YARN |

## 🧪 Testes

### B1 - Testes Hadoop

Os testes usam WordCount em um dataset gerado automaticamente:

```bash
# Verificar ambiente antes de testar
./scripts/verify.sh

# Executar todos os testes B1
./scripts/run_tests.sh
```

**Métricas coletadas:**
- Tempo total de execução
- Tempo de Map
- Tempo de Reduce
- CPU e Memória usadas
- Bytes lidos/escritos HDFS

### B2 - Testes Spark

Testes com streaming Kafka e visualização:

```bash
cd spark
./testar_ambiente.sh
```

## 📊 Resultados

Os resultados são salvos automaticamente em:

```
resultados/
├── B1/
│   ├── teste1_memoria/
│   ├── teste2_replicacao/
│   ├── teste3_blocksize/
│   ├── teste4_reducers/
│   ├── resumo_comparativo.txt
│   └── relatorio_consolidado.txt
└── ...

resultados_spark/
├── relatorio_final_spark.md
├── testes_graficos.md
└── VALIDACAO_B2.md
```

### Visualizar Resultados

```bash
# Resumo comparativo dos testes B1
cat resultados/B1/resumo_comparativo.txt

# Relatório detalhado
cat resultados/B1/relatorio_consolidado.txt

# Resultados Spark
cat resultados_spark/relatorio_final_spark.md
```

## 📚 Documentação

Documentação detalhada disponível em [`docs/`](docs/):

- [**Hadoop**](docs/hadoop.md): Arquitetura, configurações e troubleshooting
- [**Spark**](docs/spark.md): Setup do ambiente integrado com Kafka/Elastic
- [**Testes**](docs/tests.md): Metodologia e análise de resultados

## 🛠️ Estrutura do Projeto

```
.
├── README.md                  # Este arquivo
├── scripts/                   # Scripts principais
│   ├── setup.sh              # Iniciar cluster Hadoop
│   ├── run_tests.sh          # Executar testes B1
│   ├── cleanup.sh            # Limpar ambiente
│   └── verify.sh             # Verificar configurações
├── hadoop/                    # Configurações Hadoop
│   ├── docker-compose.yml
│   ├── Dockerfile
│   └── master/worker1/worker2/ # Configs XML por nó
├── spark/                     # Ambiente Spark
│   ├── docker-compose.yml
│   └── spark_app/
├── config/                    # Configurações de teste
│   ├── teste1_memoria/
│   ├── teste2_replicacao/
│   ├── teste3_blocksize/
│   └── teste4_reducers/
├── resultados/                # Outputs dos testes
├── docs/                      # Documentação detalhada
└── wordcount/                 # Aplicação WordCount

```

## 📝 Licença

Este é um projeto acadêmico para a disciplina de Programação para Sistemas Paralelos e Distribuídos.

## 👤 Autor

**Edilberto Cantuária**

---

**Última atualização**: Novembro 2025
