import express from 'express';
import axios from 'axios';
import cors from 'cors';
import dotenv from 'dotenv';
import { initializeApp, cert } from 'firebase-admin/app';
import { getFirestore, FieldValue } from 'firebase-admin/firestore';

dotenv.config();

const app = express();
const PORT = process.env.PORT || 3000;
const HOST = '0.0.0.0';
const AI_PROVIDER = (process.env.AI_PROVIDER || 'openrouter').toLowerCase();
const OPENROUTER_API_KEY = process.env.OPENROUTER_API_KEY;
const GEMINI_API_KEY = process.env.GEMINI_API_KEY;
const GEMINI_MODEL = process.env.GEMINI_MODEL || 'models/gemini-1.5-flash';

let firestore = null;
let firestoreInitErrorLogged = false;
let firestoreMissingLogged = false;
let firestoreReadyLogged = false;
let firestoreUnavailableLogged = false;

function getFirestoreDb() {
  if (firestore) return firestore;

  const serviceAccountJson = process.env.FIREBASE_SERVICE_ACCOUNT_JSON;  if (!serviceAccountJson) {
    if (!firestoreMissingLogged) {
      console.warn('Firebase disabled: FIREBASE_SERVICE_ACCOUNT_JSON not set');
      firestoreMissingLogged = true;
    }
    return null;
  }

  let serviceAccount;
  try {
    serviceAccount = JSON.parse(serviceAccountJson);
  } catch (err) {
    if (!firestoreInitErrorLogged) {
      console.error('Firebase init error: invalid JSON in FIREBASE_SERVICE_ACCOUNT_JSON');
      firestoreInitErrorLogged = true;
    }
    return null;
  }

  try {
    const app = initializeApp({ credential: cert(serviceAccount) });
    firestore = getFirestore(app);
    if (!firestoreReadyLogged) {
      console.log('Firebase Firestore initialized');
      firestoreReadyLogged = true;
    }
    return firestore;
  } catch (err) {
    if (!firestoreInitErrorLogged) {
      console.error('Firebase init error:', err.message);
      firestoreInitErrorLogged = true;
    }
    return null;
  }
}

async function logAiRequest(payload) {
  const db = getFirestoreDb();
  if (!db) {
    if (!firestoreUnavailableLogged) {
      console.warn('Firebase logging skipped: Firestore not initialized');
      firestoreUnavailableLogged = true;
    }
    return;
  }

  try {
    await db.collection('ai_requests').add({
      ...payload,
      createdAt: FieldValue.serverTimestamp(),
    });
  } catch (err) {
    console.error('Firebase log error:', err.message);
  }
}

// Middleware
app.use(express.json());
app.use(cors());

// Route de santé (pour vérifier que le serveur fonctionne)
app.get('/health', (req, res) => {
  res.json({ status: 'ok', message: 'Server is running' });
});

