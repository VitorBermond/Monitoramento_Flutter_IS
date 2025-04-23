import pika
import json
import random
import time

# Configuração da conexão com o RabbitMQ
connection = pika.BlockingConnection(pika.ConnectionParameters(host='localhost'))
channel = connection.channel()

# Declaração da fila (se não existir, será criada)
#channel.queue_declare(queue='Data.CPU')
channel.queue_declare(queue='Data.CPU', durable=False)

try:
    while True:
        # Gera um valor aleatório de uso de CPU entre 0 e 100
        cpu_usage = round(random.uniform(0, 100), 2)

        # Cria uma mensagem JSON
        message = json.dumps({"cpu_usage": cpu_usage})

        # Publica a mensagem na fila
        channel.basic_publish(exchange='',
                              routing_key='Data.CPU',
                              body=message)

        print(f"[x] Enviado: {message}")

        # Aguarda 1 segundo antes de enviar o próximo valor
        time.sleep(1)

except KeyboardInterrupt:
    print("\nEncerrando publicação...")
    connection.close()

