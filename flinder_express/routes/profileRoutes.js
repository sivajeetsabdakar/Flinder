const express = require('express');
const router = express.Router();
const profileController = require('../controllers/profileController');
const { authenticateUser } = require('../middleware/authMiddleware');

/**
 * @route   GET /api/profile/:id
 * @desc    Get user profile
 * @access  Private
 */
router.get('/:id', authenticateUser, profileController.getProfile);

/**
 * @route   PUT /api/profile/:id
 * @desc    Update user profile
 * @access  Private
 */
router.put('/:id', authenticateUser, profileController.updateProfile);

/**
 * @route   POST /api/profile/photos
 * @desc    Upload a profile photo
 * @access  Private
 */
router.post('/photos', authenticateUser, profileController.addProfilePicture);

/**
 * @route   DELETE /api/profile/photos/:id
 * @desc    Delete a profile photo
 * @access  Private
 */
router.delete('/photos/:id', authenticateUser, profileController.deleteProfilePicture);

module.exports = router; 