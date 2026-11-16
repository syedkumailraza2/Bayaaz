import Link from "next/link";

export type Crumb = { name: string; href?: string };

/** Home › Nauha › Nadeem Sarwar › Kalaam — last item is the current page. */
export default function Breadcrumbs({ items }: { items: Crumb[] }) {
  return (
    <nav aria-label="Breadcrumb" className="mb-8 text-sm">
      <ol className="flex flex-wrap items-center gap-x-1.5 gap-y-1 text-outline">
        {items.map((c, i) => {
          const last = i === items.length - 1;
          return (
            <li key={`${c.name}-${i}`} className="flex items-center gap-1.5 min-w-0">
              {c.href && !last ? (
                <Link href={c.href} className="hover:text-primary underline-offset-4 hover:underline">
                  {c.name}
                </Link>
              ) : (
                <span
                  aria-current={last ? "page" : undefined}
                  className={`truncate max-w-[240px] ${last ? "text-on-surface-variant" : ""}`}
                >
                  {c.name}
                </span>
              )}
              {!last ? <span aria-hidden>›</span> : null}
            </li>
          );
        })}
      </ol>
    </nav>
  );
}
