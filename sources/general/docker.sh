##### exports
export DOCKER_HOST="unix://${HOME}/.colima/default/docker.sock"

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

##### mysql
function del-all-mysql-db {
    # Confirmation prompt
    echo "⚠️  WARNING: This will DROP ALL user databases in MySQL"
    read -p "Are you absolutely sure? Type 'DELETE ALL' to confirm: " -r
    echo
    if [[ "$REPLY" == "DELETE ALL" ]]; then
        # Use environment variable for password to avoid command-line exposure
        if [ -z "$LOCAL_MYSQL_PASSWORD" ]; then
            echo "Error: LOCAL_MYSQL_PASSWORD not set. Set it or use mycli instead." >&2
            return 1
        fi
        mysql -uroot -p"$LOCAL_MYSQL_PASSWORD" -e "show databases" | grep -v Database | grep -v mysql| grep -v information_schema| awk '{print "drop database " $1 ";select sleep(0.1);"}' | mysql -uroot -p"$LOCAL_MYSQL_PASSWORD"
    else
        echo "Cancelled (must type 'DELETE ALL' exactly)"
    fi
}
