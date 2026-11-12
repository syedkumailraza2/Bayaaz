import { revalidatePath } from "next/cache";
import { API_URL } from "@/lib/api";

// Called by the admin panel after a kalaam is created/edited/deleted so the
// public pages and sitemap update immediately instead of within the hour.
// Auth: forwards the admin's JWT to the API's /auth/me and requires
// role === "admin" — no extra shared secret to manage.
export async function POST(req: Request) {
  const authz = req.headers.get("authorization");
  if (!authz) return Response.json({ message: "Unauthorized" }, { status: 401 });

  try {
    const res = await fetch(`${API_URL}/auth/me`, {
      headers: { Authorization: authz },
      cache: "no-store",
    });
    const body = await res.json().catch(() => ({}));
    if (!res.ok || body?.user?.role !== "admin") {
      return Response.json({ message: "Forbidden" }, { status: 403 });
    }
  } catch {
    return Response.json({ message: "API unreachable" }, { status: 502 });
  }

  // The site is small: refresh every page (kalaam pages, categories, sitemap).
  revalidatePath("/", "layout");
  return Response.json({ revalidated: true });
}
