import * as fs from 'fs';
import * as path from 'path';

// Import enhanced utilities (if available)
try {
    const { logger } = require('../src/utils/logger');
    const { configManager } = require('../src/utils/config');
    const { XmlValidator } = require('../src/utils/xmlValidator');
} catch {
    // Fallback to console logging if utilities not available
    console.log('Enhanced utilities not found, using basic logging');
}

interface BuildResult {
    success: boolean;
    outputPath?: string;
    isValid?: boolean;
    error?: string;
    warnings?: string[];
    validationReport?: string;
    buildStats?: BuildStats;
}

interface BuildStats {
    startTime: Date;
    endTime: Date;
    duration: number;
    passesProcessed: number;
    fileSize: number;
}

interface PassMapping {
    [key: string]: string;
}

class AutoUnattendBuilder {
    private templatePath: string;
    private passesDir: string;
    private buildDir: string;
    private outputPath: string;
    private logger: any;
    private validator: any;
    private buildStats: BuildStats;

    constructor() {
        // Paths relative to the unattended directory (not dist)
        const unattendedDir = path.join(__dirname, '../../unattended');
        this.templatePath = path.join(unattendedDir, 'templates', 'autounattend-template.xml');
        this.passesDir = path.join(unattendedDir, 'passes');
        this.buildDir = path.join(unattendedDir, 'build');
        this.outputPath = path.join(this.buildDir, 'autounattend.xml');
        
        // Initialize enhanced utilities if available
        try {
            const { logger } = require('../src/utils/logger');
            const { XmlValidator } = require('../src/utils/xmlValidator');
            this.logger = logger;
            this.validator = new XmlValidator();
        } catch {
            this.logger = console;
            this.validator = null;
        }
        
        // Initialize build stats
        this.buildStats = {
            startTime: new Date(),
            endTime: new Date(),
            duration: 0,
            passesProcessed: 0,
            fileSize: 0
        };
        
        // Ensure build directory exists
        if (!fs.existsSync(this.buildDir)) {
            fs.mkdirSync(this.buildDir, { recursive: true });
        }
    }

    private readTemplate(): string {
        try {
            if (!fs.existsSync(this.templatePath)) {
                throw new Error(`Template file not found: ${this.templatePath}`);
            }
            
            const content = fs.readFileSync(this.templatePath, 'utf8');
            this.logger.info ? this.logger.info(`Template loaded: ${this.templatePath}`, 'AutoUnattendBuilder') 
                             : console.log(`Template loaded: ${this.templatePath}`);
            return content;
        } catch (error) {
            this.logger.error ? this.logger.error(`Error reading template file`, error as Error, 'AutoUnattendBuilder')
                              : console.error(`Error reading template file: ${(error as Error).message}`);
            throw error;
        }
    }

    private readPassFile(passName: string): string {
        const passPath = path.join(this.passesDir, `${passName}.xml`);
        try {
            if (!fs.existsSync(passPath)) {
                this.logger.warn ? this.logger.warn(`Pass file not found: ${passPath}`, 'AutoUnattendBuilder')
                                 : console.warn(`Pass file not found: ${passPath}`);
                return '';
            }
            
            const content = fs.readFileSync(passPath, 'utf8');
            this.buildStats.passesProcessed++;
            
            this.logger.debug ? this.logger.debug(`Pass file loaded: ${passName}`, 'AutoUnattendBuilder')
                              : console.log(`Pass file loaded: ${passName}`);
            return content;
        } catch (error) {
            this.logger.error ? this.logger.error(`Error reading pass file ${passName}`, error as Error, 'AutoUnattendBuilder')
                              : console.error(`Error reading pass file ${passName}: ${(error as Error).message}`);
            return '';
        }
    }

    private buildAutounattend(): string {
        this.logger.info ? this.logger.info('Starting autounattend.xml build process', 'AutoUnattendBuilder')
                         : console.log('Starting autounattend.xml build process...');
        
        let template = this.readTemplate();
        
        // Define the mapping between placeholders and pass files
        const passMapping: PassMapping = {
            '{{WINDOWSPE_PASS}}': 'windowspe',
            '{{OFFLINESERVICING_PASS}}': 'offlineservicing',
            '{{GENERALIZE_PASS}}': 'generalize',
            '{{SPECIALIZE_PASS}}': 'specialize',
            '{{AUDITSYSTEM_PASS}}': 'auditsystem',
            '{{AUDITUSER_PASS}}': 'audituser',
            '{{OOBESYSTEM_PASS}}': 'oobesystem'
        };

        // Replace each placeholder with its corresponding pass content
        for (const [placeholder, passName] of Object.entries(passMapping)) {
            this.logger.debug ? this.logger.debug(`Processing ${passName} pass`, 'AutoUnattendBuilder')
                              : console.log(`Processing ${passName} pass...`);
            const passContent = this.readPassFile(passName);
            template = template.replace(placeholder, passContent);
        }

        // Write the final autounattend.xml file
        try {
            fs.writeFileSync(this.outputPath, template, 'utf8');
            
            // Update build stats
            const stats = fs.statSync(this.outputPath);
            this.buildStats.fileSize = stats.size;
            
            this.logger.info ? this.logger.info(`Successfully generated autounattend.xml at: ${this.outputPath}`, 'AutoUnattendBuilder')
                             : console.log(`✓ Successfully generated autounattend.xml at: ${this.outputPath}`);
        } catch (error) {
            this.logger.error ? this.logger.error('Error writing output file', error as Error, 'AutoUnattendBuilder')
                              : console.error(`Error writing output file: ${(error as Error).message}`);
            throw error;
        }

        return this.outputPath;
    }

