FROM alpine AS builder
ARG PROTOCOL=udp

RUN apk add --no-cache make cmake g++ gcc openssl-dev net-tools tcpdump bash patch

WORKDIR /app/paho

ADD ./paho.mqtt-sn.embedded-c /app/paho
ADD ./docker_entrypoint.sh /app/paho/docker_entrypoint.sh
ADD ./patch /app/paho/patch

RUN mkdir /usr/local/sbin && chmod 755 /usr/local/sbin

RUN patch -Np0 < /app/paho/patch/MQTTSNGWLogmonitor.cpp.patch && patch -Np0 < /app/paho/patch/MQTTSNGWProcess.cpp.patch

RUN cd /app/paho/MQTTSNGateway && chmod +x build.sh && ./build.sh ${PROTOCOL}

RUN cd /app/paho/MQTTSNGateway && mkdir /etc/paho/ && cp bin/MQTT-SNGateway bin/MQTT-SNLogmonitor /usr/local/sbin/ && cp bin/clients.conf bin/gateway.conf bin/predefinedTopic.conf /etc/paho/ && cp ../build.gateway/MQTTSNPacket/src/libMQTTSNPacket.so /usr/local/lib/

RUN chmod 755 /etc/paho/gateway.conf

FROM alpine:latest

RUN apk add --no-cache openssl libgcc libstdc++

COPY --from=builder /etc/paho/ /etc/paho/
COPY --from=builder /usr/local/sbin/ /usr/local/sbin/
COPY --from=builder /usr/local/lib/ /usr/local/lib/
COPY --from=builder /app/paho/docker_entrypoint.sh /app/paho/MQTTSNGateway/docker_entrypoint.sh

RUN addgroup -S docker && adduser -S docker -G docker

RUN ldconfig /usr/local/lib/

USER docker

ENTRYPOINT ["/app/paho/MQTTSNGateway/docker_entrypoint.sh"]

EXPOSE 10000 10000/udp
