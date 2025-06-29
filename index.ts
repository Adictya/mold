import clay from "./clay.wasm";
import fs from "node:fs";

const clayWasmBuffer = fs.readFileSync(clay);
const { instance } = await WebAssembly.instantiate(
  clayWasmBuffer,
  // importObject,
);
