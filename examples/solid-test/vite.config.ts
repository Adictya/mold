import { defineConfig } from "vite";
import solid from "vite-plugin-solid";

export default defineConfig({
  clearScreen: false,
  logLevel: "silent",
  server: {
    hmr: true,
  },
  plugins: [
    solid({
      solid: {
        moduleName: "@mold/core",
        generate: "universal",
      },
    }),
  ],
});
