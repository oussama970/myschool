const mongoose = require('mongoose');

const classSchema = new mongoose.Schema({
  name: {
    type: String,
    required: true,
    unique: true
  },
  level: {
    type: String,
    required: true
  },
  group: {
    type: String,
    required: true
  },
  teacherId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  teacherName: {
    type: String,
    required: true
  },
  capacity: {
    type: Number,
    default: 30
  },
  room: {
    type: String,
    default: ''
  },
  studentCount: {
    type: Number,
    default: 0
  },
  parentCount: {
    type: Number,
    default: 0
  },
  students: [{
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User'
  }],
  createdAt: {
    type: Date,
    default: Date.now
  }
});

module.exports = mongoose.model('Class', classSchema);