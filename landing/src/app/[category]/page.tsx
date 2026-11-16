import type { Metadata } from "next";
import { notFound } from "next/navigation";
import PageShell from "@/components/PageShell";
import KalaamList from "@/components/KalaamList";
import PeopleTabs from "@/components/PeopleTabs";
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
  const { reciters, shayars } = peopleInCategory(index, category);
  // Kalaams with nobody attached would be unreachable from the people
  // lists, so they get their own list below.
  const unattributed = items.filter(
    (k) => !k.reciters?.length && !k.shayars?.length,
  );
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

      {reciters.length + shayars.length > 0 ? (
        <PeopleTabs
          category={category}
          unit={unit}
          tabs={[
            { key: "reciters", label: info.reciters, people: reciters },
            { key: "shayars", label: "Shayars", people: shayars },
          ]}
        />
      ) : null}

      {unattributed.length > 0 ? (
        <section className={reciters.length + shayars.length > 0 ? "mt-14" : ""}>
          {reciters.length + shayars.length > 0 ? (
            <h2 className="text-xl font-bold text-primary mb-4">
              More {info.plural.toLowerCase()}
            </h2>
          ) : null}
          <KalaamList items={unattributed} />
        </section>
      ) : null}

      {items.length === 0 ? <KalaamList items={[]} /> : null}
    </PageShell>
  );
}
