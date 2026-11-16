"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { CATEGORIES, CATEGORY_INFO, type Category, type Kalaam } from "@/lib/api";
import {
  createKalaam,
  fileExtension,
  REFERENCE_EXTS,
  refreshPublicPages,
  removeReference,
  stanzasToText,
  textToStanzas,
  updateKalaam,
  uploadReference,
} from "@/lib/admin";
import PeopleInput, { type Chip } from "@/components/admin/PeopleInput";
import ReferencePlayer from "@/components/ReferencePlayer";

const toChips = (people?: { name: string }[], legacy?: string): Chip[] =>
  people?.length
    ? people.map((p) => ({ name: p.name, isNew: false }))
    : (legacy ?? "")
        .split(",")
        .map((n) => n.trim())
        .filter(Boolean)
        .map((name) => ({ name, isNew: false }));

const MB = 1024 * 1024;

export default function KalaamEditor({ existing }: { existing?: Kalaam }) {
  const router = useRouter();
  const [title, setTitle] = useState(existing?.title ?? "");
  const [category, setCategory] = useState<Category>(existing?.category ?? "nauha");
  const [shayars, setShayars] = useState<Chip[]>(toChips(existing?.shayars, existing?.poet));
  const [reciters, setReciters] = useState<Chip[]>(toChips(existing?.reciters));
  const media = existing?.referenceAudio ?? null;
  const [newFile, setNewFile] = useState<File | null>(null);
  const [removeMedia, setRemoveMedia] = useState(false);
  const [progress, setProgress] = useState<number | null>(null);
  const [tags, setTags] = useState((existing?.tags ?? []).join(", "));
  const [isPublic, setIsPublic] = useState(existing?.isPublic ?? true);
  const [lyrics, setLyrics] = useState(existing ? stanzasToText(existing.content) : "");
  const [error, setError] = useState<string | null>(null);
  const [saving, setSaving] = useState(false);

  const stanzas = textToStanzas(lyrics);

  async function onSave(e: React.FormEvent) {
    e.preventDefault();
    setError(null);
    if (!title.trim()) return setError("Title is required.");
    if (stanzas.length === 0) return setError("Add at least one line of lyrics.");
    setSaving(true);
    const input = {
      title: title.trim(),
      category,
      shayars: shayars.map((c) => c.name),
      reciters: reciters.map((c) => c.name),
      tags: tags.split(",").map((t) => t.trim()).filter(Boolean),
      isPublic,
      content: stanzas,
    };
    let saved: Kalaam | null = null;
    try {
      saved = existing ? await updateKalaam(existing._id, input) : await createKalaam(input);
      if (removeMedia && media && !newFile) await removeReference(saved._id);
      if (newFile) {
        setProgress(0);
        await uploadReference(saved._id, newFile, setProgress);
      }
      await refreshPublicPages();
      router.push("/admin");
    } catch (err) {
      const msg = (err as Error).message;
      // The kalaam itself saved; only the media step failed. Send the admin
      // to its edit page so a retry doesn't create a duplicate.
      if (saved && !existing) {
        setError(`Kalaam saved, but the audio/video upload failed: ${msg}. Opening it so you can retry.`);
        await refreshPublicPages();
        setTimeout(() => router.push(`/admin/kalaam/${saved!._id}`), 2500);
        return;
      }
      setError(saved ? `Saved, but the audio/video step failed: ${msg}` : msg);
      setSaving(false);
      setProgress(null);
    }
  }

  function onPickFile(e: React.ChangeEvent<HTMLInputElement>) {
    const file = e.target.files?.[0] ?? null;
    e.target.value = "";
    if (!file) return;
    const ext = fileExtension(file);
    if (!(REFERENCE_EXTS as readonly string[]).includes(ext)) {
      setError(`Unsupported file type ".${ext}". Use ${REFERENCE_EXTS.join(", ")}.`);
      return;
    }
    setError(null);
    setNewFile(file);
    setRemoveMedia(false);
  }

  return (
    <form onSubmit={onSave} className="space-y-5">
      <div className="grid gap-4 md:grid-cols-2">
        <label className="block md:col-span-2">
          <span className="text-sm font-medium">Title</span>
          <input
            value={title}
            onChange={(e) => setTitle(e.target.value)}
            className="mt-1 w-full rounded-lg hairline px-3 py-2.5 bg-white"
            required
          />
        </label>
        <label className="block">
          <span className="text-sm font-medium">Category</span>
          <select
            value={category}
            onChange={(e) => setCategory(e.target.value as Category)}
            className="mt-1 w-full rounded-lg hairline px-3 py-2.5 bg-white"
          >
            {CATEGORIES.map((c) => (
              <option key={c} value={c}>
                {CATEGORY_INFO[c].label}
              </option>
            ))}
          </select>
        </label>
        <div className="hidden md:block" />
        <div className="md:col-span-2">
          <PeopleInput
            label={CATEGORY_INFO[category].reciters}
            hint="Who recites it. Pick from suggestions, or separate names with commas."
            value={reciters}
            onChange={setReciters}
          />
        </div>
        <div className="md:col-span-2">
          <PeopleInput
            label="Shayar"
            hint="Who wrote it. More than one? Separate with commas."
            value={shayars}
            onChange={setShayars}
          />
        </div>
        <label className="block md:col-span-2">
          <span className="text-sm font-medium">Tags (comma separated)</span>
          <input
            value={tags}
            onChange={(e) => setTags(e.target.value)}
            placeholder="imam hussain, karbala, muharram"
            className="mt-1 w-full rounded-lg hairline px-3 py-2.5 bg-white"
          />
        </label>
      </div>

      <label className="block">
        <span className="text-sm font-medium">Lyrics</span>
        <span className="block text-xs text-outline">
          One line per line. Leave a blank line between stanzas.
        </span>
        <textarea
          value={lyrics}
          onChange={(e) => setLyrics(e.target.value)}
          rows={18}
          className="mt-1 w-full rounded-lg hairline px-3 py-2.5 bg-white font-mono text-sm leading-relaxed"
        />
        <span className="block text-xs text-outline mt-1">
          {stanzas.length} stanza{stanzas.length === 1 ? "" : "s"},{" "}
          {stanzas.reduce((n, s) => n + s.lines.length, 0)} lines
        </span>
      </label>

      <fieldset className="rounded-xl hairline p-4 space-y-3">
        <legend className="text-sm font-medium px-1">Reference audio / video</legend>
        <p className="text-xs text-outline -mt-1">
          Plays above the lyrics on the website and in the app. Audio (mp3, m4a, wav…)
          or video (mp4, mov, webm).
        </p>

        {media && !removeMedia && !newFile ? (
          <ReferencePlayer media={media} title={title || "this kalaam"} />
        ) : null}

        {newFile ? (
          <div className="flex items-center justify-between gap-3 rounded-lg bg-surface-container-low px-3 py-2 text-sm">
            <span className="truncate">
              {newFile.name} · {(newFile.size / MB).toFixed(1)} MB
              {media ? " (replaces the current one)" : ""}
            </span>
            <button type="button" onClick={() => setNewFile(null)} className="underline shrink-0">
              Clear
            </button>
          </div>
        ) : null}

        {progress !== null ? (
          <div className="h-2 rounded-full bg-surface-container overflow-hidden" aria-label="Upload progress">
            <div className="h-full bg-primary transition-all" style={{ width: `${Math.round(progress * 100)}%` }} />
          </div>
        ) : null}

        <div className="flex flex-wrap gap-3">
          <label className="rounded-lg hairline px-4 py-2 text-sm cursor-pointer hover:bg-surface-container-low">
            {media || newFile ? "Choose a different file" : "Choose audio or video"}
            <input
              type="file"
              accept={REFERENCE_EXTS.map((e) => `.${e}`).join(",") + ",audio/*,video/*"}
              onChange={onPickFile}
              className="sr-only"
            />
          </label>
          {media && !newFile ? (
            <button
              type="button"
              onClick={() => setRemoveMedia((r) => !r)}
              className="rounded-lg px-4 py-2 text-sm text-red-700 hover:bg-red-50"
            >
              {removeMedia ? "Undo remove" : "Remove"}
            </button>
          ) : null}
        </div>
        {removeMedia ? (
          <p className="text-xs text-red-700">It will be removed when you save.</p>
        ) : null}
      </fieldset>

      <label className="flex items-center gap-2">
        <input type="checkbox" checked={isPublic} onChange={(e) => setIsPublic(e.target.checked)} />
        <span className="text-sm">Public (shows in the app feed and on the website)</span>
      </label>

      {error ? <p className="text-sm text-red-700" role="alert">{error}</p> : null}

      <div className="flex gap-3">
        <button
          type="submit"
          disabled={saving}
          className="bg-primary text-on-primary rounded-lg px-5 py-2.5 font-semibold disabled:opacity-60"
        >
          {progress !== null
            ? `Uploading… ${Math.round(progress * 100)}%`
            : saving
              ? "Saving…"
              : existing
                ? "Save changes"
                : "Publish kalaam"}
        </button>
        <button type="button" onClick={() => router.push("/admin")} className="rounded-lg hairline px-5 py-2.5">
          Cancel
        </button>
      </div>
    </form>
  );
}
