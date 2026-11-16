"use client";

// Browser-side helpers for the admin panel. The API (Express on Render)
// already allows cross-origin requests, so the panel talks to it directly
// with the same JWT the mobile app uses.
import { API_URL, type Category, type Kalaam, type ReferenceMedia } from "@/lib/api";

const TOKEN_KEY = "bayaaz:admin-token";
const USER_KEY = "bayaaz:admin-user";

export type AdminUser = { id: string; name: string; email: string; role: string };

export function getToken(): string | null {
  try {
    return localStorage.getItem(TOKEN_KEY);
  } catch {
    return null;
  }
}

export function getStoredUser(): AdminUser | null {
  try {
    const raw = localStorage.getItem(USER_KEY);
    return raw ? (JSON.parse(raw) as AdminUser) : null;
  } catch {
    return null;
  }
}

function saveSession(token: string, user: AdminUser) {
  try {
    localStorage.setItem(TOKEN_KEY, token);
    localStorage.setItem(USER_KEY, JSON.stringify(user));
  } catch {}
}

export function logout() {
  try {
    localStorage.removeItem(TOKEN_KEY);
    localStorage.removeItem(USER_KEY);
  } catch {}
}

export class ApiError extends Error {
  constructor(public status: number, message: string) {
    super(message);
  }
}

export async function apiFetch<T>(path: string, init: RequestInit = {}): Promise<T> {
  const token = getToken();
  const res = await fetch(`${API_URL}${path}`, {
    ...init,
    headers: {
      "Content-Type": "application/json",
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
      ...(init.headers || {}),
    },
  });
  const body = await res.json().catch(() => ({}));
  if (!res.ok) {
    if (res.status === 401) logout();
    throw new ApiError(res.status, body?.message || `Request failed (${res.status})`);
  }
  return body as T;
}

async function finishLogin(data: { token: string; user: AdminUser }) {
  if (data.user.role !== "admin") {
    throw new ApiError(403, "This account is not an admin.");
  }
  saveSession(data.token, data.user);
  return data.user;
}

export async function loginWithPassword(email: string, password: string) {
  const data = await apiFetch<{ token: string; user: AdminUser }>("/auth/login", {
    method: "POST",
    body: JSON.stringify({ email, password }),
  });
  return finishLogin(data);
}

export async function loginWithGoogle(idToken: string) {
  const data = await apiFetch<{ token: string; user: AdminUser }>("/auth/google", {
    method: "POST",
    body: JSON.stringify({ idToken }),
  });
  return finishLogin(data);
}

/** Re-checks the stored session against the server (role may have changed). */
export async function verifySession(): Promise<AdminUser | null> {
  if (!getToken()) return null;
  try {
    const { user } = await apiFetch<{ user: AdminUser }>("/auth/me");
    if (user.role !== "admin") {
      logout();
      return null;
    }
    return user;
  } catch {
    return null;
  }
}

// ─── Kalaam CRUD ───────────────────────────────────────────────────────────

export type KalaamInput = {
  title: string;
  category: Category;
  /** Names; new ones are added to the People table on save (admins). */
  shayars: string[];
  reciters: string[];
  tags: string[];
  isPublic: boolean;
  content: { stanzaNumber: number; lines: string[] }[];
};

export type AdminList = {
  items: Kalaam[];
  page: number;
  total: number;
  hasMore: boolean;
};

export const listKalaams = (params: { q?: string; category?: string; page?: number }) => {
  const qs = new URLSearchParams();
  if (params.q) qs.set("q", params.q);
  if (params.category) qs.set("category", params.category);
  qs.set("page", String(params.page ?? 1));
  qs.set("limit", "50");
  return apiFetch<AdminList>(`/kalaams/admin/all?${qs}`);
};

export const getKalaamAdmin = (id: string) => apiFetch<Kalaam>(`/kalaams/${id}`);

export const createKalaam = (k: KalaamInput) =>
  apiFetch<Kalaam>("/kalaams", { method: "POST", body: JSON.stringify(k) });

export const updateKalaam = (id: string, k: KalaamInput) =>
  apiFetch<Kalaam>(`/kalaams/${id}`, { method: "PUT", body: JSON.stringify(k) });

export const toggleVisibility = (id: string) =>
  apiFetch<Kalaam>(`/kalaams/${id}/visibility`, { method: "PATCH" });

