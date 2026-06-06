const LEVELS = { debug: 0, info: 1, warn: 2, error: 3 };
const currentLevel = LEVELS[process.env.LOG_LEVEL] ?? LEVELS.info;

function log(level, prefix, ...args) {
  if (LEVELS[level] < currentLevel) return;
  const ts = new Date().toISOString().slice(11, 23);
  console[level === 'error' ? 'error' : 'log'](`[${ts}] [${level.toUpperCase()}] [${prefix}]`, ...args);
}

export const createLogger = (prefix) => ({
  debug: (...a) => log('debug', prefix, ...a),
  info:  (...a) => log('info',  prefix, ...a),
  warn:  (...a) => log('warn',  prefix, ...a),
  error: (...a) => log('error', prefix, ...a),
});
