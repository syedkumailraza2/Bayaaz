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
  { label: string; plural: string; intro: string }
> = {
  nauha: {
    label: "Nauha",
    plural: "Nauhas",
    intro:
      "Nauha (noha) lyrics for majlis and matam — elegies mourning Imam Hussain (a.s.) and the martyrs of Karbala, laid out stanza by stanza for easy recitation.",
  },
  marsiya: {
    label: "Marsiya",
    plural: "Marsiyas",
    intro:
      "Marsiya lyrics in the tradition of Mir Anis and Mirza Dabeer — long-form elegiac poetry recounting the events of Karbala.",
  },
  qasida: {
    label: "Qasida",
    plural: "Qasidas",
    intro:
      "Qasida and manqabat lyrics in praise of the Prophet (s.a.w.w.) and the Ahlul Bayt (a.s.), ready to read and recite.",
  },
  qata: {
    label: "Qata",
    plural: "Qatas",
    intro:
      "Short qata (qita) verses — compact poems for majlis openings, salaams and personal reflection.",
  },
};

export function isCategory(v: string): v is Category {
  return (CATEGORIES as readonly string[]).includes(v);
}

export type KalaamIndexItem = {
  id: string;
  title: string;
  category: Category;
  poet: string | null;
  updatedAt: string;
};

export type Kalaam = {
  _id: string;
  title: string;
  category: Category;
  poet?: string;
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
