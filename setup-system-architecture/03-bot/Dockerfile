FROM node:20-alpine

WORKDIR /app

COPY 03-bot/package.json ./package.json
RUN npm install --omit=dev

COPY 03-bot/bot.js         ./bot.js
COPY 04-integration/       ../04-integration/

ENV NODE_ENV=production
CMD ["node", "bot.js"]
