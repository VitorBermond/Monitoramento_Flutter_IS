# Grafico de CPU simulada simples

Esse projeto é uma interface flutter que recebe valores simulados de CPU via RabbitMQ e os plota num gráfico construído usando a biblioteca fl_charts

# ⚙️ Pré-requisitos

RabbitMQ rodando (Se não estiver rodando na máquina local, o ip das conexões no código deverão ser alterados)

Flutter instalado

Git instalado

# Setup de serviços

Inicie o serviço publicador localizado na pasta python_services

python3 pubcpu.py

# Iniciar aplicação flutter

Execute os seguintes comandos no diretorio do projeto

flutter clean 

flutter pub get

flutter run

