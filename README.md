Instructions for setting up reverse proxy for local development
===============================================================

This is to allow multiple local development environments side by side.

Those instructions should work with Linux, Linux in a VM and Docker for Mac.

For standardization between developers, consider using [`.test`](https://en.wikipedia.org/wiki/.test) as the default TLD.

## Important notes

This will create a reverse proxy container based on the [caddyserver](https://github.com/caddyserver/caddy) that will bind to port 80 and 443 on localhost.

If there is another container or service using those ports then the container will not start and the sites will not be accessible.

Requires a `proxy` network to already exist. If it doesn't: `docker network create proxy`.

For every local host you want to use (e.g. some.site.test) you will need to add the following line to your `/etc/hosts` (if on Linux or MacOSX) or to your `C:\Windows\System32\Drivers\etc\hosts`:

```
127.0.0.1 some.site.test
```

## SSL certificates.

A local SSL CA and local SSL intermediate will be created in `./data/caddy/pki/authorities/local` when you start caddy for the first time.

A self signed certificate will be automatically created by caddy for each site you configure when you start your site container for the first time.

You can try to add your local CA and intermediate to your trust store or just ignore the browser warnings.

Your browser will view the certificate with suspicion, but once accepted, the site will work normally with https.

## Adapting a project's docker-compose file to work with reverse proxy.

The following lines should be in the `labels` section of the container that contains nginx:

```
      caddy: ${NGINX_SERVERNAME}
      caddy.reverse_proxy: "{{upstreams}}"
```

also `- proxy` in the networks section

and:
```
networks:
  default:
  proxy:
    external: true
```

Aiming for a clear example in the common-design-stack repo - will update when that exists.

## Mounted volumes

Local volumes:
- `./var/data`: store and preserve the SSL certificates created automatically for your sites
- `./var/config`: saves the current config in json format
- `./var/logs`: caddy and site logs (both access and error) in json format

## Set up notes

Copy the contents of `new-site-template` to an `env/local` directory in the
stack repo. Follow the instructions in `setup-notes.md`, making changes to
anything that's not clear.

## 502 'too big header' error

See `etc/nginx/vhost.d/README.md`
