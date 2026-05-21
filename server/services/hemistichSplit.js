// Split each kalaam line on hemistich punctuation (Latin and Arabic commas,
// Urdu full-stop). Source documents often pack a whole bayt into one line,
// which collapses the teleprompter highlight to a single huge block. By
// splitting before we hand the kalaam to the matcher and the client, every
// hemistich becomes its own line position — the matcher can advance the
// cursor partway through a bayt, and the UI renders one short line per
// rendered row.

function splitLineIntoHemistichs(line) {
  return String(line)
    .split(/[,،۔]/)
    .map((s) => s.trim())
    .filter((s) => s.length > 0);
}

function splitKalaamHemistichs(kalaam) {
  if (!kalaam) return kalaam;
  // Mongoose docs need toObject() so we can safely mutate.
  const obj = typeof kalaam.toObject === 'function' ? kalaam.toObject() : { ...kalaam };
  if (!Array.isArray(obj.content)) return obj;
  obj.content = obj.content.map((stanza) => {
    const lines = Array.isArray(stanza.lines) ? stanza.lines : [];
    const splitLines = lines.flatMap(splitLineIntoHemistichs);
    return { ...stanza, lines: splitLines.length > 0 ? splitLines : lines };
  });
  return obj;
}

module.exports = { splitLineIntoHemistichs, splitKalaamHemistichs };
