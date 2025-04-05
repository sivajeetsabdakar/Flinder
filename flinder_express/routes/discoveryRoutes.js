const express = require('express');
const router = express.Router();
const discoveryController = require('../controllers/discoveryController');
const { authenticateUser } = require('../middleware/authMiddleware');

/**
 * @route   GET /api/discover
 * @desc    Get potential roommate matches
 * @access  Private
 */
router.get('/', authenticateUser, discoveryController.getDiscoveryProfiles);

/**
 * @route   POST /api/discover/swipe
 * @desc    Record a swipe action
 * @access  Private
 */
router.post('/swipe', authenticateUser, discoveryController.recordSwipe);

/**
 * @route   GET /api/discover/matches
 * @desc    Get all user matches
 * @access  Private
 */
router.get('/matches', authenticateUser, discoveryController.getUserMatches);

module.exports = router; 