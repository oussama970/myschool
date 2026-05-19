const Schedule = require('../models/Schedule');
const Teacher = require('../models/Teacher');

// Fonction utilitaire pour obtenir le nom du jour
const getDayName = (day) => {
  const days = {
    'Lu': 'Lundi',
    'Ma': 'Mardi',
    'Me': 'Mercredi',
    'Je': 'Jeudi',
    'Ve': 'Vendredi',
    'Sa': 'Samedi'
  };
  return days[day] || day;
};

// Créneaux horaires standards (8h à 13h uniquement)
const TIME_SLOTS = [
  '08h-09h',  // index 0
  '09h-10h',  // index 1
  '10h-11h',  // index 2
  '11h-12h',  // index 3
  '12h-13h'   // index 4
];

const DAYS = ['Lu', 'Ma', 'Me', 'Je', 'Ve', 'Sa'];

// Sauvegarder l'agenda
const saveSchedule = async (req, res) => {
  try {
    const { className, schedule } = req.body;
    
    console.log('========== SAVE SCHEDULE ==========');
    console.log('Classe:', className);
    console.log('Utilisateur:', req.user?.email, 'Rôle:', req.user?.role);
    
    if (!className) {
      return res.status(400).json({ success: false, message: 'Nom de classe requis' });
    }
    
    let existingSchedule = await Schedule.findOne({ className });
    
    if (existingSchedule) {
      existingSchedule.schedule = schedule;
      existingSchedule.updatedAt = Date.now();
      await existingSchedule.save();
      console.log('✅ Agenda mis à jour pour:', className);
    } else {
      await Schedule.create({
        className,
        schedule,
        createdBy: req.user?._id,
        createdAt: Date.now(),
        updatedAt: Date.now()
      });
      console.log('✅ Agenda créé pour:', className);
    }
    
    const verify = await Schedule.findOne({ className });
    console.log('📋 Vérification après sauvegarde:', verify ? 'OK' : 'NON TROUVÉ');
    
    res.json({ success: true, message: 'Agenda sauvegardé' });
  } catch (error) {
    console.error('❌ Erreur saveSchedule:', error);
    res.status(500).json({ success: false, message: 'Erreur serveur: ' + error.message });
  }
};

