// Server-side helpers for reading public kalaam data from the Bayaaz API.
// Override with NEXT_PUBLIC_API_URL (e.g. the raw Render URL) if the
// api.mybayaaz.com DNS isn't in place yet.
export const API_URL = (
  process.env.NEXT_PUBLIC_API_URL ?? "https://api.mybayaaz.com/api"
).replace(/\/$/, "");

// Pages are rebuilt at most once an hour; the admin panel also triggers an
// on-demand refresh after every save (see app/api/revalidate).
export const REVALIDATE_SECONDS = 3600;

export const CATEGORIES = ["nauha", "marsiya", "qasida", "qata"] as const;
export type Category = (typeof CATEGORIES)[number];

export const CATEGORY_INFO: Record<
  Category,
  {
    label: string;
    plural: string;
    intro: string;
    /** What reciters of this category are called (plural / singular). */
    reciters: string;
    reciter: string;
  }
> = {
  nauha: {
    reciters: "Nauha khwans",
    reciter: "Nauha khwan",
    label: "Nauha",
    plural: "Nauhas",
    intro:
      "Nauha (noha) lyrics for majlis and matam — elegies mourning Imam Hussain (a.s.) and the martyrs of Karbala, laid out stanza by stanza for easy recitation.",
  },
  marsiya: {
    reciters: "Marsiya khwans",
    reciter: "Marsiya khwan",
    label: "Marsiya",
    plural: "Marsiyas",
    intro:
      "Marsiya lyrics in the tradition of Mir Anis and Mirza Dabeer — long-form elegiac poetry recounting the events of Karbala.",
  },
  qasida: {
    reciters: "Qasida khwans",
    reciter: "Qasida khwan",
    label: "Qasida",
    plural: "Qasidas",
    intro:
      "Qasida and manqabat lyrics in praise of the Prophet (s.a.w.w.) and the Ahlul Bayt (a.s.), ready to read and recite.",
  },
  qata: {
    reciters: "Reciters",
    reciter: "Reciter",
    label: "Qata",
    plural: "Qatas",
    intro:
      "Short qata (qita) verses — compact poems for majlis openings, salaams and personal reflection.",
  },
};

export function isCategory(v: string): v is Category {
  return (CATEGORIES as readonly string[]).includes(v);
}

export type PersonLink = { name: string; slug: string };

export type KalaamIndexItem = {
  id: string;
  title: string;
  category: Category;
  poet: string | null;
  /** Absent until the server is on the People release. */
  shayars?: PersonLink[];
  reciters?: PersonLink[];
  updatedAt: string;
};

export type ReferenceMedia = {
  url: string;
  sourceType: "audio_file" | "video_file" | "youtube";
  sourceUrl?: string | null;
  extension?: string;
  durationMs?: number;
};

export type Kalaam = {
  _id: string;
  title: string;
  category: Category;
  poet?: string;
  shayars?: PersonLink[];
  reciters?: PersonLink[];
  referenceAudio?: ReferenceMedia | null;
  tags?: string[];
  isPublic: boolean;
  content: { stanzaNumber: number; lines: string[] }[];
  author?: { _id: string; name: string } | string;
  createdAt: string;
  updatedAt: string;
};

// Render's free dyno can take ~50s to wake up, so be patient at build time.
const TIMEOUT_MS = 60_000;

/** Every public kalaam (lightweight). Returns [] if the API is unreachable. */
export async function getKalaamIndex(): Promise<KalaamIndexItem[]> {
  try {
    const res = await fetch(`${API_URL}/kalaams/index`, {
      next: { revalidate: REVALIDATE_SECONDS, tags: ["kalaams"] },
      signal: AbortSignal.timeout(TIMEOUT_MS),
    });
    if (!res.ok) return [];
    return (await res.json()) as KalaamIndexItem[];
  } catch {
    return [];
  }
}

/** A single public kalaam, or null when missing/private/unreachable. */
export async function getKalaam(id: string): Promise<Kalaam | null> {
  try {
    const res = await fetch(`${API_URL}/kalaams/${id}`, {
      next: { revalidate: REVALIDATE_SECONDS, tags: ["kalaams", `kalaam:${id}`] },
      signal: AbortSignal.timeout(TIMEOUT_MS),
    });
    if (!res.ok) return null;
    const k = (await res.json()) as Kalaam;
    return k.isPublic ? k : null;
  } catch {
    return null;
  }
}

export type SiteStats = {
  kalaams: number;
  poets: number;
  /** Registered users. Null when only the fallback (index) was reachable. */
  reciters: number | null;
  /** Majlis sessions held. Null when only the fallback was reachable. */
  majalis: number | null;
};

