# Grafico de CPU simulada com modo tempo real e histórico

Esse projeto é uma interface flutter que recebe valores simulados de CPU via RabbitMQ e os plota num gráfico construído usando a biblioteca fl_charts. A aplicação também conta com um banco de dados que pode ser consultado com comandos dentro da própria aplicação.

# ⚙️ Pré-requisitos

RabbitMQ rodando (Se não estiver rodando na máquina local, o ip das conexões deverão ser alterados dentro do código)

Flutter instalado

Python instalado

Git instalado

# Instruções para executar o projeto

## Clone o repositório

git clone https://github.com/VitorBermond/Monitoramento_Flutter_IS.git

## Entre na pasta referente a este projeto

cd Monitoramento_Flutter_IS/2_cpuHist

## Inicie o serviço publicador e de tratamento de históricos

cd python_services

python3 pubcpu5.py

python3 reqhistcpu2.py

## Preparação e execução da aplicação Flutter

cd .. (volta para o diretório)

flutter clean 

flutter pub get

flutter run

# Se tudo cer certo...

O gráfico irá ser constantemente atualizado com os dados aleatórios gerados pelo serviço publicador no modo tempo real;
O usuário poderá buscar dados registrados inserindo intervalos nos campos de data final e inicial -- e visualizar esses dados no modo histórico;
