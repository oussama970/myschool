const mongoose = require('mongoose');

const scheduleSchema = new mongoose.Schema({
  className: {
    type: String,
    required: true,
    unique: true
  },
  schedule: {
    type: Map,
    of: Map,
    default: {}
  },
  updatedAt: {
    type: Date,
    default: Date.now
  }
});

module.exports = mongoose.model('Schedule', scheduleSchema);