const supabase = require('../supabaseClient');
const bcrypt = require('bcrypt');

/**
 * Register a new user
 * @param {Object} userData - User registration data
 * @returns {Object} The created user or error
 */
const register = async (userData) => {
  try {
    // Hash the password
    const salt = await bcrypt.genSalt(10);
    const hashedPassword = await bcrypt.hash(userData.password, salt);
    
    // Create user in the database
    const { data: user, error } = await supabase
      .from('users')
      .insert({
        email: userData.email,
        password: hashedPassword,
        name: userData.name,
        phone: userData.phone,
        date_of_birth: userData.dateOfBirth,
        gender: userData.gender,
      })
      .select('id, email, name, created_at, profile_completed, verification_status')
      .single();
    
    if (error) throw error;
    
    return { user, error: null };
  } catch (error) {
    console.error('User registration error:', error);
    return { user: null, error };
  }
};

/**
 * Login user with email and password
 * @param {string} email - User email
 * @param {string} password - User password
 * @returns {Object} The user object or error
 */
const login = async (email, password) => {
  try {
    console.log('Login attempt for email:', email);
    
    // Get user with the provided email
    const { data: user, error } = await supabase
      .from('users')
      .select('id, email, name, password, profile_completed, online_status')
      .eq('email', email)
      .single();
    
    if (error) {
      console.error('Database error:', error);
      return { user: null, error: new Error('Invalid credentials') };
    }
    
    if (!user) {
      console.log('No user found with email:', email);
      return { user: null, error: new Error('Invalid credentials') };
    }
    
    console.log('User found, comparing passwords');
    
    // Compare passwords
    const validPassword = await bcrypt.compare(password, user.password);
    console.log('Password valid:', validPassword);
    
    if (!validPassword) {
      return { user: null, error: new Error('Invalid credentials') };
    }
    
    // Update online status and last active
    const { error: updateError } = await supabase
      .from('users')
      .update({
        online_status: 'online',
        last_active: new Date().toISOString()
      })
      .eq('id', user.id);
      
    if (updateError) {
      console.error('Error updating online status:', updateError);
    }
    
    // Remove password from user object before returning
    const { password: _, ...userWithoutPassword } = user;
    
    return { user: userWithoutPassword, error: null };
  } catch (error) {
    console.error('Login error:', error);
    return { user: null, error };
  }
};

/**
 * Get user by ID
 * @param {string} id - User ID
 * @returns {Object} The user object or error
 */
const getUserById = async (id) => {
  try {
    const { data: user, error } = await supabase
      .from('users')
      .select('id, email, name, profile_completed, verification_status')
      .eq('id', id)
      .single();
    
    if (error) throw error;
    
    return { user, error: null };
  } catch (error) {
    console.error('Get user error:', error);
    return { user: null, error };
  }
};

/**
 * Get user by email
 * @param {string} email - User email
 * @returns {Object} The user object or error
 */
const getUserByEmail = async (email) => {
  try {
    const { data: user, error } = await supabase
      .from('users')
      .select('id, email, name, profile_completed, verification_status')
      .eq('email', email)
      .single();
    
    if (error) throw error;
    
    return { user, error: null };
  } catch (error) {
    console.error('Get user by email error:', error);
    return { user: null, error };
  }
};

/**
 * Add device information
 * @param {string} userId - User ID
 * @param {Object} deviceInfo - Device information
 * @returns {Object} The created device info or error
 */
const addDeviceInfo = async (userId, deviceInfo) => {
  try {
    const { data, error } = await supabase
      .from('device_info')
      .insert({
        user_id: userId,
        device_id: deviceInfo.deviceId,
        push_token: deviceInfo.pushToken,
        platform: deviceInfo.platform,
      })
      .single();
    
    if (error) throw error;
    
    return { data, error: null };
  } catch (error) {
    console.error('Add device info error:', error);
    return { data: null, error };
  }
};

module.exports = {
  register,
  login,
  getUserById,
  getUserByEmail,
  addDeviceInfo
}; 