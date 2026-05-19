const mongoose = require('mongoose');

const eventResponseSchema = new mongoose.Schema({
  studentId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Student',
    required: true
  },
  studentName: {
    type: String,
    required: true
  },
  response: {
    type: String,
    enum: ['pending', 'accepted', 'rejected'],
    default: 'pending'
  },
  comment: {
    type: String,
    default: ''
  },
  respondedAt: {
    type: Date,
    default: Date.now
  }
});

const eventSchema = new mongoose.Schema({
  title: {
    type: String,
    required: true
  },
  description: {
    type: String,
    required: true
  },
  date: {
    type: Date,
    required: true
  },
  status: {
    type: String,
    enum: ['pending', 'approved', 'rejected', 'completed'],
    default: 'pending'
  },
  teacherId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Teacher',
    required: true
  },
  teacherName: {
    type: String,
    required: true
  },
  className: {
    type: String,
    required: true
  },
  studentResponses: [eventResponseSchema],
  responseDeadline: {                    // ✅ NOUVEAU CHAMP
    type: Date,
    default: null
  },
  createdAt: {
    type: Date,
    default: Date.now
  }
});

// Index pour faciliter les recherches
eventSchema.index({ className: 1 });
eventSchema.index({ teacherId: 1 });
eventSchema.index({ date: 1 });
eventSchema.index({ responseDeadline: 1 });  // ✅ INDEX POUR LA DATE LIMITE

module.exports = mongoose.model('Event', eventSchema);