import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'


export default defineConfig({
  base: './', // 🔥 IMPORTANT pour FiveM NUI
  plugins: [react()],
  server: {
    // En dev, Vite sert automatiquement /public
    // Les images sont dans web/public/mp_m_freemode_01/... et mp_f_freemode_01/...
  },
  build: {
    // Copier les dossiers d'images dans le build final
    rollupOptions: {
      output: {
        assetFileNames: 'assets/[name][extname]',
      },
    },
  },
})
