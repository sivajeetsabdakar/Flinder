const { 
  getDiscoveryProfiles, 
  recordSwipe, 
  getUserMatches 
} = require('../models/discoveryModel');
const Joi = require('joi');

// Validation schemas
const swipeSchema = Joi.object({
  targetUserId: Joi.string().required(),
  direction: Joi.string().valid('left', 'right').required()
});

/**
 * Get discovery profiles
 * @param {object} req - Express request object
 * @param {object} res - Express response object
 */
const getDiscoveryProfilesHandler = async (req, res) => {
  try {
    if (!req.user?.id) {
      return res.status(401).json({
        success: false,
        message: 'User not authenticated'
      });
    }

    const limit = parseInt(req.query.limit) || 10;
    const offset = parseInt(req.query.offset) || 0;

    if (limit < 0 || offset < 0) {
      return res.status(400).json({
        success: false,
        message: 'Invalid pagination parameters'
      });
    }
    
    const { profiles, pagination, error } = await getDiscoveryProfiles(req.user.id, limit, offset);
    
    if (error) {
      return res.status(400).json({
        success: false,
        message: error.message || 'Failed to retrieve discovery profiles'
      });
    }
    
    return res.status(200).json({
      success: true,
      profiles,
      pagination
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: 'An error occurred while retrieving discovery profiles'
    });
  }
};

/**
 * Record a swipe action
 * @param {object} req - Express request object
 * @param {object} res - Express response object
 */
const recordSwipeHandler = async (req, res) => {
  try {
    if (!req.user?.id) {
      return res.status(401).json({
        success: false,
        message: 'User not authenticated'
      });
    }

    const { error: validationError, value } = swipeSchema.validate(req.body);
    if (validationError) {
      return res.status(400).json({
        success: false,
        message: validationError.details[0].message
      });
    }

    if (value.targetUserId === req.user.id) {
      return res.status(400).json({
        success: false,
        message: 'Cannot swipe on your own profile'
      });
    }
    
    const { success, match, matchDetails, error: swipeError } = await recordSwipe(
      req.user.id,
      value.targetUserId,
      value.direction
    );
    
    if (swipeError) {
      return res.status(400).json({
        success: false,
        message: swipeError.message || 'Failed to record swipe'
      });
    }
    
    if (match) {
      return res.status(200).json({
        success: true,
        message: "It's a match!",
        match: true,
        matchDetails
      });
    }
    
    return res.status(200).json({
      success: true,
      message: 'Preference recorded',
      match: false
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: 'An error occurred while recording swipe'
    });
  }
};

/**
 * Get user matches
 * @param {object} req - Express request object
 * @param {object} res - Express response object
 */
const getUserMatchesHandler = async (req, res) => {
  try {
    if (!req.user?.id) {
      return res.status(401).json({
        success: false,
        message: 'User not authenticated'
      });
    }

    const { matches, error } = await getUserMatches(req.user.id);
    
    if (error) {
      return res.status(400).json({
        success: false,
        message: error.message || 'Failed to retrieve matches'
      });
    }
    
    return res.status(200).json({
      success: true,
      matches
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: 'An error occurred while retrieving matches'
    });
  }
};

module.exports = {
  getDiscoveryProfiles: getDiscoveryProfilesHandler,
  recordSwipe: recordSwipeHandler,
  getUserMatches: getUserMatchesHandler
}; 