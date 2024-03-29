# Project set up - Drupal - Reverse proxy based local setup

This is the setup for a drupal site. It requires a reverse proxy
(for example https://github.com/UN-OCHA/local-reverse-proxy) and a docker
network named `nginx-proxy`.

**Note:** It is designed to run alongside other reverse-proxied sites - but
there will be a port conflict if you try running it alongside docksal.

**Note:** All the `docker-compose` commands from step 2 and onwards assume that
you are in the directory holding this README. Otherwise, try with `docker exec`.

## Step 1
**Setup local reverse proxy**
Set up local DNS
`echo "127.0.0.1 PROJECTNAME.test" | sudo tee --append /etc/hosts`

1. Clone [un-ocha/local-reverse-proxy](https://github.com/UN-OCHA/local-reverse-proxy) repo.
2. Read the repo's [README](https://github.com/UN-OCHA/local-reverse-proxy/blob/main/README.md)
3. Start the proxy: `cd local-reverse-proxy && docker-compose up -d`


## Step 2:
**Files and permissions set up on host machine**
`BASEDIR` is the location you will mount your volumes from. It can be anywhere.
For example under `/srv/PROJECT` on linux or `/Users/USERNAME/srv/
PROJECT` on macOS when using docker for mac.

Using `/srv` is useful to prevent confusion with the `SITEREPODIR` which is
where you will be making changes to the code.

Create a `BASEDIR` directory for the project and specify its path in
`env/local/.env` — that path is marked by `${BASEDIR}` in the next set
of commands.

**Note:** you may need to use `sudo` for the commands below if you use `/srv`
as `BASEDIR` for example. Ex: `sudo chmod -R 777 tmp`.

Run these commands:

```sh
# create some directories
sudo mkdir ${BASEDIR} && cd ${BASEDIR}
sudo mkdir -p srv/www srv/backups srv/solr tmp var

# allow tmp to be writeable by everyone
sudo chmod -R 777 tmp

# Assign ownership to /var. Note: 4000 is the `appuser` in the containers
sudo chown -R 4000:4000 var

# Assign ownership to /solr. Note: 8983 is the `solr` user in the containers
sudo chown -R 8983:8983 srv/solr

# Change directories so the next commands are shorter
cd srv/www

# Create some Drupal-specific directories
sudo mkdir -p shared/files shared/private shared/settings database

# Change ownership of the directories
sudo chown -R 4000:4000 shared/files shared/private
```


## Step 3
**Configure and start the containers**

Return to the local stack directory.

Adjust the `SITEREPODIR` env variable in `env/local/rplocal/.env` to match the
location where you have downloaded the PROJECTNAME-site codebase. Replace
'PROJECT' where appropriate to define other names and folders.

Build a container image for the site using the dockerfile in the repo by
running `make` in the root of the repo. Check the created container matches
the one named in the docker-compose file.

Run the command:
`docker-compose up -d`


## Step 4
**Initialize site**
On the host machine, run `composer install` from SITEREPODIR.

**Note:** Make sure to have a compatible version of PHP and composer (e.g: PHP
8 and composer 2). (We tried running composer inside the containers, but
it got complicated https://humanitarian.atlassian.net/browse/OPS-7240 .)

Run composer install within the unified builder container:

```sh
# Move to the site repo:
cd "${SITEREPODIR}

docker run --rm -u $(id -u) -v "$(pwd):/srv/www" -w /srv/www -it public.ecr.aws/unocha/unified-builder:8.0-stable sh -c "composer selfupdate && composer install"

# Copy unocha-standard settings and services files:
cp docker/services.yml docker/settings.php html/sites/default/
```

Configure settings for 'hash_salt', 'social_auth_hid' and 'stage_file_proxy' in
`./settings/settings.local.php`. (The relative path is from this README.)

```sh
# Copy settings files to the BASEDIR.
cp ./settings/* "${BASEDIR}/srv/www/shared/settings"
```

**Note:** Remember that any further changes to local settings should be made in
the BASEDIR copy. This is so that local changes won't be accidentally
committed to this stack repository.


## Step 5
**Create/ Import database**
If there are database settings in settings.local.php and a database at
https://snapshots.aws.ahconu.org/PROJECTNAME:

Get a database snapshot from https://snapshots.aws.ahconu.org/PROJECTNAME,
download it, unzip it and move it to `${BASEDIR}/tmp`.

Then import it with (replace `DATABASE-DUMP.sql` by the real filename):

1. `docker-compose exec drupal bash`
2. `drush sqlc < /tmp/DATABASE-DUMP.sql`
3. `exit`

If not, install the site:
1. `docker-compose exec drupal bash`
2. `drush -y si --db-url=mysql://PROJECTNAME:PROJECTNAME@mysql/PROJECTNAME
minimal`
3. `drush -y config-set "system.site" uuid "SITE-UID"` (If SITE-UID is found
in `/path/to/PROJECTNAME-site/config/system.site.yml`)
3. `exit`


## Step 6
**Update site**

1. `docker-compose exec -u appuser drupal drush cr`
2. `docker-compose exec -u appuser drupal drush -y cim`
3. `docker-compose exec -u appuser drupal drush -y updatedb`
4. `docker-compose exec -u appuser drupal drush cr`


## Step 7
**Test it**
Visit PROJECTNAME.test in your browser.


# Troubleshooting
1. Check BASEDIR and SITEREPODIR variables are correct in .env file.
2. `docker-compose exec drupal bash` into the container and check files are
where you'd expect them to be.
3. For 502 'too big header' errors see etc/nginx/vhost.d/README.md
4. Ask for help (and update these notes with the answer).


# Common tasks
**Composer updates**
These should be done on the host machine.

**Database updates**
See step 5, with an optional `drush sql-drop` before the import.

**Connecting to another local property**
Haven't yet worked out an automatic way to do this yet, but if reverse proxy
container is always started before other containers, it should always get the
same ip address - e.g. 172.28.0.2
@todo - try shell command in .env file for getting local_reverse_proxy_ip_address.

Find the local ip address of the *local reverse proxy* - not the site itself -
with `docker inspect local-reverse-proxy`.
Add `DOCSTORE_IP=<local_reverse_proxy_ip_address>` to .env file.
Add this to docker-compose.yml for the drupal container:
```
    extra_hosts:
      - docstore.test:${DOCSTORE_IP}
```


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
From same directory as docker-compose.yml:
`docker-compose exec drupal bash`
From elsewhere:
`docker exec -it PROJECTNAME-drupal sh`
`exit` (or Ctrl-D) to exit container again.

## Step 4
**Run commands without entering container**
From same directory as docker-compose.yml:
`docker-compose exec drupal drush cr`
From elsewhere:
`docker exec -it PROJECTNAME-drupal drush cr`

## Step 5
**Shut down stack**
`cd` to PROJECTNAME-stack/env/local/rplocal
`docker-compose stop`
