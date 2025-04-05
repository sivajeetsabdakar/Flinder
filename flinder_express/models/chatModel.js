const supabase = require('../supabaseClient');

/**
 * Get all conversations for a user
 * @param {string} userId - User ID
 * @returns {Object} List of conversations or error
 */
const getUserConversations = async (userId) => {
  try {
    // Get all conversations where the user is a participant
    const { data: conversations, error } = await supabase
      .from('conversations')
      .select('*')
      .contains('participants', [userId]);
    
    if (error) throw error;
    
    // Format the conversations for API response
    const formattedConversations = conversations.map(conversation => ({
      id: conversation.id,
      matchId: conversation.match_id,
      participants: conversation.participants,
      createdAt: conversation.created_at,
      lastMessageAt: conversation.last_message_at
    }));
    
    return { conversations: formattedConversations, error: null };
  } catch (error) {
    console.error('Get user conversations error:', error);
    return { conversations: [], error };
  }
};

/**
 * Get conversation by ID
 * @param {string} conversationId - Conversation ID
 * @param {string} userId - User ID to verify participant
 * @returns {Object} The conversation object or error
 */
const getConversationById = async (conversationId, userId) => {
  try {
    // Get the conversation
    const { data: conversation, error } = await supabase
      .from('conversations')
      .select('*')
      .eq('id', conversationId)
      .contains('participants', [userId])
      .single();
    
    if (error) throw error;
    
    // Format the conversation for API response
    const formattedConversation = {
      id: conversation.id,
      matchId: conversation.match_id,
      participants: conversation.participants,
      createdAt: conversation.created_at,
      lastMessageAt: conversation.last_message_at
    };
    
    return { conversation: formattedConversation, error: null };
  } catch (error) {
    console.error('Get conversation error:', error);
    return { conversation: null, error };
  }
};

/**
 * Get messages for a conversation
 * @param {string} conversationId - Conversation ID
 * @param {string} userId - User ID to verify participant
 * @returns {Object} List of messages or error
 */
const getConversationMessages = async (conversationId, userId) => {
  try {
    // First check if user is part of the conversation
    const { data: conversation } = await supabase
      .from('conversations')
      .select('*')
      .eq('id', conversationId)
      .contains('participants', [userId])
      .single();
    
    if (!conversation) {
      throw new Error('Conversation not found or user not a participant');
    }
    
    // Get messages for the conversation
    const { data: messages, error } = await supabase
      .from('messages')
      .select('*')
      .eq('conversation_id', conversationId)
      .order('sent_at', { ascending: false });
    
    if (error) throw error;
    
    // Format the messages for API response
    const formattedMessages = messages.map(message => ({
      id: message.id,
      conversationId: message.conversation_id,
      senderId: message.sender_id,
      content: message.content,
      sentAt: message.sent_at
    }));
    
    return { messages: formattedMessages, error: null };
  } catch (error) {
    console.error('Get conversation messages error:', error);
    return { messages: [], error };
  }
};

/**
 * Send a message in a conversation
 * @param {string} conversationId - Conversation ID
 * @param {string} senderId - Sender user ID
 * @param {string} content - Message content
 * @returns {Object} The sent message or error
 */
const sendMessage = async (conversationId, senderId, content) => {
  try {
    // First check if user is part of the conversation
    const { data: conversation } = await supabase
      .from('conversations')
      .select('*')
      .eq('id', conversationId)
      .contains('participants', [senderId])
      .single();
    
    if (!conversation) {
      throw new Error('Conversation not found or user not a participant');
    }
    
    // Send the message
    const { data: message, error } = await supabase
      .from('messages')
      .insert({
        conversation_id: conversationId,
        sender_id: senderId,
        content
      })
      .select()
      .single();
    
    if (error) throw error;
    
    // Update the conversation's last message timestamp
    await supabase
      .from('conversations')
      .update({
        last_message_at: message.sent_at
      })
      .eq('id', conversationId);
    
    // Get the other participant to create a notification
    const otherParticipant = conversation.participants.find(p => p !== senderId);
    
    // Create a notification for the other participant
    if (otherParticipant) {
      await supabase
        .from('notifications')
        .insert({
          user_id: otherParticipant,
          type: 'message',
          title: 'New Message',
          body: content.length > 30 ? `${content.substring(0, 30)}...` : content
        });
    }
    
    // Format the message for API response
    const formattedMessage = {
      id: message.id,
      conversationId: message.conversation_id,
      senderId: message.sender_id,
      content: message.content,
      sentAt: message.sent_at
    };
    
    return { message: formattedMessage, error: null };
  } catch (error) {
    console.error('Send message error:', error);
    return { message: null, error };
  }
};

module.exports = {
  getUserConversations,
  getConversationById,
  getConversationMessages,
  sendMessage
}; 