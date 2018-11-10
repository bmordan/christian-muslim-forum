# The Christian Muslim Forum

Here is the frontend code for http://christianmuslimforum.org.

It is written in [*elm*](http://elm-lang.org/) and connects to an instance of Wordpress. To run the site locally you should install *elm* and *nodejs*. Then clone this repo and build the site using

```sh
npm start
```

You can serve the site locally on http://localhost:3030 using

```sh
npm run watch
```

You have to update the ./elm/Config.elm file to reflect the target deploy domain. i.e

```
// production
frontendUrl : String
frontendUrl =
    "http://christianmuslimforum.net"

// development
frontendUrl : String
frontendUrl =
    "http://localhost:3030"
```

# DEPLOY TO PRODUCTION

On the server you'll need three files

* docker-compose.yml
* mailchimp.env
* nginx.conf

Then run the command: `docker-compose pull && docker-compose up -d`

# HTTPS

ssh into the server and run the following commands to get your first cert

```
mkdir -p /docker/letsencrypt-docker-nginx/src/letsencrypt/letsencrypt-site
```

```
# /docker/letsencrypt-docker-nginx/src/letsencrypt/docker-compose.yml

version: '3.1'

services:

  letsencrypt-nginx-container:
    container_name: 'letsencrypt-nginx-container'
    image: nginx:latest
    ports:
      - "80:80"
    volumes:
      - ./nginx.conf:/etc/nginx/conf.d/default.conf
      - ./letsencrypt-site:/usr/share/nginx/html
    networks:
      - docker-network

networks:
  docker-network:
    driver: bridge
```

```
# /docker/letsencrypt-docker-nginx/src/letsencrypt/nginx.conf

server {
    listen 80;
    listen [::]:80;
    server_name christianmuslimforum.org www.christianmuslimforum.org;

    location ~ /.well-known/acme-challenge {
        allow all;
        root /usr/share/nginx/html;
    }

    root /usr/share/nginx/html;
    index index.html;
}
```

```
# /docker/letsencrypt-docker-nginx/src/letsencrypt/letsencrypt-site/index.html

<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8" />
    <title>CMF</title>
</head>
<body>
    <h1>CMF</h1>
    <p>
        This is the temporary site that will only be used for the very first time SSL certificates are issued by Let's Encrypt's
        certbot.
    </p>
</body>
</html>

```

Test everything is working ok by running the following:

```
cd /docker/letsencrypt-docker-nginx/src/letsencrypt
sudo docker-compose up -d
```

Now visit http://christianmuslimforum.org

if all is good you'll see the temporary holding page from above. Now we are going to stage our request for a cert.

```
docker run -it --rm \
-v /docker-volumes/etc/letsencrypt:/etc/letsencrypt \
-v /docker-volumes/var/lib/letsencrypt:/var/lib/letsencrypt \
-v /docker/letsencrypt-docker-nginx/src/letsencrypt/letsencrypt-site:/data/letsencrypt \
-v "/docker-volumes/var/log/letsencrypt:/var/log/letsencrypt" \
certbot/certbot \
certonly --webroot \
--register-unsafely-without-email --agree-tos \
--webroot-path=/data/letsencrypt \
--staging \
-d christianmuslimforum.org \
-d www.christianmuslimforum.org
```

All good? Then clean up and lets do it for real.

```
rm -rf /docker-volumes/
```

```
sudo docker run -it --rm \
-v /docker-volumes/etc/letsencrypt:/etc/letsencrypt \
-v /docker-volumes/var/lib/letsencrypt:/var/lib/letsencrypt \
-v /docker/letsencrypt-docker-nginx/src/letsencrypt/letsencrypt-site:/data/letsencrypt \
-v "/docker-volumes/var/log/letsencrypt:/var/log/letsencrypt" \
certbot/certbot \
certonly --webroot \
--email bernardmordan@gmail.com --agree-tos --no-eff-email \
--webroot-path=/data/letsencrypt \
-d christianmuslimforum.org \
-d www.christianmuslimforum.org
```

OK?

```
cd /docker/letsencrypt-docker-nginx/src/letsencrypt
docker-compose down
```