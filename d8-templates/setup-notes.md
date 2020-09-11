# Set up notes.

Please note any issues!

* Step 1 - Add url to /etc/hosts:

In `/etc/hosts`, add:
`127.0.1.1 PROJECTNAME.test`

* Step 2:
Setup local reverse proxy.
Clone [un-ocha/local-reverse-proxy](https://github.com/UN-OCHA/local-reverse-proxy) repo.
Read the repo's [README](https://github.com/UN-OCHA/local-reverse-proxy/blob/main/README.md)

`cd local-reverse-proxy`

`docker-compose up -d`

`./cert-gen.sh PROJECTNAME.test`

* Step 3:
Set up directory. Suggesting in /srv/PROJECTNAME, but can be anywhere as long as it's configured in step 4.
This assumes you already have PROJECTNAME-site repo cloned onto your machine, in a different location. If not, do that now. https://github.com/UN-OCHA/PROJECTNAME-site/

`sudo mkdir -p /srv/PROJECTNAME/local/srv/`

`sudo chown -R 1000:1000 /srv/PROJECTNAME/local/srv/`

`cd /srv/PROJECTNAME/local/srv/`

`ln -s /path/to/PROJECTNAME-site www`

`mkdir database`

`mkdir -p shared/files`

`mkdir shared/private`

`chown -R 4000:4000 shared`

* Step 4
Configure local stack.

`cd PROJECTNAME-stack/env/local/rplocal`
('rp' stands for 'reverse proxy')

Adjust BASEDIR to match directory in Step 3. (If necessary).
Anything else in .env you'd like to change?

`docker-compose up -d`

* Step 5
Initialize site
`composer install` within the container sometimes has trouble with patches. If so, it can be run in the site repo outside of the container.

Import database:
Download latest snapshot from https://snapshots.aws.ahconu.org/PROJECTNAME/prod/
to `${BASEDIR}/${STACK}/srv/database`

`docker-compose exec drupal bash`

For setting up the database:
`drush sql-connect` to check if the database settings are already set. If not:

`drush -y si --db-url=mysql://PROJECTNAME:PROJECTNAME@mysql/PROJECTNAME minimal`

Note: if default.settings.php is not present, copy it from another site.

`$(drush sql-connect) < /srv/www/database/name-of-dump.sql`

Change permissions for /tmp
`chmod -R 777 /tmp`
`drush cr`


* Step 6:
Visit PROJECTNAME.test in your browser, accept the ssl warning.

# Starting and stopping, once set up

Step 1 - Check reverse proxy is running
`docker ps` to check running containers.
If it’s not running, `cd` to local-reverse-proxy directory and
`docker-compose up -d`

Step 2 - Start PROJECTNAME stack
`cd` to PROJECTNAME-stack/env/demo/rplocal
`docker-compose up -d`
The site should now be working.

Step 3 - Enter container to run commands
`docker-compose exec drupal bash`
Ctrl-D to exit container again.

Step 4 - Shut down stack
`cd` to PROJECTNAME-stack/env/demo/rplocal
`docker-compose stop`
