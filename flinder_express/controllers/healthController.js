/**
 * Health check endpoint
 * @param {object} req - Express request object
 * @param {object} res - Express response object
 */
const check = async (req, res) => {
  try {
    // You can add more health checks here (e.g., database connection)
    return res.status(200).json({
      success: true,
      status: 'healthy',
      message: 'Server is running',
      timestamp: new Date().toISOString(),
      uptime: process.uptime()
    });
  } catch (error) {
    console.error('Health check error:', error);
    return res.status(500).json({
      success: false,
      status: 'unhealthy',
      message: 'Server error',
      timestamp: new Date().toISOString()
    });
  }
};

module.exports = {
  check
}; 