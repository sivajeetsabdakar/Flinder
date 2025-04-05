const express = require('express');
const router = express.Router();
const flatController = require('../controllers/flatController');
const { authenticateUser } = require('../middleware/authMiddleware');

/**
 * @route   GET /api/flats
 * @desc    Get flats with filtering
 * @access  Public
 */
router.get('/', flatController.getFlats);

/**
 * @route   GET /api/flats/:id
 * @desc    Get flat by ID
 * @access  Public
 */
router.get('/:id', flatController.getFlatById);

module.exports = router; 