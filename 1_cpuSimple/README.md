# Grafico de CPU simulada simples

Esse projeto é uma interface flutter que recebe valores simulados de CPU via RabbitMQ e os plota num gráfico construído usando a biblioteca fl_charts

# ⚙️ Pré-requisitos

RabbitMQ rodando (Se não estiver rodando na máquina local, o ip das conexões deverão ser alterados dentro do código)

Flutter instalado

Python instalado

Git instalado

# Instruções para executar o projeto

## Clone o repositório

git clone https://github.com/VitorBermond/Monitoramento_Flutter_IS.git

## Entre na pasta referente a este projeto

cd Monitoramento_Flutter_IS/1_cpuSimple

## Inicie o serviço publicador localizado na pasta python_services

cd python_services

python3 pubcpu.py

## Preparação e execução da aplicação Flutter

cd .. (volta para o diretório)

flutter clean 

flutter pub get

flutter run

# Se tudo cer certo...

O gráfico irá ser constantemente atualizado com os dados aleatórios gerados pelo serviço
