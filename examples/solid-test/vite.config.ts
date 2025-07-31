import { defineConfig } from "vite";
import solid from "vite-plugin-solid";

export default defineConfig({
  plugins: [
    solid({
      solid: {
        moduleName: "@mold/core",
        generate: "universal",
      },
    }),
  ],
});
