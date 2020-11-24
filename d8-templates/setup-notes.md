# Set up notes.

## Step 1
**Create DNS alias**
`echo "127.0.1.1 PROJECTNAME.test" >> /etc/hosts`

## Step 2:
**Setup local reverse proxy**
Clone [un-ocha/local-reverse-proxy](https://github.com/UN-OCHA/local-reverse-proxy) repo.
Read the repo's [README](https://github.com/UN-OCHA/local-reverse-proxy/blob/main/README.md)

`cd local-reverse-proxy`

`docker-compose up -d`

`./cert-gen.sh PROJECTNAME.test`

## Step 3:
**Files and permissions set up on host machine**
Suggesting BASEDIR is /srv/PROJECTNAME/[VERSION/]/local. It can be anywhere as
long as it's configured in step 4. This set up involves a symlink so as not to
dictate the code location.

`git clone https://github.com/UN-OCHA/PROJECTNAME-site`
(clone site repo to where you normally keep your code)

`sudo mkdir -p ${BASEDIR}/srv/`

`sudo chown -R 1000:1000 ${BASEDIR}/srv/`

`cd ${BASEDIR}/srv/`

`mkdir -p tmp database shared/files shared/private`

`chmod -R 777 tmp`

`sudo chown -R 4000:4000 shared`
(4000 is the uid of `appuser` in the containers)

`ln -s /path/to/PROJECTNAME-site www`
(link the site codebase within the host machine)


## Step 4
**Configure and start the containers**

This assumes there is a `PROJECTNAME-site:local` docker image. It can be created by
running `make` in the `PROJECTNAME-site` repository.

`cd PROJECTNAME-stack/env/local/rplocal`
('rp' stands for 'reverse proxy')

Adjust BASEDIR to match directory in Step 3. (If necessary).

`docker-compose up -d`


## Step 5
**Initialize site**
`composer install` within the container sometimes has trouble with patches. It
can be run in the site repo outside of the container.


## Step 6
**Create/ Import database**
Download latest snapshot from https://snapshots.aws.ahconu.org/PROJECTNAME/prod/
to `${BASEDIR}/tmp`

`docker-compose exec drupal bash`

For setting up the database:
`drush sql-connect` to check if the database settings are already set. If not,
get a settings.local.php file from another developer on the project. If there
isn't one yet:

`drush -y si --db-url=mysql://PROJECTNAME:PROJECTNAME@mysql/PROJECTNAME minimal`

`$(drush sql-connect) < /tmp/name-of-dump.sql`

`drush -y config-set "system.site" uuid "SITE-UID"`
Where SITE-UID is found in `/path/to/PROJECTNAME-site/config/system.site.yml`

## Step 7
**Update site**
`drush cr`

Check the config directory is set in `settings.local.php`, then run:
`drush cim`
If it's not set, run `drush cim --source=../config`

`drush updatedb`

`drush cr`


## Step 8
**Test it**
Visit PROJECTNAME.test in your browser, accept the ssl warning if there is one.


# Starting and stopping, once set up

## Step 1
**Check reverse proxy is running**
`docker ps` to check running containers.
If it’s not running, `cd` to local-reverse-proxy directory and
`docker-compose up -d`

## Step 2
**Start PROJECTNAME stack**
`cd` to PROJECTNAME-stack/env/local/rplocal
`docker-compose up -d`
The site should now be working.

## Step 3
**Enter container to run commands**
`docker-compose exec drupal bash`
Ctrl-D to exit container again.
or prefix commands with
`docker-compose exec -u appuser drupal`
for example
`docker-compose exec -u appuser drupal drush cr`

## Step 4
**Shut down stack**
`cd` to PROJECTNAME-stack/env/local/rplocal
`docker-compose stop`
