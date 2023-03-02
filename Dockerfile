#  Copyright (c) 2018, Vit Holasek.
#  All rights reserved.
#
#  Redistribution and use in source and binary forms, with or without
#  modification, are permitted provided that the following conditions are met:
#  1. Redistributions of source code must retain the above copyright
#     notice, this list of conditions and the following disclaimer.
#  2. Redistributions in binary form must reproduce the above copyright
#     notice, this list of conditions and the following disclaimer in the
#     documentation and/or other materials provided with the distribution.
#  3. Neither the name of the copyright holder nor the
#     names of its contributors may be used to endorse or promote products
#     derived from this software without specific prior written permission.
#
#  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
#  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
#  IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
#  ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
#  LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
#  CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
#  SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
#  INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
#  CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
#  ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
#  POSSIBILITY OF SUCH DAMAGE.
#

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