/**
 * Live counters for the home page. Uses /kalaams/stats, falling back to
 * counting the public index (kalaams + poets only). Null if the API is down.
 */
export async function getSiteStats(): Promise<SiteStats | null> {
  try {
    const res = await fetch(`${API_URL}/kalaams/stats`, {
      next: { revalidate: REVALIDATE_SECONDS, tags: ["kalaams"] },
      signal: AbortSignal.timeout(TIMEOUT_MS),
    });
    if (res.ok) return (await res.json()) as SiteStats;
  } catch {
    // fall through to the index
  }
  const index = await getKalaamIndex();
  if (index.length === 0) return null;
  const poets = new Set(
    index.map((k) => k.poet?.trim().toLowerCase()).filter(Boolean),
  );
  return { kalaams: index.length, poets: poets.size, reciters: null, majalis: null };
}

/** 1240 → "1.2k", 12 → "12". */
export function formatCount(n: number): string {
  if (n < 1000) return String(n);
  const k = n / 1000;
  return `${k >= 10 ? Math.round(k) : k.toFixed(1).replace(/\.0$/, "")}k`;
}

// ─── People (shayars / reciters) ───────────────────────────────────────────

export type PersonSummary = PersonLink & { count: number };

/** People appearing in a category, each with how many of its kalaams. */
export function peopleInCategory(
  index: KalaamIndexItem[],
  category: Category,
): { reciters: PersonSummary[]; shayars: PersonSummary[] } {
  const tally = (pick: (k: KalaamIndexItem) => PersonLink[] | undefined) => {
    const map = new Map<string, PersonSummary>();
    for (const k of index) {
      if (k.category !== category) continue;
      for (const p of pick(k) ?? []) {
        const e = map.get(p.slug) ?? { ...p, count: 0 };
        e.count += 1;
        map.set(p.slug, e);
      }
    }
    return [...map.values()].sort(
      (a, b) => b.count - a.count || a.name.localeCompare(b.name),
    );
  };
  return { reciters: tally((k) => k.reciters), shayars: tally((k) => k.shayars) };
}

/** A person's kalaams within a category, and which roles they hold there. */
export function personInCategory(
  index: KalaamIndexItem[],
  category: Category,
  slug: string,
) {
  let person: PersonLink | null = null;
  let asReciter = 0;
  let asShayar = 0;
  const items = index.filter((k) => {
    if (k.category !== category) return false;
    const r = k.reciters?.find((p) => p.slug === slug);
    const s = k.shayars?.find((p) => p.slug === slug);
    if (r) asReciter += 1;
    if (s) asShayar += 1;
    person = person ?? r ?? s ?? null;
    return Boolean(r || s);
  });
  return { person: person as PersonLink | null, items, asReciter, asShayar };
}

/** "A, B and C" */
export function joinNames(people: PersonLink[] | undefined): string {
  const names = (people ?? []).map((p) => p.name);
  if (names.length <= 1) return names[0] ?? "";
  return `${names.slice(0, -1).join(", ")} and ${names[names.length - 1]}`;
}

// ─── Slugs ─────────────────────────────────────────────────────────────────
// URLs look like /kalaam/mujhe-awaaz-do-aaye-mere-baba-6a1c271dea5d5e07cc8b3e95.
// The Mongo id at the end is the real key, so titles can change freely
// (old slugs redirect to the current one).

export function slugify(title: string): string {
  return (
    title
      .normalize("NFKD")
      .toLowerCase()
      // keep latin letters/digits and Arabic-script letters
      .replace(/[^a-z0-9؀-ۿ\s-]/g, "")
      .trim()
      .replace(/[\s_-]+/g, "-")
      .replace(/^-+|-+$/g, "")
      .slice(0, 80) || "kalaam"
  );
}

export function kalaamSlug(k: { id?: string; _id?: string; title: string }) {
  return `${slugify(k.title)}-${k.id ?? k._id}`;
}

export function kalaamPath(k: { id?: string; _id?: string; title: string }) {
  return `/kalaam/${kalaamSlug(k)}`;
}

export function idFromSlug(slug: string): string | null {
  const m = decodeURIComponent(slug).match(/([a-f0-9]{24})$/i);
  return m ? m[1].toLowerCase() : null;
}

/** True when the text is mostly Arabic-script (Urdu written in Nastaliq). */
export function isArabicScript(text: string): boolean {
  const arabic = (text.match(/[؀-ۿ]/g) || []).length;
  const latin = (text.match(/[a-z]/gi) || []).length;
  return arabic > latin;
}
