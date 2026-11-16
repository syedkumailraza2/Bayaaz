"use client";

import { useCallback, useEffect, useState } from "react";
import Link from "next/link";
import AdminGuard from "@/components/admin/AdminGuard";
import { CATEGORIES, CATEGORY_INFO, kalaamPath, type Kalaam } from "@/lib/api";
import {
  deleteKalaam,
  listKalaams,
  refreshPublicPages,
  toggleVisibility,
  type AdminList,
} from "@/lib/admin";

function authorName(k: Kalaam) {
  return typeof k.author === "object" && k.author ? k.author.name : "—";
}

function KalaamTable() {
  const [q, setQ] = useState("");
  const [category, setCategory] = useState("");
  const [page, setPage] = useState(1);
  const [data, setData] = useState<AdminList | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [busyId, setBusyId] = useState<string | null>(null);

  const load = useCallback(() => {
    setError(null);
    listKalaams({ q: q.trim() || undefined, category: category || undefined, page })
      .then(setData)
      .catch((e) => setError((e as Error).message));
  }, [q, category, page]);

  useEffect(() => {
    const t = setTimeout(load, 250); // debounce typing in the search box
    return () => clearTimeout(t);
  }, [load]);

  async function onToggle(k: Kalaam) {
    setBusyId(k._id);
    try {
      await toggleVisibility(k._id);
      await refreshPublicPages();
      load();
    } catch (e) {
      setError((e as Error).message);
    } finally {
      setBusyId(null);
    }
  }

  async function onDelete(k: Kalaam) {
    if (!window.confirm(`Delete "${k.title}"? This cannot be undone.`)) return;
    setBusyId(k._id);
    try {
      await deleteKalaam(k._id);
      await refreshPublicPages();
      load();
    } catch (e) {
      setError((e as Error).message);
    } finally {
      setBusyId(null);
    }
  }

  return (
    <>
      <div className="flex flex-wrap items-center justify-between gap-3 mb-6">
        <h1 className="text-2xl font-bold text-primary">
          Kalaams {data ? <span className="text-outline font-normal text-lg">({data.total})</span> : null}
        </h1>
        <Link href="/admin/kalaam/new" className="bg-primary text-on-primary rounded-lg px-4 py-2 font-semibold">
          + New kalaam
        </Link>
      </div>

      <div className="flex flex-wrap gap-3 mb-4">
        <input
          value={q}
          onChange={(e) => {
            setQ(e.target.value);
            setPage(1);
          }}
          placeholder="Search title, poet, tags, lyrics…"
          className="flex-1 min-w-[200px] rounded-lg hairline px-3 py-2 bg-white"
        />
        <select
          value={category}
          onChange={(e) => {
            setCategory(e.target.value);
            setPage(1);
          }}
          className="rounded-lg hairline px-3 py-2 bg-white"
        >
          <option value="">All categories</option>
          {CATEGORIES.map((c) => (
            <option key={c} value={c}>
              {CATEGORY_INFO[c].label}
            </option>
          ))}
        </select>
      </div>

      {error ? <p className="text-red-700 mb-4" role="alert">{error}</p> : null}
      {!data ? (
        <p className="text-on-surface-variant">Loading… (the server can take up to a minute to wake up)</p>
      ) : data.items.length === 0 ? (
        <p className="text-on-surface-variant">No kalaams match.</p>
      ) : (
        <div className="overflow-x-auto bg-white rounded-xl hairline">
          <table className="w-full text-sm">
            <thead className="text-left text-outline">
              <tr>
                <th className="p-3">Title</th>
                <th className="p-3">Category</th>
                <th className="p-3">Added by</th>
                <th className="p-3">Status</th>
                <th className="p-3 text-right">Actions</th>
              </tr>
            </thead>
            <tbody>
              {data.items.map((k) => (
                <tr key={k._id} className="border-t border-outline-variant/40">
                  <td className="p-3">
                    <div className="font-medium">{k.title}</div>
                    {k.reciters?.length || k.poet ? (
                      <div className="text-outline">
                        {[
                          k.reciters?.map((p) => p.name).join(", "),
                          k.poet ? `by ${k.poet}` : null,
                        ]
                          .filter(Boolean)
                          .join(" · ")}
                      </div>
                    ) : null}
                  </td>
                  <td className="p-3">{CATEGORY_INFO[k.category]?.label ?? k.category}</td>
                  <td className="p-3">{authorName(k)}</td>
                  <td className="p-3">
                    <button
                      type="button"
                      disabled={busyId === k._id}
                      onClick={() => onToggle(k)}
                      className={`px-2 py-0.5 rounded-full text-xs font-semibold ${
                        k.isPublic ? "bg-[#E8F3EE] text-[#054A29]" : "bg-surface-container text-on-surface-variant"
                      }`}
                      title="Toggle public / private"
                    >
                      {k.isPublic ? "Public" : "Private"}
                    </button>
                  </td>
                  <td className="p-3 text-right whitespace-nowrap space-x-3">
                    {k.isPublic ? (
                      <a href={kalaamPath(k)} target="_blank" rel="noreferrer" className="underline underline-offset-4">
                        View
                      </a>
                    ) : null}
                    <Link href={`/admin/kalaam/${k._id}`} className="underline underline-offset-4">
                      Edit
                    </Link>
                    <button
                      type="button"
                      disabled={busyId === k._id}
                      onClick={() => onDelete(k)}
                      className="text-red-700 underline underline-offset-4"
                    >
                      Delete
                    </button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}

      {data && (data.page > 1 || data.hasMore) ? (
        <div className="flex justify-between mt-4">
          <button type="button" disabled={page <= 1} onClick={() => setPage(page - 1)} className="underline disabled:opacity-40">
            ← Previous
          </button>
          <span className="text-outline text-sm">Page {data.page}</span>
          <button type="button" disabled={!data.hasMore} onClick={() => setPage(page + 1)} className="underline disabled:opacity-40">
            Next →
          </button>
        </div>
      ) : null}
    </>
  );
}

export default function AdminHome() {
  return <AdminGuard>{() => <KalaamTable />}</AdminGuard>;
}
