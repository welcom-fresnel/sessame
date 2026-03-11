# ðŸš€ DÃ©ploiement sur Railway

Railway est une plateforme simple pour dÃ©ployer ton backend Node.js gratuitement.

## Ã‰tapes de dÃ©ploiement

### 1ï¸âƒ£ CrÃ©e un compte Railway
- Va sur [railway.app](https://railway.app)
- Clique "Sign Up"
- Connecte-toi avec GitHub (recommandÃ©)

### 2ï¸âƒ£ PrÃ©pare le dÃ©pÃ´t Git
```bash
# Si tu n'as pas encore initialisÃ© Git Ã  la racine
git init
git add .
git commit -m "Initial commit"

# Pousse sur GitHub
git remote add origin https://github.com/tonusername/sessame.git
git branch -M main
git push -u origin main
```

### 3ï¸âƒ£ DÃ©ploie sur Railway
1. Va sur [railway.app/dashboard](https://railway.app/dashboard)
2. Clique "New Project" â†’ "Deploy from GitHub"
3. SÃ©lectionne le repo `sessame`
4. Railway va scanner et crÃ©er un service automatiquement

**NOTE:** Le fichier `Procfile` Ã  la racine et le `package.json` Ã  la racine permettent Ã  Railway de dÃ©tecter Node et lancer le backend dans `backend`.

### 4ï¸âƒ£ Ajoute les variables d'environnement
1. Dans le dashboard Railroad, va Ã  ton projet
2. Clique sur "Variables"
3. Ajoute une nouvelle variable:
   - **Key**: `OPENROUTER_API_KEY`
   - **Value**: `sk-or-v1-xxxxxxxxxxxxx` (ta vraie clÃ©)

### 5ï¸âƒ£ RÃ©cupÃ¨re l'URL du backend
- Une fois dÃ©ployÃ©, Railroad te donne une URL comme: `https://sessame-production.up.railway.app`
- **Note cette URL**, tu en auras besoin pour l'app Flutter

### 6ï¸âƒ£ Teste ton backend
```bash
curl https://sessame-production.up.railway.app/health
```

Tu devrais voir:
```json
{"status":"ok","message":"Server is running"}
```

## ðŸ” SÃ©curitÃ©

âœ… **Ta clÃ© API est maintenant sÃ©curisÃ©e:**
- Elle n'est jamais dans le code
- Elle n'est jamais dans Git
- Elle est stockÃ©e de faÃ§on sÃ©curisÃ©e sur Railroad

âœ… **Ã€ supprimer:**
- Ancien `.env` local avec la clÃ© exposÃ©e
- La clÃ© ancienne sur OpenRouter (tu l'as dÃ©jÃ  rÃ©gÃ©nÃ©rÃ©e)

## ðŸ› ï¸ RedÃ©ploiement

Chaque push sur `main` rÃ©utilise automatiquement le dÃ©ploiement. Si tu modifies `server.js`:

```bash
git add backend/server.js
git commit -m "Update backend"
git push
```

Railroad redÃ©ploiera automatiquement en quelques secondes.

## â“ DÃ©pannage

**Le dÃ©ploiement Ã©choue?**
- VÃ©rifie que `Procfile` et `package.json` existent Ã  la racine
- VÃ©rifie que `package.json` existe dans `backend/`
- Regarde les logs dans le dashboard

**La variable d'environnement n'est pas reconnue?**
- RedÃ©ploie aprÃ¨s avoir ajoutÃ© la variable
- Attends 30 secondes que les changements se propagent

**l'API rÃ©pond "API_KEY not configured"?**
- VÃ©rifie que la variable `OPENROUTER_API_KEY` est bien ajoutÃ©e
- La clÃ© doit commencer par `sk-or-v1-`

## ðŸ“Š Monitoring

Dans le Dashboard Railroad:
- Vois les logs en temps rÃ©el
- Vois la CPU et la RAM utilisÃ©es
- Vois l'historique des dÃ©ploiements


