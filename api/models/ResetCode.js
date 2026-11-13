const mongoose = require('mongoose');

const ResetCodeSchema = new mongoose.Schema({
  email: { type: String, required: true, lowercase: true },
  code: { type: String, required: true },
  createdAt: { type: Date, default: Date.now, expires: 900 }
});

module.exports = mongoose.model('ResetCode', ResetCodeSchema);

