# Mold

A high-performance TUI library with a Zig core, SolidJS frontend, and blazingly fast flexbox-like layouting.

⚠️ **Alpha Software** - This is a first working proof-of-concept. Nothing is finalized.

https://github.com/user-attachments/assets/904644d5-c76d-4ce2-84bf-7e524e1af970

## Features

- **Zig-based core** exposed via Node API using [napigen](https://github.com/cztomsik/napigen)
- **SolidJS with HMR** for reactive UI development
- **Node and Bun compatible** runtime support
- **Blazingly fast flexbox-like layouting** powered by [Clay](https://github.com/nicbarker/clay) and [zclay](https://github.com/johan0A/clay-zig-bindings)
- **Wide range of terminal features** thanks to [libvaxis](https://github.com/rockorager/libvaxis) *(not yet exposed/used but can easily be added)*:
  - RGB colors, hyperlinks, bracketed paste
  - Kitty keyboard protocol, fancy underlines
  - Mouse shapes, system clipboard, notifications
  - Images via kitty graphics protocol

## Future Plans

- **ShadCN-like UI library** - Fully customizable and themeable terminal-first components with shadcn CLI support
- **DOM-like API** - Handle input/scrolling/dragging in Zig core with optional JS hooks
- **Zig-based animation library** - Native performance animations
- **Event bus framework** - Bubbles/libvaxis-like event system for component communication without prop drilling
- **Declarative routing** - Built-in routing system

## Project Structure

- `./native` - Zig core library
- `./examples/solid-test` - Example SolidJS application
- `./packages/core` - Core TypeScript/SolidJS bindings

## Quick Start

### Development (with HMR)

Requires Bun and Zig installed.

```bash
bun run build:native
bun install
cd examples/solid-test
bun run dev
```

### Production Build

```bash
cd examples/solid-test
bun run build
node ./dist/index.js
```

## Acknowledgements

This project builds on the excellent work of:

- [Clay](https://github.com/nicbarker/clay) by Nic Barker - High-performance 2D UI layout library
- [zclay](https://github.com/johan0A/clay-zig-bindings) by johan0A - Zig bindings for Clay
- [libvaxis](https://github.com/rockorager/libvaxis) by rockorager - Modern TUI library for Zig
- [napigen](https://github.com/cztomsik/napigen) by cztomsik - Comptime N-API bindings for Zig

## License

MIT
