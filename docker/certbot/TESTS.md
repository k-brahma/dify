# Add docker-compose certbot configurations description

## Short description

### Outline

- Certbot available with `--profile certbot` option.
- Without `--profile certbot` option you can still use cert files dir `nginx/ssl` as before.

Now that for newly launching servers SSL setup process is rather easy but still legacy way is effective.

See `docker/certbot/README.md` for easy setup.

## Files editted/added

### Document

| file                | detail                                         |
|---------------------|------------------------------------------------|
| `README.md`         | Updated, added to the section "What's Updated" |
| `certbot/README.md` | Added desciption document                      |

### docker-compose:

| file                 | detail                                                                       |
|----------------------|------------------------------------------------------------------------------|
| `docker-compse.yaml` | Updated nginx container settings, added certbot container settings           |
| `.env.example`       | Added key-value pairs for certbot container (and consequently for nginx app) |

### nginx:

| file                                 | detail                                                                      |
|--------------------------------------|-----------------------------------------------------------------------------|
| `nginx/conf.d/default.conf.template` | Added acme-challenge location directive placeholder                         |
| `nginx/https.conf.template`          | Updated, simplified                                                         |
| `nginx/docker-entrypoint.sh`         | Updated, calculate ssl_certificate_path and ssl_certificate_key_path inside |

### certbot:

| file                           | detail                                     |
|--------------------------------|--------------------------------------------|
| `certbot/docker-entrypoint.sh` | added, generates certbot/update-cert.sh    |
| `certbot/update-cert.template` | added, template for certbot/update-cert.sh |

> `update-cert.sh` works as `certbot certonly` for the first time and later as `certbot renew`.  
> Personally I think some of `certbot` command options can be moved to `CERTBOT_OPTIONS` value but as I'm not sure which to moved would best so now `CERTBOT_OPTIONS` value is empty.

### .env keys

Added keys below:

| key                              | default | details                                                          |
|----------------------------------|---------|------------------------------------------------------------------|
| `NGINX_ENABLE_CERTBOT_CHALLENGE` | `false` | Set `true` to accept requests for `/.well-known/acme-challenge/` |
| `CERTBOT_DOMAIN`                 |         | Domain name when use certbot container                           |
| `CERTBOT_EMAIL`                  |         | Email address to use on `certbot certonly` certification         |
| `CERTBOT_OPTIONS`                |         | Additional options for certbot command. i.e., `--dry-run`        |

***

## Test scenarios for this update

## Overview

This test scenarios assumes:

- Dify app is installed in dir `~/dify/docker`
- No containers ever built or launched

### Scenario1: New feature: with certbot container

1. Test that the server launches properly
2. Test that `certbot certonly` command works by running `certbot/update-cert.sh`
3. Test that certificate files obtained by the `certbot certonly` command work correctly
4. Test that `certbot renew` command works by running `certbot/update-cert.sh`
5. Test that `CERTBOT_OPTIONS` values are correctly applied to the `certbot` command

### Scenario2: Backward compatibility: without certbot container

1. Test that legacy procedure works

## Details

### Scenario1: New feature: with certbot container

#### Scenario1-1: Test that the server launches properly

> ***Purpose:***
> - Check that the server accepts normal http request.
>
> ***Process overview:***
> 1. `sudo docker-compose up`
> 2. Check that the server accepts normal http request
> 3. `sudo docker-compose down`

Navigate to the dir `~/dify/docker` and launch containers using `docker-compose.yaml`.

```shell
cd ~/dify/docker
sudo docker-compose up
```

Then check server accessibility (HTTP)

http://your_domain.com

Then, `docker-comose down`

```shell
sudo docker-compose down
```

#### Scenario1-2: Test that `certbot certonly` command works by running `certbot/update-cert.sh`

> ***Purpose:***
> - Check that the server accepts requests for `/.well-known/acme-challenge/`
> - Check that by running `certbot/update-cert.sh` `certbot certonly` command works and successfully get cert files.
>
> ***Process overview:***
> 1. Set `.env` values
> 2. `sudo docker-compose --profile certbot up`
> 3. `sudo docker-compose exec -it certbot /bin/sh /update-cert.sh`
> 4. Check the results if necessary
> 5. `sudo docker-compose down`

