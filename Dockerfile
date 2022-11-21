# notice that 22.04 has some issues on older docker hosts, so we stick to older version for now
FROM ubuntu:20.04 as run

# Install prerequisites
# notice that screen and sudo are because nquake installer needs them
RUN apt-get update \
  && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    apt-utils \
    ca-certificates \
    curl \
    unzip \
    zip \
    wget \
    dos2unix \
    gettext \
    dnsutils \
    qstat \
    screen \
    sudo \
    gosu \
  && rm -rf /var/lib/apt/lists/*

RUN useradd -rm -d /nquake -s /bin/bash -u 1001 qw
ENV HOME=/nquake/
COPY .wgetrc /nquake/.wgetrc
# install and run only one server (-p 1)
RUN curl -o /tmp/install_nquakesv.sh https://raw.githubusercontent.com/nQuake/server-linux/master/src/install_nquakesv.sh \
    && chmod +x /tmp/install_nquakesv.sh \
    && /tmp/install_nquakesv.sh -n -p=1 /nquake

# Copy files
COPY scripts/healthcheck.sh /healthcheck.sh
COPY scripts/entrypoint.sh /entrypoint.sh

RUN find /nquake -type f -print0 | xargs -0 dos2unix -q \
    && chown -R qw:qw /nquake

# do not run as root
USER qw
WORKDIR /nquake

USER qw
ENTRYPOINT ["/entrypoint.sh"]
# change "server" to something like: "qtv", "qwfwd", "server"
CMD ["server"]

