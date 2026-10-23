import { defineConfig } from "vite";

export default defineConfig({
  // Rutas relativas: funciona igual en localhost que en GitHub Pages.
  base: "./",
  server: {
    port: 5173,
  },
  build: {
    outDir: "dist",
  },
});