Create a file `~/dify/docker/.env`.

```shell
cd ~/dify/docker
vim .env
```

Add the line below and save the file.  
(Or if you already copied .env.example to .env, edit the key below)

```properties
NGINX_ENABLE_CERTBOT_CHALLENGE=true
CERTBOT_DOMAIN=your_domain.com
CERTBOT_EMAIL=example@your_domain.com
```

Launch containers using `docker-compose.yaml` with option `--profile certbot`.

```shell
sudo docker network prune
sudo docker-compose --profile certbot up --force-recreate
```

First check that the server is accesabile using http protocol.

http://your_domain.com

Then, via another terminal:

Navigate to `~/dify/docker` and check that no cert action excecuted yet.

```shell
cd ~/dify/docker
sudo docker-compose exec -it certbot ls /etc/letsencrypt/live/
sudo docker-compose exec -it certbot ls /var/log/letsencrypt/
```

> `ls /var/log/letsencrypt/` may return some of letsencrypt.log* files, as for each time certbot container launch, the log file automatically generated.

Excecute command `certbot certonly` by executing `/update-cert.sh`

```shell
sudo docker-compose exec -it certbot /bin/sh /update-cert.sh
```

Expected succssful result as follows:

```text
Certificate does not exist. Obtaining a new certificate...
Saving debug log to /var/log/letsencrypt/letsencrypt.log
Account registered.
Requesting a certificate for your_domain.com

Successfully received certificate.
Certificate is saved at: /etc/letsencrypt/live/your_domain.com/fullchain.pem
Key is saved at:         /etc/letsencrypt/live/your_domain.com/privkey.pem
This certificate expires on 2024-10-23.
These files will be updated when the certificate renews.

NEXT STEPS:
- The certificate will need to be renewed before it expires. Certbot can automatically renew the certificate in the background, but you may need to take steps to enable that functionality. See https://certbot.org/renewal-setup for instructions.

- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
If you like Certbot, please consider supporting our work by:
 * Donating to ISRG / Let's Encrypt:   https://letsencrypt.org/donate
 * Donating to EFF:                    https://eff.org/donate-le
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
Certificate operation successful
Please ensure to reload Nginx to apply any certificate changes.
```

> Check certbot logs if necesary:
> ```shell
> cat ~/dify/docker/volumes/certbot/logs/letsencrypt.log
> ```

Then `docker-compose down`

```shell
sudo docker-compose down
```

#### Scenario1-3: Test that certificate files obtained by the `certbot certonly` command work correctly

> ***Purpose:***
> - Check that the server accepts both http and https requests
> - Check that by running `certbot/update-cert.sh` `certbot certonly` command works and successfully get cert files.
>
> ***Process overview:***
> 1. Set `.env` values
> 2. `sudo docker-compose --profile certbot up`
> 3. Check both http and https reqeuests
> 4. `sudo docker-compose down`

Edit `.env` file

```shell
vim .env
```

Add the line below and save the file.  
(Or if you already copied .env.example to .env, edit the key below)

```properties
# Add (or edit if already exists):
NGINX_HTTPS_ENABLED=true
NGINX_SSL_CERT_FILENAME=fullchain.pem
NGINX_SSL_CERT_KEY_FILENAME=privkey.pem
# Keys below already there:
NGINX_ENABLE_CERTBOT_CHALLENGE=true
CERTBOT_DOMAIN=your_domain.com
CERTBOT_EMAIL=example@your_domain.com
```

Launch containers using `docker-compose.yaml` with option `--profile certbot`.

```shell
sudo docker network prune
sudo docker-compose --profile certbot up --force-recreate
```

Then check server accesability (both http and https)

http://your_domain.com  
https://your_domain.com

Then `docker-compose down`

```shell
sudo docker-compose down
```

#### Scenario1-4: Test that `certbot renew` command works by running `certbot/update-cert.sh`

