import type { Metadata } from "next";
import Link from "next/link";
import { notFound, permanentRedirect } from "next/navigation";
import PageShell from "@/components/PageShell";
import ReferencePlayer from "@/components/ReferencePlayer";
import Breadcrumbs from "@/components/Breadcrumbs";
import {
  CATEGORY_INFO,
  getKalaam,
  getKalaamIndex,
  idFromSlug,
  isArabicScript,
  joinNames,
  kalaamPath,
  kalaamSlug,
  type Kalaam,
  type PersonLink,
} from "@/lib/api";
import { breadcrumbJsonLd, siteName, siteUrl } from "@/lib/seo";

export const revalidate = 3600; // keep in sync with REVALIDATE_SECONDS in lib/api

type Props = { params: Promise<{ slug: string }> };

export async function generateStaticParams() {
  const index = await getKalaamIndex();
  return index.map((k) => ({ slug: kalaamSlug(k) }));
}

async function load(slug: string): Promise<Kalaam | null> {
  const id = idFromSlug(slug);
  if (!id) return null;
  return getKalaam(id);
}

const shayarNames = (k: Kalaam) => joinNames(k.shayars) || k.poet || "";

function excerpt(k: Kalaam): string {
  const lines = k.content.flatMap((s) => s.lines).slice(0, 2).join(" / ");
  const label = CATEGORY_INFO[k.category]?.label ?? "Kalaam";
  const reciters = joinNames(k.reciters);
  const by = [
    reciters ? ` recited by ${reciters}` : "",
    shayarNames(k) ? `, written by ${shayarNames(k)}` : "",
  ].join("").replace(/^, /, " ");
  return `${label} lyrics${by}: ${lines}`.slice(0, 160);
}

function PeopleLinks({ people, category }: { people: PersonLink[]; category: string }) {
  return (
    <>
      {people.map((p, i) => (
        <span key={p.slug}>
          {i > 0 ? (i === people.length - 1 ? " and " : ", ") : null}
          <Link
            href={`/${category}/${p.slug}`}
            className="underline underline-offset-4 hover:text-primary"
          >
            {p.name}
          </Link>
        </span>
      ))}
    </>
  );
}

export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const { slug } = await params;
  const k = await load(slug);
  if (!k) return { title: "Kalaam not found", robots: { index: false } };
  const label = CATEGORY_INFO[k.category]?.label ?? "Kalaam";
  const title = `${k.title} — ${label} Lyrics`;
  const description = excerpt(k);
  const path = kalaamPath(k);
  return {
    title,
    description,
    keywords: [
      k.title,
      `${k.title} lyrics`,
      `${label} lyrics`,
      ...(k.reciters ?? []).map((p) => p.name),
      ...(k.shayars ?? []).map((p) => p.name),
      k.poet ?? "",
      ...(k.tags ?? []),
    ].filter(Boolean),
    alternates: { canonical: path },
    openGraph: { title, description, url: path, type: "article" },
    twitter: { card: "summary", title, description },
  };
}

