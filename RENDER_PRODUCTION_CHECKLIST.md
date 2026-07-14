# Render Production Checklist — Asala

Ce document résume ce qu’il faut faire pour passer l’application en production sur Render, avec Firebase et les variables d’environnement.

## 1. Avant le déploiement

### 1.1 Vérifier le repo
S’assurer que le dépôt GitHub contient bien :
- Dockerfile
- nginx.conf.template
- render.yaml
- web/firebase_config.json
- build/web généré via Flutter

### 1.2 Vérifier la config Firebase Web
Le fichier suivant doit contenir la configuration Firebase web correcte :
- web/firebase_config.json

Contenu attendu :
- apiKey
- authDomain
- projectId
- storageBucket
- messagingSenderId
- appId
- measurementId

> Ce fichier est utilisé par l’application web au démarrage.

## 2. Configurer Firebase Console

### 2.1 Activer les services utiles
Vérifier que les services suivants sont activés dans Firebase Console :
- Authentication
- Firestore Database
- Storage (si utilisé)
- Analytics (si utilisé)

### 2.2 Ajouter les domaines autorisés
Dans Authentication > Settings > Authorized domains, ajouter :
- localhost
- le domaine Render de votre service
- éventuellement votre domaine personnalisé si vous en avez un

Exemple :
- localhost
- asala-web.onrender.com

### 2.3 Vérifier les règles Firestore
Si l’app utilise Firestore, vérifier que les règles sont correctes pour la production.

Exemple de logique à respecter :
- utilisateur connecté uniquement
- lecture/écriture autorisée seulement si nécessaire
- éviter l’accès public non contrôlé

## 3. Variables d’environnement Render

### 3.1 Variables obligatoires
Ajouter cette variable dans Render :
- PORT = 10000

### 3.2 Variables Firebase (optionnelles si vous souhaitez remplacer le fichier JSON)
Si vous voulez rendre la configuration Firebase plus propre, vous pouvez aussi définir ces variables dans Render au lieu d’utiliser web/firebase_config.json :
- FIREBASE_API_KEY
- FIREBASE_AUTH_DOMAIN
- FIREBASE_PROJECT_ID
- FIREBASE_STORAGE_BUCKET
- FIREBASE_MESSAGING_SENDER_ID
- FIREBASE_APP_ID
- FIREBASE_MEASUREMENT_ID

> Pour l’instant, le projet fonctionne avec web/firebase_config.json. Les variables ne sont pas strictement nécessaires pour un premier déploiement.

## 4. Déployer sur Render

### 4.1 Créer un service Web
Dans Render :
1. Cliquer sur New +
2. Choisir Web Service
3. Sélectionner le dépôt GitHub
4. Choisir la branche à déployer
5. Définir le runtime comme Docker
6. Cliquer sur Create Web Service

### 4.2 Vérifier la configuration
Vérifier que Render utilise bien :
- Dockerfile
- render.yaml si vous voulez garder la config de service

### 4.3 Déployer
Attendre la fin du build et du deploy.

## 5. Vérifications post-déploiement

### 5.1 Vérifier l’URL Render
Ouvrir l’URL fournie par Render et vérifier que :
- la page se charge
- le splash screen s’affiche
- l’application n’affiche pas d’erreur de chargement d’assets

### 5.2 Vérifier Firebase
Tester les points suivants :
- ouverture de l’application
- connexion / inscription
- lecture/écriture Firestore
- Google Sign-In si activé

### 5.3 Vérifier les erreurs réseau
Si l’application ne charge pas correctement :
- vérifier la console navigateur
- vérifier les logs Render
- vérifier que Firebase Console accepte bien le domaine Render

## 6. Checklist finale

- [ ] Repo GitHub à jour
- [ ] Dockerfile présent
- [ ] nginx.conf.template présent
- [ ] render.yaml présent
- [ ] web/firebase_config.json correct
- [ ] Firebase services activés
- [ ] Domaines autorisés dans Firebase
- [ ] Variable PORT = 10000 définie dans Render
- [ ] Service Render déployé avec succès
- [ ] Application accessible sur l’URL Render
- [ ] Auth/Firestore testés en production

## 7. En cas de problème

### Erreur : le conteneur ne démarre pas
Vérifier :
- PORT défini correctement
- Dockerfile correct
- nginx.conf.template valide

### Erreur : l’application se charge mais Firebase échoue
Vérifier :
- authDomain correct
- projectId correct
- domaines autorisés dans Firebase

### Erreur : Firestore refusé
Vérifier :
- règles Firestore
- utilisateur connecté
- domaine autorisé
