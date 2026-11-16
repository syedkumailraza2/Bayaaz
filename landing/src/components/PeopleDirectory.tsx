"use client";

import Link from "next/link";
import { useState } from "react";
import type { PersonSummary } from "@/lib/api";

/**
 * Every reciter and shayar in a category, in one list. Each card links to
 * that person's kalaams. All cards are in the HTML (the filter only hides
 * them), so search engines see every link.
 */
export default function PeopleDirectory({
  category,
  people,
  reciterLabel,
  unit,
}: {
  category: string;
  people: PersonSummary[];
  /** e.g. "Nauha khwan" */
  reciterLabel: string;
  /** Singular/plural noun for counts, e.g. ["nauha", "nauhas"]. */
  unit: [string, string];
}) {
  const [q, setQ] = useState("");
  const query = q.trim().toLowerCase();
  const matches = (p: PersonSummary) => !query || p.name.toLowerCase().includes(query);
  const shown = people.filter(matches).length;

  return (
    <div>
      {people.length > 6 ? (
        <label className="block mb-5">
          <span className="sr-only">Search {reciterLabel.toLowerCase()}s and shayars</span>
          <input
            type="search"
            value={q}
            onChange={(e) => setQ(e.target.value)}
            placeholder={`Search ${people.length} ${reciterLabel.toLowerCase()}s and shayars…`}
            className="w-full rounded-xl hairline px-4 py-3 bg-white text-base"
          />
        </label>
      ) : null}

      <ul className="grid grid-cols-1 sm:grid-cols-2 gap-3">
        {people.map((p) => (
          <li key={p.slug} hidden={!matches(p)}>
            <Link
              href={`/${category}/${p.slug}`}
              className="flex items-center justify-between gap-4 p-4 rounded-2xl hairline hover:bg-surface-container-low transition-colors"
            >
              <span className="flex items-center gap-3 min-w-0">
                <span
                  aria-hidden
                  className="w-11 h-11 shrink-0 rounded-full bg-[#E8F3EE] text-[#054A29] flex items-center justify-center font-bold"
                >
                  {p.name.trim().charAt(0).toUpperCase()}
                </span>
                <span className="min-w-0">
                  <span className="block font-semibold text-on-surface truncate">{p.name}</span>
                  <span className="block text-xs text-outline">
                    {[p.isReciter ? reciterLabel : null, p.isShayar ? "Shayar" : null]
                      .filter(Boolean)
                      .join(" · ")}
                  </span>
                </span>
              </span>
              <span className="shrink-0 text-sm text-outline">
                {p.count} {p.count === 1 ? unit[0] : unit[1]} →
              </span>
            </Link>
          </li>
        ))}
      </ul>

      {query && shown === 0 ? (
        <p className="text-on-surface-variant mt-2">No one matches &ldquo;{q}&rdquo;.</p>
      ) : null}
    </div>
  );
}
