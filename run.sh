#!/usr/bin/env bash

bin/grav install \
 && bin/gpm -n install admin git-sync langswitcher bootstrap twig-extensions jscomments \
 && bin/grav clearcache
