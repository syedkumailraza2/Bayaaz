import type { Metadata } from "next";
import { notFound } from "next/navigation";
import PageShell from "@/components/PageShell";
import PeopleDirectory from "@/components/PeopleDirectory";
import Breadcrumbs from "@/components/Breadcrumbs";
import {
  CATEGORIES,
  CATEGORY_INFO,
  getKalaamIndex,
  isCategory,
  peopleInCategory,
} from "@/lib/api";
import { breadcrumbJsonLd } from "@/lib/seo";

export const revalidate = 3600;
// Only the four categories exist; anything else is a 404.
export const dynamicParams = false;

type Props = { params: Promise<{ category: string }> };

export function generateStaticParams() {
  return CATEGORIES.map((category) => ({ category }));
}

export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const { category } = await params;
  if (!isCategory(category)) return {};
  const info = CATEGORY_INFO[category];
  const title = `${info.label} Lyrics — ${info.plural} by ${info.reciters} & Shayars`;
  return {
    title,
    description: info.intro,
    alternates: { canonical: `/${category}` },
    openGraph: { title, description: info.intro, url: `/${category}` },
  };
}

export default async function CategoryPage({ params }: Props) {
  const { category } = await params;
  if (!isCategory(category)) notFound();
  const info = CATEGORY_INFO[category];
  const index = await getKalaamIndex();
  const items = index
    .filter((k) => k.category === category)
    .sort((a, b) => a.title.localeCompare(b.title));
  const people = peopleInCategory(index, category);
  const unit: [string, string] = [info.label.toLowerCase(), info.plural.toLowerCase()];

  return (
    <PageShell eyebrow={`${items.length} ${info.plural}`} title={`${info.label} Lyrics`} subtitle={info.intro}>
      <script
        type="application/ld+json"
        dangerouslySetInnerHTML={{
          __html: JSON.stringify(
            breadcrumbJsonLd([
              { name: "Home", path: "/" },
              { name: `${info.label} lyrics`, path: `/${category}` },
            ]),
          ),
        }}
      />

      <Breadcrumbs items={[{ name: "Home", href: "/" }, { name: info.label }]} />

      {people.length > 0 ? (
        <>
          <h2 className="text-xl font-bold text-primary mb-1">
            {`${info.reciters} & Shayars`}
          </h2>
          <p className="text-sm text-outline mb-5">
            Choose a {info.reciter.toLowerCase()} or shayar to see their {info.plural.toLowerCase()}.
          </p>
          <PeopleDirectory
            category={category}
            people={people}
            reciterLabel={info.reciter}
            unit={unit}
          />
        </>
      ) : null}

      {people.length === 0 ? (
        <p className="text-on-surface-variant">
          {items.length === 0
            ? `No ${info.plural.toLowerCase()} here yet — check back soon.`
            : `${info.reciters} and shayars for these ${info.plural.toLowerCase()} are being added — check back soon.`}
        </p>
      ) : null}
    </PageShell>
  );
}
