/* @refresh reload */
import Mold, { createElement, render, initialize } from "@mold/core";
import App from "./src/App.tsx";

initialize();

const root = createElement("root");

render(() => <App />, root);
