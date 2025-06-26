import pika
import json
import csv
import os

# Conexão com o RabbitMQ
connection = pika.BlockingConnection(pika.ConnectionParameters(host='localhost'))
channel = connection.channel()

# Declaração das filas
channel.queue_declare(queue='HistRequest.CPU', durable=False)
channel.queue_declare(queue='Hist.CPU', durable=False)

def buscar_historico_para_planilha(filename, start_epoch, end_epoch):
    if not os.path.isfile(filename):
        return []

    historico = []

    with open(filename, mode='r', newline='') as file:
        reader = csv.reader(file, delimiter=';')

        header = next(reader, None)
        if header != ["timestamp", "cpu_usage"]:
            print(f"Erro: Cabeçalho inválido em {filename}: {header}")
            return []

        for row in reader:
            if len(row) != 2:
                continue

            try:
                row_epoch = float(row[0])
                cpu_usage = float(row[1])
            except ValueError:
                continue

            if start_epoch <= row_epoch <= end_epoch:
                historico.append({
                    "timestamp": row_epoch,
                    "cpu_usage": cpu_usage
                    # REMOVIDO o 'timeIndex'
                })

    return historico


def callback(ch, method, properties, body):
    try:
        request = json.loads(body)

        services = request.get("services_list", [])
        start_epoch = int(request.get("start_datetime", 0))
        end_epoch = int(request.get("end_datetime", 0))

        if not services:
            print("[!] Nenhum serviço especificado.")
            return

        for service_name in services:
            filename = f"cpu_usage_{service_name}.csv"
            historico = buscar_historico_para_planilha(filename, start_epoch, end_epoch)

            response = json.dumps({
                "service_name": service_name,
                "historico": historico
            })

            channel.basic_publish(
                exchange='',
                routing_key='Hist.CPU',
                body=response
            )

            print(f"[✓] Histórico de {service_name} enviado com {len(historico)} pontos.")

    except Exception as e:
        print(f"[!] Erro no callback: {e}")


channel.basic_consume(queue='HistRequest.CPU', on_message_callback=callback, auto_ack=True)
print("[x] Aguardando requisições de histórico...")
channel.start_consuming()
