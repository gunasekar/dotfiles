# COLIMA_HOME / DOCKER_HOST are exported from ~/.zshenv so they're available in
# non-interactive shells and scripts too (Colima keeps its home under XDG to
# avoid the legacy ~/.colima warning). This file holds only the helpers.

##### functions
function docker-stop-all {
    # Check if docker is running
    if ! docker info &>/dev/null; then
        echo "Error: Docker is not running" >&2
        return 1
    fi

    # Get all running container IDs
    local containers=$(docker ps -q)
    if [ -z "$containers" ]; then
        echo "No running containers to stop"
        return 0
    fi

    docker stop $(docker ps -aq)
}

function docker-start-all {
    if ! docker info &>/dev/null; then
        echo "Error: Docker is not running" >&2
        return 1
    fi

    local containers=$(docker ps -aq)
    if [ -z "$containers" ]; then
        echo "No containers to start"
        return 0
    fi

    docker start $(docker ps -aq)
}

function docker-rm-all-containers {
    if ! docker info &>/dev/null; then
        echo "Error: Docker is not running" >&2
        return 1
    fi

    local containers=$(docker ps -aq)
    if [ -z "$containers" ]; then
        echo "No containers to remove"
        return 0
    fi

    # Confirmation prompt
    echo "⚠️  WARNING: This will remove ALL containers ($(docker ps -aq | wc -l | tr -d ' ') total)"
    read -p "Are you sure? (y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        docker rm $(docker ps -aq)
    else
        echo "Cancelled"
    fi
}

function docker-rm-all-images {
    if ! docker info &>/dev/null; then
        echo "Error: Docker is not running" >&2
        return 1
    fi

    local images=$(docker images -aq)
    if [ -z "$images" ]; then
        echo "No images to remove"
        return 0
    fi

    # Confirmation prompt
    echo "⚠️  WARNING: This will remove ALL images ($(docker images -aq | wc -l | tr -d ' ') total)"
    read -p "Are you sure? (y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        docker rmi $(docker images -aq)
    else
        echo "Cancelled"
    fi
}

function docker-ips {
    docker inspect -f '{{.Name}} - {{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $(docker ps -aq)
}

##### postgres
# Start the local dev Postgres, creating the container on first run.
# Data lives in the 'pgdata' named volume (fast VM-native disk, not a host bind mount).
function pg-up {
    local name="postgresdb"

    if ! docker info &>/dev/null; then
        echo "Error: Docker is not running (start it with 'colima start')" >&2
        return 1
    fi

    if docker ps -a --format '{{.Names}}' | grep -qx "$name"; then
        docker start "$name" >/dev/null && echo "Started '$name' on localhost:5432"
        return
    fi

    local pw="${PG_PASSWORD:-password}"
    docker run --restart always --name "$name" -d \
        -p 5432:5432 \
        -e POSTGRES_PASSWORD="$pw" \
        -v pgdata:/var/lib/postgresql/data \
        --shm-size=256m \
        "postgres:${PG_VERSION:-17}" >/dev/null \
        && echo "Created '$name' on localhost:5432 (user=postgres, password=$pw)"
}
