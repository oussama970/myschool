const mongoose = require('mongoose');

const scheduleSchema = new mongoose.Schema({
  className: { 
    type: String, 
    required: true 
  },
  schedule: { 
    type: Object, 
    default: {} 
  },
  createdBy: { 
    type: mongoose.Schema.Types.ObjectId, 
    ref: 'Teacher' 
  },
  createdAt: { 
    type: Date, 
    default: Date.now 
  },
  updatedAt: { 
    type: Date, 
    default: Date.now 
  }
});

// UNIQUEMENT L'INDEX - PAS DE MIDDLEWARE pre('save')
scheduleSchema.index({ className: 1 }, { unique: true });

module.exports = mongoose.model('Schedule', scheduleSchema);