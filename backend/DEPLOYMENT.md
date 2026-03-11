# 🚀 Déploiement sur Railway

Railway est une plateforme simple pour déployer ton backend Node.js gratuitement.

## Étapes de déploiement

### 1️⃣ Crée un compte Railway
- Va sur [railway.app](https://railway.app)
- Clique "Sign Up"
- Connecte-toi avec GitHub (recommandé)

### 2️⃣ Prépare le dépôt Git
```bash
# Si tu n'as pas encore initialisé Git à la racine
git init
git add .
git commit -m "Initial commit"

# Pousse sur GitHub
git remote add origin https://github.com/tonusername/sessame.git
git branch -M main
git push -u origin main
```

### 3️⃣ Déploie sur Railway
1. Va sur [railway.app/dashboard](https://railway.app/dashboard)
2. Clique "New Project" → "Deploy from GitHub"
3. Sélectionne le repo `sessame`
4. Railway va scanner et créer un service automatiquement

**NOTE:** Le fichier `Procfile` à la racine indique à Railway comment lancer le backend dans `backend`.

### 4️⃣ Ajoute les variables d'environnement
1. Dans le dashboard Railroad, va à ton projet
2. Clique sur "Variables"
3. Ajoute une nouvelle variable:
   - **Key**: `OPENROUTER_API_KEY`
   - **Value**: `sk-or-v1-xxxxxxxxxxxxx` (ta vraie clé)

### 5️⃣ Récupère l'URL du backend
- Une fois déployé, Railroad te donne une URL comme: `https://sessame-production.up.railway.app`
- **Note cette URL**, tu en auras besoin pour l'app Flutter

### 6️⃣ Teste ton backend
```bash
curl https://sessame-production.up.railway.app/health
```

Tu devrais voir:
```json
{"status":"ok","message":"Server is running"}
```

## 🔐 Sécurité

✅ **Ta clé API est maintenant sécurisée:**
- Elle n'est jamais dans le code
- Elle n'est jamais dans Git
- Elle est stockée de façon sécurisée sur Railroad

✅ **À supprimer:**
- Ancien `.env` local avec la clé exposée
- La clé ancienne sur OpenRouter (tu l'as déjà régénérée)

## 🛠️ Redéploiement

Chaque push sur `main` réutilise automatiquement le déploiement. Si tu modifies `server.js`:

```bash
git add backend/server.js
git commit -m "Update backend"
git push
```

Railroad redéploiera automatiquement en quelques secondes.

## ❓ Dépannage

**Le déploiement échoue?**
- Vérifie que `Procfile` existe à la racine
- Vérifie que `package.json` existe dans `backend/`
- Regarde les logs dans le dashboard

**La variable d'environnement n'est pas reconnue?**
- Redéploie après avoir ajouté la variable
- Attends 30 secondes que les changements se propagent

**l'API répond "API_KEY not configured"?**
- Vérifie que la variable `OPENROUTER_API_KEY` est bien ajoutée
- La clé doit commencer par `sk-or-v1-`

## 📊 Monitoring

Dans le Dashboard Railroad:
- Vois les logs en temps réel
- Vois la CPU et la RAM utilisées
- Vois l'historique des déploiements

