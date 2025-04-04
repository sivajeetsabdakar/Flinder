const express = require('express');
const router = express.Router();
const chatController = require('../controllers/chatController');
const { authenticateUser } = require('../middleware/authMiddleware');

/**
 * @route   GET /api/conversations
 * @desc    Get all user conversations
 * @access  Private
 */
router.get('/', authenticateUser, chatController.getUserConversations);

/**
 * @route   GET /api/conversations/:id/messages
 * @desc    Get messages for a conversation
 * @access  Private
 */
router.get('/:id/messages', authenticateUser, chatController.getConversationMessages);

/**
 * @route   POST /api/conversations/:id/messages
 * @desc    Send a new message
 * @access  Private
 */
router.post('/:id/messages', authenticateUser, chatController.sendMessage);

module.exports = router; 