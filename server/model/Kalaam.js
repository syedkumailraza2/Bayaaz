const mongoose = require('mongoose');

const CATEGORIES = ['nauha', 'marsiya', 'qasida', 'qata'];

const stanzaSchema = new mongoose.Schema({
  stanzaNumber: { type: Number, required: true },
  lines: [{ type: String, required: true }],
}, { _id: false });

const kalaamSchema = new mongoose.Schema({
  title: { type: String, required: true, trim: true },
  content: { type: [stanzaSchema], required: true, validate: v => v.length > 0 },
  category: { type: String, required: true, enum: CATEGORIES },
  isPublic: { type: Boolean, default: true },
  author: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  poet: { type: String, trim: true },
  tags: [{ type: String, trim: true }],
}, { timestamps: true });

module.exports = mongoose.model('Kalaam', kalaamSchema);
