from kafka import KafkaProducer
import time
import random

# Lista de palavras para simular
words = ["python", "spark", "bigdata", "hadoop", "pspd", "unb", "cluster", "docker", "kafka", 
         "elasticsearch", "kibana", "streaming", "data", "analytics", "machine", "learning"]

def create_producer():
    """Cria e retorna um produtor Kafka"""
    try:
        producer = KafkaProducer(
            bootstrap_servers=['kafka:9092'],
            value_serializer=lambda v: v.encode('utf-8')
        )
        return producer
    except Exception as e:
        print(f"Erro ao criar producer: {e}")
        return None

def main():
    producer = create_producer()
    
    if not producer:
        print("Não foi possível criar o producer. Verifique se o Kafka está rodando.")
        return
    
    print("Producer iniciado. Enviando mensagens para o tópico 'input-topic'...")
    
    try:
        count = 0
        while True:
            # Gera uma frase com 3-8 palavras aleatórias
            sentence = " ".join(random.choices(words, k=random.randint(3, 8)))
            
            # Envia para o Kafka
            producer.send("input-topic", value=sentence)
            
            count += 1
            print(f"[{count}] Enviado: {sentence}")
            
            # Aguarda 1 segundo antes da próxima mensagem
            time.sleep(1)
            
    except KeyboardInterrupt:
        print("\nProducer interrompido pelo usuário.")
    except Exception as e:
        print(f"Erro ao enviar mensagem: {e}")
    finally:
        producer.close()
        print("Producer finalizado.")

if __name__ == "__main__":
    main()
