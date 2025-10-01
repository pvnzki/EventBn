const validation = require('../../../lib/validation');

describe('Validation Library', () => {
  describe('ValidationError', () => {
    it('should create ValidationError with message and field', () => {
      const error = new validation.ValidationError('Test error', 'testField');
      
      expect(error.message).toBe('Test error');
      expect(error.field).toBe('testField');
      expect(error.name).toBe('ValidationError');
      expect(error).toBeInstanceOf(Error);
    });

    it('should create ValidationError with message only', () => {
      const error = new validation.ValidationError('Test error');
      
      expect(error.message).toBe('Test error');
      expect(error.field).toBeNull();
    });
  });

  describe('validateEmail', () => {
    it('should validate correct email addresses', () => {
      const validEmails = [
        'test@example.com',
        'user.name@domain.co.uk',
        'admin+tag@site.org',
        'test123@gmail.com'
      ];

      validEmails.forEach(email => {
        expect(validation.validateEmail(email)).toBe(email.toLowerCase().trim());
      });
    });

    it('should normalize email to lowercase and trim', () => {
      expect(validation.validateEmail('  TEST@EXAMPLE.COM  ')).toBe('test@example.com');
      expect(validation.validateEmail('User@Domain.COM')).toBe('user@domain.com');
    });

    it('should reject invalid email formats', () => {
      const invalidEmails = [
        'invalid-email',
        '@domain.com',
        'user@',
        'user@domain',
        'user.domain.com',
        'user@domain.',
        'user @domain.com',
        'user@domain .com'
      ];

      invalidEmails.forEach(email => {
        expect(() => validation.validateEmail(email))
          .toThrow('Please provide a valid email address');
      });
    });

    it('should reject empty or null email', () => {
      expect(() => validation.validateEmail('')).toThrow('Email is required');
      expect(() => validation.validateEmail(null)).toThrow('Email is required');
      expect(() => validation.validateEmail(undefined)).toThrow('Email is required');
    });

    it('should reject non-string email', () => {
      expect(() => validation.validateEmail(123)).toThrow('Email must be a string');
      expect(() => validation.validateEmail({})).toThrow('Email must be a string');
      expect(() => validation.validateEmail([])).toThrow('Email must be a string');
    });
  });

  describe('validatePassword', () => {
    it('should validate strong passwords', () => {
      const validPasswords = [
        'password123',
        'mySecurePass',
        'P@ssw0rd!',
        '123456' // Minimum length
      ];

      validPasswords.forEach(password => {
        expect(validation.validatePassword(password)).toBe(password);
      });
    });

    it('should reject short passwords', () => {
      const shortPasswords = ['12345', 'abc', '', 'a'];

      shortPasswords.forEach(password => {
        expect(() => validation.validatePassword(password))
          .toThrow('Password must be at least 6 characters long');
      });
    });

    it('should reject empty or null password', () => {
      expect(() => validation.validatePassword('')).toThrow('Password is required');
      expect(() => validation.validatePassword(null)).toThrow('Password is required');
      expect(() => validation.validatePassword(undefined)).toThrow('Password is required');
    });

    it('should reject non-string password', () => {
      expect(() => validation.validatePassword(123456)).toThrow('Password must be a string');
      expect(() => validation.validatePassword({})).toThrow('Password must be a string');
    });
  });

  describe('validateName', () => {
    it('should validate correct names', () => {
      const validNames = [
        'John Doe',
        'Alice',
        'Jean-Pierre',
        'Mary O\'Connor',
        'José María'
      ];

      validNames.forEach(name => {
        expect(validation.validateName(name)).toBe(name.trim());
      });
    });

    it('should trim whitespace from names', () => {
      expect(validation.validateName('  John Doe  ')).toBe('John Doe');
    });

    it('should reject empty or null names', () => {
      expect(() => validation.validateName('')).toThrow('Name is required');
      expect(() => validation.validateName(null)).toThrow('Name is required');
      expect(() => validation.validateName('   ')).toThrow('Name is required'); // Only whitespace
    });

    it('should reject non-string names', () => {
      expect(() => validation.validateName(123)).toThrow('Name must be a string');
      expect(() => validation.validateName({})).toThrow('Name must be a string');
    });

    it('should reject names that are too long', () => {
      const longName = 'a'.repeat(256); // Assuming max length is 255
      expect(() => validation.validateName(longName))
        .toThrow('Name must be less than 255 characters');
    });
  });

  describe('validatePhone', () => {
    it('should validate correct phone numbers', () => {
      const validPhones = [
        '+1234567890',
        '+441234567890',
        '+94771234567',
        '1234567890'
      ];

      validPhones.forEach(phone => {
        expect(validation.validatePhone(phone)).toBe(phone);
      });
    });

    it('should reject invalid phone numbers', () => {
      const invalidPhones = [
        'abc123',
        '123',
        '+123',
        'phone-number',
        '++1234567890',
        '+12345678901234567890' // Too long
      ];

      invalidPhones.forEach(phone => {
        expect(() => validation.validatePhone(phone))
          .toThrow('Please provide a valid phone number');
      });
    });

    it('should handle optional phone validation', () => {
      expect(validation.validatePhone('')).toBeNull();
      expect(validation.validatePhone(null)).toBeNull();
      expect(validation.validatePhone(undefined)).toBeNull();
    });
  });

  describe('validateUUID', () => {
    it('should validate correct UUIDs', () => {
      const validUUIDs = [
        '123e4567-e89b-12d3-a456-426614174000',
        'f47ac10b-58cc-4372-a567-0e02b2c3d479',
        '6ba7b810-9dad-11d1-80b4-00c04fd430c8'
      ];

      validUUIDs.forEach(uuid => {
        expect(validation.validateUUID(uuid)).toBe(uuid);
      });
    });

    it('should reject invalid UUIDs', () => {
      const invalidUUIDs = [
        'not-a-uuid',
        '123e4567-e89b-12d3-a456',
        '123e4567-e89b-12d3-a456-42661417400', // Wrong length
        '123e4567_e89b_12d3_a456_426614174000', // Wrong separators
        ''
      ];

      invalidUUIDs.forEach(uuid => {
        expect(() => validation.validateUUID(uuid))
          .toThrow('Invalid UUID format');
      });
    });
  });

  describe('validateEventData', () => {
    const validEventData = {
      title: 'Test Event',
      description: 'Test Description',
      start_time: '2024-12-01T10:00:00Z',
      end_time: '2024-12-01T12:00:00Z',
      venue: 'Test Venue',
      location: 'Test Location',
      category: 'Entertainment'
    };

    it('should validate correct event data', () => {
      expect(() => validation.validateEventData(validEventData)).not.toThrow();
    });

    it('should reject missing required fields', () => {
      const requiredFields = ['title', 'description', 'start_time', 'end_time', 'venue'];
      
      requiredFields.forEach(field => {
        const invalidData = { ...validEventData };
        delete invalidData[field];
        
        expect(() => validation.validateEventData(invalidData))
          .toThrow(`${field} is required`);
      });
    });

    it('should validate date formats', () => {
      const invalidData = {
        ...validEventData,
        start_time: 'invalid-date'
      };

      expect(() => validation.validateEventData(invalidData))
        .toThrow('Invalid start_time format');
    });

    it('should validate end_time is after start_time', () => {
      const invalidData = {
        ...validEventData,
        start_time: '2024-12-01T12:00:00Z',
        end_time: '2024-12-01T10:00:00Z'
      };

      expect(() => validation.validateEventData(invalidData))
        .toThrow('end_time must be after start_time');
    });
  });

  describe('sanitizeInput', () => {
    it('should sanitize string inputs', () => {
      expect(validation.sanitizeInput('<script>alert("xss")</script>'))
        .toBe('&lt;script&gt;alert(&quot;xss&quot;)&lt;/script&gt;');
    });

    it('should handle non-string inputs', () => {
      expect(validation.sanitizeInput(123)).toBe(123);
      expect(validation.sanitizeInput(null)).toBe(null);
      expect(validation.sanitizeInput(undefined)).toBe(undefined);
    });

    it('should preserve safe strings', () => {
      expect(validation.sanitizeInput('Safe text')).toBe('Safe text');
    });
  });

  describe('validatePageParams', () => {
    it('should validate and convert page parameters', () => {
      const result = validation.validatePageParams({ page: '2', limit: '10' });
      
      expect(result).toEqual({
        page: 2,
        limit: 10,
        offset: 10 // (page - 1) * limit
      });
    });

    it('should use default values for missing params', () => {
      const result = validation.validatePageParams({});
      
      expect(result).toEqual({
        page: 1,
        limit: 10,
        offset: 0
      });
    });

    it('should enforce maximum limit', () => {
      const result = validation.validatePageParams({ limit: '1000' });
      
      expect(result.limit).toBe(100); // Assuming max limit is 100
    });

    it('should enforce minimum values', () => {
      const result = validation.validatePageParams({ page: '-1', limit: '0' });
      
      expect(result.page).toBe(1);
      expect(result.limit).toBe(1);
    });
  });
});