> ***Purpose:***
> - Check that by running `certbot/update-cert.sh` `certbot certonly` command works and successfully get cert files.
>
> ***Memo:***  
> If the certificate already exists, `certbot/update-cert.sh` executes `certbot renew`.
>
> ***Process overview:***
> 1. Set `.env` values
> 2. `sudo docker-compose --profile certbot up`
> 3. `sudo docker-compose exec -it certbot /bin/sh /update-cert.sh`
> 4. Check that timestamp for cert files ***DOES NOT*** changed
> 5. `sudo docker-compose down`

Edit `.env` file

```shell
vim .env
```

Add the line below and save the file.  
(Or if you already copied .env.example to .env, edit the key below)

```properties
# Add (or edit if already exists):
NGINX_CREATE_CERTBOT_CHALLENGE_LOCATION=true
# Keys below already there:
NGINX_HTTPS_ENABLED=true
NGINX_SSL_CERT_FILENAME=fullchain.pem
NGINX_SSL_CERT_KEY_FILENAME=privkey.pem
NGINX_ENABLE_CERTBOT_CHALLENGE=true
CERTBOT_DOMAIN=your_domain.com
CERTBOT_EMAIL=example@your_domain.com
```

Launch containers using `docker-compose.yaml` with option `--profile certbot`.

```shell
sudo docker network prune
sudo docker-compose --profile certbot up --force-recreate
```

Navigate to `~/dify/docker` and check current cert files' timestamp:

```shell
cd ~/dify/docker
sudo docker-compose exec -it certbot ls -al /etc/letsencrypt/live/your_domain.com/
```

```text
total 12
drwxr-xr-x    2 root     root          4096 Jul 25 22:06 .
drwxr-xr-x    3 root     root          4096 Jul 25 22:06 ..
-rw-r--r--    1 root     root           692 Jul 25 22:06 README
lrwxrwxrwx    1 root     root            38 Jul 25 22:06 cert.pem -> ../../archive/your_domain.com/cert1.pem
lrwxrwxrwx    1 root     root            39 Jul 25 22:06 chain.pem -> ../../archive/your_domain.com/chain1.pem
lrwxrwxrwx    1 root     root            43 Jul 25 22:06 fullchain.pem -> ../../archive/your_domain.com/fullchain1.pem
lrwxrwxrwx    1 root     root            41 Jul 25 22:06 privkey.pem -> ../../archive/your_domain.com/privkey1.pem
```

Excecute command `certbot renew` by executing `/update-cert.sh`

```shell
sudo docker-compose exec -it certbot /bin/sh /update-cert.sh
```

Expected succssful result as follows (No renewals were attempted as certs a not due for renewal).

```text
Certificate exists. Attempting to renew...
Saving debug log to /var/log/letsencrypt/letsencrypt.log

- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
Processing /etc/letsencrypt/renewal/your_domain.com.conf
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
Certificate not yet due for renewal

- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
The following certificates are not due for renewal yet:
  /etc/letsencrypt/live/your_domain.com/fullchain.pem expires on 2024-10-23 (skipped)
No renewals were attempted.
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
Certificate operation successful
Please ensure to reload Nginx to apply any certificate changes.
```

Check that cert files not updated.

```shell
cd ~/dify/docker
sudo docker-compose exec -it certbot ls -al /etc/letsencrypt/live/your_domain.com/
```

```text
total 12
drwxr-xr-x    2 root     root          4096 Jul 25 22:06 .
drwxr-xr-x    3 root     root          4096 Jul 25 22:06 ..
-rw-r--r--    1 root     root           692 Jul 25 22:06 README
lrwxrwxrwx    1 root     root            38 Jul 25 22:06 cert.pem -> ../../archive/your_domain.com/cert1.pem
lrwxrwxrwx    1 root     root            39 Jul 25 22:06 chain.pem -> ../../archive/your_domain.com/chain1.pem
lrwxrwxrwx    1 root     root            43 Jul 25 22:06 fullchain.pem -> ../../archive/your_domain.com/fullchain1.pem
lrwxrwxrwx    1 root     root            41 Jul 25 22:06 privkey.pem -> ../../archive/your_domain.com/privkey1.pem
```

> Check certbot logs if necesary:
> ```shell
> cat ~/dify/docker/volumes/certbot/logs/letsencrypt.log
> ```

Then `docker-compose down`

```shell
sudo docker-compose down
```

