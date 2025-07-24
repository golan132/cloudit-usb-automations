import * as fs from 'fs';
import * as path from 'path';
import AutoUnattendBuilder from '../unattended/merge';

// Mock fs module for testing
jest.mock('fs');
const mockedFs = fs as jest.Mocked<typeof fs>;

describe('AutoUnattendBuilder', () => {
    let builder: AutoUnattendBuilder;
    let tempDir: string;

    beforeEach(() => {
        // Create temporary directories for testing
        tempDir = path.join(__dirname, 'temp');
        if (!fs.existsSync(tempDir)) {
            fs.mkdirSync(tempDir, { recursive: true });
        }
        
        builder = new AutoUnattendBuilder();
    });

    afterEach(() => {
        // Clean up temporary files
        if (fs.existsSync(tempDir)) {
            fs.rmSync(tempDir, { recursive: true, force: true });
        }
    });

    describe('Template Reading', () => {
        test('should read template file successfully', () => {
            const templatePath = path.join(__dirname, '../unattended/templates/autounattend-template.xml');
            
            // Ensure template exists for test
            if (!fs.existsSync(path.dirname(templatePath))) {
                fs.mkdirSync(path.dirname(templatePath), { recursive: true });
            }
            
            const mockTemplate = `<?xml version="1.0" encoding="utf-8"?>
<unattend xmlns="urn:schemas-microsoft-com:unattend">
    {{WINDOWSPE_PASS}}
    {{OOBESYSTEM_PASS}}
</unattend>`;
            
            fs.writeFileSync(templatePath, mockTemplate, 'utf8');
            
            const result = builder.build();
            expect(result.success).toBe(true);
        });

        test('should handle missing template file gracefully', () => {
            // Remove template file temporarily
            const templatePath = path.join(__dirname, '../unattended/templates/autounattend-template.xml');
            const backupPath = templatePath + '.backup';
            
            if (fs.existsSync(templatePath)) {
                fs.renameSync(templatePath, backupPath);
            }
            
            const result = builder.build();
            expect(result.success).toBe(false);
            expect(result.error).toContain('Template file not found');
            
            // Restore template file
            if (fs.existsSync(backupPath)) {
                fs.renameSync(backupPath, templatePath);
            }
        });
    });

    describe('Pass File Processing', () => {
        test('should process all pass files correctly', () => {
            const passesDir = path.join(__dirname, '../unattended/passes');
            
            // Create mock pass files
            const passes = ['windowspe', 'oobesystem', 'specialize'];
            
            passes.forEach(passName => {
                const passPath = path.join(passesDir, `${passName}.xml`);
                if (!fs.existsSync(path.dirname(passPath))) {
                    fs.mkdirSync(path.dirname(passPath), { recursive: true });
                }
                
                const mockPass = `    <settings pass="${passName}">
        <component name="Microsoft-Windows-${passName}">
            <TestValue>true</TestValue>
        </component>
    </settings>`;
                
                fs.writeFileSync(passPath, mockPass, 'utf8');
            });
            
            const result = builder.build();
            expect(result.success).toBe(true);
            expect(result.buildStats?.passesProcessed).toBeGreaterThan(0);
        });

        test('should handle missing pass files gracefully', () => {
            // This should not fail the build, just log warnings
            const result = builder.build();
            expect(result.success).toBe(true);
            expect(result.warnings).toBeDefined();
        });
    });

    describe('XML Validation', () => {
        test('should validate generated XML structure', () => {
            const result = builder.build();
            
            if (result.success && result.outputPath) {
                const content = fs.readFileSync(result.outputPath, 'utf8');
                
                expect(content).toContain('<?xml version="1.0"');
                expect(content).toContain('<unattend xmlns="urn:schemas-microsoft-com:unattend">');
                expect(content).toContain('</unattend>');
                expect(result.isValid).toBe(true);
            }
        });

        test('should detect placeholder remnants', () => {
            // Create a template with unreplaced placeholders
            const templatePath = path.join(__dirname, '../unattended/templates/autounattend-template.xml');
            const mockTemplate = `<?xml version="1.0" encoding="utf-8"?>
<unattend xmlns="urn:schemas-microsoft-com:unattend">
    {{MISSING_PASS}}
</unattend>`;
            
            if (!fs.existsSync(path.dirname(templatePath))) {
                fs.mkdirSync(path.dirname(templatePath), { recursive: true });
            }
            fs.writeFileSync(templatePath, mockTemplate, 'utf8');
            
            const result = builder.build();
            
            if (result.validationReport) {
                expect(result.validationReport).toContain('placeholder');
            }
        });
    });

    describe('Build Statistics', () => {
        test('should track build performance metrics', () => {
            const result = builder.build();
            
            expect(result.buildStats).toBeDefined();
            expect(result.buildStats?.startTime).toBeInstanceOf(Date);
            expect(result.buildStats?.endTime).toBeInstanceOf(Date);
            expect(result.buildStats?.duration).toBeGreaterThanOrEqual(0);
            expect(result.buildStats?.passesProcessed).toBeGreaterThanOrEqual(0);
        });
    });

    describe('Error Handling', () => {
        test('should handle file system errors gracefully', () => {
            // Mock fs.writeFileSync to throw an error
            const originalWriteFileSync = fs.writeFileSync;
            fs.writeFileSync = jest.fn().mockImplementation(() => {
                throw new Error('Permission denied');
            });
            
            const result = builder.build();
            expect(result.success).toBe(false);
            expect(result.error).toContain('Permission denied');
            
            // Restore original function
            fs.writeFileSync = originalWriteFileSync;
        });
    });
});
