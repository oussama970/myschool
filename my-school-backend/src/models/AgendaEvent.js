const mongoose = require('mongoose');

const agendaEventSchema = new mongoose.Schema({
  className: { type: String, required: true },
  subject: { type: String, required: true },
  type: { 
    type: String, 
    enum: ['Orale', 'Evaluation', 'Examen'], 
    required: true 
  },
  day: { type: String, enum: ['Lu', 'Ma', 'Me', 'Je', 'Ve', 'Sa'], required: true },
  timeSlot: { type: String, required: true },
  date: { type: Date, required: true },
  teacherId: { type: mongoose.Schema.Types.ObjectId, ref: 'Teacher', required: true },
  teacherName: { type: String, required: true },
  createdAt: { type: Date, default: Date.now }
});

agendaEventSchema.index({ className: 1 });
agendaEventSchema.index({ date: 1 });
agendaEventSchema.index({ teacherId: 1 });

module.exports = mongoose.model('AgendaEvent', agendaEventSchema);