#### Scenario1-5: Test that `CERTBOT_OPTIONS` values are correctly applied to the `certbot` command

> ***Purpose:***
> - Check that `CERTBOT_OPTIONS` values are correctly applied to the `certbot` command
>
> ***Process overview:***
> 1. Set `.env` values
> 2. `sudo docker-compose --profile certbot up`
> 3. `sudo docker-compose exec -it certbot /bin/sh /update-cert.sh`
> 4. Check that timestamp for cert files ***DOES*** changed
> 5. `sudo docker-compose down`

Edit `.env` file

```shell
vim .env
```

Add the line below and save the file.  
(Or if you already copied .env.example to .env, edit the key below)

```properties
# Add (or edit if already exists):
CERTBOT_OPTIONS=--force-renewal
# Keys below already there:
NGINX_CREATE_CERTBOT_CHALLENGE_LOCATION=true
NGINX_HTTPS_ENABLED=true
NGINX_SSL_CERT_FILENAME=fullchain.pem
NGINX_SSL_CERT_KEY_FILENAME=privkey.pem
NGINX_ENABLE_CERTBOT_CHALLENGE=true
CERTBOT_DOMAIN=your_domain.com
CERTBOT_EMAIL=example@your_domain.com
```

Launch containers using `docker-compose.yaml` with option `--profile certbot`.

```shell
sudo docker network prune
sudo docker-compose --profile certbot up --force-recreate
```

Navigate to `~/dify/docker` and check current cert files' timestamp:

```shell
cd ~/dify/docker
sudo docker-compose exec -it certbot ls -al /etc/letsencrypt/live/your_domain.com/
```

```text
total 12
drwxr-xr-x    2 root     root          4096 Jul 25 22:06 .
drwxr-xr-x    3 root     root          4096 Jul 25 22:06 ..
-rw-r--r--    1 root     root           692 Jul 25 22:06 README
lrwxrwxrwx    1 root     root            38 Jul 25 22:06 cert.pem -> ../../archive/your_domain.com/cert1.pem
lrwxrwxrwx    1 root     root            39 Jul 25 22:06 chain.pem -> ../../archive/your_domain.com/chain1.pem
lrwxrwxrwx    1 root     root            43 Jul 25 22:06 fullchain.pem -> ../../archive/your_domain.com/fullchain1.pem
lrwxrwxrwx    1 root     root            41 Jul 25 22:06 privkey.pem -> ../../archive/your_domain.com/privkey1.pem
```

Excecute command `certbot renew` by executing `/update-cert.sh`

```shell
sudo docker-compose exec -it certbot /bin/sh /update-cert.sh
```

Expected succssful result as follows (Updated even certs a not due for renewal).

```text
webapp@ccc:~/dify/docker$ sudo docker-compose exec -it certbot /bin/sh /update-cert.sh
Certificate exists. Attempting to renew...
Saving debug log to /var/log/letsencrypt/letsencrypt.log

- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
Processing /etc/letsencrypt/renewal/your_domain.com.conf
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
Renewing an existing certificate for your_domain.com

- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
Congratulations, all renewals succeeded:
  /etc/letsencrypt/live/your_domain.com/fullchain.pem (success)
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
Certificate operation successful
Please ensure to reload Nginx to apply any certificate changes.
```

Check that cert files updated.

```shell
cd ~/dify/docker
sudo docker-compose exec -it certbot ls -al /etc/letsencrypt/live/your_domain.com/
```

```text
total 12
drwxr-xr-x    2 root     root          4096 Jul 25 23:01 .
drwxr-xr-x    3 root     root          4096 Jul 25 22:06 ..
-rw-r--r--    1 root     root           692 Jul 25 22:06 README
lrwxrwxrwx    1 root     root            38 Jul 25 23:01 cert.pem -> ../../archive/your_domain.com/cert2.pem
lrwxrwxrwx    1 root     root            39 Jul 25 23:01 chain.pem -> ../../archive/your_domain.com/chain2.pem
lrwxrwxrwx    1 root     root            43 Jul 25 23:01 fullchain.pem -> ../../archive/your_domain.com/fullchain2.pem
lrwxrwxrwx    1 root     root            41 Jul 25 23:01 privkey.pem -> ../../archive/your_domain.com/privkey2.pem
```