    private validateXml(): { isValid: boolean; report?: string; warnings?: string[] } {
        // Use enhanced validator if available
        if (this.validator) {
            const result = this.validator.validateAutounattendXml(this.outputPath);
            const report = this.validator.generateValidationReport(result);
            return {
                isValid: result.isValid,
                report: report,
                warnings: result.warnings
            };
        }
        
        // Fallback to basic validation
        try {
            const content = fs.readFileSync(this.outputPath, 'utf8');
            
            // Basic checks
            const xmlDeclaration = content.includes('<?xml version="1.0"');
            const unattendRoot = content.includes('<unattend xmlns="urn:schemas-microsoft-com:unattend">');
            const closingTag = content.includes('</unattend>');
            
            const isValid = xmlDeclaration && unattendRoot && closingTag;
            
            this.logger.info ? this.logger.info(`Basic XML validation: ${isValid ? 'PASSED' : 'FAILED'}`, 'AutoUnattendBuilder')
                             : console.log(`✓ Basic XML validation ${isValid ? 'passed' : 'failed'}`);
            
            return { isValid };
        } catch (error) {
            this.logger.error ? this.logger.error('Error validating XML', error as Error, 'AutoUnattendBuilder')
                              : console.error(`Error validating XML: ${(error as Error).message}`);
            return { isValid: false };
        }
    }

    public build(): BuildResult {
        try {
            this.buildStats.startTime = new Date();
            
            const outputPath = this.buildAutounattend();
            const validationResult = this.validateXml();
            
            this.buildStats.endTime = new Date();
            this.buildStats.duration = this.buildStats.endTime.getTime() - this.buildStats.startTime.getTime();
            
            this.logger.info ? this.logger.info('\n=== Build Summary ===', 'AutoUnattendBuilder') 
                             : console.log('\n=== Build Summary ===');
            this.logger.info ? this.logger.info(`Output file: ${outputPath}`, 'AutoUnattendBuilder')
                             : console.log(`Output file: ${outputPath}`);
            this.logger.info ? this.logger.info(`Validation: ${validationResult.isValid ? 'PASSED' : 'FAILED'}`, 'AutoUnattendBuilder')
                             : console.log(`Validation: ${validationResult.isValid ? 'PASSED' : 'FAILED'}`);
            this.logger.info ? this.logger.info(`Duration: ${this.buildStats.duration}ms`, 'AutoUnattendBuilder')
                             : console.log(`Duration: ${this.buildStats.duration}ms`);
            this.logger.info ? this.logger.info(`Passes processed: ${this.buildStats.passesProcessed}`, 'AutoUnattendBuilder')
                             : console.log(`Passes processed: ${this.buildStats.passesProcessed}`);
            this.logger.info ? this.logger.info(`File size: ${this.buildStats.fileSize} bytes`, 'AutoUnattendBuilder')
                             : console.log(`File size: ${this.buildStats.fileSize} bytes`);
            this.logger.info ? this.logger.info('===================\n', 'AutoUnattendBuilder')
                             : console.log('===================\n');
            
            // Show validation report if available
            if (validationResult.report) {
                this.logger.info ? this.logger.info(validationResult.report, 'AutoUnattendBuilder')
                                 : console.log(validationResult.report);
            }
            
            return { 
                success: true, 
                outputPath, 
                isValid: validationResult.isValid,
                warnings: validationResult.warnings,
                validationReport: validationResult.report,
                buildStats: this.buildStats
            };
        } catch (error) {
            this.buildStats.endTime = new Date();
            this.buildStats.duration = this.buildStats.endTime.getTime() - this.buildStats.startTime.getTime();
            
            this.logger.error ? this.logger.error('Build failed', error as Error, 'AutoUnattendBuilder')
                              : console.error(`Build failed: ${(error as Error).message}`);
            return { 
                success: false, 
                error: (error as Error).message,
                buildStats: this.buildStats
            };
        }
    }
}

// Main execution
if (require.main === module) {
    const builder = new AutoUnattendBuilder();
    const result = builder.build();
    
    process.exit(result.success ? 0 : 1);
}

export default AutoUnattendBuilder;