// Récupérer l'agenda
const getSchedule = async (req, res) => {
  try {
    const { className } = req.params;
    const decodedClassName = decodeURIComponent(className);
    
    console.log('========== GET SCHEDULE ==========');
    console.log('Classe demandée:', decodedClassName);
    
    const schedule = await Schedule.findOne({ className: decodedClassName });
    
    if (schedule) {
      console.log('✅ Agenda trouvé');
      
      // Formater l'agenda pour le frontend
      const formattedSchedule = {};
      for (const day of DAYS) {
        formattedSchedule[day] = {};
        for (let i = 0; i < TIME_SLOTS.length; i++) {
          const slotData = schedule.schedule[day]?.[i.toString()];
          if (slotData && slotData.subject && slotData.subject !== 'PAUSE DÉJEUNER') {
            formattedSchedule[day][i] = {
              subject: slotData.subject,
              teacher: slotData.teacher,
              room: slotData.room,
              timeSlot: TIME_SLOTS[i],
              startHour: parseInt(TIME_SLOTS[i].split('-')[0].replace('h', '')),
              endHour: parseInt(TIME_SLOTS[i].split('-')[1].replace('h', ''))
            };
          }
        }
      }
      
      res.json({ 
        success: true, 
        schedule: schedule.schedule,
        formattedSchedule: formattedSchedule,
        timeSlots: TIME_SLOTS,
        days: DAYS
      });
    } else {
      console.log('⚠️ Aucun agenda trouvé pour:', decodedClassName);
      res.json({ 
        success: true, 
        schedule: {},
        formattedSchedule: {},
        timeSlots: TIME_SLOTS,
        days: DAYS
      });
    }
  } catch (error) {
    console.error('❌ Erreur getSchedule:', error);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};

// Récupérer les créneaux d'un enseignant pour une classe
const getTeacherSchedule = async (req, res) => {
  try {
    const { teacherEmail, className } = req.params;
    const decodedClassName = decodeURIComponent(className);
    
    console.log('========== GET TEACHER SCHEDULE ==========');
    console.log('Enseignant email:', teacherEmail);
    console.log('Classe:', decodedClassName);
    
    // Récupérer l'emploi du temps de la classe
    const schedule = await Schedule.findOne({ className: decodedClassName });
    
    if (!schedule) {
      console.log('⚠️ Aucun agenda trouvé pour la classe');
      return res.json({ success: true, teacherSlots: [], subjects: [] });
    }
    
    // Récupérer les informations de l'enseignant
    const teacher = await Teacher.findOne({ email: teacherEmail.toLowerCase() });
    const teacherSubjects = teacher?.subjects || [];
    const teacherName = teacher?.fullName || '';
    const teacherEmailAddress = teacher?.email || teacherEmail;
    
    console.log('👨‍🏫 Enseignant trouvé:');
    console.log('   Nom:', teacherName);
    console.log('   Email:', teacherEmailAddress);
    console.log('   Matières:', teacherSubjects);
    
    const teacherSlots = [];
    
    // Parcourir l'agenda pour trouver les cours de cet enseignant
    for (const day of DAYS) {
      for (let i = 0; i < TIME_SLOTS.length; i++) {
        const slotData = schedule.schedule[day]?.[i.toString()];
        if (slotData) {
          const slotTeacher = slotData.teacher || '';
          // Comparer avec l'email ou le nom (insensible à la casse)
          if (slotTeacher.toLowerCase() === teacherEmailAddress.toLowerCase() || 
              slotTeacher.toLowerCase() === teacherName.toLowerCase()) {
            teacherSlots.push({
              day: day,
              dayName: getDayName(day),
              slotIndex: i,
              timeSlot: TIME_SLOTS[i],
              subject: slotData.subject,
              room: slotData.room,
              startHour: parseInt(TIME_SLOTS[i].split('-')[0].replace('h', '')),
              endHour: parseInt(TIME_SLOTS[i].split('-')[1].replace('h', ''))
            });
          }
        }
      }
    }
    
    console.log(`✅ ${teacherSlots.length} créneaux trouvés pour cet enseignant`);
    teacherSlots.forEach(slot => {
      console.log(`   - ${slot.dayName} ${slot.timeSlot}: ${slot.subject} (Salle ${slot.room})`);
    });
    
    res.json({ 
      success: true, 
      teacherSlots: teacherSlots,
      subjects: teacherSubjects,
      teacherName: teacherName
    });
  } catch (error) {
    console.error('❌ Erreur getTeacherSchedule:', error);
    res.status(500).json({ success: false, message: 'Erreur serveur: ' + error.message });
  }
};

// Récupérer tous les créneaux d'un enseignant pour toutes ses classes
const getAllTeacherSchedules = async (req, res) => {
  try {
    const { teacherEmail } = req.params;
    
    console.log('========== GET ALL TEACHER SCHEDULES ==========');
    console.log('Enseignant:', teacherEmail);
    
    // Récupérer les informations de l'enseignant
    const teacher = await Teacher.findOne({ email: teacherEmail.toLowerCase() });
    if (!teacher) {
      return res.status(404).json({ success: false, message: 'Enseignant non trouvé' });
    }
    
    const teacherName = teacher.fullName;
    const teacherEmailAddress = teacher.email;
    const assignedClasses = teacher.assignedClasses || [];
    
    console.log('Classes assignées:', assignedClasses);
    
    const allSchedules = {};
    
    for (const className of assignedClasses) {
      const schedule = await Schedule.findOne({ className });
      const teacherSlots = [];
      
      if (schedule) {
        for (const day of DAYS) {
          for (let i = 0; i < TIME_SLOTS.length; i++) {
            const slotData = schedule.schedule[day]?.[i.toString()];
            if (slotData) {
              const slotTeacher = slotData.teacher || '';
              if (slotTeacher.toLowerCase() === teacherEmailAddress.toLowerCase() || 
                  slotTeacher.toLowerCase() === teacherName.toLowerCase()) {
                teacherSlots.push({
                  className: className,
                  day: day,
                  dayName: getDayName(day),
                  slotIndex: i,
                  timeSlot: TIME_SLOTS[i],
                  subject: slotData.subject,
                  room: slotData.room,
                  startHour: parseInt(TIME_SLOTS[i].split('-')[0].replace('h', '')),
                  endHour: parseInt(TIME_SLOTS[i].split('-')[1].replace('h', ''))
                });
              }
            }
          }
        }
      }
      
      allSchedules[className] = teacherSlots;
      console.log(`   ${className}: ${teacherSlots.length} créneaux`);
    }
    
    console.log('✅ Créneaux récupérés pour toutes les classes');
    
    res.json({ 
      success: true, 
      schedules: allSchedules,
      subjects: teacher.subjects || [],
      teacherName: teacherName
    });
  } catch (error) {
    console.error('❌ Erreur getAllTeacherSchedules:', error);
    res.status(500).json({ success: false, message: 'Erreur serveur: ' + error.message });
  }
};

// Mettre à jour un créneau spécifique
const updateScheduleSlot = async (req, res) => {
  try {
    const { className, day, slotIndex } = req.params;
    const { subject, teacher, room } = req.body;
    const decodedClassName = decodeURIComponent(className);
    
    console.log('========== UPDATE SCHEDULE SLOT ==========');
    console.log('Classe:', decodedClassName);
    console.log('Jour:', day);
    console.log('Index:', slotIndex);
    console.log('Matière:', subject);
    
    const schedule = await Schedule.findOne({ className: decodedClassName });
    
    if (!schedule) {
      return res.status(404).json({ success: false, message: 'Agenda non trouvé' });
    }
    
    if (!schedule.schedule[day]) {
      schedule.schedule[day] = {};
    }
    
    schedule.schedule[day][slotIndex] = { subject, teacher, room };
    schedule.updatedAt = Date.now();
    await schedule.save();
    
    console.log('✅ Créneau mis à jour');
    res.json({ success: true, message: 'Créneau mis à jour' });
  } catch (error) {
    console.error('❌ Erreur updateScheduleSlot:', error);
    res.status(500).json({ success: false, message: 'Erreur serveur: ' + error.message });
  }
};

// Exporter les fonctions
module.exports = { 
  saveSchedule, 
  getSchedule, 
  getTeacherSchedule, 
  getAllTeacherSchedules,
  updateScheduleSlot
};