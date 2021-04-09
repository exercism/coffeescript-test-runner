FROM node:erbium-buster-slim as runner

RUN apt-get update && \
    apt-get install -y jq && \
    apt-get purge --auto-remove -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

ENV NO_UPDATE_NOTIFIER true

WORKDIR /opt/test-runner

# Pre-install packages
COPY package.json .
COPY package-lock.json .
RUN npm install

COPY . .
ENTRYPOINT ["/opt/test-runner/bin/run.sh"]