import pika
import json
import random
import time
import csv
import os
from datetime import datetime, timedelta, UTC

# Configuração da conexão com o RabbitMQ
connection = pika.BlockingConnection(pika.ConnectionParameters(host='localhost'))
channel = connection.channel()

# Declara a fila específica para número de instâncias
fila = 'Data.NI'
channel.queue_declare(queue=fila, durable=False)

# Lista de nomes de serviços
service_names = ["1A", "2B", "3C", "4D"]

def remove_old_data(filename):
    """Remove registros com mais de 30 dias do CSV específico."""
    if not os.path.isfile(filename):
        return

    with open(filename, mode='r', newline='') as file:
        reader = csv.reader(file, delimiter=';')
        rows = [row for row in reader if row]

    if len(rows) <= 1:
        return

    header = rows[0]
    now = datetime.now(UTC)
    threshold_date = now - timedelta(days=30)

    filtered_rows = [header]
    for row in rows[1:]:
        if len(row) < 1:
            continue
        try:
            raw_ts = int(row[0])
            if not (0 < raw_ts < int(now.timestamp()) + 10):
                raise ValueError("Timestamp fora do intervalo válido")
            timestamp = datetime.fromtimestamp(raw_ts, UTC)
            if timestamp >= threshold_date:
                filtered_rows.append(row)
        except (ValueError, OSError) as e:
            print(f"[Erro] Registro inválido: {row[0]} | Erro: {e}")
            continue

    with open(filename, mode='w', newline='') as file:
        writer = csv.writer(file, delimiter=';')
        writer.writerows(filtered_rows)

try:
    while True:
        now = datetime.now(UTC)
        timestamp = int(now.timestamp())

        for service_name in service_names:
            numero_instancias = random.randint(0, 3)

            message = json.dumps({
                "timestamp": timestamp,
                "NI": numero_instancias,
                "service_name": service_name
            })

            # Publica na fila
            channel.basic_publish(exchange='',
                                  routing_key=fila,
                                  body=message)

            # Cria o arquivo CSV correspondente
            csv_filename = f"ni_{service_name}.csv"
            file_exists = os.path.isfile(csv_filename)

            with open(csv_filename, mode='a', newline='') as file:
                writer = csv.writer(file, delimiter=';')
                if not file_exists:
                    writer.writerow(["timestamp", "NI"])
                writer.writerow([timestamp, numero_instancias])

            remove_old_data(csv_filename)

            print(f"[x] Serviço: {service_name} | Enviado: {message}")

        time.sleep(1)

except KeyboardInterrupt:
    print("\nEncerrando publicação...")
    connection.close()
