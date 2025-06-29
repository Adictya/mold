import clay from "./clay.wasm";
import fs from "node:fs";
import { createInterface } from "node:readline";
import { stdout, stdin } from "node:process";

// Terminal color constants
const RESET = "\x1b[0m";
const FG_BLACK = "\x1b[30m";
const FG_RED = "\x1b[31m";
const FG_GREEN = "\x1b[32m";
const FG_YELLOW = "\x1b[33m";
const FG_BLUE = "\x1b[34m";
const FG_MAGENTA = "\x1b[35m";
const FG_CYAN = "\x1b[36m";
const FG_WHITE = "\x1b[37m";
const BG_BLACK = "\x1b[40m";
const BG_RED = "\x1b[41m";
const BG_GREEN = "\x1b[42m";
const BG_YELLOW = "\x1b[43m";
const BG_BLUE = "\x1b[44m";
const BG_MAGENTA = "\x1b[45m";
const BG_CYAN = "\x1b[46m";
const BG_WHITE = "\x1b[47m";

// Clay render command types (from reference-html.html)
const CLAY_RENDER_COMMAND_TYPE_NONE = 0;
const CLAY_RENDER_COMMAND_TYPE_RECTANGLE = 1;
const CLAY_RENDER_COMMAND_TYPE_BORDER = 2;
const CLAY_RENDER_COMMAND_TYPE_TEXT = 3;
const CLAY_RENDER_COMMAND_TYPE_IMAGE = 4;
const CLAY_RENDER_COMMAND_TYPE_SCISSOR_START = 5;
const CLAY_RENDER_COMMAND_TYPE_SCISSOR_END = 6;
const CLAY_RENDER_COMMAND_TYPE_CUSTOM = 7;

// Terminal UI state
let terminalWidth = stdout.columns || 80;
let terminalHeight = stdout.rows || 24;
let screen: string[][] = [];
let memoryDataView: DataView;
let textDecoder = new TextDecoder("utf-8");
let scratchSpaceAddress = 8;
let heapSpaceAddress = 0;
let renderCommandSize = 0;
let previousFrameTime = 0;

// Struct definitions (from reference-html.html)
const dimensionsDefinition = { type: 'struct', members: [
    {name: 'width', type: 'float'},
    {name: 'height', type: 'float'},
]};

const colorDefinition = { type: 'struct', members: [
    {name: 'r', type: 'float' },
    {name: 'g', type: 'float' },
    {name: 'b', type: 'float' },
    {name: 'a', type: 'float' },
]};

const stringDefinition = { type: 'struct', members: [
    {name: 'isStaticallyAllocated', type: 'uint32_t'},
    {name: 'length', type: 'uint32_t' },
    {name: 'chars', type: 'uint32_t' },
]};

const stringSliceDefinition = { type: 'struct', members: [
    {name: 'length', type: 'uint32_t' },
    {name: 'chars', type: 'uint32_t' },
    {name: 'baseChars', type: 'uint32_t' },
]};

const borderWidthDefinition = { type: 'struct', members: [
    {name: 'left', type: 'uint16_t'},
    {name: 'right', type: 'uint16_t'},
    {name: 'top', type: 'uint16_t'},
    {name: 'bottom', type: 'uint16_t'},
    {name: 'betweenChildren', type: 'uint16_t'},
]};

const cornerRadiusDefinition = { type: 'struct', members: [
    {name: 'topLeft', type: 'float'},
    {name: 'topRight', type: 'float'},
    {name: 'bottomLeft', type: 'float'},
    {name: 'bottomRight', type: 'float'},
]};

const textConfigDefinition = { name: 'text', type: 'struct', members: [
    { name: 'userData', type: 'uint32_t' },
    { name: 'textColor', ...colorDefinition },
    { name: 'fontId', type: 'uint16_t' },
    { name: 'fontSize', type: 'uint16_t' },
    { name: 'letterSpacing', type: 'uint16_t' },
    { name: 'lineSpacing', type: 'uint16_t' },
    { name: 'wrapMode', type: 'uint8_t' },
    { name: 'disablePointerEvents', type: 'uint8_t' },
    { name: '_padding', type: 'uint16_t' },
]};

