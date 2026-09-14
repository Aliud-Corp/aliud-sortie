ARG BUILD_FROM
FROM $BUILD_FROM

# tinyproxy plutôt que squid : il tient dans deux mégaoctets, il ne met rien en
# cache — un cache sur un proxy de collecte rendrait deux fois la même réponse
# et fausserait un relevé daté — et sa configuration est un fichier plat que
# l'on peut écrire à chaque démarrage.
#
# `iproute2` sert à lire l'adresse du mesh, `jq` à lire les options de l'add-on.
RUN apk add --no-cache tinyproxy iproute2 jq

COPY run.sh /run.sh
RUN chmod a+x /run.sh

CMD [ "/run.sh" ]
