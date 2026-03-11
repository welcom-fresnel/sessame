# 🚀 Sessame Backend

Backend Node.js qui gère l'accès sécurisé à l'API OpenRouter.

## 📋 Fonctionnement

- ✅ Gère la clé API OpenRouter de façon sécurisée
- ✅ Expose un endpoint `/api/openrouter` pour l'app Flutter
- ✅ Validation et gestion d'erreurs
- ✅ CORS activé pour l'app Flutter

## 🛠️ Installation locale

```bash
# 1. Va dans le dossier backend
cd backend

# 2. Installe les dépendances
npm install

# 3. Crée un fichier .env
cp .env.example .env

# 4. Ajoute ta clé API dans .env
# OPENROUTER_API_KEY=sk-or-v1-xxxxx...

# 5. Lance le serveur
npm run dev
```

Le serveur sera disponible à http://localhost:3000

## 📡 Endpoints

### POST `/api/openrouter`

Appelle l'API OpenRouter avec le message utilisateur.

**Request:**
```json
{
  "messages": [
    {"role": "user", "content": "Hello!"}
  ],
  "model": "openai/gpt-oss-120b:free",
  "max_tokens": 800,
  "temperature": 0.7
}
```

**Response:**
```json
{
  "choices": [
    {
      "message": {
        "content": "Hello! How can I help you?"
      }
    }
  ]
}
```

### GET `/health`

Vérifie que le serveur fonctionne.

**Response:**
```json
{
  "status": "ok",
  "message": "Server is running"
}
```

## 🚀 Déploiement sur Railway

Voir le guide de déploiement dans le fichier `DEPLOYMENT.md`

## 📝 Notes

- Ne partage JAMAIS ta clé API (elle ne doit être que sur le serveur)
- `.env` est inclus dans `.gitignore` pour éviter les expositions accidentelles
- Le backend doit être en HTTPS en production (Railway le gère automatiquement)
