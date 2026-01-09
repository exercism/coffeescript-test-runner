FROM node:25.2.1-alpine3.23
RUN apk add --no-cache jq coreutils bash

ENV NO_UPDATE_NOTIFIER=true

WORKDIR /opt/test-runner

COPY package.json .
COPY package-lock.json .
RUN npm install

COPY . .
RUN npx coffee --compile ./bin/results.coffee
ENTRYPOINT ["/opt/test-runner/bin/run.sh"]
