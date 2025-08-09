import { createServer } from "vite";
import {
  createHotContext,
  viteNodeHmrPlugin,
  handleMessage,
} from "vite-node/hmr";
import { ViteNodeRunner } from "vite-node/client";
import { ViteNodeServer } from "vite-node/server";
import { installSourcemapsSupport } from "vite-node/source-map";

const files: [string] = ["./index.tsx"];

const server = await createServer({
  ssr: {
    noExternal: true,
  },
  plugins: [viteNodeHmrPlugin()],
});

await server.environments.client.pluginContainer.buildStart({});

const node = new ViteNodeServer(server);

const runner = new ViteNodeRunner({
  root: server.config.root,
  base: server.config.base,
  createHotContext(runner, url) {
    return createHotContext(runner, server.emitter, files, url);
  },
  fetchModule(id) {
    return node.fetchModule(id, "web");
  },
  resolveId(id, importer) {
    return node.resolveId(id, importer, "web");
  },
  debug: true,
});

await runner.executeId("/@vite/env");

// execute the file
await runner.executeFile(files[0]);

const transformPath = (fromPath, dirname) => {
  if (fromPath.startsWith("/@fs/")) {
    return fromPath.substring(4);
  } else if (fromPath.startsWith("/src/")) {
    const projectRoot = dirname.replace(/\/scripts$/, "");
    return `${projectRoot}${fromPath}`;
  }
  return fromPath;
};

server.emitter?.on("message", async (payload) => {
  switch (payload.type) {
    case "update":
      payload.updates.forEach((update) => {
        if (update.type === "js-update") {
          update.path = transformPath(update.path, __dirname);
          update.acceptedPath = transformPath(update.acceptedPath, __dirname);
        }
      });
  }
  handleMessage(runner, server.emitter, files, payload);
});

// close the vite server
// await server.close();
