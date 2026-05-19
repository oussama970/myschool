const generateCode = (length = 6) => {
  // CORRECTION: Permet les codes commençant par 0
  let code = '';
  for (let i = 0; i < length; i++) {
    code += Math.floor(Math.random() * 10).toString();
  }
  return code;
};

module.exports = generateCode;