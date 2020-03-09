FROM node:12 as builder

ADD . .
RUN npm i && npm run build

FROM nginx:alpine
COPY --from=builder /dist /var/www/
COPY ./nginx.conf /etc/nginx/conf.d/default.conf
