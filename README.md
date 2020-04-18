# COVID-19

## Personnes décédées

Source : [INSEE](https://www.data.gouv.fr/fr/datasets/fichier-des-personnes-decedees)

### Script de téléchargement des fichiers raw

```shell script
./personnes_decedees/download_sources-deces.sh
```

### Format des fichiers raw

Le fichier est fourni au format txt

Sexe - Longueur : 1 - Position : 81 - Type : Numérique
1 = Masculin; 2 = féminin

Date de naissance - Longueur : 8 - Position : 82-89 - Type : Numérique
Forme : AAAAMMJJ - AAAA=0000 si année inconnue; MM=00 si mois inconnu; JJ=00 si jour inconnu

Date de décès - Longueur : 8 - Position : 155-162 - Type : Numérique
Forme : AAAAMMJJ - AAAA=0000 si année inconnue; MM=00 si mois inconnu; JJ=00 si jour inconnu

Code du lieu de décès - Longueur : 5 - Position : 163-167 - Type : Alphanumérique
Code Officiel Géographique en vigueur au moment de la prise en compte du décès

### Fichiers CSV

4 champs sont préservés :
- Sexe
- Date de naissance
- Date du décès
- Code département du décès

### Création de la base de données

```shell script
./personnes_decedees/populate_db.rb
```

### Database

Dans le fichier `annee/code_departement`, chaque ligne : `date_au_format_MMJJ;nb_deces`

## Population

### Database

Dans le fichier `annee.csv`, chaque ligne : `code_departement;nb_habitants`

## Data sources

Death data form INSEE (French Statistic Agency) : https://www.data.gouv.fr/fr/datasets/fichier-des-personnes-decedees/

Geography referential (commune and departement) : https://geo.api.gouv.fr

Population data time serie from INSEE : https://www.insee.fr/fr/statistiques/1893198

Population data time serie from INSEE - 2020-03-27 Weekly update for Covid : https://www.insee.fr/fr/information/4470857

Number of admissions in hospitals due to influanza 2010-2020 from Sante Publique France : (https://www.santepubliquefrance.fr/)

Nombre de personnes décédées par département - quotidiennement
https://www.data.gouv.fr/fr/datasets/nombre-de-deces-quotidiens-par-departement/
