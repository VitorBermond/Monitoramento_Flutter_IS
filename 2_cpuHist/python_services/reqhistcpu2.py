import pika
import json
import csv
import os
from datetime import datetime, timedelta, timezone

# Configuração da conexão com o RabbitMQ
connection = pika.BlockingConnection(pika.ConnectionParameters(host='localhost'))
channel = connection.channel()

# Declaração das filas
channel.queue_declare(queue='HistRequest.CPU', durable=False)
channel.queue_declare(queue='Hist.CPU', durable=False)

# Nome do arquivo CSV para armazenar os dados
csv_filename = "cpu_usage_data.csv"

# Fuso horário UTC-3 (Brasília)
BRASIL_TZ = timezone(timedelta(hours=-3))

def buscar_historico(start_datetime, end_datetime):
    if not os.path.isfile(csv_filename):
        return []

    historico = []
    time_index = 0  # Inicializa o timeIndex para o histórico

    with open(csv_filename, mode='r', newline='') as file:
        reader = csv.reader(file, delimiter=';')
        
        header = next(reader)
        if header != ["timestamp", "cpu_usage"]:
            print(f"Erro: Cabeçalho inválido encontrado: {header}")
            return []

        for row in reader:
            if len(row) != 2:
                continue  # Pula linhas inválidas

            try:
                row_timestamp = datetime.fromisoformat(row[0])
                
                # Converte para UTC-3 se o timestamp não tiver fuso horário
                if row_timestamp.tzinfo is None:
                    row_timestamp = row_timestamp.replace(tzinfo=BRASIL_TZ)
                else:
                    row_timestamp = row_timestamp.astimezone(BRASIL_TZ)
                
                cpu_usage = float(row[1])
            except ValueError:
                continue  # Pula linhas mal formatadas

            if start_datetime <= row_timestamp <= end_datetime:
                historico.append({
                    "timestamp": row_timestamp.strftime("%H:%M:%S"),
                    "cpu_usage": cpu_usage,
                    "timeIndex": time_index
                })
                time_index += 1

    return historico


def callback(ch, method, properties, body):
    try:
        request = json.loads(body)
        
        # Garantir que os valores sejam inteiros
        start_year = int(request.get("start_year", 2025))
        start_month = int(request.get("start_month", 1))
        start_day = int(request.get("start_day", 1))
        start_hour = int(request.get("start_hour", 0))
        start_minute = int(request.get("start_minute", 0))
        
        end_year = int(request.get("end_year", 2025))
        end_month = int(request.get("end_month", 1))
        end_day = int(request.get("end_day", 1))
        end_hour = int(request.get("end_hour", 23))
        end_minute = int(request.get("end_minute", 59))

        # Criação dos objetos datetime com fuso horário
        try:
            start_datetime = datetime(start_year, start_month, start_day, start_hour, start_minute, tzinfo=BRASIL_TZ)
            end_datetime = datetime(end_year, end_month, end_day, end_hour, end_minute, tzinfo=BRASIL_TZ)
        except ValueError as e:
            print(f"Erro na criação do datetime: {e}")
            return

        # Busca o histórico no arquivo CSV
        historico = buscar_historico(start_datetime, end_datetime)

        # Preparar a resposta para envio
        response = json.dumps({"historico": historico})

        # Enviar a resposta para a fila 'Hist.CPU'
        channel.basic_publish(
            exchange='',
            routing_key='Hist.CPU',
            body=response
        )
        
        print(f"[x] Histórico enviado com sucesso! {len(historico)} registros encontrados.")
        
    except Exception as e:
        print(f"Erro no callback: {e}")


channel.basic_consume(queue='HistRequest.CPU', on_message_callback=callback, auto_ack=True)
print("[x] Aguardando requisições de histórico...")
channel.start_consuming()
