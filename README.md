# FTP module for [OpenPanel](https://openpanel.co)

Small and flexible docker image with vsftpd server + OpenPanel module to allow users to manage ftp sub-users.

### Usage

This image can be used in two ways:
- as an FTP module for OpenPanel
- as a standalone FTP server



## standalone Docker

Installation:
```
docker run -d \
    -p "21:21" \
    -p 21000-21010:21000-21010 \
    --restart=always \
    --name=openadmin_ftp \
    -v /home:/home \
    -v /etc/openpanel/ftp/users:/etc/openpanel/ftp/users
    --memory="1g" --cpus="1" \
    openpanel/ftp
```

Adding accounts:

```
# to create temporary account *(until docker restart):
docker exec -it openadmin_ftp sh -c 'echo -e "${PASSWORD}\n${PASSWORD}" | adduser -h $DIRECTORY -s /sbin/nologin $USERNAME'

# to create permanent ftp account that will be created on docker restart:
echo "$USERNAME|$PASSWORD|$DIRECTORY" >> /etc/openpanel/ftp/users/users.list
```


### OpenPanel Module

To install FTP on OpenPanel server run the following command:
```bash
opencli ftp-setup
```

To create new FTP accounts:
```bash
opencli ftp-add <NEW_USERNAME> <NEW_PASSWORD> <FOLDER> <OPENPANEL_USERNAME>
```



## Usage

To add ftp account on a s


## Configuration

Environment variables:
- `USERS` - space and `|` separated list (optional, default: `alpineftp|alpineftp`)
  - format `name1|password1|[folder1][|uid1][|gid1] name2|password2|[folder2][|uid2][|gid2]`
- `ADDRESS` - external address to which clients can connect for passive ports (optional, should resolve to ftp server ip address)
- `MIN_PORT` - minimum port number to be used for passive connections (optional, default `21000`)
- `MAX_PORT` - maximum port number to be used for passive connections (optional, default `21010`)

## USERS examples

- `user|password foo|bar|/home/foo`
- `user|password|/home/user/dir|10000`
- `user|password|/home/user/dir|10000|10000`
- `user|password||10000`
- `user|password||10000|82` : add to an existing group (www-data)
