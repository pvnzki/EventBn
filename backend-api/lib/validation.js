/**
 * Input Validation Utilities
 * 
 * Provides consistent validation functions across the application.
 */

// Email validation regex
const EMAIL_REGEX = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

// Phone validation regex (international format)
const PHONE_REGEX = /^\+?[1-9]\d{1,14}$/;

// Password validation
const PASSWORD_MIN_LENGTH = 6;

class ValidationError extends Error {
  constructor(message, field = null) {
    super(message);
    this.name = 'ValidationError';
    this.field = field;
  }
}

const validateEmail = (email) => {
  if (!email) {
    throw new ValidationError('Email is required', 'email');
  }
  if (typeof email !== 'string') {
    throw new ValidationError('Email must be a string', 'email');
  }
  if (!EMAIL_REGEX.test(email)) {
    throw new ValidationError('Please provide a valid email address', 'email');
  }
  return email.toLowerCase().trim();
};

const validatePassword = (password) => {
  if (!password) {
    throw new ValidationError('Password is required', 'password');
  }
  if (typeof password !== 'string') {
    throw new ValidationError('Password must be a string', 'password');
  }
  if (password.length < PASSWORD_MIN_LENGTH) {
    throw new ValidationError(`Password must be at least ${PASSWORD_MIN_LENGTH} characters long`, 'password');
  }
  return password;
};

const validateName = (name) => {
  if (!name) {
    throw new ValidationError('Name is required', 'name');
  }
  if (typeof name !== 'string') {
    throw new ValidationError('Name must be a string', 'name');
  }
  if (name.trim().length < 2) {
    throw new ValidationError('Name must be at least 2 characters long', 'name');
  }
  return name.trim();
};

const validatePhone = (phone) => {
  if (!phone) {
    return null; // Phone is optional
  }
  if (typeof phone !== 'string') {
    throw new ValidationError('Phone number must be a string', 'phone');
  }
  if (!PHONE_REGEX.test(phone)) {
    throw new ValidationError('Please provide a valid phone number', 'phone');
  }
  return phone;
};

const validateRequired = (value, fieldName) => {
  if (value === undefined || value === null || value === '') {
    throw new ValidationError(`${fieldName} is required`, fieldName.toLowerCase());
  }
  return value;
};

const validateEventData = (eventData) => {
  const errors = [];
  
  try {
    validateRequired(eventData.name, 'Name');
    validateRequired(eventData.description, 'Description');
    validateRequired(eventData.start_date, 'Start date');
    validateRequired(eventData.end_date, 'End date');
    validateRequired(eventData.venue, 'Venue');
    validateRequired(eventData.event_type, 'Event type');
    
    // Validate dates
    const startDate = new Date(eventData.start_date);
    const endDate = new Date(eventData.end_date);
    
    if (isNaN(startDate.getTime())) {
      errors.push({ field: 'start_date', message: 'Invalid start date format' });
    }
    if (isNaN(endDate.getTime())) {
      errors.push({ field: 'end_date', message: 'Invalid end date format' });
    }
    
    if (startDate >= endDate) {
      errors.push({ field: 'end_date', message: 'End date must be after start date' });
    }
    
    // Validate event type
    const validEventTypes = ['CONFERENCE', 'CONCERT', 'WORKSHOP', 'MEETUP', 'SEMINAR', 'OTHER'];
    if (!validEventTypes.includes(eventData.event_type)) {
      errors.push({ field: 'event_type', message: 'Invalid event type' });
    }
    
  } catch (error) {
    errors.push({ field: error.field, message: error.message });
  }
  
  if (errors.length > 0) {
    const error = new ValidationError('Validation failed');
    error.errors = errors;
    throw error;
  }
  
  return true;
};

const validateUserRegistration = (userData) => {
  const errors = [];
  
  try {
    validateEmail(userData.email);
  } catch (error) {
    errors.push({ field: error.field, message: error.message });
  }
  
  try {
    validatePassword(userData.password);
  } catch (error) {
    errors.push({ field: error.field, message: error.message });
  }
  
  try {
    validateName(userData.name);
  } catch (error) {
    errors.push({ field: error.field, message: error.message });
  }
  
  try {
    validatePhone(userData.phone);
  } catch (error) {
    errors.push({ field: error.field, message: error.message });
  }
  
  if (errors.length > 0) {
    const error = new ValidationError('Validation failed');
    error.errors = errors;
    throw error;
  }
  
  return true;
};

const validateLoginCredentials = (credentials) => {
  const errors = [];
  
  try {
    validateEmail(credentials.email);
  } catch (error) {
    errors.push({ field: error.field, message: error.message });
  }
  
  try {
    validateRequired(credentials.password, 'Password');
  } catch (error) {
    errors.push({ field: error.field, message: error.message });
  }
  
  if (errors.length > 0) {
    const error = new ValidationError('Validation failed');
    error.errors = errors;
    throw error;
  }
  
  return true;
};

module.exports = {
  ValidationError,
  validateEmail,
  validatePassword,
  validateName,
  validatePhone,
  validateRequired,
  validateEventData,
  validateUserRegistration,
  validateLoginCredentials,
  EMAIL_REGEX,
  PHONE_REGEX,
  PASSWORD_MIN_LENGTH
};