Instructions for setting up reverse proxy for local development
===============================================================

This is to allow multiple local development environments side by side.

Those instructions should work with Linux, Linux in a VM and Docker for Mac.

For standardization between developers, consider using [`.test`](https://en.wikipedia.org/wiki/.test) as the default TLD.

## Important note

This will create a reverse proxy container based on the [jwilder nginx proxy](https://github.com/jwilder/nginx-proxy) image that will bind to port 80 and 443 on localhost.

If there is another container or service using those ports then the container will not start and the sites will not be accessible.

Requires an `nginx-proxy` network to already exist. If it doesn't: `docker network create nginx-proxy`.

## SSL certificates.

A self signed certificate should be created with `cert-gen.sh` to allow access to the sites via https:

Example:
./cert-gen.sh sitename.test

Your browser will view the certificate with suspicion, but once accepted, the site will work normally with https.

## Adapting a project's docker-compose file to work with reverse proxy.

The following lines should be in the `environment` section of the container that contains nginx:

```
      - LISTEN_PORT=80
      - HTTPS_METHOD=noredirect
      - VIRTUAL_HOST=${NGINX_SERVERNAME}
      - VIRTUAL_PORT=80
      - VIRTUAL_NETWORK=nginx-proxy
```

also `- proxy` in the networks section

and:
```
networks:
  default:
  proxy:
    external:
      name: nginx-proxy
```

Aiming for a clear example in the common-design-stack repo - will update when that exists.

## Mounted volumes

./etc/nginx/conf.d and ./etc/nginx/certs are mounted as local volumes to keep track of created certificates and to make the `default.conf` file easier to access for debugging purposes.

