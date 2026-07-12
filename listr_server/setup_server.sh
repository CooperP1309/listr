#!/usr/bin/env bash

if ! command -v mvn &> /dev/null; then
    echo "Error: Maven (mvn) is not installed or not in PATH." >&2
    exit 1
fi

if ! command -v docker &> /dev/null; then
    echo "Error: Docker is not installed or not in PATH." >&2
    exit 1
fi

if ! command -v awk &> /dev/null; then
    echo "Error: awk is not installed or not in PATH." >&2
    exit 1
fi

if docker info >/dev/null 2>&1; then
    echo "Docker daemon is running."
else
    echo "Docker daemon is NOT running."
    exit 1
fi

clear
echo "--------- Welcome to the LISTR Server Setup ---------"
echo
echo
while true; do
    read -rsp "Enter your JWT secret (must be 64 characters): " jwt_secret
    echo
    if [[ ${#jwt_secret} -eq 64 ]]; then
        break
    else
        clear
        echo "--------- Welcome to the LISTR Server Setup ---------"
        echo
        echo
        echo "Error: Secret must be exactly 64 characters (you entered ${#jwt_secret})" >&2
        echo
    fi
done
echo
while true; do
    read -rsp "Enter your database password: " db_password
    echo
    read -rsp "Confirm your database password: " db_password_confirm
    echo
    if [[ "$db_password" == "$db_password_confirm" ]]; then
        break
    else
        clear
        echo "--------- Welcome to the LISTR Server Setup ---------"
        echo
        echo
        echo "Error: Passwords do not match, please try again." >&2
        echo
    fi
done
echo
read -rp "Are you sure you want to continue? (ANY PREVIOUS DATA WILL BE LOST!) (y/n): " confirm
case "$confirm" in
    [Yy]* ) echo "Proceeding...";;
    [Nn]* ) echo "Exiting..."; exit 1;;
    * ) echo "Invalid response";;
esac
echo
mkdir -p ./src/main/resources
echo "spring.application.name=listr

server.port=8005

# Database Configuration
spring.datasource.url=jdbc:mysql://localhost:3307/taskdb?serverTimezone=UTC&allowPublicKeyRetrieval=true&useSSL=false
spring.datasource.username=root
spring.datasource.password=$db_password

## Hibernate properties
spring.jpa.hibernate.ddl-auto=update
spring.jpa.open-in-view=false

# JWT Configuration
security.jwt.secret-key=$jwt_secret
# 1h in millisecond
security.jwt.expiration-time=3600000
" > ./src/main/resources/application.properties


# deploying MySQL and LLM containers
echo "A MySQL Docker container and a LLM container are about to be deployed on port 3307 and 11434."
read -rp "Would you like to proceed? (y/n): " deploy_confirm
case "$deploy_confirm" in
[Yy]* )
  if docker ps -a --format '{{.Names}}' | grep -q '^mysqldb$'; then
    docker rm -f mysqldb
  fi
  docker run -d -e MYSQL_ROOT_PASSWORD="$db_password" -e MYSQL_DATABASE=taskdb \
    --name mysqldb -p 3307:3306 mysql:8.0

  if docker ps -a --format '{{.Names}}' | grep -q '^ollama-llm$'; then
    docker rm -f ollama-llm
  fi
  docker run -d --name ollama-llm -p 11434:11434 \
    -v ollama-models:/root/.ollama ollama/ollama:0.31.2

  until curl -sf http://localhost:11434 >/dev/null 2>&1; do sleep 1; done
  docker exec ollama-llm ollama pull llama3
  docker exec ollama-llm ollama pull nomic-embed-text
  ;;
esac

# testing deployment of the containers
clear
echo "--------- Listr Setup ---------"
echo
echo
echo "Validating MySQL deployment..."

sleep 5

if docker ps | grep -q mysqldb; then
    echo "MySQL container is running."
    echo
else
    echo "Error: MySQL container is not running."
    exit 1
fi

echo "Validating LLM deployment..."

sleep 5

if docker ps | grep -q ollama-llm; then
    echo "LLM container is running."
    echo
else
    echo "Error: LLM container is not running."
    exit 1
fi

clear
echo
echo "--------- Setup Complete ---------"
echo "To start the server, run the following command:"
echo
echo "mvn spring-boot:run"
