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

// Terminal UI state
let terminalWidth = stdout.columns || 80;
let terminalHeight = stdout.rows || 24;
let screen: string[][] = [];

// Demo state
let demoCounter = 0;

// Initialize the screen buffer
function initScreen() {
    screen = Array(terminalHeight).fill(0).map(() => 
        Array(terminalWidth).fill(' ')
    );
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

// Create a simple demo UI
function createDemoUI() {
    // Clear screen
    initScreen();
    
    // Draw main window border
    drawBorder(0, 0, terminalWidth, terminalHeight, FG_CYAN);
    
    // Draw header
    drawRectangle(1, 1, terminalWidth - 2, 3, BG_BLUE);
    drawText(Math.floor(terminalWidth / 2) - 10, 2, "Clay Terminal UI Demo", FG_WHITE);
    
    // Draw sidebar
    drawRectangle(1, 4, 20, terminalHeight - 5, BG_BLACK);
    drawBorder(1, 4, 20, terminalHeight - 5, FG_GREEN);
    drawText(3, 6, "Navigation", FG_GREEN);
    drawText(3, 8, "Home", FG_WHITE);
    drawText(3, 9, "Settings", FG_WHITE);
    drawText(3, 10, "About", FG_WHITE);
    drawText(3, 11, "Exit", FG_WHITE);
    
    // Draw main content area
    drawRectangle(21, 4, terminalWidth - 22, terminalHeight - 5, BG_BLACK);
    drawBorder(21, 4, terminalWidth - 22, terminalHeight - 5, FG_YELLOW);
    
    // Draw content
    drawText(23, 6, "Welcome to Clay Terminal UI", FG_MAGENTA);
    drawText(23, 8, "This is a simple demo of the terminal UI renderer", FG_WHITE);
    drawText(23, 10, "Features:", FG_CYAN);
    drawText(25, 11, "- Text rendering", FG_WHITE);
    drawText(25, 12, "- Rectangle drawing", FG_WHITE);
    drawText(25, 13, "- Border drawing", FG_WHITE);
    drawText(25, 14, "- Color support", FG_WHITE);
    
    // Draw animated counter
    drawText(23, 16, `Counter: ${demoCounter}`, FG_GREEN);
    demoCounter++;
    
    // Draw footer
    drawRectangle(1, terminalHeight - 1, terminalWidth - 2, 1, BG_BLUE);
    drawText(2, terminalHeight - 1, "Press Ctrl+C to exit", FG_WHITE);
    
    // Render to terminal
    renderScreen();
}

// Main render loop
function renderLoop() {
    // Update terminal dimensions
    terminalWidth = stdout.columns || 80;
    terminalHeight = stdout.rows || 24;
    
    // Create demo UI
    createDemoUI();
    
    // Schedule next frame
    setTimeout(() => renderLoop(), 1000 / 5); // 5 FPS
}

// Initialize and start the demo
async function init() {
    // Initialize screen buffer
    initScreen();
    
    // Setup keyboard input
    const readline = createInterface({
        input: stdin,
        output: stdout,
    });
    
    readline.on('line', (_input) => {
        // Process input if needed
    });
    
    // Start render loop
    renderLoop();
    
    console.log("Terminal UI demo started. Press Ctrl+C to exit.");
}

// Start the application
init().catch(console.error);