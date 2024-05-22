#!/bin/bash

# this script should be run only on servers that have OpenPanel installed.
# to use OpenPanel-FTP as a standalone ftp server, check the readme

config_file="/usr/local/panel/conf/panel.config"


# OpenPanel?
check_openpanel_installed() {
  if [ -f $config_file ]; then
    return 0
  else
    return 1
  fi
}

# run container
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

# open ports
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

  # create dir
  mkdir -p /etc/openpanel/ftp/users/

  # run the container
  echo "Starting docker container.."
  run_docker_container

  # if container started, we continue..
  if docker ps --filter "name=openadmin_ftp" --filter "status=running" | grep -q openadmin_ftp; then

    echo "Copying OpenPanel module and OpenAdmin extension files.."
    # OpenPanel module
    cp module/ftp.py /usr/local/panel/modules/ftp.py
    cp module/ftp.html /usr/local/panel/templates/ftp.html
  
    # OpenAdmin extension
    cp module/admin/ftp.py /usr/local/admin/modules/ftp.py
    cp module/admin/ftp.html /usr/local/admin/templates/ftp.html
  
  # Check if 'ftp' is in the enabled_modules line
  if grep -q "^enabled_modules=.*ftp" "$config_file"; then
    # FTP already exists in enabled modules!
    echo "FTP Module is already enabled in OpenPanel configuration."
  else
    # nope
    echo "Adding FTP to enabled_modules for OpenPanel."
    sed -i '/^enabled_modules=/ s/$/,ftp/' "$config_file"
  fi
    
  
    # reload services
    echo "Reloading OpenPanel and OpenAdmin services to apply changes."
    service admin reload
    service panel reload
    
  else
    # Oops!
    echo ""
    echo "ERROR: openadmin_ftp container is not running. Exiting..."
    echo ""
    docker stop openadmin_ftp
    docker rm openadmin_ftp
    exit 1
  fi

  # Open the required ports
  open_ports
  echo ""
  echo "SUCCESS: FTP is now running and enabled for all OpenPanel users."
  echo ""
else
  echo ""
  echo "ERROR: OpenPanel is not installed. To run a standalone FTP without OpenPanel, please read the README.md file."
  echo ""
fi
