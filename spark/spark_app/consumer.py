from kafka import KafkaConsumer
import json

def main():
    """Consumer simples para verificar mensagens no Kafka"""
    try:
        consumer = KafkaConsumer(
            'input-topic',
            bootstrap_servers=['kafka:9092'],
            auto_offset_reset='earliest',
            enable_auto_commit=True,
            group_id='test-consumer',
            value_deserializer=lambda x: x.decode('utf-8')
        )
        
        print("Consumer iniciado. Aguardando mensagens do tópico 'input-topic'...")
        
        for message in consumer:
            print(f"Recebido: {message.value}")
            
    except KeyboardInterrupt:
        print("\nConsumer interrompido pelo usuário.")
    except Exception as e:
        print(f"Erro no consumer: {e}")
    finally:
        consumer.close()
        print("Consumer finalizado.")

if __name__ == "__main__":
    main()
