import * as fs from 'fs';
import * as path from 'path';

interface BuildResult {
    success: boolean;
    outputPath?: string;
    isValid?: boolean;
    error?: string;
}

interface PassMapping {
    [key: string]: string;
}

class AutoUnattendBuilder {
    private templatePath: string;
    private passesDir: string;
    private buildDir: string;
    private outputPath: string;

    constructor() {
        // Paths relative to the unattended directory (not dist)
        const unattendedDir = path.join(__dirname, '../../unattended');
        this.templatePath = path.join(unattendedDir, 'templates', 'autounattend-template.xml');
        this.passesDir = path.join(unattendedDir, 'passes');
        this.buildDir = path.join(unattendedDir, 'build');
        this.outputPath = path.join(this.buildDir, 'autounattend.xml');
        
        // Ensure build directory exists
        if (!fs.existsSync(this.buildDir)) {
            fs.mkdirSync(this.buildDir, { recursive: true });
        }
    }

    private readTemplate(): string {
        try {
            return fs.readFileSync(this.templatePath, 'utf8');
        } catch (error) {
            console.error(`Error reading template file: ${(error as Error).message}`);
            throw error;
        }
    }

    private readPassFile(passName: string): string {
        const passPath = path.join(this.passesDir, `${passName}.xml`);
        try {
            if (!fs.existsSync(passPath)) {
                console.warn(`Pass file not found: ${passPath}`);
                return '';
            }
            return fs.readFileSync(passPath, 'utf8');
        } catch (error) {
            console.error(`Error reading pass file ${passName}: ${(error as Error).message}`);
            return '';
        }
    }

    private buildAutounattend(): string {
        console.log('Starting autounattend.xml build process...');
        
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
            console.log(`Processing ${passName} pass...`);
            const passContent = this.readPassFile(passName);
            template = template.replace(placeholder, passContent);
        }

        // Write the final autounattend.xml file
        try {
            fs.writeFileSync(this.outputPath, template, 'utf8');
            console.log(`✓ Successfully generated autounattend.xml at: ${this.outputPath}`);
        } catch (error) {
            console.error(`Error writing output file: ${(error as Error).message}`);
            throw error;
        }

        return this.outputPath;
    }

    private validateXml(): boolean {
        // Basic XML validation - check if file is well-formed
        try {
            const content = fs.readFileSync(this.outputPath, 'utf8');
            
            // Basic checks
            const xmlDeclaration = content.includes('<?xml version="1.0"');
            const unattendRoot = content.includes('<unattend xmlns="urn:schemas-microsoft-com:unattend">');
            const closingTag = content.includes('</unattend>');
            
            if (xmlDeclaration && unattendRoot && closingTag) {
                console.log('✓ Basic XML validation passed');
                return true;
            } else {
                console.warn('⚠ XML structure validation failed');
                return false;
            }
        } catch (error) {
            console.error(`Error validating XML: ${(error as Error).message}`);
            return false;
        }
    }

    public build(): BuildResult {
        try {
            const outputPath = this.buildAutounattend();
            const isValid = this.validateXml();
            
            console.log('\n=== Build Summary ===');
            console.log(`Output file: ${outputPath}`);
            console.log(`Validation: ${isValid ? 'PASSED' : 'FAILED'}`);
            console.log('===================\n');
            
            return { success: true, outputPath, isValid };
        } catch (error) {
            console.error(`Build failed: ${(error as Error).message}`);
            return { success: false, error: (error as Error).message };
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
