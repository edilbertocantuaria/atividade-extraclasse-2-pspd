import random

def generate_text(word_count=20):
    """
    Gera texto aleatório para testes
    
    Args:
        word_count: Número de palavras a gerar
    
    Returns:
        String com palavras aleatórias separadas por espaço
    """
    words = [
        "data", "spark", "stream", "cluster", "unb", "bigdata",
        "python", "hadoop", "kafka", "analytics", "processing",
        "distributed", "computing", "machine", "learning", "ai",
        "docker", "container", "microservices", "cloud", "aws"
    ]
    
    return " ".join(random.choices(words, k=word_count))

def generate_sentences(num_sentences=10, words_per_sentence=(5, 15)):
    """
    Gera múltiplas sentenças
    
    Args:
        num_sentences: Número de sentenças a gerar
        words_per_sentence: Tupla (min, max) de palavras por sentença
    
    Returns:
        Lista de sentenças
    """
    sentences = []
    for _ in range(num_sentences):
        word_count = random.randint(*words_per_sentence)
        sentences.append(generate_text(word_count))
    
    return sentences

if __name__ == "__main__":
    # Teste do gerador
    print("Texto de teste:")
    print(generate_text(30))
    print("\nSentenças de teste:")
    for i, sentence in enumerate(generate_sentences(5), 1):
        print(f"{i}. {sentence}")
