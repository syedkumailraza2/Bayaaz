import Link from "next/link";
import { CATEGORY_INFO, joinNames, kalaamPath, type KalaamIndexItem } from "@/lib/api";

export default function KalaamList({
  items,
  showCategory = false,
}: {
  items: KalaamIndexItem[];
  showCategory?: boolean;
}) {
  if (items.length === 0) {
    return (
      <p className="text-on-surface-variant">
        No kalaams here yet — check back soon.
      </p>
    );
  }
  return (
    <ul className="divide-y divide-outline-variant/40 border-y border-outline-variant/40">
      {items.map((k) => (
        <li key={k.id}>
          <Link
            href={kalaamPath(k)}
            className="flex items-baseline justify-between gap-4 py-4 hover:bg-surface-container-low transition-colors px-2 -mx-2 rounded"
          >
            <span className="font-semibold text-on-surface break-words min-w-0">
              {k.title}
            </span>
            <span className="shrink-0 text-sm text-outline text-right">
              {[
                joinNames(k.reciters) || joinNames(k.shayars) || k.poet,
                showCategory ? CATEGORY_INFO[k.category]?.label : null,
              ]
                .filter(Boolean)
                .join(" · ")}
            </span>
          </Link>
        </li>
      ))}
    </ul>
  );
}
