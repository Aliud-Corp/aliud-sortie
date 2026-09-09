#!/bin/sh
# Écrit la configuration du proxy à chaque démarrage, puis le lance au premier
# plan pour que le Supervisor voie sa sortie et son état.
set -eu

OPTIONS=/data/options.json

port="$(jq -r '.port' "$OPTIONS")"
utilisateur="$(jq -r '.utilisateur' "$OPTIONS")"
mot_de_passe="$(jq -r '.mot_de_passe' "$OPTIONS")"
interface="$(jq -r '.interface' "$OPTIONS")"
journal="$(jq -r '.journal' "$OPTIONS")"

[ -n "$mot_de_passe" ] || {
  echo "aliud-sortie: aucun mot de passe dans les options." >&2
  echo "  Un proxy sans authentification sur le mesh est un relais ouvert pour" >&2
  echo "  tout ce qui y entre. Poser 'mot_de_passe' dans la configuration." >&2
  exit 1
}

# L'ADRESSE SUIT LE MESH, ELLE NE SE SAISIT PAS
#
# Un pair prend une adresse neuve en changeant de compte NetBird — l'hôte du
# studio l'a appris le 08/09/2026. Une adresse écrite dans les options serait
# donc juste jusqu'au jour où elle ne l'est plus, et le proxy refuserait de se
# lier sans dire pourquoi.
adresse="$(ip -4 -o addr show "$interface" 2>/dev/null | awk '{print $4}' | cut -d/ -f1 | head -1)"
[ -n "$adresse" ] || {
  echo "aliud-sortie: pas d'adresse sur l'interface '$interface'." >&2
  echo "  L'add-on NetBird doit tourner et être connecté : c'est lui qui pose" >&2
  echo "  cette interface dans l'espace réseau de l'hôte." >&2
  exit 1
}

# La liste blanche. `FilterDefaultDeny` inverse le sens du fichier : ce qui n'y
# est pas est refusé, au lieu d'être autorisé.
jq -r '.domaines[]' "$OPTIONS" > /etc/tinyproxy/filtre
nb_domaines="$(wc -l < /etc/tinyproxy/filtre | tr -d ' ')"
[ "$nb_domaines" -gt 0 ] || {
  echo "aliud-sortie: liste blanche vide, donc rien ne passerait." >&2
  exit 1
}

cat > /etc/tinyproxy/tinyproxy.conf <<CONF
User tinyproxy
Group tinyproxy

# Une seule adresse d'écoute, celle du mesh : rien n'entre par le réseau local
# ni par la boucle locale.
Listen $adresse
Port $port
Timeout 600

# Deuxième verrou après la politique d'accès du mesh, qui est le premier.
BasicAuth $utilisateur $mot_de_passe

# Et troisième : les clients possibles sont dans la plage du mesh, jamais
# ailleurs. 100.64.0.0/10 est la plage que NetBird distribue.
Allow 100.64.0.0/10

# CE QUI SERAIT UN AVEU, ET QUI EST COUPÉ ICI
#
# tinyproxy ajoute par défaut un en-tête `Via: 1.1 tinyproxy` à chaque requête
# en clair, et `X-Tinyproxy` peut y joindre l'adresse du client. Les deux
# annoncent au média qu'il parle à un intermédiaire — exactement le signal que
# ce montage existe pour ne pas donner. En HTTPS la question ne se pose pas, le
# CONNECT étant un tunnel, mais un seul appel en clair suffirait à le dire.
DisableViaHeader Yes
XTinyproxy Off

# Aucun cache, aucune réécriture : un relevé daté doit être ce que le média a
# rendu à cet instant, pas ce qu'un intermédiaire avait gardé.
#
# Les ports où le tunnel est permis. 443 seulement : un CONNECT vers 22 ou 25
# ferait de cette ligne un relais pour autre chose que de la lecture.
ConnectPort 443

Filter "/etc/tinyproxy/filtre"
FilterDefaultDeny Yes
FilterCaseSensitive No
FilterURLs Off

LogLevel $journal
CONF

echo "aliud-sortie: $adresse:$port, $nb_domaines domaine(s) autorisé(s), journal $journal"
exec tinyproxy -d -c /etc/tinyproxy/tinyproxy.conf
