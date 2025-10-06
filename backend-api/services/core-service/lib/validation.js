/**
 * Input Validation Utilities
 * 
 * Provides consistent validation functions across the application.
 */

// Custom validation error class
class ValidationError extends Error {
    constructor(message, field = null) {
        super(message);
        this.name = 'ValidationError';
        this.field = field;
    }
}

// Email validation regex
const EMAIL_REGEX = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

// Phone validation regex (international format)
const PHONE_REGEX = /^\+?[\d\s\-\(\)]+$/;

// Password validation (at least 8 characters, 1 uppercase, 1 lowercase, 1 number)
const PASSWORD_REGEX = /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)[a-zA-Z\d@$!%*?&]{8,}$/;

// MongoDB ObjectId validation
const OBJECT_ID_REGEX = /^[0-9a-fA-F]{24}$/;

/**
 * Validates email format
 * @param {string} email - Email to validate
 * @returns {boolean} - True if valid email format
 */
function isValidEmail(email) {
    if (!email || typeof email !== 'string') return false;
    return EMAIL_REGEX.test(email.trim());
}

/**
 * Validates phone number format
 * @param {string} phone - Phone number to validate
 * @returns {boolean} - True if valid phone format
 */
function isValidPhone(phone) {
    if (!phone || typeof phone !== 'string') return false;
    return PHONE_REGEX.test(phone.trim());
}

/**
 * Validates password strength
 * @param {string} password - Password to validate
 * @returns {boolean} - True if password meets requirements
 */
function isValidPassword(password) {
    if (!password || typeof password !== 'string') return false;
    return PASSWORD_REGEX.test(password);
}

/**
 * Validates MongoDB ObjectId format
 * @param {string} id - ID to validate
 * @returns {boolean} - True if valid ObjectId format
 */
function isValidObjectId(id) {
    if (!id || typeof id !== 'string') return false;
    return OBJECT_ID_REGEX.test(id);
}

/**
 * Validates required fields in an object
 * @param {object} obj - Object to validate
 * @param {string[]} requiredFields - Array of required field names
 * @returns {object} - { isValid: boolean, missingFields: string[] }
 */
function validateRequiredFields(obj, requiredFields) {
    const missingFields = [];
    
    for (const field of requiredFields) {
        if (!obj || obj[field] === undefined || obj[field] === null || obj[field] === '') {
            missingFields.push(field);
        }
    }
    
    return {
        isValid: missingFields.length === 0,
        missingFields
    };
}

/**
 * Sanitizes string input by trimming and removing dangerous characters
 * @param {string} input - Input string to sanitize
 * @returns {string} - Sanitized string
 */
function sanitizeString(input) {
    if (!input || typeof input !== 'string') return '';
    
    return input
        .trim()
        .replace(/[<>]/g, '') // Remove potential HTML tags
        .substring(0, 1000); // Limit length
}

/**
 * Validates and sanitizes user input for registration
 * @param {object} userData - User data object
 * @returns {object} - { isValid: boolean, errors: string[], sanitizedData: object }
 */
function validateUserRegistration(userData) {
    const errors = [];
    const sanitizedData = {};
    
    // Validate required fields
    const { isValid: hasRequired, missingFields } = validateRequiredFields(userData, ['name', 'email', 'password']);
    if (!hasRequired) {
        errors.push(`Missing required fields: ${missingFields.join(', ')}`);
    }
    
    // Validate email
    if (userData.email && !isValidEmail(userData.email)) {
        errors.push('Invalid email format');
    } else if (userData.email) {
        sanitizedData.email = sanitizeString(userData.email).toLowerCase();
    }
    
    // Validate password
    if (userData.password && !isValidPassword(userData.password)) {
        errors.push('Password must be at least 8 characters with 1 uppercase, 1 lowercase, and 1 number');
    } else if (userData.password) {
        sanitizedData.password = userData.password; // Don't sanitize passwords
    }
    
    // Validate name
    if (userData.name) {
        sanitizedData.name = sanitizeString(userData.name);
        if (sanitizedData.name.length < 2) {
            errors.push('Name must be at least 2 characters');
        }
    }
    
    // Validate phone (optional)
    if (userData.phone_number) {
        if (!isValidPhone(userData.phone_number)) {
            errors.push('Invalid phone number format');
        } else {
            sanitizedData.phone_number = sanitizeString(userData.phone_number);
        }
    }
    
    return {
        isValid: errors.length === 0,
        errors,
        sanitizedData
    };
}

