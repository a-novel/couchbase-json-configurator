FROM couchbase:community-6.6.0

MAINTAINER Anovel Team <kuzanisu@gmail.com>

# Install dependencies.
RUN apt-get update && apt-get install -yq jq bc git && apt-get autoremove && apt-get clean

ENV DIVAN_CONFIG_FOLDER /root/DIVAN-config
ENV DIVAN_CONFIG /root/DIVAN-config/config.json
ENV DIVAN_SCRIPTS /root/DIVAN-scripts
ENV TERM xterm-256color
ENV DIVAN_SECRET /root/DIVAN-config/secret.json

# Create scripts directory.
RUN mkdir $DIVAN_CONFIG_FOLDER
RUN mkdir $DIVAN_SCRIPTS

# Clone directory.
RUN cd ~ && git clone -b master https://github.com/a-novel/divan-docker.git

# Copy scripts.
RUN cp -r ~/divan-docker/scripts/. $DIVAN_SCRIPTS/
# Remove git folder.
RUN rm -rf ~/divan-docker

# Make config scripts executable.
RUN chmod -R +rx $DIVAN_SCRIPTS
RUN chmod -R +rw $DIVAN_CONFIG_FOLDER

ENTRYPOINT [ "bash", "/root/DIVAN-scripts/entrypoint.sh" ]