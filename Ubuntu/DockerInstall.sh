#!/bin/bash
source /media/sf_shared/Functions.sh
# Add Docker's official GPG key:
sudo apt-get update
sudo apt-get install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo systemctl status docker
# Add your user to the docker group
sudo groupadd docker
sudo usermod -aG docker $USER
# Restart the docker service
sudo systemctl restart docker
# Test Docker installation
docker run hello-world
sudo docker search httpd
sudo docker pull httpd
read -p "Indica el puerto que deseas utilizar" port 
while (sudo lsof -i :$port &>/dev/null) || (is_port_in_common_ports $port); do
    read -p "Ingresa un puerto: " port
done
read -p "Indica el nombre del contenedor" container_name
while (sudo docker ps -a | grep $container_name &>/dev/null); do
    read -p "Ingresa un nombre de contenedor: " container_name
done
sudo docker network create containers_network

sudo mkdir -p $container_name
cat > $container_name/index.php <<'EOF'
<!DOCTYPE html>
<html lang='es'>
<head>
    <meta charset='UTF-8'>
    <meta name='viewport' content='width=device-width, initial-scale=1.0'>
    <title>Docker Page</title>
    <body>
        <h1>Pagina Generada en un contenedor de docker</h1>
        <p>Este contenedor fue creado por el script DockerInstall.sh</p>
<?php
$db_container_1 = 'postgres_container_1';
$db_container_2 = 'postgres_container_2';
$db_user = 'chuas';
$db_password = 'chuas';
$db_name_1 = 'games';
$db_name_2 = 'players';

$db_conn_1 = pg_connect("host=$db_container_1 dbname=$db_name_1 user=$db_user password=$db_password");
$db_conn_2 = pg_connect("host=$db_container_2 dbname=$db_name_2 user=$db_user password=$db_password");

if (!$db_conn_1) {
    echo "<p>Fallo la conexión a la base de datos $db_name_1</p>";
} else {
    $result_set_1 = pg_query($db_conn_1, "SELECT * FROM score");
    if (!$result_set_1) {
        echo "<p>Fallo la consulta a la base de datos $db_name_1</p>";
    } else {
        echo "<h1>Puntuaciones de los equipos</h1>";
        echo "<table border='1'>";
        echo "<tr><th>Id</th><th>Team_name</th><th>Points</th><th>Goal_difference</th></tr>";
        while ($row = pg_fetch_assoc($result_set_1)) {
            echo "<tr>";
            echo "<td>" . $row['id'] . "</td>";
            echo "<td>" . $row['team_name'] . "</td>";
            echo "<td>" . $row['points'] . "</td>";
            echo "<td>" . $row['goal_difference'] . "</td>";
            echo "</tr>";
        }
        echo "</table>";
    }
}

if (!$db_conn_2) {
    echo "<p>Fallo la conexión a la base de datos $db_name_2</p>";
} else {
    $result_set_2 = pg_query($db_conn_2, "SELECT * FROM players");
    if (!$result_set_2) {
        echo "<p>Fallo la consulta a la base de datos $db_name_2</p>";
    } else {
        echo "<h1>Jugadores</h1>";
        echo "<table border='1'>";
        echo "<tr><th>Id</th><th>Name</th><th>Age</th><th>Team_name</th></tr>";
        while ($row = pg_fetch_assoc($result_set_2)) {
            echo "<tr>";
            echo "<td>" . $row['id'] . "</td>";
            echo "<td>" . $row['name'] . "</td>";
            echo "<td>" . $row['age'] . "</td>";
            echo "<td>" . $row['team_name'] . "</td>";
            echo "</tr>";
        }
        echo "</table>";
    }
}
?>
    </body>
</html>
EOF
cd $container_name
cat > Dockerfile <<EOF
FROM php:8.2-apache
RUN apt-get update && apt-get install -y libpq-dev \
    && docker-php-ext-install pdo pdo_pgsql pgsql
COPY index.php /var/www/html/index.php
EOF
chmod 644 index.php
sudo docker build -t $container_name .
sudo docker run -d -p $port:80 --name $container_name --network containers_network $container_name
#Create a network to stablish a connection between the containers
  sudo docker pull postgres:latest

  sudo docker stop postgres_container_1
  sudo docker stop postgres_container_2
  sudo docker rm postgres_container_1
  sudo docker rm postgres_container_2
  
    # Levantar el primer contenedor postgreSQL
docker run -d \
  --name postgres_container_1 \
  --network containers_network \
  -e POSTGRES_USER=chuas \
  -e POSTGRES_PASSWORD=chuas \
  -e POSTGRES_DB=games \
  postgres:latest
sleep 5
docker run -d \
  --name postgres_container_2 \
  --network containers_network \
  -e POSTGRES_USER=chuas \
  -e POSTGRES_PASSWORD=chuas \
  -e POSTGRES_DB=players \
  postgres:latest
    sleep 5
    #Execute a SQL command to create a table in both databases
sudo docker exec -i postgres_container_1 psql -U chuas -d games <<EOF
CREATE TABLE score (
    Id SERIAL PRIMARY KEY,
    Team_name VARCHAR(50) NOT NULL,
    Points INT NOT NULL,
    Goal_difference INT NOT NULL
);
INSERT INTO score (Team_name, Points, Goal_difference) VALUES
('Profes', 13, 10),
('DHCP', 11, 8),
('Los Vazques', 11, 6),
('Sichar F.C', 11, 5),
('TorosLocos', 9, -1),
('Plan 3', 4, -6),
('Sexomatas', 4, -11);
EOF
sleep 5
sudo docker exec -i postgres_container_2 psql -U chuas -d players <<EOF
CREATE TABLE players (
    Id SERIAL PRIMARY KEY,
    Name VARCHAR(50) NOT NULL,
    Age INT NOT NULL,
    Team_name VARCHAR(50) NOT NULL
);
INSERT INTO players (Name, Age, Team_name) VALUES
('Herman', 25, 'Profes'),
('Carlos', 30, 'DHCP'),
('Juan', 28, 'Los Vazques'),
('Pedro', 22, 'Sichar F.C'),
('Javier', 27, 'TorosLocos'),
('Diego', 24, 'Plan 3'),
('Negrete', 29, 'Sexomatas');
EOF
sleep 5
echo "Registro de contenedor postgres_container_1"
docker exec -i postgres_container_1 psql -U chuas -d games <<EOF
SELECT * FROM score;
EOF
echo "Registro de contenedor postgres_container_2"
docker exec -i postgres_container_2 psql -U chuas -d players <<EOF
SELECT * FROM players;
EOF
