const mongoose = require('mongoose');

const CATEGORIES = ['nauha', 'marsiya', 'qasida', 'qata'];

const stanzaSchema = new mongoose.Schema({
  stanzaNumber: { type: Number, required: true },
  lines: [{ type: String, required: true }],
}, { _id: false });

// Reference recitation attached to a kalaam. `url` is the absolute (or
// app-relative `/uploads/reference/<id>.<ext>`) location the audio can be
// fetched from. `sourceType` mirrors the client's local label so we can
// rehydrate it on a new device exactly as the uploader intended.
const referenceAudioSchema = new mongoose.Schema({
  url: { type: String, required: true },
  sourceType: { type: String, enum: ['audio_file', 'video_file', 'youtube'], required: true },
  sourceUrl: { type: String, default: null },
  durationMs: { type: Number, default: 0, min: 0 },
  extension: { type: String, default: '' },
  uploadedAt: { type: Date, default: Date.now },
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
  // Distinct users who have opened this kalaam at least once. Paired with
  // `reads` so the counter only bumps the first time each user views the
  // kalaam, instead of incrementing on every detail-screen open.
  readers: { type: [{ type: mongoose.Schema.Types.ObjectId, ref: 'User' }], default: [] },
  reads: { type: Number, default: 0, min: 0 },
  // Denormalised count of users who have this kalaam in their savedKalaams.
  // Save authority still lives on User.savedKalaams (so per-user listing is
  // a single doc read); this mirror lets feed/detail payloads expose the
  // count without an N+1 aggregation. Kept in sync inside the save route.
  savesCount: { type: Number, default: 0, min: 0 },
  // Optional follow-voice / timeline reference. Set when the uploader
  // attaches an audio/video/YouTube file in the create-kalaam screen, so
  // any device opening the kalaam can fetch and play it locally.
  referenceAudio: { type: referenceAudioSchema, default: null },
}, { timestamps: true });

// Shape a kalaam for the client: omit the raw `likes` array (which can grow
// unbounded) and emit `likesCount` + `likedByMe`. Pass the requesting user's
// id (or null) so we can compute the boolean cheaply. Optionally pass a Set
// of the requesting user's savedKalaam ids so we can also compute
// `savedByMe` without a per-item DB round trip.
kalaamSchema.statics.formatForClient = function (
  kalaamDoc,
  currentUserId,
  userSavedIds = null,
) {
  if (!kalaamDoc) return kalaamDoc;
  const obj = typeof kalaamDoc.toObject === 'function'
    ? kalaamDoc.toObject({ virtuals: false })
    : { ...kalaamDoc };
  const likes = Array.isArray(obj.likes) ? obj.likes : [];
  obj.likesCount = likes.length;
  obj.likedByMe = !!currentUserId &&
    likes.some(uid => uid && uid.toString() === currentUserId.toString());
  delete obj.likes;
  obj.savesCount = typeof obj.savesCount === 'number' ? obj.savesCount : 0;
  obj.savedByMe = !!(userSavedIds && obj._id && userSavedIds.has(obj._id.toString()));
  // `readers` can grow unbounded — clients only need the aggregate count
  // (already exposed via `reads`), so strip it from the payload.
  delete obj.readers;
  return obj;
};

module.exports = mongoose.model('Kalaam', kalaamSchema);
