/* @refresh skip */
import { createRenderer } from "solid-js/universal";
import Core from "./core";
import { log as winstonLogger } from "./logging";

const log = winstonLogger.info;

log("Module re-initialized for some reason");

// --- HMR State Management (Global Approach) ---

type listener = (event: any) => void;

type RendererState = {
  listeners: listener[];
  onClickListeners: Record<string, () => void>;
  initialized: boolean;
};

// Use a unique symbol to avoid conflicts on the global object.
const MOLD_RENDERER_STATE_KEY = Symbol.for("MOLD_RENDERER_STATE");

// Attach a state manager to the global object.
// This ensures it's the same object across all HMR updates.
const getGlobalState = (): RendererState => {
  if (!globalThis[MOLD_RENDERER_STATE_KEY]) {
    log("Creating new global state for Mold renderer.");
    globalThis[MOLD_RENDERER_STATE_KEY] = {
      listeners: [],
      onClickListeners: {},
      initialized: false,
    };
  }
  return globalThis[MOLD_RENDERER_STATE_KEY];
};

const state = getGlobalState();

// Use the persistent state objects throughout the module.
const { listeners, onClickListeners } = state;

// --- End HMR State Management ---

export const addListener = (listener: listener) => {
  listeners.push(listener);
};

const PropertiesEnum = Object.freeze({
  position: 0,
  sizing: 1,
  padding: 2,
  childLayout: 3,
  scroll: 4,
  style: 5,
  border: 6,
  fgColor: 7,
  bgColor: 8,
  textStyle: 9,
  text: 10,
  debug_id: 11,
  onClick: 12,
});

type DomNode = { id: number };

const m = (id?: number): DomNode | undefined => (id ? { id } : undefined);
const um = (d?: DomNode): number => (d ? d.id : 0);

export const initialize = () => {
  // The initialized flag is now on the persistent global state.
  if (state.initialized) {
    log("Renderer already initialized. Skipping Core.init().");
    return;
  }

  Core.init((eventType: bigint, eventData: any) => {
    log("Event received:", { eventType, eventData });
    if (eventType === 1n) {
      const { id } = eventData;
      const eventId = `${id}`;
      log("Click event received:", { eventId, onClickListeners });
      if (eventId in onClickListeners) {
        onClickListeners[eventId](eventData);
      }
    } else {
      listeners.forEach((listener) => listener(eventData));
    }
  });

  state.initialized = true;
  log("Renderer Core initialized.");
};

export const {
  render,
  effect,
  memo,
  createComponent,
  createElement,
  createTextNode,
  insertNode,
  insert,
  spread,
  setProp,
  mergeProps,
  use,
} = createRenderer<DomNode>({
  // ... no changes to the renderer implementation itself ...
  // All functions like setProperty will now close over the stable
  // `onClickListeners` reference retrieved from `globalThis`.

  createElement(tagName: string): DomNode {
    log("createElement", { tagName });
    const elementId = Core.createElement({
      element_id: tagName,
      text: tagName === "span",
    });
    log("result of createElement", { elementId });
    return m(elementId)!;
  },

  createTextNode(value: string): DomNode {
    throw new Error("Not implemented");
  },

  replaceText(textNode: DomNode, value: string): void {
    throw new Error("Not implemented");
  },

  setProperty(node: DomNode, name: string, value: any): void {
    log("setProperty", {
      nodeId: node.id,
      name,
      isFunction: typeof value === "function",
    });

    if (name in PropertiesEnum) {
      const property = PropertiesEnum[name as keyof typeof PropertiesEnum];
      let [simpleValue, complexValue] = ["string"].includes(typeof value)
        ? [value, undefined]
        : ["", value];

      if (name === "text" && complexValue) {
        simpleValue = Array.isArray(complexValue)
          ? complexValue.join("")
          : String(complexValue);
        complexValue = undefined;
      }

      if (name === "onClick") {
        complexValue = true;
        // This now updates the globally-stored object.
        onClickListeners[node.id] = value;
        log("Setting onClick", {
          id: node.id,
          totalListeners: Object.keys(onClickListeners).length,
        });
      }

      Core.setProperty(
        {
          element_id: um(node),
          property: property,
        },
        simpleValue,
        complexValue,
      );
    }
  },

  insertNode(parent: DomNode, node: DomNode, anchor?: DomNode | null): void {
    log("insertNode", {
      parentId: um(parent),
      nodeId: um(node),
      anchorId: (anchor && um(anchor)) || null,
    });
    Core.insertNode({
      parent: um(parent),
      node: um(node),
      anchor: (anchor && um(anchor)) || null,
    });
  },

  isTextNode(node: DomNode): boolean {
    log("isTextNode", { nodeId: node.id });
    const result = Core.isTextNode({ node: um(node) });
    log("result of isTextNode", { result });
    return result;
  },

  removeNode(parent: DomNode, node: DomNode): void {
    log("removeNode", {
      parentId: parent.id,
      nodeId: node.id,
    });
    Core.removeNode({
      parent: um(parent),
      node: um(node),
    });
  },

  getParentNode(node: DomNode): DomNode | undefined {
    log("getParentNode", { nodeId: node.id });
    const result =
      Core.getRelatedNodes({
        node: um(node),
        relationship: 0, // parent
      }) || undefined;
    log("result of getParentNode", { result });
    return m(result);
  },

  getFirstChild(node: DomNode): DomNode | undefined {
    log("getFirstChild", { nodeId: node.id });
    const result =
      Core.getRelatedNodes({
        node: um(node),
        relationship: 1, // child
      }) || undefined;
    log("result of getFirstChild", { result });
    return m(result);
  },

  getNextSibling(node: DomNode): DomNode | undefined {
    log("getNextSibling", { nodeId: node.id });
    const result =
      Core.getRelatedNodes({
        node: um(node),
        relationship: 2, // sibling
      }) || undefined;
    log("result of getNextSibling", { result });
    return m(result);
  },
});

// Forward Solid control flow
export {
  For,
  Show,
  Suspense,
  SuspenseList,
  Switch,
  Match,
  Index,
  ErrorBoundary,
} from "solid-js";
