import type { Metadata } from "next";
import { notFound } from "next/navigation";
import PageShell from "@/components/PageShell";
import KalaamList from "@/components/KalaamList";
import Breadcrumbs from "@/components/Breadcrumbs";
import {
  CATEGORIES,
  CATEGORY_INFO,
  getKalaamIndex,
  isCategory,
  peopleInCategory,
  personInCategory,
} from "@/lib/api";
import { breadcrumbJsonLd, siteUrl } from "@/lib/seo";

export const revalidate = 3600; // keep in sync with REVALIDATE_SECONDS in lib/api

type Props = { params: Promise<{ category: string; person: string }> };

export async function generateStaticParams() {
  const index = await getKalaamIndex();
  return CATEGORIES.flatMap((category) => {
    return peopleInCategory(index, category).map((p) => ({ category, person: p.slug }));
  });
}

async function load(category: string, slug: string) {
  if (!isCategory(category)) return null;
  const found = personInCategory(await getKalaamIndex(), category, slug);
  return found.person ? { ...found, category } : null;
}

function roleLine(category: keyof typeof CATEGORY_INFO, asReciter: number, asShayar: number) {
  const info = CATEGORY_INFO[category];
  return [asReciter ? info.reciter : null, asShayar ? "Shayar" : null]
    .filter(Boolean)
    .join(" & ");
}

export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const { category, person } = await params;
  const data = await load(category, person);
  if (!data || !data.person) return { title: "Not found", robots: { index: false } };
  const info = CATEGORY_INFO[data.category];
  const name = data.person.name;
  const title = `${name} ${info.plural} — Lyrics`;
  const description = `${data.items.length} ${
    data.items.length === 1 ? info.label.toLowerCase() : info.plural.toLowerCase()
  } by ${name} (${roleLine(data.category, data.asReciter, data.asShayar)}): ${data.items
    .slice(0, 3)
    .map((k) => k.title)
    .join(", ")}.`.slice(0, 160);
  const path = `/${category}/${person}`;
  return {
    title,
    description,
    keywords: [name, `${name} ${info.plural.toLowerCase()}`, `${name} ${info.label.toLowerCase()} lyrics`],
    alternates: { canonical: path },
    openGraph: { title, description, url: path },
  };
}

export default async function PersonPage({ params }: Props) {
  const { category, person } = await params;
  const data = await load(category, person);
  if (!data || !data.person) notFound();

  const info = CATEGORY_INFO[data.category];
  const name = data.person.name;
  const path = `/${category}/${person}`;
  const items = [...data.items].sort((a, b) => a.title.localeCompare(b.title));

  return (
    <PageShell
      eyebrow={roleLine(data.category, data.asReciter, data.asShayar)}
      title={name}
      subtitle={`${items.length} ${
        items.length === 1 ? info.label.toLowerCase() : info.plural.toLowerCase()
      } on BAYAAZ`}
    >
      <script
        type="application/ld+json"
        dangerouslySetInnerHTML={{
          __html: JSON.stringify({
            "@context": "https://schema.org",
            "@type": "Person",
            name,
            url: `${siteUrl}${path}`,
          }),
        }}
      />
      <script
        type="application/ld+json"
        dangerouslySetInnerHTML={{
          __html: JSON.stringify(
            breadcrumbJsonLd([
              { name: "Home", path: "/" },
              { name: `${info.label} lyrics`, path: `/${category}` },
              { name, path },
            ]),
          ),
        }}
      />

      <Breadcrumbs
        items={[
          { name: "Home", href: "/" },
          { name: info.label, href: `/${category}` },
          { name },
        ]}
      />

      <KalaamList items={items} />
    </PageShell>
  );
}
