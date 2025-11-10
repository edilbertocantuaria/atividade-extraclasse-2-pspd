from pyspark.sql import SparkSession
from pyspark.streaming import StreamingContext
from pyspark.streaming.kafka import KafkaUtils
from elasticsearch import Elasticsearch
import json
import os

def send_to_elastic(rdd):
    """Envia os dados processados ao ElasticSearch"""
    if not rdd.isEmpty():
        es = Elasticsearch(["http://elasticsearch:9200"])
        for word, count in rdd.collect():
            doc = {"word": word, "count": count, "timestamp": "now"}
            try:
                es.index(index="wordcount", document=doc)
                print(f"Enviado ao ES: {word} -> {count}")
            except Exception as e:
                print(f"Erro ao enviar ao ES: {e}")

if __name__ == "__main__":
    # Inicializa Spark
    spark = SparkSession.builder \
        .appName("SparkKafkaWordCount") \
        .config("spark.jars.packages", "org.apache.spark:spark-streaming-kafka-0-10_2.12:3.5.0") \
        .getOrCreate()
    
    sc = spark.sparkContext
    sc.setLogLevel("WARN")
    
    # Cria streaming context com batch de 5 segundos
    ssc = StreamingContext(sc, 5)
    
    # Configura Kafka Stream
    kafkaParams = {
        "zookeeper.connect": "zookeeper:2181",
        "group.id": "spark-streaming",
        "auto.offset.reset": "smallest"
    }
    
    try:
        kafkaStream = KafkaUtils.createStream(
            ssc, 
            "zookeeper:2181", 
            "spark-streaming", 
            {"input-topic": 1}
        )
        
        # WordCount
        words = kafkaStream.map(lambda x: x[1]) \
                          .flatMap(lambda line: line.lower().split(" ")) \
                          .filter(lambda w: len(w) > 0)
        
        pairs = words.map(lambda w: (w, 1))
        counts = pairs.reduceByKey(lambda a, b: a + b)
        
        # Debug: imprime na console
        counts.pprint()
        
        # Envia ao ElasticSearch
        counts.foreachRDD(send_to_elastic)
        
        print("Iniciando streaming...")
        ssc.start()
        ssc.awaitTermination()
        
    except Exception as e:
        print(f"Erro no streaming: {e}")
        ssc.stop()
