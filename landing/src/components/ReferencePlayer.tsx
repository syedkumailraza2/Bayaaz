import { youtubeId, type ReferenceMedia } from "@/lib/api";

const VIDEO_EXTS = new Set(["mp4", "mov", "webm", "mkv"]);

/** Audio or video player for a kalaam's reference recitation. */
export default function ReferencePlayer({
  media,
  title,
}: {
  media: ReferenceMedia;
  title: string;
}) {
  // A pasted YouTube link (no uploaded file): use YouTube's own player.
  const embedId = youtubeId(media.url);
  if (embedId) {
    return (
      <section
        aria-label="Watch this kalaam"
        className="mb-10 rounded-2xl hairline bg-surface-container-low p-4 md:p-5"
      >
        <p className="font-mono text-[11px] uppercase tracking-widest text-outline mb-3">
          Watch the recitation
        </p>
        <div className="relative w-full aspect-video rounded-xl overflow-hidden bg-black">
          <iframe
            src={`https://www.youtube-nocookie.com/embed/${embedId}?rel=0`}
            title={`Recitation of ${title}`}
            loading="lazy"
            allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share"
            referrerPolicy="strict-origin-when-cross-origin"
            allowFullScreen
            className="absolute inset-0 w-full h-full"
          />
        </div>
      </section>
    );
  }

  const ext = (media.extension || media.url.split(".").pop() || "").toLowerCase();
  const isVideo = media.sourceType === "video_file" || VIDEO_EXTS.has(ext);

  return (
    <section
      aria-label="Listen to this kalaam"
      className="mb-10 rounded-2xl hairline bg-surface-container-low p-4 md:p-5"
    >
      <p className="font-mono text-[11px] uppercase tracking-widest text-outline mb-3">
        {isVideo ? "Watch the recitation" : "Listen to the recitation"}
      </p>
      {isVideo ? (
        <video
          controls
          playsInline
          preload="metadata"
          src={media.url}
          className="w-full max-h-[420px] rounded-xl bg-black"
          aria-label={`Recitation of ${title}`}
        />
      ) : (
        <audio
          controls
          preload="metadata"
          src={media.url}
          className="w-full"
          aria-label={`Recitation of ${title}`}
        />
      )}
      {media.sourceType === "youtube" && media.sourceUrl ? (
        <a
          href={media.sourceUrl}
          target="_blank"
          rel="noopener noreferrer"
          className="mt-3 inline-block text-sm underline underline-offset-4 text-on-surface-variant hover:text-primary"
        >
          Watch on YouTube
        </a>
      ) : null}
    </section>
  );
}
