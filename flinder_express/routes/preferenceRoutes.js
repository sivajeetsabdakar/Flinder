const express = require('express');
const router = express.Router();
const preferenceController = require('../controllers/preferenceController');
const { authenticateUser } = require('../middleware/authMiddleware');

/**
 * @route   GET /api/preferences
 * @desc    Get user preferences
 * @access  Private
 */
router.get('/', authenticateUser, preferenceController.getUserPreferences);

/**
 * @route   PUT /api/preferences
 * @desc    Update user preferences
 * @access  Private
 */
router.put('/', authenticateUser, preferenceController.updateUserPreferences);

module.exports = router; 