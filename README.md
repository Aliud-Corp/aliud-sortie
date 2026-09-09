# aliud-sortie

Un add-on Home Assistant qui pose un proxy HTTP sur la ligne du domicile,
joignable seulement depuis le mesh du studio.

## Pourquoi

Les scripts du studio tournent sur un serveur d'hébergeur. Plusieurs médias
refusent une adresse de datacenter à la première requête, quel que soit le
rythme : ce n'est pas une limite de débit, c'est une porte. Le code et le
modèle restent donc là où ils sont, et seule la sortie réseau passe par la
maison.

Ce n'est pas un nœud de sortie. Une route par défaut ferait passer tout le
trafic de l'hôte — son inférence, sa supervision, ses sauvegardes — par une
ligne domestique. Un proxy nommé dans un script ne déplace que les requêtes qui
le nomment.

## Ce qu'il fait

- écoute sur l'adresse du mesh, lue sur l'interface NetBird à chaque démarrage,
  jamais saisie : un pair change d'adresse en changeant de compte ;
- exige un mot de passe, et refuse de démarrer sans ;
- n'autorise que les noms d'hôte d'une liste blanche, en refusant tout le
  reste ;
- n'autorise le tunnel HTTPS que vers 443 ;
- coupe les en-têtes `Via` et `X-Tinyproxy`, qui annonceraient l'intermédiaire
  au média ;
- ne met rien en cache : un relevé daté doit être ce que le média a rendu à cet
  instant.

## Installation

Ce dépôt est un dépôt d'add-ons. Dans Home Assistant : Paramètres → Modules →
boutique → menu → Dépôts, ajouter `https://github.com/Aliud-Corp/aliud-sortie`,
puis installer « Aliud Sortie ».

Il exige l'add-on NetBird, connecté : c'est lui qui pose l'interface du mesh
dans l'espace réseau de l'hôte.

## Configuration

| Option | Ce qu'elle décide |
|---|---|
| `port` | le port d'écoute, 8888 par défaut |
| `utilisateur`, `mot_de_passe` | l'authentification du proxy, obligatoire |
| `interface` | l'interface du mesh, `wt0` par défaut |
| `domaines` | la liste blanche, en expressions régulières de nom d'hôte |
| `journal` | le niveau de journal de tinyproxy |

Trois verrous, et non un : la politique d'accès du mesh, qui décide quel pair
atteint ce port ; le mot de passe ; la liste blanche des destinations. Le
premier tombe si quelqu'un ouvre le mesh, le deuxième si le mot de passe fuit,
le troisième tient quand même — une clé volée sur l'hôte ne fait pas de cette
ligne un relais ouvert.

## Ce qu'il ne résout pas

Une adresse résidentielle ne suffit pas à passer pour un navigateur. La
signature TLS d'un client Python est reconnaissable, et un tunnel ne la change
pas : elle est celle de la machine qui appelle. Le côté appelant a donc sa part
du travail — en-têtes cohérents, signature TLS imitée, rythme irrégulier — et
ce dépôt ne la fait pas à sa place.