export const deleteKalaam = (id: string) =>
  apiFetch<{ message: string }>(`/kalaams/${id}`, { method: "DELETE" });

// ─── People (shayars / nauha khwans) ───────────────────────────────────────

export type Person = { id: string; name: string; slug: string };

export const searchPeople = (q: string) =>
  apiFetch<Person[]>(`/people?q=${encodeURIComponent(q)}&limit=8`);

// ─── Reference audio / video ───────────────────────────────────────────────

export const REFERENCE_EXTS = [
  "mp3", "m4a", "aac", "wav", "ogg", "opus", "flac",
  "mp4", "mov", "webm", "mkv",
] as const;
const VIDEO_EXTS = new Set(["mp4", "mov", "webm", "mkv"]);

export function fileExtension(file: File) {
  return (file.name.split(".").pop() || "").toLowerCase();
}

/** Duration in ms read from the file's metadata in the browser (0 if unknown). */
function measureDuration(file: File): Promise<number> {
  return new Promise((resolve) => {
    const url = URL.createObjectURL(file);
    const el = document.createElement(VIDEO_EXTS.has(fileExtension(file)) ? "video" : "audio");
    const done = (ms: number) => {
      URL.revokeObjectURL(url);
      resolve(ms);
    };
    el.preload = "metadata";
    el.onloadedmetadata = () => done(Number.isFinite(el.duration) ? Math.round(el.duration * 1000) : 0);
    el.onerror = () => done(0);
    setTimeout(() => done(0), 8000);
    el.src = url;
  });
}

/**
 * Upload a reference audio/video for a kalaam: presign on the API, PUT the
 * bytes straight to R2 (with progress), then record it on the kalaam.
 */
export async function uploadReference(
  kalaamId: string,
  file: File,
  onProgress: (fraction: number) => void,
): Promise<Kalaam> {
  const extension = fileExtension(file);
  const presign = await apiFetch<{ uploadUrl: string; publicUrl: string; contentType: string }>(
    `/kalaams/${kalaamId}/reference/presign`,
    { method: "POST", body: JSON.stringify({ extension }) },
  );
  await new Promise<void>((resolve, reject) => {
    const xhr = new XMLHttpRequest();
    xhr.open("PUT", presign.uploadUrl);
    xhr.setRequestHeader("Content-Type", presign.contentType);
    xhr.upload.onprogress = (e) => e.lengthComputable && onProgress(e.loaded / e.total);
    xhr.onload = () =>
      xhr.status >= 200 && xhr.status < 300
        ? resolve()
        : reject(new Error(`Upload failed (${xhr.status})`));
    xhr.onerror = () => reject(new Error("Upload failed — check your connection."));
    xhr.send(file);
  });
  const durationMs = await measureDuration(file);
  const media: ReferenceMedia = {
    url: presign.publicUrl,
    sourceType: VIDEO_EXTS.has(extension) ? "video_file" : "audio_file",
    extension,
    durationMs,
  };
  return apiFetch<Kalaam>(`/kalaams/${kalaamId}/reference`, {
    method: "POST",
    body: JSON.stringify(media),
  });
}

export const removeReference = (kalaamId: string) =>
  apiFetch<Kalaam>(`/kalaams/${kalaamId}/reference`, { method: "DELETE" });

/** Ask the website to rebuild its public pages after a change. Best-effort. */
export async function refreshPublicPages() {
  const token = getToken();
  if (!token) return;
  try {
    await fetch("/api/revalidate", {
      method: "POST",
      headers: { Authorization: `Bearer ${token}` },
    });
  } catch {}
}

// ─── Lyrics text <-> stanzas ───────────────────────────────────────────────
// Same rules as the app's Add Kalaam screen: a blank line separates stanzas,
// each non-empty line is one line of the stanza.

export function textToStanzas(text: string) {
  const clean = text.replace(/\r\n?/g, "\n").trim();
  if (!clean) return [];
  return clean
    .split(/\n[ \t]*\n+/)
    .map((chunk) =>
      chunk
        .split("\n")
        .map((l) => l.trim())
        .filter(Boolean),
    )
    .filter((lines) => lines.length > 0)
    .map((lines, i) => ({ stanzaNumber: i + 1, lines }));
}

export function stanzasToText(content: { lines: string[] }[]) {
  return content.map((s) => s.lines.join("\n")).join("\n\n");
}
