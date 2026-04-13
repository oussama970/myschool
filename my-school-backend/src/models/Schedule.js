const mongoose = require('mongoose');

const scheduleSchema = new mongoose.Schema({
  className: {
    type: String,
    required: true,
    unique: true,
  },
  schedule: {
    type: Object,
    default: {},
  },
  createdBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
  },
  createdAt: {
    type: Date,
    default: Date.now,
  },
  updatedAt: {
    type: Date,
    default: Date.now,
  },
});

scheduleSchema.pre('save', function(next) {
  this.updatedAt = Date.now();
  next();
});

module.exports = mongoose.model('Schedule', scheduleSchema);