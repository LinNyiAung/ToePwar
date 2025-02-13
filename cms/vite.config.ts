import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

export default defineConfig({
  plugins: [react()],
  server: {
    proxy: {
      '/admin': 'http://localhost:800'  // Adjust to your FastAPI port
    }
  }
});