const Schedule = require('../models/Schedule');

const saveSchedule = async (req, res) => {
  try {
    const { className, schedule } = req.body;
    
    let existingSchedule = await Schedule.findOne({ className });
    
    if (existingSchedule) {
      existingSchedule.schedule = schedule;
      await existingSchedule.save();
    } else {
      await Schedule.create({
        className,
        schedule,
        createdBy: req.user._id,
      });
    }
    
    res.json({ success: true, message: 'Agenda sauvegardé' });
  } catch (error) {
    console.error('Erreur saveSchedule:', error);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};

const getSchedule = async (req, res) => {
  try {
    const { className } = req.params;
    const schedule = await Schedule.findOne({ className });
    
    res.json({ success: true, schedule: schedule?.schedule || {} });
  } catch (error) {
    console.error('Erreur getSchedule:', error);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};

module.exports = { saveSchedule, getSchedule };