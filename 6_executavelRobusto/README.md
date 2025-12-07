# Aplicação de monitoramento de métricas de desempenho com modos tempo real e histórico

Esse projeto é uma interface flutter que recebe métricas via RabbitMQ e as plota em gráfico construídos usando a biblioteca fl_charts. A aplicação foi construída e compilada para linux e então empacotada em formato .deb.

# ⚙️ Pré-requisitos

Sistema operacional Linux

# Instruções para executar a aplicação

Abra o executável (monitoramentoapp-deb.deb)

Instale

Abra o gerenciador de apps do Linux e abra a aplicação (monitoramentoapp)

# Se tudo cer certo...

A aplicação irá abrir. Existirá uma tela para monitorar métricas.

# Teste a funcionalidade

 - Para testar localmente, instale o docker e as bibliotecas necessárias.

sudo snap install docker

sudo apt install python3-pika

 - Execute a imagem docker oficial do RabbitMQ:

sudo docker run -it --rm --name rabbitmq -p 5672:5672 -p 15672:15672 rabbitmq:4-management

 - Configure as conexões de acordo como os dados serão publicados. A configuração é feita na tela de configurações que pode ser acessada clicando no icone de engrenagem.

 - Um exemplo de configuração é a feita para receber os dados simulados do serviço "pubunixCPU.py" ilustrado na img2.png

 <div align="center">
  <img src="https://raw.githubusercontent.com/VitorBermond/Monitoramento_Flutter_IS/master/6_executavelRobusto/img2.png" width="700px" />
</div>

 - Os campos do JSON e a fila a receber os dados devem bater com os do publicador.

 - Execute o serviço que publica dados simulados de CPU. Eles serão recebidos e plotados no gráfico dentro da aplicação:

python3 pubunixCPU.py

 - O resultado esperado é algo como a imagem img.png

<div align="center">
  <img src="https://raw.githubusercontent.com/VitorBermond/Monitoramento_Flutter_IS/master/4_executavelFinal/img.png" width="700px" />
</div>

 - (A função de histórico não foi atualizada)

