import { createRenderer } from "solid-js/universal";
import Core from "./core";

type listener = (event: any) => void;
const listeners: listener[] = [];

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
});

// DomNode is now just a string ID that references a node in the Zig implementation
type DomNode = { id: string };

const m = (id?: string): DomNode | undefined => (id ? { id } : undefined);
const um = (d: DomNode): string => d.id;

// Debug logging helper
function log(operation: string, ...args: any[]) {
  // console.log(`[DEBUG] ${operation}:`, args);
}

Core.init((...event) => {
  listeners.forEach((listener) => listener(event));
});

const idCounter = {
  span: 0,
  div: 0,
  root: 0,
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
  createElement(tagName: string): DomNode {
    log("createElement", { tagName });

    if (idCounter[tagName] === undefined) {
      throw new Error(`Element not supportd: ${tagName}`);
    }

    log("1createElement", { tagName, id: idCounter[tagName] });

    idCounter[tagName] += 1;

    log("2createElement", { tagName, id: idCounter[tagName] });
    const elementId = Core.createElement({
      element_id: `${tagName}-${idCounter[tagName]}`,
      text: tagName === "span",
    });
    log("result of createElement", { elementId });
    return m(elementId)!;
  },

  createTextNode(value: string): DomNode {
    throw new Error("Not implemented");
    log("createTextNode", { value });
    const elementId = Core.createElement({
      element_id: value,
      text: true,
    });
    log("result of createTextNode", { elementId });
    return m(elementId)!;
  },

  replaceText(textNode: DomNode, value: string): void {
    throw new Error("Not implemented");
    log("replaceText", {
      oldValue: textNode,
      newValue: value,
    });
    Core.replaceText({
      element_id: um(textNode),
      text: value,
    });
  },

  setProperty(node: DomNode, name: string, value: any): void {
    log("setProperty", {
      nodeId: node,
      name,
      value,
    });

    if (name in PropertiesEnum) {
      const property = PropertiesEnum[name];
      var [simpleValue, complexValue] = [
        "string",
        "boolean",
        "number",
      ].includes(typeof value)
        ? [value, undefined]
        : ["", value];

      if (name === "text" && complexValue) {
        simpleValue = complexValue.join(" ");
        complexValue = undefined;
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
    log("isTextNode", { nodeId: node });
    const result = Core.isTextNode({ node: um(node) });

    log("result of isTextNode", { result });
    return result;
  },

  removeNode(parent: DomNode, node: DomNode): void {
    log("removeNode", {
      parentId: parent,
      nodeId: node,
    });

    Core.removeNode({
      parent: um(parent),
      node: um(node),
    });
  },

  getParentNode(node: DomNode): DomNode | undefined {
    log("getParentNode", { nodeId: node });

    const result =
      Core.getRelatedNodes({
        node: um(node),
        relationship: 0, // parent
      }) || undefined;

    log("result of getParentNode", { result });
    return m(result);
  },

  getFirstChild(node: DomNode): DomNode | undefined {
    log("getFirstChild", { nodeId: node });

    const result =
      Core.getRelatedNodes({
        node: um(node),
        relationship: 1, // child
      }) || undefined;

    log("result of getFirstChild", { result });
    return m(result);
  },

  getNextSibling(node: DomNode): DomNode | undefined {
    log("getNextSibling", { nodeId: node });

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

// Helper function to visualize the DOM tree (for debugging)
// This function is no longer needed as we're using string IDs now
// and the DOM tree is managed by the Zig implementation