export default async function KalaamPage({ params }: Props) {
  const { slug } = await params;
  const k = await load(slug);
  if (!k) notFound();

  // Title changed since the link was made → send to the canonical slug.
  const canonical = kalaamSlug(k);
  if (decodeURIComponent(slug) !== canonical) permanentRedirect(`/kalaam/${canonical}`);

  const info = CATEGORY_INFO[k.category];
  const allText = k.content.flatMap((s) => s.lines).join(" ");
  const arabic = isArabicScript(allText);
  const path = kalaamPath(k);
  // Breadcrumb goes through the first reciter (or shayar) so visitors can
  // step back to that person's list.
  const crumbPerson = k.reciters?.[0] ?? k.shayars?.[0] ?? null;

  const jsonLd = {
    "@context": "https://schema.org",
    "@type": "CreativeWork",
    name: k.title,
    genre: info?.label,
    inLanguage: arabic ? "ur" : "ur-Latn",
    url: `${siteUrl}${path}`,
    datePublished: k.createdAt,
    dateModified: k.updatedAt,
    ...(k.shayars?.length
      ? { author: k.shayars.map((p) => ({ "@type": "Person", name: p.name, url: `${siteUrl}/${k.category}/${p.slug}` })) }
      : k.poet
        ? { author: { "@type": "Person", name: k.poet } }
        : {}),
    ...(k.reciters?.length
      ? { contributor: k.reciters.map((p) => ({ "@type": "Person", name: p.name, url: `${siteUrl}/${k.category}/${p.slug}` })) }
      : {}),
    keywords: (k.tags ?? []).join(", ") || undefined,
    text: k.content.map((s) => s.lines.join("\n")).join("\n\n"),
    publisher: { "@type": "Organization", name: siteName, url: siteUrl },
  };

  return (
    <PageShell
      eyebrow={info?.label ?? "Kalaam"}
      title={k.title}
      subtitle={
        <span className="flex flex-col gap-1">
          {k.reciters?.length ? (
            <span>
              <span className="text-outline">{info?.reciter ?? "Reciter"}: </span>
              <PeopleLinks people={k.reciters} category={k.category} />
            </span>
          ) : null}
          {k.shayars?.length ? (
            <span>
              <span className="text-outline">Shayar: </span>
              <PeopleLinks people={k.shayars} category={k.category} />
            </span>
          ) : k.poet ? (
            <span>
              <span className="text-outline">Shayar: </span>
              {k.poet}
            </span>
          ) : null}
        </span>
      }
    >
      <script
        type="application/ld+json"
        dangerouslySetInnerHTML={{ __html: JSON.stringify(jsonLd) }}
      />
      <script
        type="application/ld+json"
        dangerouslySetInnerHTML={{
          __html: JSON.stringify(
            breadcrumbJsonLd([
              { name: "Home", path: "/" },
              { name: `${info?.label ?? "Kalaam"} lyrics`, path: `/${k.category}` },
              ...(crumbPerson
                ? [{ name: crumbPerson.name, path: `/${k.category}/${crumbPerson.slug}` }]
                : []),
              { name: k.title, path },
            ]),
          ),
        }}
      />

      <Breadcrumbs
        items={[
          { name: "Home", href: "/" },
          { name: info?.label ?? "Kalaams", href: `/${k.category}` },
          ...(crumbPerson
            ? [{ name: crumbPerson.name, href: `/${k.category}/${crumbPerson.slug}` }]
            : []),
          { name: k.title },
        ]}
      />

      {k.referenceAudio?.url ? (
        <ReferencePlayer media={k.referenceAudio} title={k.title} />
      ) : null}

      <article
        lang={arabic ? "ur" : "ur-Latn"}
        dir={arabic ? "rtl" : "ltr"}
        className={`space-y-8 ${arabic ? "font-urdu text-2xl leading-[2.2]" : "text-lg md:text-xl leading-relaxed"}`}
      >
        {k.content.map((s) => (
          <section key={s.stanzaNumber} aria-label={`Stanza ${s.stanzaNumber}`}>
            <p className="text-on-surface">
              {s.lines.map((line, i) => (
                <span key={i} className="block">
                  {line}
                </span>
              ))}
            </p>
          </section>
        ))}
      </article>

      {k.tags && k.tags.length > 0 ? (
        <ul className="mt-10 flex flex-wrap gap-2" aria-label="Tags">
          {k.tags.map((t) => (
            <li key={t} className="px-3 py-1 rounded-full bg-surface-container text-sm text-on-surface-variant">
              {t}
            </li>
          ))}
        </ul>
      ) : null}

      <div className="mt-14 rounded-2xl bg-primary text-on-primary p-6 md:p-8">
        <p className="text-xl font-bold">Recite this kalaam in BAYAAZ</p>
        <p className="mt-2 text-on-primary/80">
          Distraction-free reading, offline access, and synced majlis
          sessions where everyone follows the same line.
        </p>
        <Link
          href="/#get-started"
          className="mt-5 inline-block bg-white text-primary px-5 py-2.5 rounded-lg font-semibold"
        >
          Get the app
        </Link>
      </div>
    </PageShell>
  );
}