> Check certbot logs if necesary:
> ```shell
> cat ~/dify/docker/volumes/certbot/logs/letsencrypt.log
> ```

Then check renewed cert files effective by:

Reload Nginx

```shell
sudo docker-compose exec nginx nginx -s reload
```

Or restart docker containers

```shell
sudo docker-compose down
sudo docker network prune
sudo docker-compose --profile certbot up --force-recreate
```

Then check server accesability (both http and https)

http://your_domain.com  
https://your_domain.com

Then, it is recommended to set `CERTBOT_OPTIONS` value blank (or delete the key)

```shell
vim .env
```

Edit the line below and save the file.  
(Or if you already copied .env.example to .env, edit the key below)

```properties
# Edit
CERTBOT_OPTIONS=""
# Keys below already there:
NGINX_CREATE_CERTBOT_CHALLENGE_LOCATION=true
NGINX_HTTPS_ENABLED=true
NGINX_SSL_CERT_FILENAME=fullchain.pem
NGINX_SSL_CERT_KEY_FILENAME=privkey.pem
NGINX_ENABLE_CERTBOT_CHALLENGE=true
CERTBOT_DOMAIN=your_domain.com
CERTBOT_EMAIL=example@your_domain.com
```

Then `docker-compose down`

```shell
sudo docker-compose down
```

### Scenario2: Backward compatibility: without certbot container

> ***Memo:***  
> Create a new server. ***Don't use the server used for the scenario test 1***

#### Scenario2-1. Test that legacy procedure works

> ***Purpose:***  
> Confirm that legacy `docker/nginx/ssl` storage also works as cert files location.
>
> ***Process overview:***
> 1. Get cert files using host os certbot
> 2. Copy cert files to `docker/nginx/ssl`
> 3. `sudo docker-compose`
> 4. Check both http and https reqeuests
> 5. `sudo docker-compose down`

Get cert files using host os' certbot

```bash
# Update system packages
sudo apt update

# Install Certbot
sudo apt install certbot

# Obtain SSL certificate (standalone mode)
sudo certbot certonly --standalone -d your_domain.com
```

copy cert files to `nginx/ssl/` and set read permission.

```
sudo ls -al /etc/letsencrypt/live/your_domain.com/

sudo cp -L /etc/letsencrypt/live/your_domain.com/{cert,chain,fullchain,privkey}.pem ~/dify/docker/nginx/ssl/
sudo mv ~/dify/docker/nginx/ssl/fullchain.pem ~/dify/docker/nginx/ssl/dify.crt
sudo mv ~/dify/docker/nginx/ssl/privkey.pem ~/dify/docker/nginx/ssl/dify.key

sudo chmod +r ~/dify/docker/nginx/ssl/*

ls -al ~/dify/docker/nginx/ssl/
```

Then you'll find that `dify.crt` and `dify.key` exists in the dir`docker/nginx/ssl/`.

```text
total 24
drwxrwxr-x 2 webapp webapp 4096 Jul 25 23:34 .
drwxrwxr-x 4 webapp webapp 4096 Jul 24 16:48 ..
-rw-rw-r-- 1 webapp webapp    0 Jul 24 09:45 .gitkeep
-rw-r--r-- 1 root   root   1273 Jul 25 23:34 cert.pem
-rw-r--r-- 1 root   root   1566 Jul 25 23:34 chain.pem
-rw-r--r-- 1 root   root   2839 Jul 25 23:34 dify.crt
-rw-r--r-- 1 root   root    241 Jul 25 23:34 dify.key
```

Create a file `~/dify/docker/.env`.

```shell
cd ~/dify/docker
vim .env
```

Add the line below and save the file.  
(Or if you already copied .env.example to .env, edit the key below)

```properties
# Add (or edit if already exists):
NGINX_HTTPS_ENABLED=true
```

Navigate to the dir `~/dify/docker` and launch containers using `docker-compose.yaml`.

```shell
cd ~/dify/docker
sudo docker-compose up
```

Then check server accesability (both http and https)

http://your_domain.com  
https://your_domain.com

Then `docker-compose down`

```shell
sudo docker-compose down
```
