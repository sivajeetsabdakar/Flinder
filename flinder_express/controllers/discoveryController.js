const discoveryModel = require('../models/discoveryModel');

/**
 * @route   GET /api/discover
 * @desc    Get potential roommate matches based on user preferences
 * @access  Private
 */
const getDiscoveryProfiles = async (req, res) => {
  try {
    const userId = req.user.id;
    const limit = parseInt(req.query.limit) || 10;
    const offset = parseInt(req.query.offset) || 0;
    
    console.log(`Processing discovery request for user: ${userId}, limit: ${limit}, offset: ${offset}`);
    
    // Get discovery profiles directly from the model
    // We're passing only userId because we're not filtering on specific preferences
    const { profiles, pagination, error } = await discoveryModel.getDiscoveryProfiles(
      userId,
      limit,
      offset
    );
    
    if (error) {
      console.error('Error in discovery controller:', error);
      return res.status(400).json({
        success: false,
        message: 'Failed to retrieve discovery profiles',
        error: error.message
      });
    }
    
    return res.status(200).json({
      success: true,
      profiles,
      pagination
    });
  } catch (error) {
    console.error('Get discovery profiles error:', error);
    return res.status(500).json({
      success: false,
      message: 'Server error',
      error: error.message
    });
  }
};

/**
 * @route   POST /api/discover/swipe
 * @desc    Record a swipe action
 * @access  Private
 */
const recordSwipe = async (req, res) => {
  try {
    const userId = req.user.id;
    const { targetUserId, action } = req.body;
    
    if (!targetUserId || !action) {
      return res.status(400).json({
        success: false,
        message: 'Target user ID and action are required'
      });
    }
    
    if (action !== 'like' && action !== 'pass') {
      return res.status(400).json({
        success: false,
        message: 'Action must be either "like" or "pass"'
      });
    }
    
    const { success, match, error } = await discoveryModel.recordSwipe(userId, targetUserId, action);
    
    if (error) {
      return res.status(400).json({
        success: false,
        message: 'Failed to record swipe',
        error: error.message
      });
    }
    
    return res.status(200).json({
      success: true,
      match: match || null
    });
  } catch (error) {
    console.error('Record swipe error:', error);
    return res.status(500).json({
      success: false,
      message: 'Server error',
      error: error.message
    });
  }
};

/**
 * @route   GET /api/discover/matches
 * @desc    Get all user matches
 * @access  Private
 */
const getUserMatches = async (req, res) => {
  try {
    const userId = req.user.id;
    
    const { matches, error } = await discoveryModel.getUserMatches(userId);
    
    if (error) {
      return res.status(400).json({
        success: false,
        message: 'Failed to retrieve matches',
        error: error.message
      });
    }
    
    return res.status(200).json({
      success: true,
      matches
    });
  } catch (error) {
    console.error('Get user matches error:', error);
    return res.status(500).json({
      success: false,
      message: 'Server error',
      error: error.message
    });
  }
};

module.exports = {
  getDiscoveryProfiles,
  recordSwipe,
  getUserMatches
};