// Route principale pour appeller OpenRouter
app.post('/api/openrouter', async (req, res) => {
  const startedAt = Date.now();
  const ip =
    (req.headers['x-forwarded-for'] || '').toString().split(',')[0].trim() ||
    req.ip ||
    null;
  const userAgent = req.get('user-agent') || null;
  const clientId = req.get('x-client-id') || req.body?.client_id || null;
  const clientProfile = req.body?.client_profile || null;

  try {
    const { messages, model = 'openai/stepfun/step-3.5-flash:free', max_tokens = 10000, temperature = 0.7 } = req.body;

    // Valide l'input
    if (!messages || !Array.isArray(messages)) {
      await logAiRequest({
        status: 'error',
        errorMessage: 'messages must be an array',
        model,
        max_tokens,
        temperature,
        clientProfile,
        clientId,
        ip,
        userAgent,
        latencyMs: Date.now() - startedAt,
      });
      return res.status(400).json({ error: 'messages must be an array' });
    }

    const provider = AI_PROVIDER === 'gemini' || AI_PROVIDER === 'google_gemini'
      ? 'gemini'
      : 'openrouter';

    if (provider === 'openrouter' && !OPENROUTER_API_KEY) {
      await logAiRequest({
        status: 'error',
        errorMessage: 'OPENROUTER_API_KEY not configured on server',
        model,
        max_tokens,
        temperature,
        messages,
        clientProfile,
        clientId,
        ip,
        userAgent,
        latencyMs: Date.now() - startedAt,
      });
      return res.status(500).json({ error: 'OPENROUTER_API_KEY not configured on server' });
    }

    if (provider === 'gemini' && !GEMINI_API_KEY) {
      await logAiRequest({
        status: 'error',
        errorMessage: 'GEMINI_API_KEY not configured on server',
        model,
        max_tokens,
        temperature,
        messages,
        clientProfile,
        clientId,
        ip,
        userAgent,
        latencyMs: Date.now() - startedAt,
      });
      return res.status(500).json({ error: 'GEMINI_API_KEY not configured on server' });
    }

    const response = provider === 'gemini'
      ? await axios.post(
          `https://generativelanguage.googleapis.com/v1beta/models/${GEMINI_MODEL}:generateContent?key=${GEMINI_API_KEY}`,
          {
            contents: messages.map((message) => ({
              parts: [
                {
                  text: message.content,
                },
              ],
              role: message.role === 'assistant' ? 'model' : 'user',
            })),
            generationConfig: {
              temperature: temperature,
              maxOutputTokens: Math.min(max_tokens, 2048),
            },
          },
          {
            headers: {
              'Content-Type': 'application/json',
            },
          },
        )
      : await axios.post(
          'https://openrouter.ai/api/v1/chat/completions',
          {
            model,
            messages,
            max_tokens,
            temperature,
          },
          {
            headers: {
              'Authorization': `Bearer ${OPENROUTER_API_KEY}`,
              'HTTP-Referer': 'https://github.com/welcom-fresnel/sessame.git',
              'X-Title': 'Sessame',
              'Content-Type': 'application/json',
            },
          },
        );

    const responseData = response.data;
    let formattedResponse = responseData;

    if (provider === 'gemini') {
      const candidate = Array.isArray(responseData?.candidates)
        ? responseData.candidates[0]
        : null;
      let contentText = '';

      if (candidate != null && candidate.content && Array.isArray(candidate.content.parts)) {
        contentText = candidate.content.parts
            .map((part) => part.text || '')
            .join('\n');
      }

      formattedResponse = {
        choices: [
          {
            message: {
              content: contentText.length > 0 ? contentText : 'Réponse vide du modèle Gemini',
            },
          },
        ],
        raw: responseData,
      };
    }

    await logAiRequest({
      status: 'ok',
      model,
      max_tokens,
      temperature,
      messages,
      clientProfile,
      clientId,
      ip,
      userAgent,
      latencyMs: Date.now() - startedAt,
      usage: responseData?.usage || null,
    });

    res.json(formattedResponse);
  } catch (error) {
    console.error(`${AI_PROVIDER} API Error:`, error.response?.data || error.message);
    
    const status = error.response?.status || 500;
    const errorMessage = error.response?.data?.error?.message || error.message;
    
    await logAiRequest({
      status: 'error',
      errorMessage,
      model: req.body?.model,
      max_tokens: req.body?.max_tokens,
      temperature: req.body?.temperature,
      messages: req.body?.messages,
      clientProfile,
      clientId,
      ip,
      userAgent,
      latencyMs: Date.now() - startedAt,
      usage: error.response?.data?.usage || null,
    });
    
    res.status(status).json({ 
      error: errorMessage,
      details: error.response?.data 
    });
  }
});

// Gestion des routes non trouvées
app.use((req, res) => {
  res.status(404).json({ error: 'Route not found' });
});

// Démarre le serveur
app.listen(PORT, HOST, () => {
  console.log(`🚀 Server running on port ${PORT}`);
  console.log(`🌐 API endpoint: http://${HOST}:${PORT}/api/openrouter`);
  console.log(`📊 Health check: http://${HOST}:${PORT}/health`);
});

// Ping automatique toutes les 2 minutes pour garder Render éveillé
setInterval(async () => {
  try {
    await axios.get(`http://localhost:${PORT}/health`);
    console.log('🔄 Self-ping successful - keeping Render awake');
  } catch (err) {
    console.error('❌ Self-ping failed:', err.message);
  }
}, 2 * 60 * 1000); // 2 minutes


