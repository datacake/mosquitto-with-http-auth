FROM debian:jessie

COPY be-http.patch /tmp/be-http.patch
RUN sed -i '/jessie-updates/d' /etc/apt/sources.list
RUN apt-get -o Acquire::Check-Valid-Until=false update
RUN \
    apt-get update && apt-get install -y git cmake libc-ares-dev uuid-dev libssl-dev zlib1g-dev wget build-essential libcurl4-openssl-dev \
    && wget https://github.com/warmcat/libwebsockets/archive/v1.6.2.tar.gz \
    && tar xzvf v1.6.2.tar.gz \
    && cd libwebsockets-1.6.2 \
    && mkdir build \
    && cd build \
    && cmake .. -DLIB_SUFFIX=64 \
    && make install \
    && ln -s /usr/local/lib64/libwebsockets.so.6 /lib/libwebsockets.so.6 \
    && cd ../.. \
    && wget http://mosquitto.org/files/source/mosquitto-1.5.8.tar.gz \
    && tar xzvf mosquitto-1.5.8.tar.gz \
    && cd mosquitto-1.5.8 \
    && make WITH_WEBSOCKETS=yes \
    && make install \
    && groupadd mosquitto \
    && useradd -s /sbin/nologin mosquitto -g mosquitto -d /var/lib/mosquitto \
    && git clone https://github.com/datacake/mosquitto-auth-plug.git \
    && cd mosquitto-auth-plug \
    && git checkout tags/0.1.3 -b latest \
    && patch be-http.c < /tmp/be-http.patch \
    && cp config.mk.in config.mk \
    && sed -i "s/BACKEND_HTTP ?= no/BACKEND_HTTP ?= yes/" config.mk \
    && sed -i "s/BACKEND_MYSQL ?= yes/BACKEND_MYSQL ?= no/" config.mk \
    && sed -i "s/CFG_LDFLAGS =/CFG_LDFLAGS = -lcares/" config.mk \
    && sed -i "s/MOSQUITTO_SRC =/MOSQUITTO_SRC = \/tmp\/mosquitto-src\//" config.mk \
    && sed -i "s/SUPPORT_DJANGO_HASHERS ?= no/SUPPORT_DJANGO_HASHERS ?= yes/" config.mk \
    && echo "WITH_WEBSOCKETS:=yes" >> config.mk \
    && make \
    && cp np /usr/bin/np \
    && mkdir /mqtt && cp auth-plug.so /mqtt/ \
    && cp auth-plug.so /usr/local/lib/ \
    # && useradd -r mosquitto \
    && apt-get purge -y build-essential git wget ca-certificates \
    && apt-get autoremove -y \
    && apt-get -y autoclean \
    && rm -rf /var/cache/apt/* \
    && rm -rf  /tmp/*

COPY mosquitto.conf /etc/mosquitto/mosquitto.conf
VOLUME ["/var/lib/mosquitto"]

EXPOSE 1883 8883

ADD run.sh /run.sh
RUN chmod +x /run.sh

ENTRYPOINT ["/run.sh"]
CMD ["mosquitto"]