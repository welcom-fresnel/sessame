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
const OPENROUTER_MODEL = process.env.OPENROUTER_MODEL || 'deepseek/deepseek-v4-flash:free';
const GROQ_API_KEY = process.env.GROQ_API_KEY;
const GEMINI_API_KEY = process.env.GEMINI_API_KEY;
const GEMINI_MODEL = process.env.GEMINI_MODEL || 'gemini-1.5-flash-latest';
const GEMINI_API_VERSION = (process.env.GEMINI_API_VERSION || '').trim(); // e.g. v1 or v1beta
const GEMINI_MODELS_CACHE_TTL_MS = Number(process.env.GEMINI_MODELS_CACHE_TTL_MS || 10 * 60 * 1000); // 10 min
const GROQ_MODEL = process.env.GROQ_MODEL || 'llama-3.3-70versatitle';

let geminiModelsIndexCache = { fetchedAt: 0, index: [] };

function normalizeGeminiModelName(modelName) {
  if (!modelName) return modelName;
  return modelName.startsWith('models/') ? modelName.slice('models/'.length) : modelName;
}

function defaultGeminiApiVersion(modelName) {
  if (GEMINI_API_VERSION) return GEMINI_API_VERSION;
  // In practice, model aliases like `*-latest` are often exposed on `v1beta`.
  if ((modelName || '').endsWith('-latest')) return 'v1beta';
  return 'v1';
}

function isGeminiModelNotFoundError(error) {
  const status = error?.response?.status;
  return status === 404;
}

async function listGeminiModelsRaw(apiVersion) {
  const models = [];
  let pageToken = null;

  do {
    const url = new URL(`https://generativelanguage.googleapis.com/${apiVersion}/models`);
    url.searchParams.set('key', GEMINI_API_KEY);
    url.searchParams.set('pageSize', '100');
    if (pageToken) url.searchParams.set('pageToken', pageToken);

    const response = await axios.get(url.toString(), {
      headers: { 'Content-Type': 'application/json' },
    });

    if (Array.isArray(response?.data?.models)) models.push(...response.data.models);
    pageToken = response?.data?.nextPageToken || null;
  } while (pageToken);

  return models;
}

async function buildGeminiModelsIndex() {
  const [v1beta, v1] = await Promise.allSettled([
    listGeminiModelsRaw('v1beta'),
    listGeminiModelsRaw('v1'),
  ]);

  const index = [];
  if (v1beta.status === 'fulfilled') {
    for (const m of v1beta.value) index.push({ apiVersion: 'v1beta', model: m });
  }
  if (v1.status === 'fulfilled') {
    for (const m of v1.value) index.push({ apiVersion: 'v1', model: m });
  }

  // De-duplicate by apiVersion+name.
  const seen = new Set();
  const unique = [];
  for (const item of index) {
    const name = item?.model?.name;
    if (!name) continue;
    const key = `${item.apiVersion}:${name}`;
    if (seen.has(key)) continue;
    seen.add(key);
    unique.push(item);
  }

  return unique;
}

async function getGeminiModelsIndexCached() {
  const now = Date.now();
  const isFresh = now - geminiModelsIndexCache.fetchedAt < GEMINI_MODELS_CACHE_TTL_MS;
  if (isFresh && Array.isArray(geminiModelsIndexCache.index) && geminiModelsIndexCache.index.length > 0) {
    return geminiModelsIndexCache.index;
  }

  const index = await buildGeminiModelsIndex();
  geminiModelsIndexCache = { fetchedAt: now, index };
  return index;
}

