const {
  getPreferencesByUserId,
  createOrUpdatePreferences
} = require('../models/preferenceModel');
const Joi = require('joi');

// Validation schemas
const preferencesSchema = Joi.object({
  critical: Joi.object({
    location: Joi.object({
      city: Joi.string().required(),
      neighborhoods: Joi.array().items(Joi.string()),
      maxDistance: Joi.number()
    }).required(),
    budget: Joi.object({
      min: Joi.number().required(),
      max: Joi.number().required()
    }).required(),
    roomType: Joi.string().valid('private', 'shared', 'studio', 'any').required(),
    genderPreference: Joi.string().valid('same_gender', 'any_gender').required(),
    moveInDate: Joi.alternatives().try(
      Joi.date().iso(),
      Joi.string().valid('immediate', 'next_month', 'flexible')
    ).required(),
    leaseDuration: Joi.string().valid('short_term', 'long_term', 'flexible').required()
  }).required(),
  nonCritical: Joi.object({
    schedule: Joi.string().valid('early_riser', 'night_owl', 'flexible'),
    noiseLevel: Joi.string().valid('silent', 'moderate', 'loud'),
    cookingFrequency: Joi.string().valid('rarely', 'sometimes', 'daily'),
    diet: Joi.string().valid('vegetarian', 'vegan', 'non_vegetarian', 'no_restrictions'),
    smoking: Joi.string().valid('yes', 'no', 'occasionally'),
    drinking: Joi.string().valid('yes', 'no', 'occasionally'),
    pets: Joi.string().valid('has_pets', 'no_pets', 'comfortable_with_pets'),
    cleaningHabits: Joi.string().valid('very_clean', 'average', 'messy'),
    guestPolicy: Joi.string().valid('no_guests', 'occasional_guests', 'frequent_guests'),
    interestWeights: Joi.object().pattern(
      Joi.string(),
      Joi.number().min(1).max(5)
    )
  }),
  discoverySettings: Joi.object({
    ageRange: Joi.object({
      min: Joi.number().min(18).required(),
      max: Joi.number().required()
    }),
    distance: Joi.number(),
    showMeToOthers: Joi.boolean()
  })
});

/**
 * Get user preferences
 * @param {object} req - Express request object
 * @param {object} res - Express response object
 */
const getUserPreferences = async (req, res) => {
  try {
    // Get user preferences
    const { preferences, error } = await getPreferencesByUserId(req.user.id);
    
    if (error) {
      return res.status(404).json({
        success: false,
        message: 'Preferences not found'
      });
    }
    
    return res.status(200).json({
      success: true,
      preferences
    });
  } catch (error) {
    console.error('Get user preferences error:', error);
    return res.status(500).json({
      success: false,
      message: 'An error occurred while retrieving preferences'
    });
  }
};

/**
 * Update user preferences
 * @param {object} req - Express request object
 * @param {object} res - Express response object
 */
const updateUserPreferences = async (req, res) => {
  try {
    // Validate request data
    const { error, value } = preferencesSchema.validate(req.body);
    if (error) {
      return res.status(400).json({
        success: false,
        message: 'Invalid preferences data',
        errors: error.details.map(detail => ({
          field: detail.path.join('.'),
          message: detail.message
        }))
      });
    }
    
    // Update preferences
    const { preferences, error: updateError } = await createOrUpdatePreferences(req.user.id, value);
    
    if (updateError) {
      return res.status(400).json({
        success: false,
        message: updateError.message || 'Failed to update preferences'
      });
    }
    
    return res.status(200).json({
      success: true,
      message: 'Preferences updated successfully',
      preferences
    });
  } catch (error) {
    console.error('Update user preferences error:', error);
    return res.status(500).json({
      success: false,
      message: 'An error occurred while updating preferences'
    });
  }
};

module.exports = {
  getUserPreferences,
  updateUserPreferences
}; 