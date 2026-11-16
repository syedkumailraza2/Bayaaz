// YouTube link helpers. A reference can be "just a YouTube link" (pasted in
// the web admin): we store the canonical watch URL; the website embeds it
// and the app downloads the audio on-device (youtube_explode_dart).

const ID = /^[A-Za-z0-9_-]{11}$/;
const HOSTS = new Set([
  'youtube.com', 'www.youtube.com', 'm.youtube.com', 'music.youtube.com',
  'youtube-nocookie.com', 'www.youtube-nocookie.com', 'youtu.be',
]);

/** Video id from any common YouTube URL shape, or null. */
function youtubeId(raw) {
  if (typeof raw !== 'string') return null;
  let u;
  try {
    u = new URL(raw.trim());
  } catch {
    return null;
  }
  if (!/^https?:$/.test(u.protocol) || !HOSTS.has(u.hostname.toLowerCase())) return null;
  let id = null;
  if (u.hostname.toLowerCase() === 'youtu.be') {
    id = u.pathname.split('/')[1];
  } else if (u.pathname === '/watch') {
    id = u.searchParams.get('v');
  } else {
    const m = u.pathname.match(/^\/(?:shorts|live|embed|v)\/([^/?#]+)/);
    id = m && m[1];
  }
  return id && ID.test(id) ? id : null;
}

const watchUrl = (id) => `https://www.youtube.com/watch?v=${id}`;

module.exports = { youtubeId, watchUrl };
