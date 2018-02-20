FROM node:carbon
WORKDIR /usr/src/app
COPY . .
RUN npm install
RUN npm install -g elm --unsafe-perm=true
RUN elm-package install -y
EXPOSE 3030
CMD [ "npm", "start" ]