const textRenderDataDefinition = { type: 'struct', members: [
    { name: 'stringContents', ...stringSliceDefinition },
    { name: 'textColor', ...colorDefinition },
    { name: 'fontId', type: 'uint16_t' },
    { name: 'fontSize', type: 'uint16_t' },
    { name: 'letterSpacing', type: 'uint16_t' },
    { name: 'lineHeight', type: 'uint16_t' },
]};

const rectangleRenderDataDefinition = { type: 'struct', members: [
    { name: 'backgroundColor', ...colorDefinition },
    { name: 'cornerRadius', ...cornerRadiusDefinition },
]};

const borderRenderDataDefinition = { type: 'struct', members: [
    { name: 'color', ...colorDefinition },
    { name: 'cornerRadius', ...cornerRadiusDefinition },
    { name: 'width', ...borderWidthDefinition },
    { name: 'padding', type: 'uint16_t'}
]};

const clipRenderDataDefinition = { type: 'struct', members: [
    { name: 'horizontal', type: 'bool' },
    { name: 'vertical', type: 'bool' },
]};

const renderCommandDefinition = {
    name: 'Clay_RenderCommand',
    type: 'struct',
    members: [
        { name: 'boundingBox', type: 'struct', members: [
            { name: 'x', type: 'float' },
            { name: 'y', type: 'float' },
            { name: 'width', type: 'float' },
            { name: 'height', type: 'float' },
        ]},
        { name: 'renderData', type: 'union', members: [
            { name: 'rectangle', ...rectangleRenderDataDefinition },
            { name: 'text', ...textRenderDataDefinition },
            { name: 'border', ...borderRenderDataDefinition },
            { name: 'clip', ...clipRenderDataDefinition },
        ]},
        { name: 'userData', type: 'uint32_t'},
        { name: 'id', type: 'uint32_t' },
        { name: 'zIndex', type: 'int16_t' },
        { name: 'commandType', type: 'uint8_t' },
        { name: '_padding', type: 'uint8_t' },
    ]
};

// Helper functions for reading struct data
function getStructTotalSize(definition: any): number {
    switch(definition.type) {
        case 'union':
        case 'struct': {
            let totalSize = 0;
            for (const member of definition.members) {
                let result = getStructTotalSize(member);
                if (definition.type === 'struct') {
                    totalSize += result;
                } else {
                    totalSize = Math.max(totalSize, result);
                }
            }
            return totalSize;
        }
        case 'float': return 4;
        case 'uint32_t': return 4;
        case 'int32_t': return 4;
        case 'uint16_t': return 2;
        case 'int16_t': return 2;
        case 'uint8_t': return 1;
        case 'bool': return 1;
        default: {
            throw new Error("Unimplemented C data type " + definition.type);
        }
    }
}

function readStructAtAddress(address: number, definition: any): any {
    switch(definition.type) {
        case 'union':
        case 'struct': {
            let struct: any = { __size: 0 };
            for (const member of definition.members) {
                let result = readStructAtAddress(address, member);
                struct[member.name] = result;
                if (definition.type === 'struct') {
                    struct.__size += result.__size;
                    address += result.__size;
                } else {
                    struct.__size = Math.max(struct.__size, result.__size);
                }
            }
            return struct;
        }
        case 'float': return { value: memoryDataView.getFloat32(address, true), __size: 4 };
        case 'uint32_t': return { value: memoryDataView.getUint32(address, true), __size: 4 };
        case 'int32_t': return { value: memoryDataView.getInt32(address, true), __size: 4 };
        case 'uint16_t': return { value: memoryDataView.getUint16(address, true), __size: 2 };
        case 'int16_t': return { value: memoryDataView.getInt16(address, true), __size: 2 };
        case 'uint8_t': return { value: memoryDataView.getUint8(address, true), __size: 1 };
        case 'bool': return { value: memoryDataView.getUint8(address, true) ? true : false, __size: 1 };
        default: {
            throw new Error("Unimplemented C data type " + definition.type);
        }
    }
}

// Initialize the screen buffer
function initScreen() {
    screen = Array(terminalHeight).fill(0).map(() => 
        Array(terminalWidth).fill(' ')
    );
}

