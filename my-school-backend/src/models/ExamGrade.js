const mongoose = require('mongoose');

const examGradeSchema = new mongoose.Schema({
  examId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'AgendaEvent',
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
  subject: {
    type: String,
    required: true
  },
  grade: {
    type: Number,
    required: true,
    min: 0,
    max: 20
  },
  appreciation: {
    type: String,
    default: ''
  },
  photoUrl: {
    type: String,
    default: null
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
  createdAt: {
    type: Date,
    default: Date.now
  }
});

examGradeSchema.index({ examId: 1, studentId: 1 }, { unique: true });
examGradeSchema.index({ studentId: 1 });

module.exports = mongoose.model('ExamGrade', examGradeSchema);