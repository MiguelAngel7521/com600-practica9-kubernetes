FROM ghcr.io/miguelangel7521/com600-practico8:438ae59c65fa005841fc44db8522ac356ad68f01
ARG VERSION=1.0.0
ENV APP_VERSION=${VERSION}
COPY --chown=node:node server-salud.js /app/src/server-salud.js
CMD ["node", "src/server-salud.js"]
