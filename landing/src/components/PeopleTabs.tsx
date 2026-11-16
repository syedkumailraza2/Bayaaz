"use client";

import Link from "next/link";
import { useState } from "react";
import type { PersonSummary } from "@/lib/api";

type Tab = { key: string; label: string; people: PersonSummary[] };

/**
 * Reciters / Shayars switcher for a category page. Both lists are rendered
 * into the HTML (the inactive one is just `hidden`) so search engines see
 * every person link without running JS.
 */
export default function PeopleTabs({
  category,
  tabs,
  unit,
}: {
  category: string;
  tabs: Tab[];
  /** Singular/plural noun for counts, e.g. ["nauha", "nauhas"]. */
  unit: [string, string];
}) {
  const visible = tabs.filter((t) => t.people.length > 0);
  const [active, setActive] = useState(visible[0]?.key);
  if (visible.length === 0) return null;

  return (
    <div>
      <div role="tablist" className="flex gap-2 mb-6">
        {visible.map((t) => (
          <button
            key={t.key}
            role="tab"
            type="button"
            aria-selected={active === t.key}
            onClick={() => setActive(t.key)}
            className={`px-4 py-2 rounded-full text-sm font-semibold transition-colors ${
              active === t.key
                ? "bg-primary text-on-primary"
                : "bg-surface-container text-on-surface-variant hover:text-primary"
            }`}
          >
            {t.label}
            <span className="ml-2 opacity-70">{t.people.length}</span>
          </button>
        ))}
      </div>

      {visible.map((t) => (
        <ul
          key={t.key}
          role="tabpanel"
          hidden={active !== t.key}
          className="grid grid-cols-1 sm:grid-cols-2 gap-3"
        >
          {t.people.map((p) => (
            <li key={p.slug}>
              <Link
                href={`/${category}/${p.slug}`}
                className="flex items-center justify-between gap-4 p-4 rounded-2xl hairline hover:bg-surface-container-low transition-colors"
              >
                <span className="flex items-center gap-3 min-w-0">
                  <span
                    aria-hidden
                    className="w-10 h-10 shrink-0 rounded-full bg-[#E8F3EE] text-[#054A29] flex items-center justify-center font-bold"
                  >
                    {p.name.trim().charAt(0).toUpperCase()}
                  </span>
                  <span className="font-semibold text-on-surface truncate">
                    {p.name}
                  </span>
                </span>
                <span className="shrink-0 text-sm text-outline">
                  {p.count} {p.count === 1 ? unit[0] : unit[1]} →
                </span>
              </Link>
            </li>
          ))}
        </ul>
      ))}
    </div>
  );
}
