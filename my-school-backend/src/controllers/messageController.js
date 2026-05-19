const Message = require('../models/Message');
const Teacher = require('../models/Teacher');
const Student = require('../models/Student');
const Parent = require('../models/Parent');

// Récupérer toutes les conversations d'un utilisateur
const getConversations = async (req, res) => {
  try {
    const userId = req.user._id;
    const userRole = req.user.role;
    
    console.log('========== GET CONVERSATIONS ==========');
    console.log('User ID:', userId);
    console.log('User Role:', userRole);
    
    // Récupérer tous les messages où l'utilisateur est impliqué
    const messages = await Message.find({
      $or: [
        { senderId: userId },
        { receiverId: userId }
      ]
    }).sort({ createdAt: -1 });
    
    console.log(`📨 ${messages.length} messages trouvés`);
    
    // Regrouper par contact
    const conversationsMap = new Map();
    
    for (const msg of messages) {
      const isSender = msg.senderId.toString() === userId.toString();
      const contactId = isSender ? msg.receiverId.toString() : msg.senderId.toString();
      const contactName = isSender ? msg.receiverName : msg.senderName;
      const contactRole = isSender ? msg.receiverRole : msg.senderRole;
      
      if (!conversationsMap.has(contactId)) {
        conversationsMap.set(contactId, {
          id: contactId,
          name: contactName,
          role: contactRole,
          lastMessage: msg.message,
          lastMessageTime: msg.createdAt,
          unreadCount: (!isSender && !msg.isRead) ? 1 : 0
        });
      } else if (!isSender && !msg.isRead) {
        const conv = conversationsMap.get(contactId);
        conv.unreadCount += 1;
      }
    }
    
    const conversations = Array.from(conversationsMap.values());
    console.log(`✅ ${conversations.length} conversations trouvées`);
    
    res.json({ success: true, conversations: conversations });
  } catch (error) {
    console.error('❌ Erreur getConversations:', error);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};

// Récupérer les messages d'une conversation
const getMessages = async (req, res) => {
  try {
    const { contactId } = req.params;
    const userId = req.user._id;
    
    console.log('========== GET MESSAGES ==========');
    console.log('Contact ID:', contactId);
    console.log('User ID:', userId);
    
    const messages = await Message.find({
      $or: [
        { senderId: userId, receiverId: contactId },
        { senderId: contactId, receiverId: userId }
      ]
    }).sort({ createdAt: 1 });
    
    console.log(`📨 ${messages.length} messages trouvés`);
    
    // Marquer les messages comme lus
    const unreadMessages = messages.filter(
      msg => msg.senderId.toString() === contactId && !msg.isRead
    );
    
    if (unreadMessages.length > 0) {
      await Message.updateMany(
        { senderId: contactId, receiverId: userId, isRead: false },
        { $set: { isRead: true } }
      );
      console.log(`✅ ${unreadMessages.length} messages marqués comme lus`);
    }
    
    res.json({ success: true, messages: messages });
  } catch (error) {
    console.error('❌ Erreur getMessages:', error);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};

// Envoyer un message
const sendMessage = async (req, res) => {
  try {
    const { receiverId, receiverName, receiverRole, message, attachments } = req.body;
    
    console.log('========== SEND MESSAGE ==========');
    console.log('Destinataire ID:', receiverId);
    console.log('Message:', message);
    
    if (!message || message.trim() === '') {
      return res.status(400).json({ success: false, message: 'Message vide' });
    }
    
    const newMessage = await Message.create({
      senderId: req.user._id,
      senderName: req.user.fullName,
      senderRole: req.user.role,
      receiverId: receiverId,
      receiverName: receiverName,
      receiverRole: receiverRole,
      message: message.trim(),
      attachments: attachments || [],
      isRead: false
    });
    
    console.log('✅ Message envoyé:', newMessage._id);
    
    res.status(201).json({ success: true, message: newMessage });
  } catch (error) {
    console.error('❌ Erreur sendMessage:', error);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};

// Marquer un message comme lu
const markAsRead = async (req, res) => {
  try {
    const { messageId } = req.params;
    
    const message = await Message.findById(messageId);
    if (!message) {
      return res.status(404).json({ success: false, message: 'Message non trouvé' });
    }
    
    message.isRead = true;
    await message.save();
    
    console.log(`✅ Message ${messageId} marqué comme lu`);
    
    res.json({ success: true, message: 'Message marqué comme lu' });
  } catch (error) {
    console.error('❌ Erreur markAsRead:', error);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};

// Récupérer les contacts (parents et élèves de la classe)
const getContacts = async (req, res) => {
  try {
    const userRole = req.user.role;
    let contacts = [];
    
    console.log('========== GET CONTACTS ==========');
    console.log('Rôle utilisateur:', userRole);
    
    if (userRole === 'teacher') {
      const assignedClasses = req.user.assignedClasses || [];
      console.log('Classes assignées:', assignedClasses);
      
      const students = await Student.find({ className: { $in: assignedClasses } })
        .select('fullName email className');
      
      const parents = await Parent.find()
        .select('fullName email linkedChildren');
      
      contacts = [
        ...students.map(s => ({
          id: s._id,
          name: s.fullName,
          role: 'student',
          class: s.className,
          email: s.email
        })),
        ...parents.map(p => ({
          id: p._id,
          name: p.fullName,
          role: 'parent',
          email: p.email
        }))
      ];
      
      console.log(`📚 ${students.length} élèves trouvés`);
      console.log(`👨‍👩‍👧 ${parents.length} parents trouvés`);
    }
    
    res.json({ success: true, contacts: contacts });
  } catch (error) {
    console.error('❌ Erreur getContacts:', error);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};

// Supprimer un message
const deleteMessage = async (req, res) => {
  try {
    const { messageId } = req.params;
    
    const message = await Message.findById(messageId);
    if (!message) {
      return res.status(404).json({ success: false, message: 'Message non trouvé' });
    }
    
    if (message.senderId.toString() !== req.user._id.toString()) {
      return res.status(403).json({ success: false, message: 'Non autorisé' });
    }
    
    await message.deleteOne();
    console.log(`🗑️ Message ${messageId} supprimé`);
    
    res.json({ success: true, message: 'Message supprimé' });
  } catch (error) {
    console.error('❌ Erreur deleteMessage:', error);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};

module.exports = {
  getConversations,
  getMessages,
  sendMessage,
  markAsRead,
  getContacts,
  deleteMessage
};