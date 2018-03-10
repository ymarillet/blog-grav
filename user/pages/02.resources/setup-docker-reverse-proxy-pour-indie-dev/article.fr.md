---
title: 'Setup docker + reverse proxy pour indie dev'
date: '06-03-2018 14:30'
taxonomy:
    categories:
        - Tech
    technologies:
        - Docker
        - Nginx
        - 'Let''s Encrypt'
header_image: '0'
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

```bash
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
```

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

networks:
  reverseproxy:
     driver: "bridge"

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
```

#### Explications
```yaml
networks:
  reverseproxy:
     driver: "bridge"
```
On déclare un network qui sera **partagé** avec d'autres containers (de manière non-implicite cependant)

```yaml
    ports:
        - "80:80"
        - "443:443"
```
Notre reverse proxy est notre point d'entrée principal, on mappe donc les ports 80 et 443 du host dessus. Vous ne pourrez donc pas mapper une deuxième fois les ports 80 et 443 du host, mais c'est tout le but du reverse proxy ...
Le port 80 reste indispensable pour Let's Encrypt.

```yaml
    labels:
        - "com.github.jrcs.letsencrypt_nginx_proxy_companion.nginx_proxy"
```
C'est ce qui fait le lien avec *nginx-proxy-companion*. Si vous n'avez pas besoin de Let's Encrypt (j'espère quand même que vous n'exposerez pas vos services de prod en http), vous pouvez virer cette ligne, ainsi que le service *nginx-proxy-companion*.

```yaml
 nginx-proxy-companion:
```
C'est le petit container magique qui va générer et regénérer automatiquement vos certificats ssl. Notez bien sûr que pendant le renouvellement, votre application sera **indisponible**, car Let's Encrypt a besoin de dialoguer avec le reverse proxy pour vérifier que votre domaine est bien mappé sur votre serveur.

### Setup d'un autre service (par exemple, une stack nginx/php toute simple)

#### docker-compose.yml

```yaml
version: '3'

networks:
  reverseproxy:
    external:
      name: "reverseproxy_reverseproxy"

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
```

#### Explications

```yaml
networks:
  reverseproxy:
    external:
      name: "reverseproxy_reverseproxy"
```
On importe le network qu'on a créé dans notre docker compose précédent. Le nom est `reverseproxy_reverseproxy` parce que le `docker-compose.yml` de mon reverse proxy se trouve dans le dossier `reverseproxy` (en remplacement de `service1` dans l'arborescence exemple) et parce que la clé de la définition du network dans ce même fichier est `reverseproxy`. A vous d'adapter en conséquence si vous modifier ces valeurs.
Cela veut également dire qu'il vaudrait mieux lancer votre reverse proxy `docker-compose up -d` avant de lancer vos autres services, au moins une fois, histoire de créer le network.

```yaml
  environment:
      - VIRTUAL_HOST=domain.com
      - LETSENCRYPT_HOST=domain.com
      - LETSENCRYPT_EMAIL=mail@domain.com
```
Ahhh, on arrive enfin à la partie croustillante (tout ça pour ça !).

La variable `VIRTUAL_HOST` sera hookée par le reverse proxy pour TOUS les containers qui l'auront définie. C'est possible grâce à l'API docker parce qu'on a partagé le socket docker du host dans le container du reverse proxy:

```yaml
    volumes:
        - "/var/run/docker.sock:/tmp/docker.sock:ro"
```

Ce hook va s'opérer lors du démarrage du container du reverse proxy, mais aussi lors du démarrage d'un container contenant cette variable d'environement. Ce qui veut dire que vous n'avez pas à redémarrer le reverse proxy à chaque création de service.
![Génial](pseb.jpg) Oh pu**** c'est génial. 

Vous pouvez bien sûr mettre un sous domaine, et même plusieurs domaines, en les séparant par des `,` virgules. Le contenu de `LETSENCRYPT_HOST` doit être identique à celui de `VIRTUAL_HOST` (sauf si certains domaines/sous-domaines ne doivent pas être soumis à Let's Encrypt). `LETSENCRYPT_EMAIL`, c'est l'adresse email qui sera associée aux certificats générés. Il me semble qu'avec des virgules et si votre container est en domaines multiples, vous pouvez donner des adresses email différentes pour vos différents domaines, mais j'ai jamais testé. `LETSENCRYPT_HOST` et `LETSENCRYPT_EMAIL` sont bien sûr optionnels (genre, sur une machine de dev, vous en voulez pas).

```yaml
  networks:
      - "default"
      - "reverseproxy"
```
Il faudra mettre le network `reverseproxy` (ou le petit nom que vous lui aurez donné si vous le changez) partout où une variable d'environnement `VIRTUAL_HOST` est définie. Quant au network "default", il s'agit du nom du network qui est normalement mis en place pour tous les services définis dans un `docker-compose.yml`, donc histoire de pas perdre cette feature, il faut le remettre (sinon plus de communcation entre vos containers).

Notez que le network `reverseproxy` n'a pas été mis sur le service `php`, il n'en a pas besoin.

Avec ce setup cependant, vos containers communiquent en **HTTP** avec le reverse proxy (port 80 par défaut donc, ou vous pouvez aussi définir la variable d'environement `VIRTUAL_PORT`), il peut s'agir d'un problème de sécurité si vous êtes absolument psychopathe.