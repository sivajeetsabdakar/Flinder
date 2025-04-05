const { 
  getProfileByUserId, 
  createOrUpdateProfile, 
  addProfilePicture, 
  deleteProfilePicture 
} = require('../models/profileModel');
const Joi = require('joi');

// Validation schemas
const profileSchema = Joi.object({
  bio: Joi.string().required(),
  generatedDescription: Joi.string(),
  interests: Joi.array().items(Joi.string()),
  location: Joi.object({
    city: Joi.string().required(),
    neighborhood: Joi.string().allow(null, ''),
    coordinates: Joi.object({
      latitude: Joi.number(),
      longitude: Joi.number()
    })
  }).required(),
  budget: Joi.object({
    min: Joi.number().required(),
    max: Joi.number().required(),
    currency: Joi.string().required()
  }).required(),
  roomPreference: Joi.string().valid('private', 'shared', 'studio', 'any').required(),
  genderPreference: Joi.string().valid('same_gender', 'any_gender').required(),
  moveInDate: Joi.alternatives().try(
    Joi.date().iso(),
    Joi.string().valid('immediate', 'next_month', 'flexible')
  ).required(),
  leaseDuration: Joi.string().valid('short_term', 'long_term', 'flexible').required(),
  lifestyle: Joi.object({
    schedule: Joi.string().valid('early_riser', 'night_owl', 'flexible').required(),
    noiseLevel: Joi.string().valid('silent', 'moderate', 'loud').required(),
    cookingFrequency: Joi.string().valid('rarely', 'sometimes', 'daily').required(),
    diet: Joi.string().valid('vegetarian', 'vegan', 'non_vegetarian', 'no_restrictions').required(),
    smoking: Joi.string().valid('yes', 'no', 'occasionally').required(),
    drinking: Joi.string().valid('yes', 'no', 'occasionally').required(),
    pets: Joi.string().valid('has_pets', 'no_pets', 'comfortable_with_pets').required(),
    cleaningHabits: Joi.string().valid('very_clean', 'average', 'messy').required(),
    guestPolicy: Joi.string().valid('no_guests', 'occasional_guests', 'frequent_guests').required()
  }).required(),
  languages: Joi.array().items(Joi.string())
});

const pictureSchema = Joi.object({
  url: Joi.string().uri().required(),
  isPrimary: Joi.boolean().default(false)
});

/**
 * Get user profile
 * @param {object} req - Express request object
 * @param {object} res - Express response object
 */
const getProfile = async (req, res) => {
  try {
    const userId = req.params.id;
    
    // Check if the requested profile is for the authenticated user
    if (userId !== req.user.id && userId !== 'me') {
      return res.status(403).json({
        success: false,
        message: 'Access denied'
      });
    }
    
    // If 'me' is specified, use the authenticated user ID
    const profileUserId = userId === 'me' ? req.user.id : userId;
    
    // Get profile
    const { profile, error } = await getProfileByUserId(profileUserId);
    
    if (error) {
      return res.status(404).json({
        success: false,
        message: 'Profile not found'
      });
    }
    
    return res.status(200).json({
      success: true,
      profile
    });
  } catch (error) {
    console.error('Get profile error:', error);
    return res.status(500).json({
      success: false,
      message: 'An error occurred while retrieving the profile'
    });
  }
};

/**
 * Update user profile
 * @param {object} req - Express request object
 * @param {object} res - Express response object
 */
const updateProfile = async (req, res) => {
  try {
    const userId = req.params.id;
    
    // Check if the requested profile is for the authenticated user
    if (userId !== req.user.id && userId !== 'me') {
      return res.status(403).json({
        success: false,
        message: 'Access denied'
      });
    }
    
    // If 'me' is specified, use the authenticated user ID
    const profileUserId = userId === 'me' ? req.user.id : userId;
    
    // Validate request data
    const { error, value } = profileSchema.validate(req.body);
    if (error) {
      return res.status(400).json({
        success: false,
        message: 'Invalid data provided',
        errors: error.details.map(detail => ({
          field: detail.path.join('.'),
          message: detail.message
        }))
      });
    }
    
    // Update profile
    const { profile, error: updateError } = await createOrUpdateProfile(profileUserId, value);
    
    if (updateError) {
      return res.status(400).json({
        success: false,
        message: updateError.message || 'Failed to update profile'
      });
    }
    
    return res.status(200).json({
      success: true,
      message: 'Profile updated successfully',
      profile
    });
  } catch (error) {
    console.error('Update profile error:', error);
    return res.status(500).json({
      success: false,
      message: 'An error occurred while updating the profile'
    });
  }
};

/**
 * Add profile picture
 * @param {object} req - Express request object
 * @param {object} res - Express response object
 */
const addProfilePictureHandler = async (req, res) => {
  try {
    // Validate request data
    const { error, value } = pictureSchema.validate(req.body);
    if (error) {
      return res.status(400).json({
        success: false,
        message: error.details[0].message
      });
    }
    
    // Add profile picture
    const { picture, error: pictureError } = await addProfilePicture(req.user.id, value);
    
    if (pictureError) {
      return res.status(400).json({
        success: false,
        message: pictureError.message || 'Failed to upload photo'
      });
    }
    
    return res.status(200).json({
      success: true,
      message: 'Photo uploaded successfully',
      photo: picture
    });
  } catch (error) {
    console.error('Add profile picture error:', error);
    return res.status(500).json({
      success: false,
      message: 'An error occurred while uploading the photo'
    });
  }
};

/**
 * Delete profile picture
 * @param {object} req - Express request object
 * @param {object} res - Express response object
 */
const deleteProfilePictureHandler = async (req, res) => {
  try {
    const pictureId = req.params.id;
    
    // Delete profile picture
    const { success, error } = await deleteProfilePicture(pictureId);
    
    if (error) {
      return res.status(404).json({
        success: false,
        message: 'Photo not found'
      });
    }
    
    return res.status(200).json({
      success: true,
      message: 'Photo deleted successfully'
    });
  } catch (error) {
    console.error('Delete profile picture error:', error);
    return res.status(500).json({
      success: false,
      message: 'An error occurred while deleting the photo'
    });
  }
};

module.exports = {
  getProfile,
  updateProfile,
  addProfilePicture: addProfilePictureHandler,
  deleteProfilePicture: deleteProfilePictureHandler
}; 