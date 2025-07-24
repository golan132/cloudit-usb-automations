// Configuration management with validation and environment support
import * as fs from 'fs';
import * as path from 'path';
import { logger } from './logger';

export interface UserAccount {
    username: string;
    password: string;
    fullName: string;
    description: string;
    autoLogon: boolean;
}

export interface IsoSettings {
    label: string;
    publisher: string;
    outputPath: string;
}

export interface BuildSettings {
    timeout: number;
    retryAttempts: number;
    cleanupAfterBuild: boolean;
    preserveLogs: boolean;
}

export interface Config {
    userAccount: UserAccount;
    isoSettings: IsoSettings;
    buildSettings: BuildSettings;
    paths: {
        templates: string;
        passes: string;
        scripts: string;
        build: string;
    };
    validation: {
        enableXmlValidation: boolean;
        enableSchemaValidation: boolean;
        strictMode: boolean;
    };
}

export class ConfigManager {
    private config: Config;
    private configPath: string;

    constructor(configPath?: string) {
        this.configPath = configPath || path.join(process.cwd(), 'config', 'cloudit-config.json');
        this.config = this.loadConfig();
    }

    private getDefaultConfig(): Config {
        return {
            userAccount: {
                username: 'cloudit',
                password: 'CloudIT',
                fullName: 'CloudIT User',
                description: 'Default CloudIT automation user',
                autoLogon: true
            },
            isoSettings: {
                label: 'CloudIT_Windows',
                publisher: 'CloudIT',
                outputPath: './iso/result'
            },
            buildSettings: {
                timeout: 600000, // 10 minutes
                retryAttempts: 3,
                cleanupAfterBuild: false,
                preserveLogs: true
            },
            paths: {
                templates: './unattended/templates',
                passes: './unattended/passes',
                scripts: './unattended/scripts',
                build: './unattended/build'
            },
            validation: {
                enableXmlValidation: true,
                enableSchemaValidation: false,
                strictMode: false
            }
        };
    }

    private loadConfig(): Config {
        try {
            if (fs.existsSync(this.configPath)) {
                const configData = fs.readFileSync(this.configPath, 'utf8');
                const userConfig = JSON.parse(configData);
                const defaultConfig = this.getDefaultConfig();
                
                // Merge with defaults
                return this.deepMerge(defaultConfig, userConfig);
            } else {
                logger.info('Config file not found, creating default configuration', 'ConfigManager');
                this.saveConfig(this.getDefaultConfig());
                return this.getDefaultConfig();
            }
        } catch (error) {
            logger.error('Failed to load configuration, using defaults', error as Error, 'ConfigManager');
            return this.getDefaultConfig();
        }
    }

    private deepMerge(target: any, source: any): any {
        const result = { ...target };
        
        for (const key in source) {
            if (source[key] && typeof source[key] === 'object' && !Array.isArray(source[key])) {
                result[key] = this.deepMerge(target[key] || {}, source[key]);
            } else {
                result[key] = source[key];
            }
        }
        
        return result;
    }

    public getConfig(): Config {
        return this.config;
    }

    public updateConfig(updates: Partial<Config>): void {
        this.config = this.deepMerge(this.config, updates);
        this.saveConfig(this.config);
    }

    public saveConfig(config?: Config): void {
        const configToSave = config || this.config;
        
        try {
            const configDir = path.dirname(this.configPath);
            if (!fs.existsSync(configDir)) {
                fs.mkdirSync(configDir, { recursive: true });
            }
            
            fs.writeFileSync(this.configPath, JSON.stringify(configToSave, null, 2), 'utf8');
            logger.info('Configuration saved successfully', 'ConfigManager');
        } catch (error) {
            logger.error('Failed to save configuration', error as Error, 'ConfigManager');
        }
    }

    public validateConfig(): boolean {
        try {
            const config = this.getConfig();
            
            // Basic validation
            if (!config.userAccount.username || !config.userAccount.password) {
                logger.error('Invalid user account configuration', undefined, 'ConfigManager');
                return false;
            }
            
            if (!config.isoSettings.label) {
                logger.error('Invalid ISO settings configuration', undefined, 'ConfigManager');
                return false;
            }
            
            logger.info('Configuration validation passed', 'ConfigManager');
            return true;
        } catch (error) {
            logger.error('Configuration validation failed', error as Error, 'ConfigManager');
            return false;
        }
    }
}

// Singleton instance
export const configManager = new ConfigManager();
