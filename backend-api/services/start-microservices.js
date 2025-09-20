#!/usr/bin/env node

/**
 * EventBn Microservices Startup Script
 * Starts both core-service and post-service as separate processes
 */

const { spawn } = require('child_process');
const path = require('path');
const fs = require('fs');

// Configuration
const SERVICES = {
  'core-service': {
    port: process.env.CORE_SERVICE_PORT || 3001,
    dir: path.join(__dirname, 'core-service'),
    script: 'server.js',
    env: {
      ...process.env,
      NODE_ENV: process.env.NODE_ENV || 'development',
      CORE_SERVICE_PORT: process.env.CORE_SERVICE_PORT || 3001,
      INTER_SERVICE_KEY: process.env.INTER_SERVICE_KEY || 'dev-service-key'
    }
  },
  'post-service': {
    port: process.env.POST_SERVICE_PORT || 3002,
    dir: path.join(__dirname, 'post-service'),
    script: 'server.js',
    env: {
      ...process.env,
      NODE_ENV: process.env.NODE_ENV || 'development',
      POST_SERVICE_PORT: process.env.POST_SERVICE_PORT || 3002,
      CORE_SERVICE_URL: process.env.CORE_SERVICE_URL || 'http://localhost:3001',
      INTER_SERVICE_KEY: process.env.INTER_SERVICE_KEY || 'dev-service-key'
    }
  }
};

const processes = new Map();

// Utility functions
const log = (service, message, type = 'info') => {
  const timestamp = new Date().toISOString();
  const colors = {
    info: '\x1b[36m',    // Cyan
    error: '\x1b[31m',   // Red
    success: '\x1b[32m', // Green
    warn: '\x1b[33m',    // Yellow
    reset: '\x1b[0m'
  };
  
  console.log(`${colors[type]}[${timestamp}] [${service.toUpperCase()}] ${message}${colors.reset}`);
};

const checkPort = (port) => {
  return new Promise((resolve) => {
    const net = require('net');
    const server = net.createServer();
    
    server.listen(port, () => {
      server.once('close', () => resolve(true));
      server.close();
    });
    
    server.on('error', () => resolve(false));
  });
};

const waitForService = (url, maxRetries = 60, interval = 1000) => {
  return new Promise((resolve, reject) => {
    const http = require('http');
    let retries = 0;
    
    const check = () => {
      const urlObj = new URL(url);
      const options = {
        hostname: urlObj.hostname,
        port: urlObj.port,
        path: urlObj.pathname,
        method: 'GET',
        timeout: 2000
      };
      
      const req = http.request(options, (res) => {
        let data = '';
        res.on('data', chunk => data += chunk);
        res.on('end', () => {
          if (res.statusCode >= 200 && res.statusCode < 400) {
            log('SYSTEM', `✅ Service at ${url} is ready (${res.statusCode})`, 'success');
            resolve(true);
          } else {
            handleRetry(`HTTP ${res.statusCode}`);
          }
        });
      });
      
      req.on('error', (err) => {
        handleRetry(`Connection error: ${err.code || err.message}`);
      });
      
      req.on('timeout', () => {
        req.destroy();
        handleRetry('Request timeout');
      });
      
      req.setTimeout(2000);
      req.end();
    };
    
    const handleRetry = (error) => {
      retries++;
      if (retries >= maxRetries) {
        reject(new Error(`Service at ${url} not ready after ${maxRetries} attempts. Last error: ${error}`));
      } else {
        if (retries === 1 || retries % 10 === 0) {
          log('SYSTEM', `⏳ Waiting for service (attempt ${retries}/${maxRetries})...`, 'info');
        }
        setTimeout(check, interval);
      }
    };
    
    // Wait a bit before first check to let service start
    setTimeout(check, 3000);
  });
};

// Service management functions
const startService = async (serviceName) => {
  const config = SERVICES[serviceName];
  
  // Check if port is available
  const portAvailable = await checkPort(config.port);
  if (!portAvailable) {
    log(serviceName, `Port ${config.port} is already in use`, 'error');
    return false;
  }
  
  // Check if service directory and script exist
  const scriptPath = path.join(config.dir, config.script);
  if (!fs.existsSync(scriptPath)) {
    log(serviceName, `Script not found: ${scriptPath}`, 'error');
    return false;
  }
  
  log(serviceName, `Starting service on port ${config.port}...`);
  
  const child = spawn('node', [config.script], {
    cwd: config.dir,
    env: config.env,
    stdio: ['inherit', 'pipe', 'pipe']
  });
  
  // Store process reference
  processes.set(serviceName, child);
  
  // Handle stdout
  child.stdout.on('data', (data) => {
    const output = data.toString().trim();
    if (output) {
      log(serviceName, output);
    }
  });
  
  // Handle stderr
  child.stderr.on('data', (data) => {
    const error = data.toString().trim();
    if (error) {
      log(serviceName, error, 'error');
    }
  });
  
  // Handle process exit
  child.on('exit', (code, signal) => {
    processes.delete(serviceName);
    if (code === 0) {
      log(serviceName, 'Process exited normally', 'info');
    } else {
      log(serviceName, `Process exited with code ${code} (signal: ${signal})`, 'error');
    }
  });
  
  child.on('error', (error) => {
    log(serviceName, `Failed to start: ${error.message}`, 'error');
    processes.delete(serviceName);
  });
  
  return true;
};

