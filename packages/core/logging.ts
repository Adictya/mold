import { transports, format, createLogger } from "winston";

// Create the logger instance
export const log = createLogger({
  level: "debug",
  format: format.combine(
		format.timestamp(),
		format.json(),
		format.uncolorize(),
		format.errors({ stack: true }),
		format.metadata(),
		format.prettyPrint({ colorize: true }),
  ),
  transports: [
    new transports.File({
      filename: "ui-debug.log",
      level: "debug",
    }),
    // new transports.Console(),
  ],
  // Don't exit on uncaught exceptions
  exitOnError: true,
});

// Redirect console methods to winston
const tag = "[Console] ";
console.log = (arg, ...args) => {
  log.info(`${tag}log: ${arg}`, args.join(" "));
};

console.info = (arg, ...args) => {
  log.info(`${tag} info: ${arg}`, args.join(" "));
  // logger.info(
  //   args
  //     .map((arg) => (typeof arg === "object" ? JSON.stringify(arg) : arg))
  //     .join(" "),
  // );
};

console.warn = (...args) => {
  log.warn("console warn", args.join(" "));
  // logger.warn(
  //   args
  //     .map((arg) => (typeof arg === "object" ? JSON.stringify(arg) : arg))
  //     .join(" "),
  // );
};

console.error = (...args) => {
  log.error("console error", args.join(" "));
  // logger.error(
  //   args
  //     .map((arg) => (typeof arg === "object" ? JSON.stringify(arg) : arg))
  //     .join(" "),
  // );
};

console.debug = (...args) => {
  log.debug("console debug", args.join(" "));
  // logger.debug(
  //   args
  //     .map((arg) => (typeof arg === "object" ? JSON.stringify(arg) : arg))
  //     .join(" "),
  // );
};
