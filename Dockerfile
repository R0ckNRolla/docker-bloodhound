FROM openjdk:11-jre
MAINTAINER github.com/belane
ARG neo4j=4.2.3
ARG bloodhound=4.0.1

# Base packages
RUN apt-get update -qq &&\
    apt-get install --no-install-recommends -y -qq\
      wget \
      git \
      unzip \
      curl \
      gnupg \
      libgtk2.0-bin \
      libcanberra-gtk-module \
      libx11-xcb1 \
      libva-glx2 \
      libgl1-mesa-glx \
      libgl1-mesa-dri \
      libgconf-2-4 \
      libasound2 \
      libxss1 \
      libatk-bridge2.0-0 \
      libgtk-3-0 \
      libgbm1 \
      libxtst6 \
      libnss3 \
      libnspr4

# BloodHound
RUN wget https://github.com/BloodHoundAD/BloodHound/releases/download/$bloodhound/BloodHound-linux-x64.zip -nv -P /tmp &&\
    unzip -q /tmp/BloodHound-linux-x64.zip -d /opt/ &&\
    mkdir /opt/BloodHound-linux-x64/Ingestors && \
    mkdir /data && \
    wget https://github.com/BloodHoundAD/BloodHound/raw/$bloodhound/Ingestors/SharpHound.ps1 -nv -P /opt/BloodHound-linux-x64/Ingestors && \
    wget https://github.com/BloodHoundAD/BloodHound/raw/$bloodhound/Ingestors/SharpHound.exe -nv -P /opt/BloodHound-linux-x64/Ingestors && \
    chmod +x /opt/BloodHound-linux-x64/BloodHound

# BloodHound Config
COPY config/*.json /root/.config/bloodhound/


# BloodHound Test Data
#RUN if [ "$data" = "example" ]; then \
#    git clone https://github.com/adaptivethreat/BloodHound.git /tmp/BloodHound/ &&\
#    cp -r /tmp/BloodHound/BloodHoundExampleDB.graphdb /var/lib/neo4j/data/databases/ &&\
#    chown -R neo4j:neo4j /var/lib/neo4j/data/databases/BloodHoundExampleDB.graphdb/ &&\
#    echo "dbms.active_database=BloodHoundExampleDB.graphdb" >> /etc/neo4j/neo4j.conf &&\
#    echo "dbms.allow_upgrade=true" >> /etc/neo4j/neo4j.conf; fi

# Start
RUN echo '#!/usr/bin/env bash\n\
    echo "Starting ..."\n\
    sed -i -r "s#\"password\": \"[^\"]+\"#\"password\": \"${PASSWORD}\"#g" /root/.config/bloodhound/config.json \n\
    if [ ! -e /opt/.ready ]; then touch /opt/.ready\n\
    echo "First run takes some time"; sleep 5\n\
    sleep 10 \n\
    fi \n\
    cp -n /opt/BloodHound-linux-x64/Ingestors/SharpHound.* /data\n\
    echo "\e[92m*** Log in with bolt://neo4j:7687 (neo4j:${PASSWORD}) ***\e[0m"\n\
    sleep 7; /opt/BloodHound-linux-x64/BloodHound --no-sandbox --disable-dev-shm-usage \n' > /opt/run.sh &&\
    chmod +x /opt/run.sh


# Clean up
RUN apt-get clean &&\
    apt-get clean autoclean &&\
    apt-get autoremove -y &&\
    rm -rf /tmp/* &&\
    rm -rf /var/lib/{apt,dpkg,cache,log}/

WORKDIR /data
CMD ["/opt/run.sh"]
