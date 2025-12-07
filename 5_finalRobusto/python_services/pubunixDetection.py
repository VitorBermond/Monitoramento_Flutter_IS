import pika
import json
import random
import time
import csv
import os
import uuid
from datetime import datetime, timedelta, timezone

# Configuração da conexão com o RabbitMQ
connection = pika.BlockingConnection(pika.ConnectionParameters(host='localhost'))
channel = connection.channel()

fila = 'zipkin_logs'
channel.queue_declare(queue=fila, durable=False)

# Serviços a simular (exemplo com um detector de pessoas; adicione outros se quiser)
service_names = ["person.detector"]

def remove_old_data(filename):
    """Remove linhas com timestamp (em segundos ou microssegundos) mais antigas que 30 dias."""
    if not os.path.isfile(filename):
        return

    with open(filename, mode='r', newline='') as file:
        reader = csv.reader(file, delimiter=';')
        rows = [row for row in reader if row]

    if len(rows) <= 1:
        return

    header = rows[0]
    now = datetime.now(timezone.utc)
    threshold_date = now - timedelta(days=30)

    filtered_rows = [header]
    for row in rows[1:]:
        try:
            raw_ts = int(row[0])
            # Detecta se timestamp está em microssegundos (>= 1e12) ou em segundos
            if raw_ts > 10**12:
                ts_seconds = raw_ts / 1_000_000.0
            else:
                ts_seconds = raw_ts
            timestamp = datetime.fromtimestamp(ts_seconds, timezone.utc)
            if timestamp >= threshold_date:
                filtered_rows.append(row)
        except Exception:
            # ignora linhas malformadas
            continue

    with open(filename, mode='w', newline='') as file:
        writer = csv.writer(file, delimiter=';')
        writer.writerows(filtered_rows)

try:
    while True:
        now = datetime.now(timezone.utc)
        timestamp_micros = int(now.timestamp() * 1_000_000)  # timestamp em microssegundos

        for service_name in service_names:
            # duração em microssegundos: escolhi um intervalo razoável (5ms a 50ms -> 5000 a 50000 us)
            duration_us = random.randint(5_000, 50_000)

            trace_id = uuid.uuid4().hex[:16]
            parent_id = uuid.uuid4().hex[:16]
            span_id = uuid.uuid4().hex[:16]

            detections = random.randint(0, 3)  # 0 a 3 aleatoriamente

            message_dict = {
                "traceId": trace_id,
                "parentId": parent_id,
                "id": span_id,
                "name": "detection_and_render",
                "timestamp": timestamp_micros,
                "duration": duration_us,
                "localEndpoint": {
                    "serviceName": f"{service_name}",
                    "port": 30200
                },
                "tags": {
                    "Detections": detections
                }
            }

            message = json.dumps(message_dict)

            # publica no RabbitMQ
            channel.basic_publish(exchange='', routing_key=fila, body=message)

            # grava CSV por serviço (timestamp em microssegundos, detections como int)
            csv_filename = f"detections_{service_name.replace('.', '_')}.csv"
            file_exists = os.path.isfile(csv_filename)

            with open(csv_filename, mode='a', newline='') as file:
                writer = csv.writer(file, delimiter=';')
                if not file_exists:
                    writer.writerow(["timestamp_micros", "duration_us", "detections"])
                writer.writerow([timestamp_micros, duration_us, detections])

            # remove dados antigos (>30 dias)
            remove_old_data(csv_filename)

            # print no formato solicitado
            print("🚀 Log recebido:", json.dumps(message_dict, ensure_ascii=False))

        time.sleep(1)

except KeyboardInterrupt:
    print("\nEncerrando publicação...")
    try:
        connection.close()
    except Exception:
        pass
