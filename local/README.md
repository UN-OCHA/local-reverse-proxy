# Normal usage

### *See `../setup-notes.md` for first-time set-up.*

## To start
`docker compose -p SHORTNAME-local -f local/docker-compose.yml up -d`
## To enter the container
`docker exec -it SHORTNAME-local-site sh`
## To stop
`docker compose -p SHORTNAME-local -f local/docker-compose.yml down`

## Notes
Composer should be run from inside the container.
