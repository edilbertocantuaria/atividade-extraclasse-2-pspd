# Relatório - Cluster Hadoop

## Arquitetura
### Topologia
- 1 nó mestre (hadoop-master)
- 2 nós workers (hadoop-worker1, hadoop-worker2)
- Rede dedicada (hadoop-net)

### Papéis dos nós
- Master: HDFS NameNode + YARN ResourceManager
- Workers: HDFS DataNode + YARN NodeManager

## Configurações XML
### core-site.xml
- fs.defaultFS: hdfs://master:9000

### hdfs-site.xml
- dfs.replication: 2

### mapred-site.xml
- mapreduce.framework.name: yarn

### yarn-site.xml
- yarn.nodemanager.aux-services: mapreduce_shuffle
- yarn.resourcemanager.hostname: master

## Testes de Comportamento
[Será preenchido com os resultados dos 5 casos de teste]

## Cenários de Falha e Recuperação
[Será preenchido com os 3 casos de teste de tolerância a falhas]

## Conclusões
[Será preenchido após a execução dos testes]

## Screenshots/Links
- HDFS UI: http://localhost:9870
- YARN UI: http://localhost:8088