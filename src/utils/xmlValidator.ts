// Enhanced XML validation with schema support and detailed error reporting
import * as fs from 'fs';

export interface ValidationResult {
    isValid: boolean;
    errors: string[];
    warnings: string[];
    suggestions: string[];
}

export class XmlValidator {
    private schemaPath?: string;

    constructor(schemaPath?: string) {
        this.schemaPath = schemaPath;
    }

    public validateAutounattendXml(xmlPath: string): ValidationResult {
        const result: ValidationResult = {
            isValid: true,
            errors: [],
            warnings: [],
            suggestions: []
        };

        try {
            if (!fs.existsSync(xmlPath)) {
                result.errors.push(`XML file not found: ${xmlPath}`);
                result.isValid = false;
                return result;
            }

            const content = fs.readFileSync(xmlPath, 'utf8');
            
            // Basic structure validation
            this.validateBasicStructure(content, result);
            
            // Windows component validation
            this.validateWindowsComponents(content, result);
            
            // Password security validation
            this.validatePasswordSecurity(content, result);
            
            // Performance optimization suggestions
            this.suggestOptimizations(content, result);

            if (result.errors.length > 0) {
                result.isValid = false;
            }

            return result;

        } catch (error) {
            result.errors.push(`Validation failed: ${(error as Error).message}`);
            result.isValid = false;
            return result;
        }
    }

    private validateBasicStructure(content: string, result: ValidationResult): void {
        // XML declaration
        if (!content.includes('<?xml version="1.0"')) {
            result.errors.push('Missing XML declaration');
        }

        // Root element
        if (!content.includes('<unattend xmlns="urn:schemas-microsoft-com:unattend">')) {
            result.errors.push('Missing or invalid unattend root element');
        }

        // Closing tag
        if (!content.includes('</unattend>')) {
            result.errors.push('Missing closing unattend tag');
        }

        // Check for common XML issues
        const openTags = (content.match(/<[^\/!?][^>]*>/g) || []).length;
        const closeTags = (content.match(/<\/[^>]*>/g) || []).length;
        
        if (openTags !== closeTags) {
            result.warnings.push('Potential tag mismatch detected');
        }

        // Check for placeholder remnants
        const placeholders = content.match(/\{\{[^}]+\}\}/g);
        if (placeholders) {
            result.errors.push(`Unreplaced placeholders found: ${placeholders.join(', ')}`);
        }
    }

    private validateWindowsComponents(content: string, result: ValidationResult): void {
        // Check for required components
        const requiredComponents = [
            'Microsoft-Windows-Setup',
            'Microsoft-Windows-Shell-Setup'
        ];

        for (const component of requiredComponents) {
            if (!content.includes(component)) {
                result.warnings.push(`Recommended component missing: ${component}`);
            }
        }

        // Check for deprecated components
        const deprecatedComponents = [
            'Microsoft-Windows-LUA-Settings',
            'Microsoft-Windows-OutOfBoxExperience'
        ];

        for (const component of deprecatedComponents) {
            if (content.includes(component)) {
                result.warnings.push(`Deprecated component found: ${component}`);
            }
        }

        // Validate architecture consistency
        const architectures = content.match(/processorArchitecture="([^"]+)"/g);
        if (architectures) {
            const uniqueArchs = [...new Set(architectures)];
            if (uniqueArchs.length > 1) {
                result.warnings.push('Multiple processor architectures detected - ensure consistency');
            }
        }
    }

    private validatePasswordSecurity(content: string, result: ValidationResult): void {
        // Check for plaintext passwords
        const passwordPattern = /<Password>([^<]+)<\/Password>/gi;
        const passwords = content.match(passwordPattern);
        
        if (passwords) {
            for (const password of passwords) {
                const passwordValue = password.replace(/<\/?Password>/g, '');
                
                // Check if password is Base64 encoded
                if (!this.isBase64(passwordValue)) {
                    result.warnings.push('Plaintext password detected - consider using Base64 encoding');
                }
                
                // Check for common weak passwords
                const weakPasswords = ['password', '123456', 'admin', 'user'];
                const decodedPassword = this.isBase64(passwordValue) ? 
                    Buffer.from(passwordValue, 'base64').toString() : passwordValue;
                
                if (weakPasswords.some(weak => decodedPassword.toLowerCase().includes(weak))) {
                    result.warnings.push('Weak password detected');
                }
            }
        }

        // Check for auto-logon without password
        if (content.includes('<AutoLogon>') && !content.includes('<Password>')) {
            result.warnings.push('Auto-logon enabled without password');
        }
    }

    private suggestOptimizations(content: string, result: ValidationResult): void {
        // Suggest enabling Windows Updates
        if (!content.includes('Microsoft-Windows-WindowsUpdateServices')) {
            result.suggestions.push('Consider adding Windows Update configuration');
        }

        // Suggest regional settings
        if (!content.includes('Microsoft-Windows-International')) {
            result.suggestions.push('Consider adding international/regional settings');
        }

        // Suggest disk configuration
        if (!content.includes('<DiskConfiguration>')) {
            result.suggestions.push('Consider adding explicit disk configuration');
        }

        // Check for error reporting settings
        if (!content.includes('DoNotSendAdditionalData')) {
            result.suggestions.push('Consider configuring Windows Error Reporting settings');
        }
    }

    private isBase64(str: string): boolean {
        try {
            return Buffer.from(str, 'base64').toString('base64') === str;
        } catch {
            return false;
        }
    }

    public generateValidationReport(result: ValidationResult): string {
        let report = '\n=== XML Validation Report ===\n';
        report += `Status: ${result.isValid ? '✅ VALID' : '❌ INVALID'}\n\n`;

        if (result.errors.length > 0) {
            report += '🚨 ERRORS:\n';
            result.errors.forEach(error => report += `  • ${error}\n`);
            report += '\n';
        }

        if (result.warnings.length > 0) {
            report += '⚠️  WARNINGS:\n';
            result.warnings.forEach(warning => report += `  • ${warning}\n`);
            report += '\n';
        }

        if (result.suggestions.length > 0) {
            report += '💡 SUGGESTIONS:\n';
            result.suggestions.forEach(suggestion => report += `  • ${suggestion}\n`);
            report += '\n';
        }

        report += '===========================\n';
        return report;
    }
}