const stopService = (serviceName) => {
  const process = processes.get(serviceName);
  if (process) {
    log(serviceName, 'Stopping service...');
    process.kill('SIGTERM');
    
    // Force kill after 10 seconds
    setTimeout(() => {
      if (processes.has(serviceName)) {
        log(serviceName, 'Force killing process...', 'warn');
        process.kill('SIGKILL');
      }
    }, 10000);
  }
};

const stopAllServices = () => {
  log('SYSTEM', 'Shutting down all services...');
  
  for (const serviceName of processes.keys()) {
    stopService(serviceName);
  }
  
  // Exit after all services are stopped
  setTimeout(() => {
    if (processes.size === 0) {
      log('SYSTEM', 'All services stopped. Goodbye!', 'success');
      process.exit(0);
    }
  }, 5000);
};

// Main startup function
const startMicroservices = async () => {
  console.log(`
\x1b[36m╔════════════════════════════════════════╗\x1b[0m
\x1b[36m║        EventBn Microservices           ║\x1b[0m
\x1b[36m║         Startup Manager                ║\x1b[0m
\x1b[36m╚════════════════════════════════════════╝\x1b[0m
`);
  
  log('SYSTEM', 'Starting EventBn microservices...', 'success');
  
  try {
    // Start core-service first
    log('SYSTEM', 'Starting core-service (dependency)...');
    const coreStarted = await startService('core-service');
    
    if (!coreStarted) {
      log('SYSTEM', 'Failed to start core-service', 'error');
      process.exit(1);
    }
    
    // Wait for core-service to be ready
    log('SYSTEM', 'Waiting for core-service to be ready...');
    try {
      await waitForService('http://localhost:3001/health');
      log('SYSTEM', 'Core-service is ready!', 'success');
    } catch (error) {
      log('SYSTEM', `Core-service health check failed: ${error.message}`, 'error');
      throw error;
    }
    
    // Start post-service
    log('SYSTEM', 'Starting post-service...');
    const postStarted = await startService('post-service');
    
    if (!postStarted) {
      log('SYSTEM', 'Failed to start post-service', 'error');
      stopService('core-service');
      process.exit(1);
    }
    
    // Wait for post-service to be ready
    log('SYSTEM', 'Waiting for post-service to be ready...');
    try {
      await waitForService('http://localhost:3002/health');
      log('SYSTEM', 'Post-service is ready!', 'success');
    } catch (error) {
      log('SYSTEM', `Post-service health check failed: ${error.message}`, 'error');
      throw error;
    }
    
    console.log(`
\x1b[32m╔════════════════════════════════════════╗\x1b[0m
\x1b[32m║     🚀 All Services Started! 🚀       ║\x1b[0m
\x1b[32m╠════════════════════════════════════════╣\x1b[0m
\x1b[32m║ Core Service:  http://localhost:3001   ║\x1b[0m
\x1b[32m║ Post Service:  http://localhost:3002   ║\x1b[0m
\x1b[32m║                                        ║\x1b[0m
\x1b[32m║ Health Checks:                         ║\x1b[0m
\x1b[32m║ - Core: http://localhost:3001/health   ║\x1b[0m
\x1b[32m║ - Post: http://localhost:3002/health   ║\x1b[0m
\x1b[32m╚════════════════════════════════════════╝\x1b[0m

\x1b[33mPress Ctrl+C to stop all services\x1b[0m
`);
    
  } catch (error) {
    log('SYSTEM', `Startup failed: ${error.message}`, 'error');
    stopAllServices();
    process.exit(1);
  }
};

// Handle graceful shutdown
process.on('SIGINT', stopAllServices);
process.on('SIGTERM', stopAllServices);

// Handle uncaught exceptions
process.on('uncaughtException', (error) => {
  log('SYSTEM', `Uncaught Exception: ${error.message}`, 'error');
  stopAllServices();
});

process.on('unhandledRejection', (reason, promise) => {
  log('SYSTEM', `Unhandled Rejection at: ${promise}, reason: ${reason}`, 'error');
  stopAllServices();
});

// Start the services
startMicroservices();