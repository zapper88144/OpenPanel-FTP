#!/bin/bash

# this script should be run only on servers that have OpenPanel installed.
# to use OpenPanel-FTP as a standalone ftp server, check the readme

PANEL_CONFIG="/etc/openpanel/openpanel/conf/openpanel.config"
GIT_URL="https://github.com/stefanpejcic/OpenPanel-FTP/archive/refs/heads/master.zip"
ETC_DIR="/etc/openpanel/ftp/users/"

apt-get install zip -y

# OpenPanel?
check_openpanel_installed() {
  if [ -f $PANEL_CONFIG ]; then
    return 0
  else
    return 1
  fi
}

# run container
run_docker_container() {
  cd /root && docker compose up openadmin_ftp -d
}


# open ports
open_ports() {

# Check for CSF
if command -v csf >/dev/null 2>&1; then
  function open_port_csf() {
      local port=$1
      local csf_conf="/etc/csf/csf.conf"
      
      # Check if port is already open
      port_opened=$(grep "TCP_IN = .*${port}" "$csf_conf")
      if [ -z "$port_opened" ]; then
          # Open port
          sed -i "s/TCP_IN = \"\(.*\)\"/TCP_IN = \"\1,${port}\"/" "$csf_conf"
          echo "Port ${port} opened in CSF."
          ports_opened=1
      else
          echo "Port ${port} is already open in CSF."
      fi
  }
  
  open_port_csf 21
  open_port_csf 21000:21010
  csf -r
      
# Check for UFW
elif command -v ufw >/dev/null 2>&1; then

  ufw allow 21/tcp
  for port in $(seq 21000 21010); do
    ufw allow $port/tcp
  done
  ufw reload
  
else
    echo "Error: Neither CSF nor UFW are detected. If using external firewall make sure to open ports: '21' and '21000:21010'."
fi






}

#cleanup
cleanup() {
  rm file.zip
  rm -rf OpenPanel-FTP-master
} 



# Main script
if check_openpanel_installed; then
  echo "OpenPanel is installed. Proceeding with Docker container setup and port opening."
      run_docker_container
  fi


  # if container started, we continue..
  if docker ps --filter "name=openadmin_ftp" --filter "status=running" | grep -q openadmin_ftp; then
  
  # Check if 'ftp' is in the enabled_modules line
  if grep -q "^enabled_modules=.*ftp" "$PANEL_CONFIG"; then
    # ftp already exists in enabled modules!
    echo "FTP Module is already enabled in OpenPanel configuration."
  else
    # nope, add it!
    echo "Adding FTP to enabled_modules for OpenPanel."
    sed -i '/^enabled_modules=/ s/$/,ftp/' "$PANEL_CONFIG"
  fi
    
  
    # reload services
    echo "Reloading OpenPanel and OpenAdmin services to apply changes."
    #service admin reload
    docker restart openpanel
    
  else
    # Oops!
    echo ""
    echo "ERROR: openadmin_ftp container is not running. Exiting..."
    echo ""
    docker stop openadmin_ftp
    docker rm openadmin_ftp
    exit 1
  fi

  # ufw
  open_ports

  #rm
  cleanup

  echo ""
  echo "SUCCESS: FTP is now running and enabled for all OpenPanel users."
  echo ""
else
  echo ""
  echo "ERROR: OpenPanel is not installed. To run a standalone FTP without OpenPanel, please read the README.md file."
  echo ""
fi
