import * as fs from 'fs';
import * as path from 'path';

// Simple test functions to replace Jest
function describe(name: string, fn: () => void): void {
    console.log(`\n=== ${name} ===`);
    fn();
}

function test(name: string, fn: () => void): void {
    try {
        console.log(`  Testing: ${name}`);
        fn();
        console.log(`  ✓ PASSED`);
    } catch (error) {
        console.log(`  ❌ FAILED: ${(error as Error).message}`);
    }
}

function beforeEach(fn: () => void): void {
    fn();
}

function afterEach(fn: () => void): void {
    fn();
}

// Simple assertion functions
const expect = (actual: any) => ({
    toBe: (expected: any) => {
        if (actual !== expected) {
            throw new Error(`Expected ${actual} to be ${expected}`);
        }
    },
    toContain: (expected: string) => {
        if (typeof actual !== 'string' || !actual.includes(expected)) {
            throw new Error(`Expected "${actual}" to contain "${expected}"`);
        }
    },
    toBeDefined: () => {
        if (actual === undefined) {
            throw new Error(`Expected value to be defined`);
        }
    },
    toBeInstanceOf: (constructor: any) => {
        if (!(actual instanceof constructor)) {
            throw new Error(`Expected ${actual} to be instance of ${constructor.name}`);
        }
    },
    toBeGreaterThan: (expected: number) => {
        if (actual <= expected) {
            throw new Error(`Expected ${actual} to be greater than ${expected}`);
        }
    },
    toBeGreaterThanOrEqual: (expected: number) => {
        if (actual < expected) {
            throw new Error(`Expected ${actual} to be greater than or equal to ${expected}`);
        }
    }
});

// Import the class we want to test
import AutoUnattendBuilder from '../unattended/merge';

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
            if (result.buildStats) {
                expect(result.buildStats.passesProcessed).toBeGreaterThan(0);
            }
        });
    });

    describe('XML Validation', () => {
        test('should validate generated XML structure', () => {
            // Setup template first
            const templatePath = path.join(__dirname, '../unattended/templates/autounattend-template.xml');
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
            
            if (result.success && result.outputPath) {
                const content = fs.readFileSync(result.outputPath, 'utf8');
                
                expect(content).toContain('<?xml version="1.0"');
                expect(content).toContain('<unattend xmlns="urn:schemas-microsoft-com:unattend">');
                expect(content).toContain('</unattend>');
                expect(result.isValid).toBe(true);
            }
        });
    });

    describe('Build Statistics', () => {
        test('should track build performance metrics', () => {
            // Setup template
            const templatePath = path.join(__dirname, '../unattended/templates/autounattend-template.xml');
            if (!fs.existsSync(path.dirname(templatePath))) {
                fs.mkdirSync(path.dirname(templatePath), { recursive: true });
            }
            
            const mockTemplate = `<?xml version="1.0" encoding="utf-8"?>
<unattend xmlns="urn:schemas-microsoft-com:unattend">
</unattend>`;
            
            fs.writeFileSync(templatePath, mockTemplate, 'utf8');
            
            const result = builder.build();
            
            expect(result.buildStats).toBeDefined();
            if (result.buildStats) {
                expect(result.buildStats.startTime).toBeInstanceOf(Date);
                expect(result.buildStats.endTime).toBeInstanceOf(Date);
                expect(result.buildStats.duration).toBeGreaterThanOrEqual(0);
                expect(result.buildStats.passesProcessed).toBeGreaterThanOrEqual(0);
            }
        });
    });
});

// Run the tests
console.log('Running AutoUnattendBuilder Tests...');
describe('AutoUnattendBuilder', () => {
    let builder: AutoUnattendBuilder;
    let tempDir: string;

    beforeEach(() => {
        tempDir = path.join(__dirname, 'temp');
        if (!fs.existsSync(tempDir)) {
            fs.mkdirSync(tempDir, { recursive: true });
        }
        builder = new AutoUnattendBuilder();
    });

    afterEach(() => {
        if (fs.existsSync(tempDir)) {
            fs.rmSync(tempDir, { recursive: true, force: true });
        }
    });

    describe('Template Reading', () => {
        test('should read template file successfully', () => {
            const templatePath = path.join(__dirname, '../unattended/templates/autounattend-template.xml');
            
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
    });

    describe('Build Statistics', () => {
        test('should track build performance metrics', () => {
            const templatePath = path.join(__dirname, '../unattended/templates/autounattend-template.xml');
            if (!fs.existsSync(path.dirname(templatePath))) {
                fs.mkdirSync(path.dirname(templatePath), { recursive: true });
            }
            
            const mockTemplate = `<?xml version="1.0" encoding="utf-8"?>
<unattend xmlns="urn:schemas-microsoft-com:unattend">
</unattend>`;
            
            fs.writeFileSync(templatePath, mockTemplate, 'utf8');
            
            const result = builder.build();
            
            expect(result.buildStats).toBeDefined();
            if (result.buildStats) {
                expect(result.buildStats.startTime).toBeInstanceOf(Date);
                expect(result.buildStats.endTime).toBeInstanceOf(Date);
                expect(result.buildStats.duration).toBeGreaterThanOrEqual(0);
            }
        });
    });
});

console.log('\nTest run completed!');
