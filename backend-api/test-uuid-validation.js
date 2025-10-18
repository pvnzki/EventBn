const { validateUUID, ValidationError } = require('./lib/validation');

// Test cases for UUID validation
console.log('Testing UUID validation...\n');

// Test valid UUID
try {
  const validUUID = '550e8400-e29b-41d4-a716-446655440000';
  const result = validateUUID(validUUID, 'Test UUID');
  console.log('✅ Valid UUID passed:', result);
} catch (error) {
  console.log('❌ Valid UUID failed:', error.message);
}

// Test invalid UUID starting with 'm' (like the error)
try {
  const invalidUUID = 'm123456789';
  const result = validateUUID(invalidUUID, 'Test UUID');
  console.log('❌ Invalid UUID unexpectedly passed:', result);
} catch (error) {
  console.log('✅ Invalid UUID correctly rejected:', error.message);
}

// Test empty UUID
try {
  const emptyUUID = '';
  const result = validateUUID(emptyUUID, 'Test UUID');
  console.log('❌ Empty UUID unexpectedly passed:', result);
} catch (error) {
  console.log('✅ Empty UUID correctly rejected:', error.message);
}

// Test non-string UUID
try {
  const numberUUID = 123456;
  const result = validateUUID(numberUUID, 'Test UUID');
  console.log('❌ Number UUID unexpectedly passed:', result);
} catch (error) {
  console.log('✅ Number UUID correctly rejected:', error.message);
}

console.log('\nUUID validation tests completed.');