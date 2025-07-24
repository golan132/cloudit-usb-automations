// Performance monitoring and benchmarking utilities
import * as fs from 'fs';
import * as path from 'path';
import { logger } from './logger';

export interface PerformanceMetrics {
    operation: string;
    startTime: number;
    endTime: number;
    duration: number;
    memoryUsage: {
        before: NodeJS.MemoryUsage;
        after: NodeJS.MemoryUsage;
        peak: number;
    };
    success: boolean;
    metadata?: Record<string, any>;
}

export interface BenchmarkSuite {
    name: string;
    metrics: PerformanceMetrics[];
    totalDuration: number;
    averageDuration: number;
    successRate: number;
}

export class PerformanceMonitor {
    private metrics: PerformanceMetrics[] = [];
    private benchmarkHistory: string;

    constructor() {
        this.benchmarkHistory = path.join(process.cwd(), 'logs', 'benchmarks.json');
        this.ensureBenchmarkDir();
    }

    private ensureBenchmarkDir(): void {
        const dir = path.dirname(this.benchmarkHistory);
        if (!fs.existsSync(dir)) {
            fs.mkdirSync(dir, { recursive: true });
        }
    }

    public startMeasurement(operation: string, metadata?: Record<string, any>): () => PerformanceMetrics {
        const startTime = performance.now();
        const memoryBefore = process.memoryUsage();

        return (): PerformanceMetrics => {
            const endTime = performance.now();
            const memoryAfter = process.memoryUsage();
            const duration = endTime - startTime;

            const metric: PerformanceMetrics = {
                operation,
                startTime,
                endTime,
                duration,
                memoryUsage: {
                    before: memoryBefore,
                    after: memoryAfter,
                    peak: Math.max(memoryBefore.heapUsed, memoryAfter.heapUsed)
                },
                success: true,
                metadata
            };

            this.metrics.push(metric);
            this.logMetric(metric);
            return metric;
        };
    }

    public markFailure(operation: string): void {
        const lastMetric = this.metrics.find(m => m.operation === operation && m.endTime === 0);
        if (lastMetric) {
            lastMetric.success = false;
            lastMetric.endTime = performance.now();
            lastMetric.duration = lastMetric.endTime - lastMetric.startTime;
        }
    }

    private logMetric(metric: PerformanceMetrics): void {
        const memoryDelta = metric.memoryUsage.after.heapUsed - metric.memoryUsage.before.heapUsed;
        const memoryDeltaMB = (memoryDelta / 1024 / 1024).toFixed(2);
        
        logger.info(
            `Operation: ${metric.operation} | Duration: ${metric.duration.toFixed(2)}ms | Memory: ${memoryDeltaMB}MB | Success: ${metric.success}`,
            'PerformanceMonitor'
        );
    }

    public getSummary(): BenchmarkSuite {
        const totalDuration = this.metrics.reduce((sum, m) => sum + m.duration, 0);
        const successCount = this.metrics.filter(m => m.success).length;
        
        return {
            name: `Benchmark-${new Date().toISOString()}`,
            metrics: [...this.metrics],
            totalDuration,
            averageDuration: this.metrics.length > 0 ? totalDuration / this.metrics.length : 0,
            successRate: this.metrics.length > 0 ? (successCount / this.metrics.length) * 100 : 0
        };
    }

    public saveBenchmarkResults(suite: BenchmarkSuite): void {
        try {
            let history: BenchmarkSuite[] = [];
            
            if (fs.existsSync(this.benchmarkHistory)) {
                const existingData = fs.readFileSync(this.benchmarkHistory, 'utf8');
                history = JSON.parse(existingData);
            }
            
            history.push(suite);
            
            // Keep only the last 100 benchmark runs
            if (history.length > 100) {
                history = history.slice(-100);
            }
            
            fs.writeFileSync(this.benchmarkHistory, JSON.stringify(history, null, 2), 'utf8');
            logger.info(`Benchmark results saved: ${this.benchmarkHistory}`, 'PerformanceMonitor');
        } catch (error) {
            logger.error('Failed to save benchmark results', error as Error, 'PerformanceMonitor');
        }
    }

    public generatePerformanceReport(): string {
        const suite = this.getSummary();
        
        let report = '\n=== Performance Report ===\n';
        report += `Suite: ${suite.name}\n`;
        report += `Total Operations: ${suite.metrics.length}\n`;
        report += `Total Duration: ${suite.totalDuration.toFixed(2)}ms\n`;
        report += `Average Duration: ${suite.averageDuration.toFixed(2)}ms\n`;
        report += `Success Rate: ${suite.successRate.toFixed(1)}%\n\n`;
        
        // Slowest operations
        const slowest = [...suite.metrics]
            .sort((a, b) => b.duration - a.duration)
            .slice(0, 5);
        
        if (slowest.length > 0) {
            report += 'Slowest Operations:\n';
            slowest.forEach((metric, index) => {
                report += `  ${index + 1}. ${metric.operation}: ${metric.duration.toFixed(2)}ms\n`;
            });
            report += '\n';
        }
        
        // Memory usage analysis
        const memoryMetrics = suite.metrics.map(m => ({
            operation: m.operation,
            memoryDelta: m.memoryUsage.after.heapUsed - m.memoryUsage.before.heapUsed
        }));
        
        const highestMemory = memoryMetrics
            .sort((a, b) => b.memoryDelta - a.memoryDelta)[0];
        
        if (highestMemory) {
            report += `Highest Memory Usage: ${highestMemory.operation} (${(highestMemory.memoryDelta / 1024 / 1024).toFixed(2)}MB)\n`;
        }
        
        report += '========================\n';
        return report;
    }

    public clear(): void {
        this.metrics = [];
    }
}

// Singleton instance
export const performanceMonitor = new PerformanceMonitor();

// Decorator for automatic performance monitoring
export function monitor(operation?: string) {
    return function (target: any, propertyName: string, descriptor: PropertyDescriptor) {
        const method = descriptor.value;
        const operationName = operation || `${target.constructor.name}.${propertyName}`;

        descriptor.value = function (...args: any[]) {
            const stopMeasurement = performanceMonitor.startMeasurement(operationName);
            
            try {
                const result = method.apply(this, args);
                
                // Handle async methods
                if (result && typeof result.then === 'function') {
                    return result
                        .then((value: any) => {
                            stopMeasurement();
                            return value;
                        })
                        .catch((error: any) => {
                            performanceMonitor.markFailure(operationName);
                            throw error;
                        });
                }
                
                stopMeasurement();
                return result;
            } catch (error) {
                performanceMonitor.markFailure(operationName);
                throw error;
            }
        };
    };
}