function pickBestGeminiModel(index) {
  const supportsGenerateContent = (m) =>
    Array.isArray(m?.supportedGenerationMethods) &&
    m.supportedGenerationMethods.includes('generateContent');

  const candidates = (index || [])
    .map((i) => ({ apiVersion: i.apiVersion, model: i.model }))
    .filter((i) => supportsGenerateContent(i.model));
  if (candidates.length === 0) return null;

  const score = (fullName) => {
    const name = normalizeGeminiModelName(fullName || '').toLowerCase();
    if (name.includes('flash')) return 0;
    if (name.includes('lite')) return 1;
    return 2;
  };

  // Prefer v1beta when tied (usually exposes more/updated models).
  candidates.sort((a, b) => {
    const s = score(a.model?.name) - score(b.model?.name);
    if (s !== 0) return s;
    if (a.apiVersion === b.apiVersion) return 0;
    return a.apiVersion === 'v1beta' ? -1 : 1;
  });

  return candidates[0];
}

async function geminiGenerateContent({ apiVersion, modelName, apiKey, contents, generationConfig }) {
  return axios.post(
    `https://generativelanguage.googleapis.com/${apiVersion}/models/${modelName}:generateContent?key=${apiKey}`,
    { contents, generationConfig },
    {
      headers: {
        'Content-Type': 'application/json',
      },
    },
  );
}

async function callGeminiWithFallback({ messages, max_tokens, temperature }) {
  const normalizedModel = normalizeGeminiModelName(GEMINI_MODEL);
  const modelWithoutLatest = normalizedModel.replace(/-latest$/, '');
  const initialVersion = defaultGeminiApiVersion(normalizedModel);
  const alternateVersion = initialVersion === 'v1' ? 'v1beta' : 'v1';

  const attempts = [
    { apiVersion: initialVersion, modelName: normalizedModel },
    { apiVersion: initialVersion, modelName: modelWithoutLatest },
    { apiVersion: alternateVersion, modelName: normalizedModel },
    { apiVersion: alternateVersion, modelName: modelWithoutLatest },
  ].filter((a) => a.modelName && a.modelName.length > 0);

  // De-duplicate attempts while preserving order.
  const seen = new Set();
  const uniqueAttempts = attempts.filter((a) => {
    const key = `${a.apiVersion}:${a.modelName}`;
    if (seen.has(key)) return false;
    seen.add(key);
    return true;
  });

  const contents = messages.map((message) => ({
    parts: [{ text: message.content }],
    role: message.role === 'assistant' ? 'model' : 'user',
  }));

  const generationConfig = {
    temperature: temperature,
    maxOutputTokens: Math.min(max_tokens, 2048),
  };

  let lastError = null;
  const attemptedModels = [];
  for (const attempt of uniqueAttempts) {
    try {
      attemptedModels.push(`${attempt.apiVersion}:${attempt.modelName}`);
      if (uniqueAttempts.length > 1) {
        console.log(`Gemini: trying ${attempt.apiVersion} / ${attempt.modelName}`);
      }
      return await geminiGenerateContent({
        apiVersion: attempt.apiVersion,
        modelName: attempt.modelName,
        apiKey: GEMINI_API_KEY,
        contents,
        generationConfig,
      });
    } catch (err) {
      lastError = err;
      if (!isGeminiModelNotFoundError(err)) throw err;
    }
  }

  // If all attempts are 404, query ListModels with the same API key and retry once
  // using the first generateContent-capable "flash" model (or a reasonable fallback).
  try {
    const index = await getGeminiModelsIndexCached();
    const best = pickBestGeminiModel(index);
    const bestName = normalizeGeminiModelName(best?.model?.name || '');
    if (best && bestName) {
      attemptedModels.push(`${best.apiVersion}:${bestName}`);
      console.log(`Gemini: auto-selected ${best.apiVersion} / ${bestName}`);
      return await geminiGenerateContent({
        apiVersion: best.apiVersion,
        modelName: bestName,
        apiKey: GEMINI_API_KEY,
        contents,
        generationConfig,
      });
    }
  } catch (err) {
    lastError = err;
    console.error('Gemini: auto-selected model failed:', err.response?.data || err.message);
  }

  if (lastError && attemptedModels.length > 0) {
    lastError.geminiAttempts = attemptedModels;
  }
  throw lastError;
}

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

