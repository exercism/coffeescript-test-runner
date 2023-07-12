FROM node:12-alpine
RUN apk add --no-cache jq coreutils bash

ENV NO_UPDATE_NOTIFIER true

WORKDIR /opt/test-runner
COPY . .

RUN npm install -g
RUN npx coffee --compile ./bin/results.coffee
ENTRYPOINT ["/opt/test-runner/bin/run.sh"]
