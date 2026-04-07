const Schedule = require('../models/Schedule');

// @desc    Sauvegarder l'agenda d'une classe
// @route   POST /api/teacher/schedule
const saveSchedule = async (req, res) => {
  try {
    const { className, schedule } = req.body;
    
    let scheduleDoc = await Schedule.findOne({ className });
    
    if (scheduleDoc) {
      scheduleDoc.schedule = schedule;
      scheduleDoc.updatedAt = Date.now();
      await scheduleDoc.save();
    } else {
      scheduleDoc = await Schedule.create({
        className,
        schedule,
        updatedAt: Date.now()
      });
    }
    
    res.json({
      success: true,
      message: 'Agenda sauvegardé avec succès',
      schedule: scheduleDoc
    });
  } catch (error) {
    console.error('Erreur sauvegarde agenda:', error);
    res.status(500).json({ 
      success: false,
      message: 'Erreur serveur' 
    });
  }
};

// @desc    Récupérer l'agenda d'une classe
// @route   GET /api/teacher/schedule/:className
const getSchedule = async (req, res) => {
  try {
    const { className } = req.params;
    
    const scheduleDoc = await Schedule.findOne({ className });
    
    if (scheduleDoc) {
      res.json({
        success: true,
        schedule: scheduleDoc.schedule
      });
    } else {
      res.json({
        success: true,
        schedule: null
      });
    }
  } catch (error) {
    console.error('Erreur récupération agenda:', error);
    res.status(500).json({ 
      success: false,
      message: 'Erreur serveur' 
    });
  }
};

module.exports = {
  saveSchedule,
  getSchedule
};