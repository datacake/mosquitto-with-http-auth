FROM debian:jessie

ENV MOSQUITTO_VERSION=1.5.5 \
    GPG_KEYS=A0D6EEA1DCAE49A635A3B2F0779B22DFB3E717B7

RUN \
        set -x; \
        apt-get update && apt-get install -y --no-install-recommends \
                libc-ares-dev git libmysqlclient-dev libssl-dev   uuid-dev build-essential wget  ca-certificates \
                curl libcurl4-openssl-dev  libc-ares2 libcurl3 \
        && cd /tmp \
        && wget http://mosquitto.org/files/source/mosquitto-$MOSQUITTO_VERSION.tar.gz -O mosquitto.tar.gz \
        && wget http://mosquitto.org/files/source/mosquitto-$MOSQUITTO_VERSION.tar.gz.asc -O mosquitto.tar.gz.asc \
        export GNUPGHOME="$(mktemp -d)" && \
        found=''; \
        for server in \
            ha.pool.sks-keyservers.net \
            hkp://keyserver.ubuntu.com:80 \
            hkp://p80.pool.sks-keyservers.net:80 \
            pgp.mit.edu \
        ; do \
            echo "Fetching GPG key $GPG_KEYS from $server"; \
            gpg --keyserver "$server" --keyserver-options timeout=10 --recv-keys "$GPG_KEYS" && found=yes && break; \
        done; \
        gpg --verify mosquitto.tar.gz.asc \
        && mkdir mosquitto-src && tar xfz mosquitto.tar.gz --strip-components=1 -C mosquitto-src \
        && cd mosquitto-src \
        && make WITH_SRV=yes WITH_MEMORY_TRACKING=no \
        && make install && ldconfig \
        && git clone https://github.com/jpmens/mosquitto-auth-plug.git \
        && cd mosquitto-auth-plug \
        && git checkout tags/0.1.3 -b latest \
        && cp config.mk.in config.mk \
        && sed -i "s/BACKEND_HTTP ?= no/BACKEND_HTTP ?= yes/" config.mk \
        && sed -i "s/BACKEND_MYSQL ?= yes/BACKEND_MYSQL ?= no/" config.mk \
        && sed -i "s/CFG_LDFLAGS =/CFG_LDFLAGS = -lcares/" config.mk \
        && sed -i "s/MOSQUITTO_SRC =/MOSQUITTO_SRC = \/tmp\/mosquitto-src\//" config.mk \
        && sed -i "s/SUPPORT_DJANGO_HASHERS ?= no/SUPPORT_DJANGO_HASHERS ?= yes/" config.mk \
        && make \
        && cp np /usr/bin/np \
        && mkdir /mqtt && cp auth-plug.so /mqtt/ \
        && cp auth-plug.so /usr/local/lib/ \
        && useradd -r mosquitto \
        && apt-get purge -y build-essential git wget ca-certificates \
        && apt-get autoremove -y \
        && apt-get -y autoclean \
        && rm -rf /var/cache/apt/* \
        && rm -rf  /tmp/*

VOLUME ["/var/lib/mosquitto"]

EXPOSE 1883 8883

ADD run.sh /run.sh
RUN chmod +x /run.sh

ENTRYPOINT ["/run.sh"]
CMD ["mosquitto"]