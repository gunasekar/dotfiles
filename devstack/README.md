# devstack

The two containers I use for day-to-day development, defined in one Compose file:

| Service | Container | Image | Reach |
|---------|-----------|-------|-------|
| Postgres | `postgresdb` | `postgres:17` | `localhost:5432`, user `postgres`, password `password` |
| Floci (AWS emulator) | `floci` | `floci/floci:latest-compat` | `http://localhost:4566` |

Runs on Colima (see `colima/README.md`). Both containers use `restart: unless-stopped`,
so they come back whenever Colima starts at login.

## Commands

From `sources/docker.sh`, usable from any directory:

```bash
dev-up        # create/start both containers
dev-down      # stop them (data kept)
dev-update    # pull newer images, recreate only the containers that changed
dev-logs      # follow logs (dev-logs postgres / dev-logs floci for one)
dev-backup    # pg_dumpall to ~/backups/devstack/pg-<timestamp>.sql
```

`dev-update` also runs as a `topgrade` step, so containers update when everything
else does. Nothing updates them in the background.

## Data and updates

Data lives in the named volumes `pgdata` and `floci-data`, not in the containers.
An update replaces the container and reattaches the volume, so data survives.

It is lost only when the volume itself is deleted: `docker compose down -v`,
`docker volume rm`, `docker volume prune --all`, or `colima delete --data`.

### Postgres major upgrades

The image is pinned to major 17, so `dev-update` only brings 17.x patch releases,
which share the on-disk format. A new major cannot read the old data directory.
To move majors, match prod RDS and:

```bash
dev-backup                       # dump everything
dev-down && docker rm postgresdb && docker volume rm pgdata
# bump the image tag in compose.yaml; postgres:18+ also moves its data dir,
# so mount the volume at /var/lib/postgresql instead of .../data
dev-up
docker exec -i postgresdb psql -U postgres < ~/backups/devstack/pg-<timestamp>.sql
```

### Floci

Follows `latest-compat`. Floci data is disposable dev data. A release that changes
its storage format may not load old resources. If that happens, remove the
`floci-data` volume and recreate.

## Installation

```bash
cd ~/.dotfiles
mkdir -p ~/.config/devstack
stow -v --no-folding devstack
dev-up
```

Creates `~/.config/devstack/compose.yaml` → `~/.dotfiles/devstack/.config/devstack/compose.yaml`.
