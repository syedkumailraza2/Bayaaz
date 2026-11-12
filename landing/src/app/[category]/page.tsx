import type { Metadata } from "next";
import { notFound } from "next/navigation";
import PageShell from "@/components/PageShell";
import KalaamList from "@/components/KalaamList";
import { CATEGORIES, CATEGORY_INFO, getKalaamIndex, isCategory } from "@/lib/api";
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
  const title = `${info.label} Lyrics — Read ${info.plural} Online`;
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
  const items = (await getKalaamIndex())
    .filter((k) => k.category === category)
    .sort((a, b) => a.title.localeCompare(b.title));

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
      <KalaamList items={items} />
    </PageShell>
  );
}
