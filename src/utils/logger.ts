// Enhanced logging utility for better debugging and monitoring
import * as fs from 'fs';
import * as path from 'path';

export enum LogLevel {
    DEBUG = 0,
    INFO = 1,
    WARN = 2,
    ERROR = 3
}

export interface LogEntry {
    timestamp: Date;
    level: LogLevel;
    message: string;
    context?: string;
    error?: Error;
}

export class Logger {
    private logFile: string;
    private currentLevel: LogLevel = LogLevel.INFO;

    constructor(logFile?: string) {
        this.logFile = logFile || path.join(process.cwd(), 'logs', 'cloudit-automation.log');
        this.ensureLogDir();
    }

    private ensureLogDir(): void {
        const logDir = path.dirname(this.logFile);
        if (!fs.existsSync(logDir)) {
            fs.mkdirSync(logDir, { recursive: true });
        }
    }

    public setLevel(level: LogLevel): void {
        this.currentLevel = level;
    }

    public debug(message: string, context?: string): void {
        this.log(LogLevel.DEBUG, message, context);
    }

    public info(message: string, context?: string): void {
        this.log(LogLevel.INFO, message, context);
    }

    public warn(message: string, context?: string): void {
        this.log(LogLevel.WARN, message, context);
    }

    public error(message: string, error?: Error, context?: string): void {
        this.log(LogLevel.ERROR, message, context, error);
    }

    private log(level: LogLevel, message: string, context?: string, error?: Error): void {
        if (level < this.currentLevel) return;

        const entry: LogEntry = {
            timestamp: new Date(),
            level,
            message,
            context,
            error
        };

        // Console output with colors
        this.logToConsole(entry);
        
        // File output
        this.logToFile(entry);
    }

    private logToConsole(entry: LogEntry): void {
        const timestamp = entry.timestamp.toISOString();
        const levelStr = LogLevel[entry.level].padEnd(5);
        const contextStr = entry.context ? ` [${entry.context}]` : '';
        
        const colors = {
            [LogLevel.DEBUG]: '\x1b[90m', // Gray
            [LogLevel.INFO]: '\x1b[36m',  // Cyan
            [LogLevel.WARN]: '\x1b[33m',  // Yellow
            [LogLevel.ERROR]: '\x1b[31m'  // Red
        };

        const reset = '\x1b[0m';
        const color = colors[entry.level];
        
        console.log(`${color}[${timestamp}] ${levelStr}${contextStr} ${entry.message}${reset}`);
        
        if (entry.error) {
            console.error(`${color}Stack: ${entry.error.stack}${reset}`);
        }
    }

    private logToFile(entry: LogEntry): void {
        const timestamp = entry.timestamp.toISOString();
        const levelStr = LogLevel[entry.level].padEnd(5);
        const contextStr = entry.context ? ` [${entry.context}]` : '';
        
        let logLine = `[${timestamp}] ${levelStr}${contextStr} ${entry.message}\n`;
        
        if (entry.error) {
            logLine += `Stack: ${entry.error.stack}\n`;
        }

        try {
            fs.appendFileSync(this.logFile, logLine, 'utf8');
        } catch (err) {
            console.error('Failed to write to log file:', err);
        }
    }
}

// Singleton instance
export const logger = new Logger();
