const mongoose = require('mongoose');

const lessonSchema = new mongoose.Schema({
  title: { 
    type: String, 
    required: true 
  },
  subject: { 
    type: String, 
    default: '' 
  },
  description: { 
    type: String, 
    default: '' 
  },
  type: { 
    type: String, 
    enum: ['Cours', 'Devoir', 'Rappel'], 
    required: true 
  },
  className: { 
    type: String, 
    required: true 
  },
  deadline: { 
    type: Date, 
    default: null 
  },
  files: [{ 
    type: String 
  }],
  teacherId: { 
    type: mongoose.Schema.Types.ObjectId, 
    ref: 'User', 
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

module.exports = mongoose.model('Lesson', lessonSchema);