app.get('/api/ads/home-summary', async (req, res) => {
  const fallbackAd = {
    id: 'premium-productivity',
    title: 'Passe au niveau supérieur',
    message: 'Débloque les statistiques avancées, les exports et les modèles Premium.',
    ctaLabel: 'Voir Premium',
    ctaUrl: 'sesame://premium',
    type: 'text',
    imageUrl: null,
    accentColorHex: '#FFD740',
    active: true,
  };

  try {
    const db = getFirestoreDb();
    if (!db) return res.json({ ad: fallbackAd, ads: [fallbackAd], source: 'fallback' });

    const snap = await db
      .collection('ads')
      .where('placement', '==', 'home_summary')
      .where('active', '==', true)
      .orderBy('priority', 'desc')
      .limit(10)
      .get();

    if (snap.empty) return res.json({ ad: fallbackAd, ads: [fallbackAd], source: 'fallback' });

    const ads = snap.docs.map((doc) => {
      const data = doc.data();
      return {
        id: doc.id,
        title: data.title || fallbackAd.title,
        message: data.message || fallbackAd.message,
        ctaLabel: data.ctaLabel || fallbackAd.ctaLabel,
        ctaUrl: data.ctaUrl || fallbackAd.ctaUrl,
        type: data.type === 'image' ? 'image' : 'text',
        imageUrl: data.imageUrl || null,
        accentColorHex: data.accentColorHex || fallbackAd.accentColorHex,
        active: data.active === true,
      };
    });

    res.json({
      ad: ads[0] || fallbackAd,
      ads: ads.length > 0 ? ads : [fallbackAd],
      source: 'firestore',
    });
  } catch (error) {
    console.error('Ads endpoint error:', error.message);
    res.json({ ad: fallbackAd, ads: [fallbackAd], source: 'fallback_error' });
  }
});

// Debug: lists Gemini models visible to the current GEMINI_API_KEY.
app.get('/api/gemini/models', async (req, res) => {
  try {
    if (!GEMINI_API_KEY) return res.status(500).json({ error: 'GEMINI_API_KEY not configured on server' });

    const apiVersion = (req.query.apiVersion || '').toString().trim();
    if (apiVersion) {
      const models = await listGeminiModelsRaw(apiVersion);
      return res.json({ apiVersion, count: models.length, models });
    }

    const index = await getGeminiModelsIndexCached();
    const simplified = index.map((i) => ({
      apiVersion: i.apiVersion,
      name: i.model?.name,
      displayName: i.model?.displayName,
      supportedGenerationMethods: i.model?.supportedGenerationMethods,
      inputTokenLimit: i.model?.inputTokenLimit,
      outputTokenLimit: i.model?.outputTokenLimit,
    }));

    res.json({ apiVersion: 'v1beta+v1', count: simplified.length, models: simplified });
  } catch (error) {
    res.status(error.response?.status || 500).json({
      error: error.response?.data?.error?.message || error.message,
      details: error.response?.data || null,
    });
  }
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
    const defaultModel = AI_PROVIDER === 'openrouter' ? OPENROUTER_MODEL : GROQ_MODEL;
    const { messages, model = defaultModel, max_tokens = 10000, temperature = 0.7 } = req.body;

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

    const provider =
      AI_PROVIDER === 'gemini' || AI_PROVIDER === 'google_gemini'
        ? 'gemini'
        : AI_PROVIDER === 'groq'
          ? 'groq'
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

    if (provider === 'groq' && !GROQ_API_KEY) {
      await logAiRequest({
        status: 'error',
        errorMessage: 'GROQ_API_KEY not configured on server',
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
      return res.status(500).json({ error: 'GROQ_API_KEY not configured on server' });
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

    const response =
      provider === 'gemini'
        ? await callGeminiWithFallback({ messages, max_tokens, temperature })
        : provider === 'groq'
          ? await axios.post(
              'https://api.groq.com/openai/v1/chat/completions',
              {
                model,
                messages,
                max_tokens,
                temperature,
              },
              {
                headers: {
                  Authorization: `Bearer ${GROQ_API_KEY}`,
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
