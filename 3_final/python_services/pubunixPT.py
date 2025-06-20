import pika
import json
import random
import time
import csv
import os
import uuid
from datetime import datetime, timedelta, UTC

# Configuração da conexão com o RabbitMQ
connection = pika.BlockingConnection(pika.ConnectionParameters(host='localhost'))
channel = connection.channel()

fila = 'Data.PT'
channel.queue_declare(queue=fila, durable=False)

service_names = ["1A", "2B", "3C", "4D"]

def remove_old_data(filename):
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
        try:
            raw_ts = int(row[0])
            timestamp = datetime.fromtimestamp(raw_ts, UTC)
            if timestamp >= threshold_date:
                filtered_rows.append(row)
        except Exception:
            continue

    with open(filename, mode='w', newline='') as file:
        writer = csv.writer(file, delimiter=';')
        writer.writerows(filtered_rows)

try:
    while True:
        now = datetime.now(UTC)
        timestamp = int(now.timestamp())
        ts_nano = int(now.timestamp() * 1_000_000_000)  # agora em nanossegundos


        for service_name in service_names:
            duration_ms = round(random.uniform(0.01, 0.0001),4)  # duração entre 1 e 50 ms
            duration_us = int(duration_ms * 1000)

            trace_id = uuid.uuid4().hex[:16]
            parent_id = uuid.uuid4().hex[:16]
            span_id = uuid.uuid4().hex[:16]

            message_dict = {
                "traceId": trace_id,
                "parentId": parent_id,
                "id": span_id,
                "name": "grayprocess",
                "timestamp": timestamp,
                "duration": duration_us,
                "localEndpoint": {
                    "serviceName": f"{service_name}",
                    "port": 30200
                },
                "tags": {
                    "Tempo de Processamento (ms)": duration_ms
                }
            }

            message = json.dumps(message_dict)

            channel.basic_publish(exchange='',
                                  routing_key=fila,
                                  body=message)

            csv_filename = f"processing_time_{service_name}.csv"
            file_exists = os.path.isfile(csv_filename)

            with open(csv_filename, mode='a', newline='') as file:
                writer = csv.writer(file, delimiter=';')
                if not file_exists:
                    writer.writerow(["timestamp", "tempo_processamento_ms"])
                writer.writerow([timestamp, duration_ms])

            remove_old_data(csv_filename)
            print(f"[x] Serviço: {service_name} | Enviado: {message}")

        time.sleep(1)

except KeyboardInterrupt:
    print("\nEncerrando publicação...")
    connection.close()
