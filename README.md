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

Run in a container by building the image `docker build .` and then starting with:

```
docker container run -p 80:3030 -d bmordan/build-server
```
