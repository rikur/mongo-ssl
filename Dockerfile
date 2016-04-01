FROM ubuntu
MAINTAINER fernand.galiana@gmail.com

RUN apt-get update && apt-get -y install \
  build-essential \
  git-core \
  scons \
  libssl-dev \
  libboost-filesystem-dev \
  libboost-program-options-dev \
  libboost-system-dev \
  libboost-thread-dev

RUN apt-get install curl -qy

ADD ./mongo /var/downloads/mongo

WORKDIR /var/downloads/mongo

RUN mkdir -p /usr/local/bin
RUN git checkout r3.2.1
RUN scons mongod --ssl -j8 --prefix=/usr/local
RUN cp /var/downloads/mongo/build/opt/mongo/mongod /usr/local/bin && rm -rf /var/downloads

RUN mkdir -p /data/db

EXPOSE 27017
CMD ["/usr/local/bin/mongod", "--config", "/etc/mongod.yaml"]

# SSL key
RUN openssl req -newkey rsa:2048 -new -nodes -x509 -days 3650 -subj "/C=CA/ST=BC/L=Vancouver/O=Monstercat/CN=mongo.monstercat.com" -keyout /tmp/mongod-snakeoil-key.pem -out /tmp/mongod-snakeoil-cert.pem && cat /tmp/mongod-snakeoil-cert.pem /tmp/mongod-snakeoil-key.pem > /etc/mongod-snakeoil.pem

# Cleanup
RUN apt-get remove -y --purge git-core scons build-essential libssl-dev libboost-filesystem-dev libboost-program-options-dev libboost-system-dev libboost-thread-dev curl \
    && apt-get autoremove -y --purge \
    && apt-get clean autoclean \
    && rm -rf /var/lib/{apt,dpkg,cache,lists} /tmp/* /var/tmp/*

ADD ./mongod.yaml /etc/mongod.yaml

WORKDIR /