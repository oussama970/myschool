const User = require('../models/User');

// @desc    Récupérer tous les parents avec leurs enfants
// @route   GET /api/admin/parents
// @access  Private/Admin
const getAllParents = async (req, res) => {
  try {
    // Récupérer tous les parents
    const parents = await User.find({ role: 'parent' }).select('-password');
    
    // Pour chaque parent, récupérer les enfants
    const parentsWithChildren = await Promise.all(parents.map(async (parent) => {
      let children = [];
      
      // Vérifier si le parent a des enfants (via le champ children)
      if (parent.children && parent.children.length > 0) {
        children = await User.find({ 
          '_id': { $in: parent.children },
          role: 'student' 
        }).select('fullName email className childCode');
      }
      
      // Vérifier aussi via linkedParents (si des élèves sont liés par email)
      const linkedStudents = await User.find({ 
        linkedParents: parent.email,
        role: 'student' 
      }).select('fullName email className childCode');
      
      // Fusionner les deux listes sans doublons
      const allChildren = [...children, ...linkedStudents];
      const uniqueChildren = [];
      const ids = new Set();
      
      for (const child of allChildren) {
        if (!ids.has(child._id.toString())) {
          ids.add(child._id.toString());
          uniqueChildren.push(child);
        }
      }
      
      // Convertir en objet simple
      const parentObj = parent.toObject();
      parentObj.children = uniqueChildren;
      
      return parentObj;
    }));
    
    console.log(`📚 ${parentsWithChildren.length} parents chargés`);
    
    res.json({ success: true, parents: parentsWithChildren });
  } catch (error) {
    console.error('Erreur récupération parents:', error);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};

// @desc    Supprimer un parent
// @route   DELETE /api/admin/parents/:id
// @access  Private/Admin
const deleteParent = async (req, res) => {
  try {
    const parent = await User.findById(req.params.id);
    if (!parent || parent.role !== 'parent') {
      return res.status(404).json({ success: false, message: 'Parent non trouvé' });
    }
    
    // Retirer le parent des élèves liés
    await User.updateMany(
      { linkedParents: parent.email },
      { $pull: { linkedParents: parent.email } }
    );
    
    await parent.deleteOne();
    res.json({ success: true, message: 'Parent supprimé' });
  } catch (error) {
    console.error('Erreur suppression parent:', error);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};

module.exports = { getAllParents, deleteParent };