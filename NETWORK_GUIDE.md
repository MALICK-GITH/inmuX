# sniX Network — Mode d'emploi

## 1. Présentation

**sniX Network** est une console interactive de diagnostic réseau destinée aux tests autorisés. Elle permet d'inspecter des connexions TLS/SNI et de conserver les résultats dans une session.

> Utilisez l'outil uniquement sur des systèmes, domaines, IP et réseaux pour lesquels vous avez une autorisation.

## 2. Installation / mise à jour

Depuis Termux :

```bash
cd ~/inmuX
git pull origin main
```

Le module sniX utilise uniquement la bibliothèque standard Python. Il n'est donc pas nécessaire de faire `pip install sniX`.

## 3. Lancement

```bash
cd ~/inmuX
python3 network/interactive.py
```

Vous obtenez le menu principal :

```text
[1] SNI / TLS Discovery
[2] Current Results
[3] Export JSON Report
[4] Clear Session
[5] Guide / Toutes les fonctionnalités
[0] Exit
```

## 4. Fonction 1 — SNI / TLS Discovery

Cette fonction analyse les cibles saisies et tente une connexion TLS sur les ports demandés.

### Cibles acceptées

- nom de domaine : `example.com`
- adresse IP : `203.0.113.10`
- plusieurs cibles séparées par des virgules : `example.com,example.net`
- réseau CIDR pour une découverte bornée : `192.168.1.0/24`

La découverte CIDR est volontairement limitée à **256 adresses maximum**.

### Ports

Vous pouvez saisir plusieurs ports :

```text
443,8443
```

ou une plage :

```text
443,8000-8010
```

Les ports valides sont compris entre 1 et 65535.

### Timeout

Le timeout définit le temps maximum d'attente d'une tentative de connexion.

Exemple :

```text
Timeout seconds [3]: 5
```

### Workers

Les workers permettent de traiter plusieurs sondes en parallèle.

Exemple :

```text
Workers [12]: 20
```

La limite maximale est de 32 workers.

## 5. Informations récupérées

Pour chaque cible/port accessible, sniX peut afficher :

- état de la connexion
- adresse IP résolue
- reverse DNS lorsqu'il est disponible
- version TLS négociée
- chiffrement/cipher négocié
- ALPN (`h2`, `http/1.1`, etc.)
- Common Name (CN) du certificat
- Subject Alternative Names (SAN)
- émetteur du certificat
- début de validité du certificat
- fin de validité du certificat
- erreur détaillée lorsqu'une sonde échoue

## 6. Fonction 2 — Current Results

Affiche les résultats conservés pendant la session courante.

Le résumé indique le nombre de sondes réussies par rapport au nombre total.

Les résultats détaillés peuvent ensuite être exportés.

## 7. Fonction 3 — Export JSON Report

Permet d'enregistrer les résultats dans un fichier JSON.

Nom par défaut :

```text
snix-report.json
```

Exemple :

```text
Report filename [snix-report.json]: rapport.json
```

Le rapport contient notamment :

```json
{
  "tool": "sniX",
  "version": "1.2.0",
  "results": []
}
```

## 8. Fonction 4 — Clear Session

Efface les résultats actuellement conservés en mémoire par la console.

Cela ne supprime pas les fichiers JSON déjà exportés.

## 9. Fonction 5 — Guide

Affiche directement dans Termux un résumé du fonctionnement, des paramètres, des informations collectées et des limites de sniX Network.

## 10. Fonction 0 — Exit

Ferme proprement la console.

Les commandes suivantes permettent également de quitter :

```text
0
q
quit
exit
```

## 11. Exemple complet

Lancez :

```bash
python3 network/interactive.py
```

Choisissez `1`, puis par exemple :

```text
Target(s), comma separated: example.com
TLS ports [443,8443]: 443,8443
Timeout seconds [3]: 3
Workers [12]: 12
```

sniX lance alors les sondes et affiche les résultats au fur et à mesure.

## 12. Utilisation recommandée

Pour un diagnostic simple :

```text
1 → cible → 443 → timeout 3 → workers 12
```

Pour plusieurs services TLS :

```text
1 → cible → 443,8443 → timeout 3 → workers 12
```

Pour analyser un petit réseau que vous contrôlez :

```text
1 → réseau CIDR autorisé → ports nécessaires → paramètres raisonnables
```

Puis utilisez `2` pour consulter les résultats et `3` pour les sauvegarder.

## 13. Dépannage

### `ModuleNotFoundError: No module named 'sniX'`

Ne faites pas `pip install sniX`.

Mettez le dépôt à jour :

```bash
cd ~/inmuX
git pull origin main
```

Puis relancez :

```bash
python3 network/interactive.py
```

### Permission ou problème Python

Vérifiez :

```bash
python3 --version
git --version
```

### Vérifier les fichiers

```bash
ls -la network
```

Vous devez notamment trouver :

```text
network/
├── __init__.py
├── interactive.py
└── sniX.py
```

## 14. Limites de sécurité

sniX Network est conçu pour le diagnostic et la visibilité réseau autorisés. Il ne fournit pas de fonctions d'exploitation, de vol d'identifiants, de contournement de sécurité, de furtivité ou de balayage Internet sans limite.

Les limites de CIDR et de concurrence sont intentionnelles afin de garder l'outil adapté à des diagnostics contrôlés.

## 15. Structure du projet

```text
inmuX/
└── network/
    ├── __init__.py
    ├── interactive.py
    └── sniX.py
```

`interactive.py` fournit l'interface interactive.

`sniX.py` contient le moteur de diagnostic TLS/SNI.

`__init__.py` identifie le dossier comme module Python.

## 16. Résumé rapide

| Fonction | Utilité |
|---|---|
| SNI/TLS Discovery | Tester les connexions TLS autorisées |
| Domaines/IP | Analyser des cibles individuelles |
| CIDR borné | Découverte d'un petit réseau autorisé |
| Ports | Tester plusieurs ports ou plages |
| Workers | Accélérer les sondes concurrentes |
| Timeout | Contrôler l'attente par connexion |
| Certificat | Lire CN, SAN, issuer et validité |
| TLS | Identifier version et cipher |
| ALPN | Identifier le protocole négocié |
| Reverse DNS | Rechercher le nom associé à l'IP |
| Results | Consulter la session |
| JSON | Sauvegarder les résultats |
| Guide | Afficher le mode d'emploi |
| Clear | Réinitialiser la session |
