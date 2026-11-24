import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

// FiveM serves the UI from nui://kios/web/dist/, so every asset path must be relative.
export default defineConfig({
  plugins: [react()],
  base: './',
  build: {
    outDir: 'dist',
    emptyOutDir: true,
    assetsInlineLimit: 0,
    chunkSizeWarningLimit: 1000,
  },
});
