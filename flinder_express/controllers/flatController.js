const { getFlats, getFlatById } = require('../models/flatModel');

/**
 * Get flats with filtering
 * @param {object} req - Express request object
 * @param {object} res - Express response object
 */
const getFlatsHandler = async (req, res) => {
  try {
    // Extract query parameters for filtering
    const filters = {
      city: req.query.city,
      minRent: req.query.minRent ? parseInt(req.query.minRent) : undefined,
      maxRent: req.query.maxRent ? parseInt(req.query.maxRent) : undefined,
      rooms: req.query.rooms ? parseInt(req.query.rooms) : undefined
    };
    
    // Extract pagination parameters
    const limit = req.query.limit ? parseInt(req.query.limit) : 10;
    const offset = req.query.offset ? parseInt(req.query.offset) : 0;
    
    // Validate pagination parameters
    if (limit < 0 || offset < 0) {
      return res.status(400).json({
        status: 'error',
        message: 'Invalid pagination parameters'
      });
    }
    
    // Get flats with the provided filters and pagination
    const { flats, pagination, error } = await getFlats(filters, limit, offset);
    
    if (error) {
      return res.status(400).json({
        status: 'error',
        message: error.message || 'Failed to retrieve flats'
      });
    }
    
    return res.status(200).json({
      status: 'success',
      flats,
      pagination
    });
  } catch (error) {
    return res.status(500).json({
      status: 'error',
      message: 'An error occurred while retrieving flats'
    });
  }
};

/**
 * Get flat by ID
 * @param {object} req - Express request object
 * @param {object} res - Express response object
 */
const getFlatByIdHandler = async (req, res) => {
  try {
    const flatId = req.params.id;
    
    if (!flatId) {
      return res.status(400).json({
        status: 'error',
        message: 'Flat ID is required'
      });
    }
    
    const { flat, error } = await getFlatById(flatId);
    
    if (error) {
      return res.status(404).json({
        status: 'error',
        message: 'Flat not found'
      });
    }
    
    return res.status(200).json({
      status: 'success',
      flat
    });
  } catch (error) {
    return res.status(500).json({
      status: 'error',
      message: 'An error occurred while retrieving the flat'
    });
  }
};

module.exports = {
  getFlats: getFlatsHandler,
  getFlatById: getFlatByIdHandler
}; 