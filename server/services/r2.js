// Cloudflare R2 (S3-compatible) helpers — presigned uploads and object
// deletion. Keys live in env vars; nothing in this module is safe to ship to
// the client. The endpoint format and `region: 'auto'` are R2's quirks.
//
// Required env:
//   R2_ACCOUNT_ID         Cloudflare account ID (32-hex string)
//   R2_ACCESS_KEY_ID      API token Access Key ID
//   R2_SECRET_ACCESS_KEY  API token Secret Access Key
//   R2_BUCKET             Bucket name (e.g. 'bayaaz-references')
//   R2_PUBLIC_BASE_URL    Where uploaded objects are publicly served, no
//                         trailing slash. Either a custom domain
//                         (https://media.bayaaz.app) or the bucket's r2.dev
//                         URL (https://pub-<hash>.r2.dev).

const {
  S3Client,
  DeleteObjectCommand,
  PutObjectCommand,
} = require('@aws-sdk/client-s3');
const { getSignedUrl } = require('@aws-sdk/s3-request-presigner');
const crypto = require('crypto');

function requireEnv(name) {
  const v = process.env[name];
  if (!v) {
    throw new Error(
      `R2 not configured — set ${name} in the server environment.`,
    );
  }
  return v;
}

let _client = null;
function client() {
  if (_client) return _client;
  const accountId = requireEnv('R2_ACCOUNT_ID');
  _client = new S3Client({
    region: 'auto',
    endpoint: `https://${accountId}.r2.cloudflarestorage.com`,
    credentials: {
      accessKeyId: requireEnv('R2_ACCESS_KEY_ID'),
      secretAccessKey: requireEnv('R2_SECRET_ACCESS_KEY'),
    },
  });
  return _client;
}

const ALLOWED_EXTS = new Set([
  'mp3', 'm4a', 'aac', 'wav', 'ogg', 'opus', 'flac',
  'mp4', 'mov', 'webm', 'mkv',
]);

const CONTENT_TYPE_BY_EXT = {
  mp3: 'audio/mpeg',
  m4a: 'audio/aac',
  aac: 'audio/aac',
  wav: 'audio/wav',
  ogg: 'audio/ogg',
  opus: 'audio/ogg',
  flac: 'audio/flac',
  mp4: 'video/mp4',
  mov: 'video/quicktime',
  webm: 'video/webm',
  mkv: 'video/x-matroska',
};

function bucket() {
  return requireEnv('R2_BUCKET');
}

function publicBase() {
  return requireEnv('R2_PUBLIC_BASE_URL').replace(/\/+$/, '');
}

// Builds <kalaamId>/<uuid>.<ext>. We use crypto.randomUUID instead of pulling
// in another dep — Node 16.7+ has it built in.
function buildObjectKey({ kalaamId, extension }) {
  const ext = String(extension || '').toLowerCase().replace(/^\./, '');
  const safeExt = ALLOWED_EXTS.has(ext) ? ext : 'm4a';
  const id = crypto.randomUUID();
  return `${kalaamId}/${id}.${safeExt}`;
}

function publicUrlFor(key) {
  return `${publicBase()}/${key}`;
}

// Returns `{ uploadUrl, publicUrl, key, contentType, expiresInSec }`.
// The client must PUT the file bytes to `uploadUrl` with a matching
// `Content-Type` header within `expiresInSec` seconds.
async function presignReferenceUpload({ kalaamId, extension }) {
  const key = buildObjectKey({ kalaamId, extension });
  const ext = key.split('.').pop().toLowerCase();
  const contentType = CONTENT_TYPE_BY_EXT[ext] || 'application/octet-stream';
  const expiresInSec = 60 * 10; // 10 minutes is plenty for mobile uploads
  const cmd = new PutObjectCommand({
    Bucket: bucket(),
    Key: key,
    ContentType: contentType,
  });
  const uploadUrl = await getSignedUrl(client(), cmd, { expiresIn: expiresInSec });
  return {
    uploadUrl,
    publicUrl: publicUrlFor(key),
    key,
    contentType,
    expiresInSec,
  };
}

// `key` is the object's storage key — derived from the public URL on the
// server so the client never gets to specify arbitrary keys.
function keyFromPublicUrl(rawUrl) {
  try {
    const u = new URL(rawUrl);
    const base = new URL(publicBase());
    if (u.hostname !== base.hostname) return null;
    // Strip the base path (in case the custom domain is mapped at a prefix).
    const basePath = base.pathname.replace(/\/+$/, '');
    if (!u.pathname.startsWith(basePath + '/')) return null;
    return u.pathname.slice(basePath.length + 1);
  } catch {
    return null;
  }
}

async function deleteByPublicUrl(rawUrl) {
  const key = keyFromPublicUrl(rawUrl);
  if (!key) return false;
  await client().send(new DeleteObjectCommand({ Bucket: bucket(), Key: key }));
  return true;
}

// True when the given URL points at our configured public base — used by
// `routes/kalaam.js` to validate `setReferenceAudio` payloads.
function isManagedPublicUrl(rawUrl) {
  if (typeof rawUrl !== 'string' || !rawUrl) return false;
  try {
    const u = new URL(rawUrl);
    if (u.protocol !== 'https:') return false;
    const base = new URL(publicBase());
    if (u.hostname !== base.hostname) return false;
    const basePath = base.pathname.replace(/\/+$/, '');
    return u.pathname.startsWith(basePath + '/');
  } catch {
    return false;
  }
}

module.exports = {
  presignReferenceUpload,
  deleteByPublicUrl,
  isManagedPublicUrl,
  ALLOWED_EXTS,
};
