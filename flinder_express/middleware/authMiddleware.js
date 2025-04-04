const supabase = require('../supabaseClient');

/**
 * Authentication middleware
 * Verifies if the user exists in the database based on the email in the Authorization header
 */
const authenticateUser = async (req, res, next) => {
  try {
    // Get email from Authorization header
    const email = req.headers.authorization;
    
    if (!email) {
      return res.status(401).json({
        success: false,
        message: 'Unauthorized: Missing authentication token'
      });
    }

    // Check if user exists in the database
    const { data: user, error } = await supabase
      .from('users')
      .select('id, email, name')
      .eq('email', email)
      .single();
    
    if (error || !user) {
      return res.status(401).json({
        success: false,
        message: 'Unauthorized: Invalid authentication token'
      });
    }

    // Attach user to request object for use in route handlers
    req.user = user;
    
    // Update last_active timestamp
    await supabase
      .from('users')
      .update({ last_active: new Date().toISOString() })
      .eq('id', user.id);
    
    next();
  } catch (error) {
    console.error('Authentication error:', error);
    return res.status(500).json({
      success: false,
      message: 'Authentication error'
    });
  }
};

module.exports = {
  authenticateUser
}; 