FROM couchbase:community-6.6.0

MAINTAINER Anovel Team <kuzanisu@gmail.com>

# Install dependencies.
RUN apt-get update && \
    apt-get -y upgrade && \
    apt-get -y install gcc git && \
    apt-get autoremove && \
    apt-get clean

RUN cd /usr/local && wget -q https://dl.google.com/go/go1.15.6.linux-amd64.tar.gz && \
    tar -C /usr/local -xzf go1.15.6.linux-amd64.tar.gz

# Create env variables.
ENV DIVAN_CONFIG /root/DIVAN_config/config.json
ENV DIVAN_SCRIPTS /root/DIVAN_scripts
ENV TERM xterm-256color
ENV GO111MODULE=on
ENV PATH="${PATH}:/usr/local/go/bin"

# Create scripts directory.
RUN mkdir /root/DIVAN_config
RUN mkdir $DIVAN_SCRIPTS

# Clone directory.
RUN cd ~ && git clone -b master https://github.com/a-novel/divan-docker.git

# Copy scripts.
RUN cp -r ~/divan-docker/go_scripts/ $DIVAN_SCRIPTS/
# Remove git folder.
RUN rm -rf ~/divan-docker

# Make config scripts executable.
RUN chmod -R +rwx $DIVAN_SCRIPTS
RUN chmod -R +rw /root/DIVAN_config

ENTRYPOINT [ "bash", "/root/DIVAN_scripts/scripts/entrypoint.sh" ]