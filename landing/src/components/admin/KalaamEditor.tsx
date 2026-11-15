"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { CATEGORIES, CATEGORY_INFO, type Category, type Kalaam } from "@/lib/api";
import {
  createKalaam,
  refreshPublicPages,
  stanzasToText,
  textToStanzas,
  updateKalaam,
} from "@/lib/admin";

export default function KalaamEditor({ existing }: { existing?: Kalaam }) {
  const router = useRouter();
  const [title, setTitle] = useState(existing?.title ?? "");
  const [category, setCategory] = useState<Category>(existing?.category ?? "nauha");
  const [poet, setPoet] = useState(existing?.poet ?? "");
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
      poet: poet.trim() || undefined,
      tags: tags.split(",").map((t) => t.trim()).filter(Boolean),
      isPublic,
      content: stanzas,
    };
    try {
      if (existing) await updateKalaam(existing._id, input);
      else await createKalaam(input);
      await refreshPublicPages();
      router.push("/admin");
    } catch (err) {
      setError((err as Error).message);
      setSaving(false);
    }
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
        <label className="block">
          <span className="text-sm font-medium">Poet</span>
          <input
            value={poet}
            onChange={(e) => setPoet(e.target.value)}
            className="mt-1 w-full rounded-lg hairline px-3 py-2.5 bg-white"
          />
        </label>
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
          {saving ? "Saving…" : existing ? "Save changes" : "Publish kalaam"}
        </button>
        <button type="button" onClick={() => router.push("/admin")} className="rounded-lg hairline px-5 py-2.5">
          Cancel
        </button>
      </div>
    </form>
  );
}
