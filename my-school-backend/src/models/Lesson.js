const mongoose = require('mongoose');

const fileSchema = new mongoose.Schema({
  filename: { type: String, required: true },
  originalName: { type: String, required: true },
  fileType: { type: String, required: true },
  fileSize: { type: Number, required: true },
  filePath: { type: String, required: true },
  uploadedAt: { type: Date, default: Date.now }
});

const lessonSchema = new mongoose.Schema({
  title: { type: String, required: true },
  subject: { type: String, default: '' },
  description: { type: String, default: '' },
  type: { type: String, enum: ['Cours', 'Devoir', 'Rappel'], required: true },
  className: { type: String, required: true },
  deadline: { type: Date, default: null },
  files: [fileSchema],  // Changé: maintenant un tableau d'objets avec métadonnées
  teacherId: { type: mongoose.Schema.Types.ObjectId, ref: 'Teacher', required: true },
  teacherName: { type: String, required: true },
  createdAt: { type: Date, default: Date.now }
});

lessonSchema.index({ className: 1 });
lessonSchema.index({ type: 1 });
lessonSchema.index({ teacherId: 1 });
lessonSchema.index({ createdAt: -1 });

module.exports = mongoose.model('Lesson', lessonSchema);