// Convert RGB to closest terminal color
function rgbToTerminalColor(r: number, g: number, b: number, isForeground: boolean = true): string {
    // Simple mapping to basic terminal colors
    if (r > 200 && g < 100 && b < 100) return isForeground ? FG_RED : BG_RED;
    if (r < 100 && g > 200 && b < 100) return isForeground ? FG_GREEN : BG_GREEN;
    if (r > 200 && g > 200 && b < 100) return isForeground ? FG_YELLOW : BG_YELLOW;
    if (r < 100 && g < 100 && b > 200) return isForeground ? FG_BLUE : BG_BLUE;
    if (r > 200 && g < 100 && b > 200) return isForeground ? FG_MAGENTA : BG_MAGENTA;
    if (r < 100 && g > 200 && b > 200) return isForeground ? FG_CYAN : BG_CYAN;
    if (r > 200 && g > 200 && b > 200) return isForeground ? FG_WHITE : BG_WHITE;
    return isForeground ? FG_BLACK : BG_BLACK;
}

// Draw a pixel to the screen buffer
function drawPixel(x: number, y: number, char: string, fgColor: string = '', bgColor: string = '') {
    const xPos = Math.floor(x);
    const yPos = Math.floor(y);
    
    if (xPos >= 0 && xPos < terminalWidth && yPos >= 0 && yPos < terminalHeight) {
        screen[yPos][xPos] = `${bgColor}${fgColor}${char}${RESET}`;
    }
}

// Draw a rectangle
function drawRectangle(x: number, y: number, width: number, height: number, bgColor: string) {
    for (let row = y; row < y + height; row++) {
        for (let col = x; col < x + width; col++) {
            drawPixel(col, row, ' ', '', bgColor);
        }
    }
}

// Draw text
function drawText(x: number, y: number, text: string, fgColor: string) {
    for (let i = 0; i < text.length; i++) {
        drawPixel(x + i, y, text[i], fgColor);
    }
}

// Draw a border
function drawBorder(x: number, y: number, width: number, height: number, color: string) {
    // Top and bottom borders
    for (let col = x; col < x + width; col++) {
        drawPixel(col, y, '─', color);
        drawPixel(col, y + height - 1, '─', color);
    }
    
    // Left and right borders
    for (let row = y; row < y + height; row++) {
        drawPixel(x, row, '│', color);
        drawPixel(x + width - 1, row, '│', color);
    }
    
    // Corners
    drawPixel(x, y, '┌', color);
    drawPixel(x + width - 1, y, '┐', color);
    drawPixel(x, y + height - 1, '└', color);
    drawPixel(x + width - 1, y + height - 1, '┘', color);
}

// Render the screen buffer to the terminal
function renderScreen() {
    // Clear the terminal
    stdout.write('\x1b[2J\x1b[H');
    
    // Render each line
    for (let row = 0; row < terminalHeight; row++) {
        stdout.write(screen[row].join('') + '\n');
    }
}

// Process Clay render commands
function processRenderCommands() {
    const capacity = memoryDataView.getInt32(scratchSpaceAddress, true);
    const length = memoryDataView.getInt32(scratchSpaceAddress + 4, true);
    let arrayOffset = memoryDataView.getUint32(scratchSpaceAddress + 8, true);
    
    // Clear screen before rendering
    initScreen();
    
    for (let i = 0; i < length; i++, arrayOffset += renderCommandSize) {
        const renderCommand = readStructAtAddress(arrayOffset, renderCommandDefinition);
        const boundingBox = renderCommand.boundingBox;
        const x = Math.floor(boundingBox.x.value);
        const y = Math.floor(boundingBox.y.value);
        const width = Math.floor(boundingBox.width.value);
        const height = Math.floor(boundingBox.height.value);
        
        // Process command based on type
        switch (renderCommand.commandType.value & 0xff) {
            case CLAY_RENDER_COMMAND_TYPE_RECTANGLE: {
                const config = renderCommand.renderData.rectangle;
                const color = config.backgroundColor;
                const bgColor = rgbToTerminalColor(color.r.value, color.g.value, color.b.value, false);
                drawRectangle(x, y, width, height, bgColor);
                break;
            }
            case CLAY_RENDER_COMMAND_TYPE_TEXT: {
                const config = renderCommand.renderData.text;
                const textContents = config.stringContents;
                const stringContents = new Uint8Array(memoryDataView.buffer.slice(textContents.chars.value, textContents.chars.value + textContents.length.value));
                const text = textDecoder.decode(stringContents);
                const color = config.textColor;
                const fgColor = rgbToTerminalColor(color.r.value, color.g.value, color.b.value, true);
                drawText(x, y, text, fgColor);
                break;
            }
            case CLAY_RENDER_COMMAND_TYPE_BORDER: {
                const config = renderCommand.renderData.border;
                const color = config.color;
                const borderColor = rgbToTerminalColor(color.r.value, color.g.value, color.b.value, true);
                drawBorder(x, y, width, height, borderColor);
                break;
            }
            case CLAY_RENDER_COMMAND_TYPE_SCISSOR_START:
            case CLAY_RENDER_COMMAND_TYPE_SCISSOR_END:
            case CLAY_RENDER_COMMAND_TYPE_NONE:
            default:
                // Not implemented or no action needed
                break;
        }
    }
    
    // Render the screen
    renderScreen();
}

