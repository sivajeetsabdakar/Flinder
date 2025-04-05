const supabase = require('../supabaseClient');

/**
 * Get flats with filtering
 * @param {Object} filters - Filter criteria
 * @param {string} filters.city - Filter by city
 * @param {number} filters.minRent - Minimum rent
 * @param {number} filters.maxRent - Maximum rent
 * @param {number} filters.rooms - Number of rooms
 * @param {number} limit - Number of flats to return
 * @param {number} offset - Pagination offset
 * @returns {Object} List of flats or error
 */
const getFlats = async (filters = {}, limit = 10, offset = 0) => {
  try {
    // Start building the query
    let query = supabase
      .from('flats')
      .select('*', { count: 'exact' });
    
    // Apply filters if provided
    if (filters.city) {
      query = query.ilike('city', `%${filters.city}%`);
    }
    
    if (filters.minRent) {
      query = query.gte('rent', filters.minRent);
    }
    
    if (filters.maxRent) {
      query = query.lte('rent', filters.maxRent);
    }
    
    if (filters.rooms) {
      query = query.eq('num_rooms', filters.rooms);
    }
    
    // Add pagination
    query = query
      .limit(limit)
      .range(offset, offset + limit - 1)
      .order('created_at', { ascending: false });
    
    // Execute the query
    const { data: flats, error, count } = await query;
    
    if (error) {
      throw error;
    }
    
    return {
      flats: flats || [],
      pagination: {
        limit,
        offset,
        total: count || 0
      },
      error: null
    };
  } catch (error) {
    console.error('Get flats error:', error);
    return {
      flats: [],
      pagination: {
        limit,
        offset,
        total: 0
      },
      error: {
        message: error.message,
        code: error.code
      }
    };
  }
};

/**
 * Get flat by ID
 * @param {string} flatId - Flat ID
 * @returns {Object} Flat details or error
 */
const getFlatById = async (flatId) => {
  try {
    const { data: flat, error } = await supabase
      .from('flats')
      .select('*')
      .eq('id', flatId)
      .single();
    
    if (error) {
      throw error;
    }
    
    return { flat, error: null };
  } catch (error) {
    console.error('Get flat by ID error:', error);
    return { flat: null, error };
  }
};

module.exports = {
  getFlats,
  getFlatById
}; 