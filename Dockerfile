FROM node:carbon
WORKDIR /usr/src/app
COPY package*.json ./
RUN npm install
RUN npm install -g elm --unsafe-perm=true
COPY . .
EXPOSE 3030
CMD [ "npm", "start" ]
