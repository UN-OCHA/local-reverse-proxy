# First time set-up:
* Copy the `local` directory to `local` in the root directory of your repo.
* Add `<shortname-of-this-property>-local.test` to `/etc/hosts`.
* Check the containers from the stack repository - do we need to adjust the docker-compose file? (e.g. add memcache or solr)
* Change 'SHORTNAME' for '<shortname-of-this-property>' with:
`for file in $(find ./local -type f); do echo $file && sed -i 's/SHORTNAME/<shortname-of-this-property>/' $file; done`
* Check image value for in docker-compose.yml - does it match the name in Makefile?
`make`
`docker compose -p SHORTNAME-local -f local/docker-compose.yml up -d`
Download database from `https://snapshots.aws.ahconu.org/`.
Put database into ./database and gunzip it
`docker exec -it SHORTNAME-local-site sh`
`chmod -R 777 sites/default/files/ sites/default/private/`
`drush sqlc < ../database/SHORTNAME<tab to bring up the database dump name>`
`composer install` (to bring in dev modules)
`drush cim`
`drush uli`
