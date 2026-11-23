FROM node:22-slim
ENV NODE_ENV=production PORT=3000 HOST=0.0.0.0 DB_PATH=/data/taskpad.db
WORKDIR /app
COPY package.json main.js server.js db.js ./
COPY migrations ./migrations
COPY public ./public
RUN mkdir -p /data && chown -R node:node /data
USER node
VOLUME ["/data"]
EXPOSE 3000
HEALTHCHECK --interval=10s --timeout=3s --start-period=5s --retries=3 \
  CMD node -e "fetch('http://127.0.0.1:3000/healthz').then(r=>process.exit(r.ok?0:1)).catch(()=>process.exit(1))"
CMD ["node", "main.js"]
