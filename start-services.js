const { spawn } = require('child_process');
const path = require('path');

const services = [
  {
    name: 'Core Service',
    port: 3001,
    directory: path.join(__dirname, 'backend-api', 'services', 'core-service'),
    command: 'npm',
    args: ['start']
  },
  {
    name: 'Post Service', 
    port: 3002,
    directory: path.join(__dirname, 'backend-api', 'services', 'post-service'),
    command: 'npm',
    args: ['start']
  }
];

let runningProcesses = [];

function startService(service) {
  console.log(`🚀 Starting ${service.name} on port ${service.port}...`);
  
  const process = spawn(service.command, service.args, {
    cwd: service.directory,
    stdio: ['inherit', 'pipe', 'pipe'],
    shell: true
  });

  process.stdout.on('data', (data) => {
    console.log(`[${service.name}] ${data.toString().trim()}`);
  });

  process.stderr.on('data', (data) => {
    console.error(`[${service.name} ERROR] ${data.toString().trim()}`);
  });

  process.on('close', (code) => {
    console.log(`[${service.name}] Process exited with code ${code}`);
  });

  process.on('error', (error) => {
    console.error(`[${service.name}] Failed to start: ${error.message}`);
  });

  runningProcesses.push(process);
  return process;
}

function gracefulShutdown() {
  console.log('\\n🛑 Shutting down services...');
  runningProcesses.forEach(process => {
    if (process && !process.killed) {
      process.kill('SIGTERM');
    }
  });
  process.exit(0);
}

// Handle shutdown signals
process.on('SIGINT', gracefulShutdown);
process.on('SIGTERM', gracefulShutdown);

async function startAllServices() {
  console.log('🎬 EventBn Microservices Startup Script');
  console.log('======================================\\n');

  // Start each service with a delay
  for (let i = 0; i < services.length; i++) {
    const service = services[i];
    startService(service);
    
    if (i < services.length - 1) {
      console.log(`⏱️  Waiting 3 seconds before starting next service...\\n`);
      await new Promise(resolve => setTimeout(resolve, 3000));
    }
  }

  console.log('\\n✅ All services started!');
  console.log('Press Ctrl+C to stop all services');
}

startAllServices().catch(console.error);