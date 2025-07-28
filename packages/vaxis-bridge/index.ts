const native = require('./zig-out/lib/example.node')

// types.ts
export enum ComponentType {
  Box,
  Text,
}

export interface Component {
  ctype: ComponentType;
  x: number;
  y: number;
  width: number;
  height: number;
  fgColor: number;
  bgColor: number;
  border: boolean;
  text?: string;
}

export enum EventType {
  KeyPress,
  Winsize,
}

export interface KeyEvent {
  key: string;
  ctrl: boolean;
  alt: boolean;
  shift: boolean;
}

export interface WinsizeEvent {
  rows: number;
  cols: number;
}

export interface AppEvent {
  etype: EventType;
  key: KeyEvent;
  winsize: WinsizeEvent;
}

// console.log('1 + 2 =', native.add(1, 2))

const testComponents: Component[] = [
  {
    ctype: ComponentType.Box,
    x: 5,
    y: 5,
    width: 20,
    height: 5,
    fgColor: 2,
    bgColor: 0,
    border: true,
  },
  {
    ctype: ComponentType.Text,
    x: 7,
    y: 7,
    width: 17,
    height: 1,
    fgColor: 3,
    bgColor: 0,
    border: false,
    text: "Hello from javascript!",
  }
]

native.init((...val) => console.log("Called back", val));
console.log("Initialized native module");
// native.render(testComponents);
//
// while (true) {
//   // sleep in js for 1000ms
//   await new Promise(resolve => setTimeout(resolve, 1000));
// }
// native.shutdown();
