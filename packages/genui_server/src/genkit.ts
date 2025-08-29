import { genkit, z } from 'genkit';
import { googleAI } from '@genkit-ai/googleai';
import { initializeApp } from 'firebase-admin/app';

// Initialize Firebase Admin SDK
initializeApp({
  projectId: 'fluttergenui',
});

export { z };

export const ai = genkit({
  plugins: [googleAI()],
  model: 'googleai/gemini-1.5-flash',
});
