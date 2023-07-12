FROM node:18-alpine
RUN apk add --no-cache jq coreutils bash

ENV NO_UPDATE_NOTIFIER true

WORKDIR /opt/test-runner

# Pre-install packages
COPY package.json .
COPY package-lock.json .
RUN npm install -g
COPY . .
RUN npx coffee -c ./bin/results.coffee
ENTRYPOINT ["/opt/test-runner/bin/run.sh"]