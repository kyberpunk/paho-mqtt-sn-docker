# Eclipse Paho MQTT-SN Transparent / Aggregating Gateway

This docker image contains custom build of Eclipse Paho MQTT-SN Gateway for **IPv4 UDP** packets. Images for ARM platforms are supported.

[MQTT-SN protocol](http://www.mqtt.org/new/wp-content/uploads/2009/06/MQTT-SN_spec_v1.2.pdf) requires a MQTT-SN Gateway which acts as a protocol converter to convert MQTT-SN messages to MQTT messages. MQTT-SN client can not communicate directly with MQTT broker (TCP/IP). You can find more information on [project GitHub](https://github.com/eclipse/paho.mqtt-sn.embedded-c/tree/master/MQTTSNGateway).

## Build docker image

Clone the repository with `--recursive`

```
git submodule update
docker build [--build-arg PROTOCOL=<protocol>] .
```

Following protocols are supported:
* udp (default)
* udp6
* dtls
* dtls6
* loralink
* xbee

## Using the image

### Using default configuration

Run gateway with default configuration. By default application is listening on port 10000 and connects to broker [mqtt.eclipse.org](https://mqtt.eclipse.org/).

```
docker run -d -p 10000:10000 -p 10000:10000/udp kyberpunk/paho
```

### Using custom MQTT broker settings

Run gateway with custom settings of MQTT broker IP address and port.

```
docker run -d -p 10000:10000 -p 10000:10000/udp kyberpunk/paho --broker-name $HOST --broker-port $PORT
```

Modify $HOST to the target MQTT broker hostname or IP address and $PORT to target broker port number.

### Using custom configuration

Run gateway with custom configuration on filesystem. You can adjust default configuration template from [Eclipse project GitHub](https://github.com/eclipse/paho.mqtt-sn.embedded-c/blob/master/MQTTSNGateway/gateway.conf)

```
docker run -d -p 10000:10000 -p 10000:10000/udp -v $PWD/gateway.conf:/etc/paho/gateway.conf:ro kyberpunk/paho
```

Modify $PWD to the directory where you stored the configuration file.