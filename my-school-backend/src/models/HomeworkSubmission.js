const mongoose = require('mongoose');

const homeworkSubmissionSchema = new mongoose.Schema({
  lessonId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Lesson',
    required: true
  },
  studentId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Student',
    required: true
  },
  studentName: {
    type: String,
    required: true
  },
  className: {
    type: String,
    required: true
  },
  content: {
    type: String,
    default: ''
  },
  attachments: [{
    filename: String,
    originalName: String,
    fileType: String,
    fileSize: Number,
    filePath: String
  }],
  grade: {
    type: Number,
    min: 0,
    max: 20,
    default: null
  },
  feedback: {
    type: String,
    default: ''
  },
  status: {
    type: String,
    enum: ['submitted', 'graded', 'returned'],
    default: 'submitted'
  },
  submittedAt: {
    type: Date,
    default: Date.now
  },
  gradedAt: {
    type: Date,
    default: null
  }
});

// Index pour recherches rapides
homeworkSubmissionSchema.index({ lessonId: 1, studentId: 1 }, { unique: true });
homeworkSubmissionSchema.index({ className: 1 });
homeworkSubmissionSchema.index({ status: 1 });

module.exports = mongoose.model('HomeworkSubmission', homeworkSubmissionSchema);