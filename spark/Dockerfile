FROM apache/spark:3.4.1-python3

USER root

# Instalar dependências
RUN pip3 install --no-cache-dir \
    pyspark==3.4.1 \
    kafka-python \
    elasticsearch \
    wordcloud \
    matplotlib

# Copiar aplicação
COPY spark_app /opt/spark_app
WORKDIR /opt/spark_app

ENV PYTHONUNBUFFERED=1
