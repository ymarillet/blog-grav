---
title: 'Setup docker + reverse proxy pour indie dev'
date: '06-03-2018 14:30'
---

## Objectifs
Vous êtes un développeur. Vous êtes bidouilleur. Vous voulez vous monter votre propre ferme de micro services (soit parce que vous êtes trop parano pour utiliser les services qui existent potentiellement déjà en SaaS, soit pour acquérir une expérience dans le domaine, soit ... bref, vous avez vos raisons.), sauf que, vous êtes tout seul, pauvre petit développeur, et vous vous êtes vite rendu compte que ça nécessitait pas mal d'investissement sur votre temps de loisir.

Je ne prétends pas être un maître dans l'art subtil qu'est la containerisation, par contre je vous donne un petit setup efficace pour monter vos stacks techniques et exposer facilement n'importe quel service ayant une interface web (protocole http(s)), avec certificats Let's Encrypt générés et renouvellés automatiquement, histoire que vous puissiez vous concentrer sur ce qui est réelement important pour vous: le DEV !

Un des autres objectifs est de pouvoir migrer tout votre serveur sans trop de difficulté puisque tous les 2/3 ans, les fermes de serveurs se renouvellent, et donc on vous prévient gentiement 3 à 6 mois à l'avance que votre serveur dédié/mutualisé va finir à la poubelle, même si on vous proposera un serveur de la meme gamme derrière, n'empêche que si vous vous bougez pas le fion, vous allez tout perdre.

## Architecture
On part sur une architecture single serveur (ben oui, en tant que pauvre petit dév, vous avez pas beaucoup de moyen, ou alors vous êtes proche de votre compte en banque), je n'ai pas encore expérimenté le clustering (j'en ai pas encore eu le besoin.)

Les recettes sont à base de docker-compose (je pars du principe que vous savez comment utiliser/installer docker et docker-compose, sinon filez sur le net lire quelques tutos).

Créez-vous un utilisateur (n'utilisez jamais `root` pour vos applications). Pensez à noter l'UID et le GID, ça nous sera utile un peu plus loin.

Notre arboresence se déterminera comme suit:
<pre>
$ tree ~
/home/your_user
└── docker
    ├── images
    │   ├── service1
    │   │   ├── docker-compose.yml
    │   │   └── volumes -> ../../volumes/service1
    │   └── service2
    │       ├── docker-compose.yml
    │       └── volumes -> ../../volumes/service2
    └── volumes
        ├── service1
        │   └── config.conf
        └── service2
            └── env.ini
</pre>

On sépare les dossiers `images` et `volumes`:
* `images` contiendra les docker compose, les variables d'environement, d'autres fichiers pouvant être versionnés, etc.
* `volumes` contiendra les données persistantes pour vos containers

On centralise tous les volumes dans un seul dossier, comme ça vous pouvez faire un point de montage, une partition différente, etc. Ca permet aussi un gain de temps lors d'une migration de serveur.
Le dossier `images` quant à lui, peut être versionné facilement, en 1 ou plusieurs repo, à votre convenance.

## Réalisation

### Setup du reverse proxy

#### docker-compose.yml
Path: ~/docker/images/reverseproxy/docker-compose.yml

```yaml
version: '3'

services:
  nginx-proxy:
    restart: "unless-stopped"
    image: "jwilder/nginx-proxy:alpine"
    ports:
        - "80:80"
        - "443:443"
    volumes:
        - "./volumes/certs:/etc/nginx/certs:ro"
        - "./volumes/vhosts:/etc/nginx/vhost.d"
        - "./volumes/html:/usr/share/nginx/html"
        - "./volumes/htpasswd:/etc/nginx/htpasswd:ro"
        - "/var/run/docker.sock:/tmp/docker.sock:ro"
    networks:
        - "reverseproxy"
    labels:
        - "com.github.jrcs.letsencrypt_nginx_proxy_companion.nginx_proxy"

  nginx-proxy-companion:
    restart: "unless-stopped"
    image: "jrcs/letsencrypt-nginx-proxy-companion"
    volumes:
        - "./volumes/certs:/etc/nginx/certs:rw"
        - "./volumes/vhosts:/etc/nginx/vhost.d"
        - "./volumes/html:/usr/share/nginx/html"
        - "/var/run/docker.sock:/var/run/docker.sock"
    networks:
        - "reverseproxy"

networks:
  reverseproxy:
     driver: "bridge"
```

#### Explications: todo

### Setup d'un autre service (par exemple, une stack nginx/php toute simple)

#### docker-compose.yml

```yaml
version: '3'
services:
  web:
    image: nginx
    restart: "unless-stopped"
    volumes:
      - "./volumes/logs:/var/log/nginx"
      - "./volumes/conf/nginx.conf:/etc/nginx/nginx.conf"
      - "./volumes/sources:/mnt/sources"
    environment:
      - VIRTUAL_HOST=domain.com
      - LETSENCRYPT_HOST=domain.com
      - LETSENCRYPT_EMAIL=mail@domain.com
    depends_on:
      - php
    networks:
      - "default"
      - "reverseproxy"

  php:
    image: php:fpm-alpine
    restart: "unless-stopped"
    volumes:
      - "./volumes/php/php.ini:/usr/local/etc/php/php.ini"
      - "./volumes/sources:/mnt/sources"
    networks:
      - "default"

networks:
  reverseproxy:
    external:
      name: "reverseproxy_reverseproxy"
```

#### Explications: todo
