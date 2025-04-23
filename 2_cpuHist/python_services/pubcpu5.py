import pika
import json
import random
import time
import csv
import os
from datetime import datetime, timedelta, timezone

# Define o fuso horário do Brasil (UTC-3)
brasil_tz = timezone(timedelta(hours=-3))

# Configuração da conexão com o RabbitMQ
connection = pika.BlockingConnection(pika.ConnectionParameters(host='localhost'))
channel = connection.channel()

# Declaração da fila (se não existir, será criada)
channel.queue_declare(queue='Data.CPU', durable=False)

# Nome do arquivo CSV para armazenar os dados
csv_filename = "cpu_usage_data.csv"

# Verifica se o arquivo já existe para escrever o cabeçalho
file_exists = os.path.isfile(csv_filename)

# Abre o arquivo no modo de adição
with open(csv_filename, mode='a', newline='') as file:
    writer = csv.writer(file, delimiter=';')  # Usa ponto e vírgula como separador
    
    # Escreve o cabeçalho caso o arquivo esteja sendo criado agora
    if not file_exists:
        writer.writerow(["timestamp", "cpu_usage"])

def remove_old_data():
    """Remove registros com mais de 30 dias."""
    if not os.path.isfile(csv_filename):
        return
    
    # Lê os dados existentes
    with open(csv_filename, mode='r', newline='') as file:
        reader = csv.reader(file, delimiter=';')
        rows = [row for row in reader if row]  # Remove linhas vazias
    
    # Verifica se há pelo menos duas linhas (cabeçalho + dados)
    if len(rows) <= 1:
        return  # Nenhum dado a ser processado

    # Mantém o cabeçalho e filtra os dados recentes
    header = rows[0]
    now = datetime.now(brasil_tz)
    threshold_date = now - timedelta(days=30)
    
    filtered_rows = [header]  # Inicializa a lista com o cabeçalho

    for row in rows[1:]:
        if len(row) < 1:
            continue  # Pula linhas vazias ou incompletas
        try:
            timestamp = datetime.fromisoformat(row[0])
            if timestamp >= threshold_date:
                filtered_rows.append(row)
        except ValueError:
            print(f"[Erro] Formato de data inválido encontrado: {row[0]}")
            continue  # Ignora linhas com formatos incorretos

    # Reescreve o arquivo com os dados filtrados
    with open(csv_filename, mode='w', newline='') as file:
        writer = csv.writer(file, delimiter=';')
        writer.writerows(filtered_rows)


try:
    while True:
        # Gera um valor aleatório de uso de CPU entre 0 e 100
        cpu_usage = round(random.uniform(0, 100), 2)
        
        # Captura o timestamp atual com o fuso horário do Brasil
        now = datetime.now(brasil_tz)
        timestamp = now.isoformat()

        # Cria uma mensagem JSON
        message = json.dumps({
            "timestamp": timestamp,
            "cpu_usage": cpu_usage
        })
        
        # Publica a mensagem na fila
        channel.basic_publish(exchange='',
                              routing_key='Data.CPU',
                              body=message)
        
        # Salva a medição no arquivo CSV
        with open(csv_filename, mode='a', newline='') as file:
            writer = csv.writer(file, delimiter=';')
            writer.writerow([timestamp, cpu_usage])
        
        # Realiza a manutenção dos dados
        remove_old_data()
        
        print(f"[x] Enviado e salvo: {message}")
        
        # Aguarda 1 segundo antes de enviar o próximo valor
        time.sleep(1)

except KeyboardInterrupt:
    print("\nEncerrando publicação...")
    connection.close()