// Main render loop
function renderLoop(currentTime: number) {
    const elapsed = currentTime - previousFrameTime;
    previousFrameTime = currentTime;
    
    // Update terminal dimensions
    terminalWidth = stdout.columns || 80;
    terminalHeight = stdout.rows || 24;
    
    // Update Clay frame
    instance.exports.UpdateDrawFrame(
        scratchSpaceAddress,
        terminalWidth,
        terminalHeight,
        0, 0, 0, 0, false, false, false, false, false,
        elapsed / 1000
    );
    
    // Process and render Clay commands
    processRenderCommands();
    
    // Schedule next frame
    setTimeout(() => renderLoop(Date.now()), 1000 / 30); // 30 FPS
}

// Initialize Clay and start the renderer
async function init() {
    // Load Clay WASM
    const clayWasmBuffer = fs.readFileSync(clay);
    
    // Define import object for Clay
    const importObject = {
        clay: {
            measureTextFunction: (addressOfDimensions: number, textToMeasure: number, addressOfConfig: number, userData: number) => {
                const stringLength = memoryDataView.getUint32(textToMeasure, true);
                const pointerToString = memoryDataView.getUint32(textToMeasure + 4, true);
                const text = textDecoder.decode(memoryDataView.buffer.slice(pointerToString, pointerToString + stringLength));
                
                // Simple text measurement for terminal (1 char = 1 column)
                memoryDataView.setFloat32(addressOfDimensions, text.length, true);
                memoryDataView.setFloat32(addressOfDimensions + 4, 1, true);
            },
            queryScrollOffsetFunction: (addressOfOffset: number, elementId: number) => {
                // No scrolling in terminal mode
                memoryDataView.setFloat32(addressOfOffset, 0, true);
                memoryDataView.setFloat32(addressOfOffset + 4, 0, true);
            },
        },
    };
    
    // Instantiate WASM
    const { instance: wasmInstance } = await WebAssembly.instantiate(clayWasmBuffer, importObject);
    const instance = wasmInstance as any;
    
    // Setup memory and addresses
    memoryDataView = new DataView(new Uint8Array(instance.exports.memory.buffer).buffer);
    scratchSpaceAddress = instance.exports.__heap_base.value;
    const clayScratchSpaceAddress = instance.exports.__heap_base.value + 1024;
    heapSpaceAddress = instance.exports.__heap_base.value + 2048;
    const arenaAddress = scratchSpaceAddress + 8;
    
    // Create main arena
    const memorySize = instance.exports.Clay_MinMemorySize();
    instance.exports.Clay_CreateArenaWithCapacityAndMemory(arenaAddress, memorySize, heapSpaceAddress);
    
    // Initialize Clay
    memoryDataView.setFloat32(instance.exports.__heap_base.value, terminalWidth, true);
    memoryDataView.setFloat32(instance.exports.__heap_base.value + 4, terminalHeight, true);
    instance.exports.Clay_Initialize(arenaAddress, instance.exports.__heap_base.value);
    instance.exports.SetScratchMemory(clayScratchSpaceAddress);
    
    // Calculate render command size
    renderCommandSize = getStructTotalSize(renderCommandDefinition);
    
    // Initialize screen buffer
    initScreen();
    
    // Setup keyboard input
    const readline = createInterface({
        input: stdin,
        output: stdout,
    });
    
    readline.on('line', (input) => {
        // Process input if needed
    });
    
    // Start render loop
    renderLoop(Date.now());
    
    console.log("Terminal UI renderer started. Press Ctrl+C to exit.");
}

// Start the application
init().catch(console.error);
