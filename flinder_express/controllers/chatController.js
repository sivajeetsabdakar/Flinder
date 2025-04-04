const { 
  getUserConversations, 
  getConversationMessages, 
  sendMessage 
} = require('../models/chatModel');
const Joi = require('joi');

// Validation schemas
const messageSchema = Joi.object({
  content: Joi.string().required()
});

/**
 * Get user conversations
 * @param {object} req - Express request object
 * @param {object} res - Express response object
 */
const getUserConversationsHandler = async (req, res) => {
  try {
    // Get all conversations for the user
    const { conversations, error } = await getUserConversations(req.user.id);
    
    if (error) {
      return res.status(400).json({
        success: false,
        message: error.message || 'Failed to retrieve conversations'
      });
    }
    
    return res.status(200).json({
      success: true,
      conversations
    });
  } catch (error) {
    console.error('Get user conversations error:', error);
    return res.status(500).json({
      success: false,
      message: 'An error occurred while retrieving conversations'
    });
  }
};

/**
 * Get conversation messages
 * @param {object} req - Express request object
 * @param {object} res - Express response object
 */
const getConversationMessagesHandler = async (req, res) => {
  try {
    const conversationId = req.params.id;
    
    // Get messages for the conversation
    const { messages, error } = await getConversationMessages(conversationId, req.user.id);
    
    if (error) {
      return res.status(404).json({
        success: false,
        message: 'Conversation not found or you don\'t have access to it'
      });
    }
    
    return res.status(200).json({
      success: true,
      messages
    });
  } catch (error) {
    console.error('Get conversation messages error:', error);
    return res.status(500).json({
      success: false,
      message: 'An error occurred while retrieving messages'
    });
  }
};

/**
 * Send a message
 * @param {object} req - Express request object
 * @param {object} res - Express response object
 */
const sendMessageHandler = async (req, res) => {
  try {
    const conversationId = req.params.id;
    
    // Validate request data
    const { error, value } = messageSchema.validate(req.body);
    if (error) {
      return res.status(400).json({
        success: false,
        message: error.details[0].message
      });
    }
    
    // Send message
    const { message, error: sendError } = await sendMessage(
      conversationId,
      req.user.id,
      value.content
    );
    
    if (sendError) {
      return res.status(400).json({
        success: false,
        message: sendError.message || 'Failed to send message'
      });
    }
    
    return res.status(200).json({
      success: true,
      message
    });
  } catch (error) {
    console.error('Send message error:', error);
    return res.status(500).json({
      success: false,
      message: 'An error occurred while sending the message'
    });
  }
};

module.exports = {
  getUserConversations: getUserConversationsHandler,
  getConversationMessages: getConversationMessagesHandler,
  sendMessage: sendMessageHandler
}; 