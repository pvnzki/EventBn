/**
 * Input Validation Utilities
 * 
 * Provides consistent validation functions across the application.
 */

// Email validation regex
const EMAIL_REGEX = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

// Phone validation regex (international format) - minimum 7 digits
const PHONE_REGEX = /^\+?[1-9]\d{6,14}$/;

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
  
  const trimmedEmail = email.toLowerCase().trim();
  if (!trimmedEmail) {
    throw new ValidationError('Email is required', 'email');
  }
  
  if (!EMAIL_REGEX.test(trimmedEmail)) {
    throw new ValidationError('Please provide a valid email address', 'email');
  }
  return trimmedEmail;
};

const validatePassword = (password) => {
  if (password === null || password === undefined) {
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
  
  const trimmedName = name.trim();
  if (!trimmedName || trimmedName.length === 0) {
    throw new ValidationError('Name is required', 'name');
  }
  if (trimmedName.length < 2) {
    throw new ValidationError('Name must be at least 2 characters long', 'name');
  }
  if (trimmedName.length > 255) {
    throw new ValidationError('Name must be less than 255 characters', 'name');
  }
  return trimmedName;
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

const validateUUID = (uuid, fieldName = 'UUID') => {
  if (!uuid || uuid === '') {
    throw new ValidationError(`Invalid UUID format`, fieldName.toLowerCase());
  }
  if (typeof uuid !== 'string') {
    throw new ValidationError(`${fieldName} must be a string`, fieldName.toLowerCase());
  }
  
  // UUID v4 regex pattern
  const UUID_REGEX = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
  
  if (!UUID_REGEX.test(uuid)) {
    throw new ValidationError(`Invalid UUID format`, fieldName.toLowerCase());
  }
  
  return uuid;
};

const validateEventData = (eventData) => {
  // Validate required fields first - this will throw specific errors
  validateRequired(eventData.title, 'title');
  validateRequired(eventData.description, 'description');
  validateRequired(eventData.start_time, 'start_time');
  validateRequired(eventData.end_time, 'end_time');
  validateRequired(eventData.venue, 'venue');
  validateRequired(eventData.location, 'location');
  validateRequired(eventData.category, 'category');
  
  // Validate dates
  const startTime = new Date(eventData.start_time);
  const endTime = new Date(eventData.end_time);
  
  if (isNaN(startTime.getTime())) {
    throw new ValidationError('Invalid start_time format', 'start_time');
  }
  if (isNaN(endTime.getTime())) {
    throw new ValidationError('Invalid end_time format', 'end_time');
  }
  
  if (startTime >= endTime) {
    throw new ValidationError('end_time must be after start_time', 'end_time');
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

/**
 * Sanitizes input to prevent XSS attacks
 * @param {any} input - Input to sanitize
 * @returns {any} Sanitized input
 */
const sanitizeInput = (input) => {
  if (typeof input !== 'string') {
    return input;
  }
  
  return input
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#x27;');
};

/**
 * Validates and normalizes pagination parameters
 * @param {Object} params - Pagination parameters
 * @param {string} params.page - Page number
 * @param {string} params.limit - Items per page
 * @returns {Object} Normalized pagination parameters
 */
const validatePageParams = (params = {}) => {
  const DEFAULT_PAGE = 1;
  const DEFAULT_LIMIT = 10;
  const MAX_LIMIT = 100;
  const MIN_LIMIT = 1;
  const MIN_PAGE = 1;

  // Parse and validate page
  let page = parseInt(params.page) || DEFAULT_PAGE;
  if (page < MIN_PAGE) {
    page = MIN_PAGE;
  }

  // Parse and validate limit
  let limit = parseInt(params.limit);
  if (isNaN(limit)) {
    limit = DEFAULT_LIMIT;
  }
  if (limit < MIN_LIMIT) {
    limit = MIN_LIMIT;
  }
  if (limit > MAX_LIMIT) {
    limit = MAX_LIMIT;
  }

  // Calculate offset
  const offset = (page - 1) * limit;

  return {
    page,
    limit,
    offset
  };
};

module.exports = {
  ValidationError,
  validateEmail,
  validatePassword,
  validateName,
  validatePhone,
  validateRequired,
  validateUUID,
  validateEventData,
  validateUserRegistration,
  validateLoginCredentials,
  sanitizeInput,
  validatePageParams,
  EMAIL_REGEX,
  PHONE_REGEX,
  PASSWORD_MIN_LENGTH
};