import type { Metadata } from "next";
import Link from "next/link";
import PageShell from "@/components/PageShell";
import KalaamList from "@/components/KalaamList";
import { CATEGORIES, CATEGORY_INFO, getKalaamIndex } from "@/lib/api";

export const revalidate = 3600;

const description =
  "Browse nauha, marsiya, qasida and qata lyrics on BAYAAZ — laid out stanza by stanza for reading and recitation.";

export const metadata: Metadata = {
  title: "Kalaam Lyrics Library — Nauha, Marsiya, Qasida & Qata",
  description,
  alternates: { canonical: "/kalaams" },
  openGraph: { title: "Kalaam Lyrics Library — BAYAAZ", description, url: "/kalaams" },
};

export default async function KalaamsPage() {
  const index = await getKalaamIndex();
  return (
    <PageShell eyebrow="Library" title="Kalaam Lyrics" subtitle={description}>
      <div className="space-y-14">
        {CATEGORIES.map((c) => {
          const items = index.filter((k) => k.category === c).slice(0, 10);
          const total = index.filter((k) => k.category === c).length;
          return (
            <section key={c}>
              <div className="flex items-baseline justify-between mb-3">
                <h2 className="text-2xl font-bold text-primary">{CATEGORY_INFO[c].plural}</h2>
                <Link href={`/${c}`} className="text-sm underline underline-offset-4 text-on-surface-variant hover:text-primary">
                  All {total} →
                </Link>
              </div>
              <KalaamList items={items} />
            </section>
          );
        })}
      </div>
    </PageShell>
  );
}
