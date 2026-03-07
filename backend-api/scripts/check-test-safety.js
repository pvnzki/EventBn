#!/usr/bin/env node

/**
 * Database Safety Check for Tests
 * 
 * This script verifies that test configuration won't affect production data
 */

require('dotenv').config({ path: '.env.test' });

const chalk = require('chalk');

function checkTestSafety() {
  console.log(chalk.blue('🔍 Checking test environment safety...'));
  
  const issues = [];
  
  // Check 1: NODE_ENV should be test
  if (process.env.NODE_ENV !== 'test') {
    issues.push('NODE_ENV is not set to "test"');
  }
  
  // Check 2: Database URL should not be production
  const dbUrl = process.env.DATABASE_URL;
  if (!dbUrl) {
    issues.push('DATABASE_URL is not configured');
  } else if (dbUrl.includes('supabase.com')) {
    issues.push('DATABASE_URL points to Supabase (potential production data)');
  } else if (dbUrl === 'PLEASE_SET_UP_A_SEPARATE_TEST_DATABASE') {
    issues.push('DATABASE_URL still has placeholder value');
  }
  
  // Check 3: Direct URL should match
  const directUrl = process.env.DIRECT_URL;
  if (!directUrl) {
    issues.push('DIRECT_URL is not configured');
  } else if (directUrl.includes('supabase.com')) {
    issues.push('DIRECT_URL points to Supabase (potential production data)');
  }
  
  // Check 4: Test mode should be enabled
  if (process.env.TEST_MODE !== 'true') {
    issues.push('TEST_MODE is not enabled');
  }
  
  if (issues.length > 0) {
    console.log(chalk.red('❌ SAFETY CHECK FAILED!'));
    console.log(chalk.red('The following issues could result in data loss:'));
    issues.forEach(issue => {
      console.log(chalk.red(`  • ${issue}`));
    });
    console.log(chalk.yellow('\n💡 To fix these issues:'));
    console.log(chalk.yellow('1. Ensure .env.test is properly configured'));
    console.log(chalk.yellow('2. Use a separate test database (SQLite recommended)'));
    console.log(chalk.yellow('3. Never use production database URLs in tests'));
    
    process.exit(1);
  }
  
  console.log(chalk.green('✅ Safety check passed!'));
  console.log(chalk.green('📦 Test database:'), process.env.DATABASE_URL);
  console.log(chalk.green('🧪 Test mode enabled:'), process.env.TEST_MODE);
  console.log(chalk.green('\n🚀 Safe to run tests!'));
}

if (require.main === module) {
  checkTestSafety();
}

module.exports = checkTestSafety;