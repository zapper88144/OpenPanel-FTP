#!/bin/bash

# this script should be run only on servers that have OpenPanel installed.
# to use OpenPanel-FTP as a standalone ftp server, check the readme

# OpenPanel?
check_openpanel_installed() {
  if [ -d "/usr/local/panel/" ]; then
    return 0
  else
    return 1
  fi
}

# Function to run the Docker container
run_docker_container() {
  docker run -d \
    -p "21:21" \
    -p 21000-21010:21000-21010 \
    --restart=always \
    --name=openadmin_ftp \
    -v /home:/home \
    -v /etc/openpanel/ftp/users:/etc/openpanel/ftp/users
    --memory="1g" --cpus="1" \
    openpanel/ftp
}

# Function to open ports using ufw
open_ports() {
  ufw allow 21/tcp    -v /home:/home \
    -v /etc/openpanel/ftp/users:/etc/openpanel/ftp/users
  for port in $(seq 21000 21010); do
    ufw allow $port/tcp
  done
  ufw reload
}

# Main script
if check_openpanel_installed; then
  echo "OpenPanel is installed. Proceeding with Docker container setup and port opening."

  # Run the Docker container
  run_docker_container

  # Open the required ports
  open_ports

  echo "Docker container started and ports opened."
else
  echo "OpenPanel is not installed. Exiting."
fi
