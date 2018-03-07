#!/usr/bin/env bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

bin/grav install \
 && bin/gpm -n install admin git-sync langswitcher bootstrap twig-extensions jscomments

if [ ! -d "$DIR/user/plugins/prism" ]
then
	cd "$DIR/user/plugins" \
	&& git clone https://github.com/alvr/grav-prism-highlight.git prism \
	&& rm -rf .git/ \
	&& cd "$DIR"
fi

bin/grav clearcache
