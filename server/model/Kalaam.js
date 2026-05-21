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
  // Stored as an array of user IDs so we can answer "did *I* like this?"
  // without a join. Routes return only `likesCount` + `likedByMe` to keep
  // payloads small.
  likes: { type: [{ type: mongoose.Schema.Types.ObjectId, ref: 'User' }], default: [] },
  reads: { type: Number, default: 0, min: 0 },
}, { timestamps: true });

// Shape a kalaam for the client: omit the raw `likes` array (which can grow
// unbounded) and emit `likesCount` + `likedByMe`. Pass the requesting user's
// id (or null) so we can compute the boolean cheaply.
kalaamSchema.statics.formatForClient = function (kalaamDoc, currentUserId) {
  if (!kalaamDoc) return kalaamDoc;
  const obj = typeof kalaamDoc.toObject === 'function'
    ? kalaamDoc.toObject({ virtuals: false })
    : { ...kalaamDoc };
  const likes = Array.isArray(obj.likes) ? obj.likes : [];
  obj.likesCount = likes.length;
  obj.likedByMe = !!currentUserId &&
    likes.some(uid => uid && uid.toString() === currentUserId.toString());
  delete obj.likes;
  return obj;
};

module.exports = mongoose.model('Kalaam', kalaamSchema);
