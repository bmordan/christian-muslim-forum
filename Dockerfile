FROM node:carbon
WORKDIR /usr/src/app
COPY . .
RUN npm install
RUN cp ./bin/elm* /usr/local/bin
RUN elm-package install -y
EXPOSE 3030
CMD [ "npm", "start" ]
