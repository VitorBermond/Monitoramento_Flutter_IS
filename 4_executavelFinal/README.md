# Aplicação de monitoramento de métricas de desempenho com modos tempo real e histórico

Esse projeto é uma interface flutter que recebe valores simulados de multiplas métricas via RabbitMQ e as plota em gráfico construídos usando a biblioteca fl_charts. A aplicação foi construída e compilada para linux e então empacotada em formato .deb. O arquivo zipado são os arquivos utilizados para construir o executável. Já o arquivo .deb é o arquivo utilizado para instalar a interface localmente.

o .deb foi construído utilizando o tutorial disponível em:

https://jacodouhoje.dev/2025/02/06/como-criar-um-binario-para-distribuir-aplicativos-flutter-no-linux/

# ⚙️ Pré-requisitos

Sistema operacional Linux Ubuntu

# Instruções para executar a aplicação

Abra o executável (monitoramentoapp-deb.deb)

Instale

Abra o gerenciador de apps do Linux e abra a aplicação (monitoramentoapp)

# Se tudo cer certo...

A aplicação irá abrir. Existirá diferentes telas para serem acessadas e monitorar as respectivas métricas. Mais informações no documento do TCC.

# Teste a funcionalidade

 - Para testar localmente, instale o docker e as bibliotecas necessárias.

sudo snap install docker

sudo apt install python3-pika

 - Execute a imagem docker oficial do RabbitMQ:

sudo docker run -it --rm --name rabbitmq -p 5672:5672 -p 15672:15672 rabbitmq:4-management

 - Execute um serviço que publica dados simulados de CPU. Eles serão recebidos e plotados nos gráficos da tela de CPU dentro da aplicação:

python3 pubunixCPU.py

 - O resultado esperado é algo como a imagem img.png

<div align="center">
  <img src="https://raw.githubusercontent.com/VitorBermond/Monitoramento_Flutter_IS/master/4_executavelFinal/img.png" width="700px" />
</div>