/**
 * Validates event data
 * @param {object} eventData - Event data object
 * @returns {object} - { isValid: boolean, errors: string[], sanitizedData: object }
 */
function validateEvent(eventData) {
    const errors = [];
    const sanitizedData = {};
    
    // Validate required fields
    const requiredFields = ['title', 'description', 'date', 'location', 'organizer_id'];
    const { isValid: hasRequired, missingFields } = validateRequiredFields(eventData, requiredFields);
    if (!hasRequired) {
        errors.push(`Missing required fields: ${missingFields.join(', ')}`);
    }
    
    // Validate title
    if (eventData.title) {
        sanitizedData.title = sanitizeString(eventData.title);
        if (sanitizedData.title.length < 3) {
            errors.push('Event title must be at least 3 characters');
        }
    }
    
    // Validate description
    if (eventData.description) {
        sanitizedData.description = sanitizeString(eventData.description);
        if (sanitizedData.description.length < 10) {
            errors.push('Event description must be at least 10 characters');
        }
    }
    
    // Validate date
    if (eventData.date) {
        const eventDate = new Date(eventData.date);
        if (isNaN(eventDate.getTime())) {
            errors.push('Invalid date format');
        } else if (eventDate < new Date()) {
            errors.push('Event date cannot be in the past');
        } else {
            sanitizedData.date = eventDate;
        }
    }
    
    // Validate location
    if (eventData.location) {
        sanitizedData.location = sanitizeString(eventData.location);
        if (sanitizedData.location.length < 3) {
            errors.push('Location must be at least 3 characters');
        }
    }
    
    // Validate organizer_id
    if (eventData.organizer_id && !isValidObjectId(eventData.organizer_id)) {
        errors.push('Invalid organizer ID format');
    } else if (eventData.organizer_id) {
        sanitizedData.organizer_id = eventData.organizer_id;
    }
    
    // Validate ticket_price (optional)
    if (eventData.ticket_price !== undefined) {
        const price = parseFloat(eventData.ticket_price);
        if (isNaN(price) || price < 0) {
            errors.push('Ticket price must be a valid positive number');
        } else {
            sanitizedData.ticket_price = price;
        }
    }
    
    return {
        isValid: errors.length === 0,
        errors,
        sanitizedData
    };
}

/**
 * Validates login credentials
 * @param {object} credentials - Login credentials object
 * @returns {object} - { isValid: boolean, errors: string[], sanitizedData: object }
 */
function validateLoginCredentials(credentials) {
    const errors = [];
    const sanitizedData = {};
    
    // Validate required fields
    const { isValid: hasRequired, missingFields } = validateRequiredFields(credentials, ['email', 'password']);
    if (!hasRequired) {
        errors.push(`Missing required fields: ${missingFields.join(', ')}`);
    }
    
    // Validate email
    if (credentials.email && !isValidEmail(credentials.email)) {
        errors.push('Invalid email format');
    } else if (credentials.email) {
        sanitizedData.email = sanitizeString(credentials.email).toLowerCase();
    }
    
    // Password is required but don't validate strength for login
    if (credentials.password) {
        sanitizedData.password = credentials.password; // Don't sanitize passwords
    }
    
    return {
        isValid: errors.length === 0,
        errors,
        sanitizedData
    };
}

module.exports = {
    ValidationError,
    isValidEmail,
    isValidPhone,
    isValidPassword,
    isValidObjectId,
    validateRequiredFields,
    sanitizeString,
    validateUserRegistration,
    validateLoginCredentials,
    validateEvent,
    
    // Regex patterns for custom validation
    EMAIL_REGEX,
    PHONE_REGEX,
    PASSWORD_REGEX,
    OBJECT_ID_REGEX
};