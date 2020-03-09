FROM node:12 as builder

ADD . .
RUN npm i && npm run build

FROM scratch
RUN mkdir -p /var/www/
COPY --from=builder /dist /var/www/
