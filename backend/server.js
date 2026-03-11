import express from 'express';
import axios from 'axios';
import cors from 'cors';
import dotenv from 'dotenv';

dotenv.config();

const app = express();
const PORT = process.env.PORT || 3000;
const HOST = '0.0.0.0';

// Middleware
app.use(express.json());
app.use(cors());

// Route de santé (pour vérifier que le serveur fonctionne)
app.get('/health', (req, res) => {
  res.json({ status: 'ok', message: 'Server is running' });
});

// Route principale pour appeller OpenRouter
app.post('/api/openrouter', async (req, res) => {
  try {
    const { messages, model = 'openai/stepfun/step-3.5-flash:free', max_tokens = 10000, temperature = 0.7 } = req.body;

    // Valide l'input
    if (!messages || !Array.isArray(messages)) {
      return res.status(400).json({ error: 'messages must be an array' });
    }

    if (!process.env.OPENROUTER_API_KEY) {
      return res.status(500).json({ error: 'API_KEY not configured on server' });
    }

    // Appelle OpenRouter
    const response = await axios.post(
      'https://openrouter.ai/api/v1/chat/completions',
      {
        model,
        messages,
        max_tokens,
        temperature
      },
      {
        headers: {
          'Authorization': `Bearer ${process.env.OPENROUTER_API_KEY}`,
          'HTTP-Referer': 'https://github.com/welcom-fresnel/sessame.git',
          'X-Title': 'Sessame',
          'Content-Type': 'application/json'
        }
      }
    );

    // Retourne la réponse
    res.json(response.data);
  } catch (error) {
    console.error('OpenRouter API Error:', error.response?.data || error.message);
    
    const status = error.response?.status || 500;
    const errorMessage = error.response?.data?.error?.message || error.message;
    
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
