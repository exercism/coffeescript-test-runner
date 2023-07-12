FROM node:16-alpine
RUN apk add --no-cache jq coreutils bash

ENV NO_UPDATE_NOTIFIER true

WORKDIR /opt/test-runner
COPY . .

RUN npm install -g
RUN npx -v
RUN npx coffee -v
RUN npx coffee --compile ./bin/results.coffee -o ./bin
ENTRYPOINT ["/opt/test-runner/bin/run.sh"]
