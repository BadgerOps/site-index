FROM alpine:latest

RUN apk add --update python py-pip
RUN pip install --upgrade pip

COPY requirements.txt /
RUN pip install -r /requirements.txt 

COPY server.py /
COPY default.cfg /
RUN mkdir /templates /static
COPY templates/index.html /templates
COPY static /static/

ENV CONSUL_HTTP_ADDR consul.service.consul:8500

EXPOSE 5000

CMD python /server.py
