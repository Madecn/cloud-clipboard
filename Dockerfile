FROM node:21.7.1-alpine3.19 AS builder
ENV NODE_OPTIONS=--openssl-legacy-provider
COPY . /app
WORKDIR /app/client
RUN npm install --registry=https://registry.npmmirror.com
RUN npm run build

FROM node:21.7.1-alpine3.19
ENV NODE_OPTIONS=--openssl-legacy-provider
COPY . /app
COPY --from=builder /app/client/dist/ /app/server-node/static/
WORKDIR /app/server-node
RUN npm install  --registry=https://registry.npmmirror.com

RUN mkdir -p /app/server-node/data
ENV STORAGE_DIR=/app/server-node/data/storage
ENV HISTORY_FILE=/app/server-node/data/history.json

EXPOSE 9501
CMD ["node", "main.js"]

