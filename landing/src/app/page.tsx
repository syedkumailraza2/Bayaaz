import type { Metadata } from "next";
import Image from "next/image";
import Nav from "@/components/Nav";
import Footer from "@/components/Footer";
import Splash from "@/components/Splash";
import { softwareApplicationJsonLd } from "@/lib/seo";
import { formatCount, getSiteStats } from "@/lib/api";

export const metadata: Metadata = {
  title: {
    absolute:
      "BAYAAZ — Nauha, Marsiya & Qasida lyrics from underrated poets and anjumans",
  },
  alternates: { canonical: "/" },
};

// Live KPIs: rebuilt hourly, and immediately when an admin saves a kalaam.
export const revalidate = 3600; // = REVALIDATE_SECONDS (must be a literal)

const MARQUEE = ["UNDERRATED POETS", "بیاض", "ANJUMAN KALAAMS", "PURANE KALAAM", "MAJLIS SYNC"];

export default async function Home() {
  const stats = await getSiteStats();
  const kpis: [string, string][] = stats
    ? ([
        [formatCount(stats.kalaams), "KALAAMS"],
        [formatCount(stats.poets), "POETS"],
        stats.reciters != null ? [formatCount(stats.reciters), "RECITERS"] : null,
        stats.majalis != null ? [formatCount(stats.majalis), "MAJALIS HELD"] : null,
      ].filter(Boolean) as [string, string][])
    : [];

  return (
    <>
      <script
        type="application/ld+json"
        dangerouslySetInnerHTML={{
          __html: JSON.stringify(softwareApplicationJsonLd()),
        }}
      />
      <Splash />
      <Nav />

      {/* Hero — fits in viewport, no scroll required */}
      <section className="relative h-[100svh] min-h-[640px] flex items-center pt-16 overflow-hidden">
        <div className="absolute inset-0 grid-bg z-0" />
        <div className="container mx-auto max-w-[1080px] px-6 md:px-0 relative z-10 grid grid-cols-1 md:grid-cols-12 gap-8 md:gap-12 items-center">
          <div className="md:col-span-8 flex flex-col items-start gap-5">
            <div className="flex items-center gap-3 px-3 py-1 bg-[#E8F3EE] rounded-full border border-[#054A29]/10">
              <span className="w-2 h-2 rounded-full bg-[#054A29] pulse-emerald" />
              <span className="font-mono text-[10px] md:text-[11px] tracking-[0.05em] text-[#054A29] font-bold">
                NEW — REAL-TIME MAJLIS SESSIONS
              </span>
            </div>
            <h1 className="text-[44px] sm:text-[56px] md:text-[72px] lg:text-[84px] leading-[0.95] tracking-tight text-primary font-extrabold">
              Beyond the kalaams <br />
              everyone{" "}
              <i className="text-secondary-fixed-dim italic font-extrabold">
                remembers
              </i>
              .
            </h1>
            <p className="max-w-[560px] text-base md:text-lg leading-relaxed text-on-surface-variant">
              Most platforms only carry the same few popular kalaams. Bayaaz
              brings together hand-picked nauhas, marsiyas and qasidas from
              underrated poets, anjumans and old bayaazes — ready to read,
              recite and share in your majlis.
            </p>
            <div className="flex flex-col sm:flex-row items-stretch sm:items-center gap-4 mt-1">
              <a
                href="#get-started"
                className="bg-primary text-on-primary px-6 py-3 rounded-xl text-base font-semibold flex items-center justify-center gap-2 group hover:shadow-lg transition-all"
              >
                Get the app{" "}
                <span className="group-hover:translate-x-1 transition-transform">
                  →
                </span>
              </a>
              <a
                href="#how-it-works"
                className="hairline px-6 py-3 rounded-xl text-base font-semibold hover:bg-surface-container transition-colors text-center"
              >
                See how it works
              </a>
            </div>
            <div className="flex flex-wrap gap-4 md:gap-6 mt-3 font-mono text-[11px] text-outline uppercase tracking-[0.15em]">
              <span>Free</span>
              <span className="text-primary-fixed-dim">·</span>
              <span>Offline-First</span>
              {stats && (
                <>
                  <span className="text-primary-fixed-dim">·</span>
                  <span>{formatCount(stats.kalaams)} Kalaams</span>
                  <span className="text-primary-fixed-dim">·</span>
                  <span>{formatCount(stats.poets)} Poets</span>
                </>
              )}
            </div>
          </div>

          {/* Floating mockup — real app screenshot */}
          <div className="md:col-span-4 relative hidden md:block">
            <div className="relative w-[260px] h-[560px] mx-auto rotate-3">
              <div className="absolute inset-0 rounded-[36px] overflow-hidden ring-1 ring-black/10 shadow-2xl bg-black">
                <Image
                  src="/mockups/library.png"
                  alt="BAYAAZ home screen on iPhone."
                  fill
                  sizes="260px"
                  priority
                  className="object-cover"
                />
              </div>
            </div>
            <div className="absolute -top-12 -right-12 w-32 h-32 bg-primary-fixed opacity-20 blur-3xl rounded-full pointer-events-none" />
            <div className="absolute -bottom-12 -left-8 w-40 h-40 bg-secondary-fixed-dim/30 opacity-30 blur-3xl rounded-full pointer-events-none" />
          </div>
        </div>
      </section>

      {/* Marquee */}
      <div className="hairline-t hairline-b h-14 flex items-center bg-white marquee-container">
        {[0, 1].map((copy) => (
          <div
            key={copy}
            className="marquee-content flex items-center gap-12 px-6"
            aria-hidden={copy === 1}
          >
            {[0, 1].map((i) => (
              <div key={i} className="inline-flex items-center gap-12">
                {MARQUEE.map((label) =>
                  label === "بیاض" ? (
                    <span
                      key={label}
                      className="font-[family-name:var(--font-naskh)] text-xl text-primary font-bold"
                    >
                      {label}
                    </span>
                  ) : (
                    <span
                      key={label}
                      className="font-mono text-xs tracking-widest text-on-surface-variant"
                    >
                      {label}
                    </span>
                  ),
                ).flatMap((el, j) => [
                  el,
                  <span
                    key={`dot-${j}`}
                    className="w-2 h-2 rounded-full bg-secondary-fixed-dim"
                  />,
                ])}
              </div>
            ))}
          </div>
        ))}
      </div>

      {/* Stats — live counts from the API; hidden if it's unreachable */}
      {kpis.length > 0 && (
      <section className="py-24 md:py-[120px] bg-white">
        <div className="container mx-auto max-w-[1080px] px-6 md:px-0">
          <h2 className="text-center text-[36px] md:text-[56px] text-primary mb-12 md:mb-20 tracking-tight font-bold">
            A growing home for tradition.
          </h2>
          <div
            className={`grid grid-cols-2 hairline-t ${
              kpis.length === 4 ? "md:grid-cols-4" : "md:grid-cols-2"
            }`}
          >
            {kpis.map(([value, label], idx, arr) => (
              <div
                key={label}
                className={`p-8 md:p-12 flex flex-col items-center ${
                  idx < arr.length - 1 ? "md:hairline-r" : ""
                }`}
              >
                <span className="text-[56px] md:text-[88px] text-secondary tracking-tighter font-extrabold leading-none">
                  {value}
                </span>
                <span className="font-mono text-[11px] tracking-widest text-outline mt-3">
                  {label}
                </span>
              </div>
            ))}
          </div>
        </div>
      </section>
      )}

      {/* Showcase */}
      <section
        id="how-it-works"
        className="py-24 md:py-32 bg-white overflow-hidden"
      >
        <div className="container mx-auto max-w-[1080px] px-6 md:px-0">
          <div className="grid grid-cols-1 md:grid-cols-2 gap-16 md:gap-24 items-start">
            <div className="md:sticky md:top-32 space-y-12 md:space-y-16">
              {[
                {
                  step: "Open.",
                  body: "Browse hand-picked nauhas, marsiyas, qasidas and qatas — including poets and anjumans you won't find anywhere else. Saved offline, ready when the majlis starts.",
                  active: true,
                },
                {
                  step: "Tap.",
                  body: "Start a majlis session with one tap and invite fellow reciters. Everyone opens the same kalaam instantly.",
                  active: false,
                },
                {
                  step: "Practice.",
                  body: "Rehearse in practice mode and get feedback on your recitation — line by line, so you know exactly what to work on.",
                  active: false,
                  soon: true,
                },
                {
                  step: "Recite.",
                  body: "The host taps the line being recited and every screen follows. No one loses their place.",
                  active: false,
                },
              ].map((s) => (
                <div key={s.step} className="relative pl-12">
                  <div className="absolute left-0 top-0 bottom-0 w-px border-l border-dashed border-outline-variant" />
                  <div
                    className={`absolute -left-[5px] top-2 w-2.5 h-2.5 rounded-full ring-4 ring-white ${
                      s.active ? "bg-secondary" : "bg-outline-variant"
                    }`}
                  />
                  <h3 className="text-3xl md:text-4xl text-primary font-bold tracking-tight flex items-center gap-3">
                    {s.step}
                    {s.soon && (
                      <span className="px-2.5 py-1 rounded-full bg-[#E8F3EE] border border-[#054A29]/10 font-mono text-[10px] tracking-[0.1em] text-[#054A29] font-bold uppercase">
                        Coming soon
                      </span>
                    )}
                  </h3>
                  <p className="text-on-surface-variant mt-4 text-base md:text-lg">
                    {s.body}
                  </p>
                </div>
              ))}
            </div>
            <div className="w-full aspect-[4/5] bg-surface-container-low rounded-[32px] hairline overflow-hidden relative">
              <div className="absolute inset-0 grid-bg opacity-60" />
              <div className="absolute inset-0">
                <Image
                  src="/mockups/showcase.png"
                  alt="BAYAAZ on iPhone — home library and recite views."
                  fill
                  sizes="(min-width: 768px) 50vw, 100vw"
                  className="object-contain"
                />
              </div>
              <div className="absolute bottom-0 left-0 right-0 p-6 md:p-8 flex flex-col text-primary z-10 pointer-events-none">
                <span className="font-mono text-[11px] mb-2 uppercase tracking-widest">
                  Library &amp; Recite
                </span>
                <p className="text-lg md:text-xl font-semibold">
                  Built to be performed.
                </p>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* Testimonials */}
      <section className="py-24 md:py-32 bg-surface">
        <div className="container mx-auto max-w-[1080px] px-6 md:px-0">
          <h2 className="text-center text-3xl md:text-5xl mb-12 md:mb-20 font-bold tracking-tight text-primary">
            Loved by the literary elite.
          </h2>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-6 md:gap-8">
            {[
              {
                quote:
                  "Finally, a tool that respects the weight of the words. The sync feature is a game-changer for our majalis.",
                name: "A. Rizvi",
                role: "Lead Zakir, London",
                initials: "AR",
                bg: "bg-secondary",
                text: "text-white",
              },
              {
                quote:
                  "The bento-style organization makes managing over 500 poems feel like a breeze. Minimalist yet powerful.",
                name: "S. Bilgrami",
                role: "Poetry Archivist",
                initials: "SB",
                bg: "bg-primary",
                text: "text-white",
              },
              {
                quote:
                  "The real-time scoring helped me master the cadence of Mir Anis's marsiyas. Indispensable for practice.",
                name: "Z. Naqvi",
                role: "Classical Reciter",
                initials: "ZN",
                bg: "bg-secondary-fixed-dim",
                text: "text-primary",
              },
            ].map((t) => (
              <div
                key={t.name}
                className="bg-white p-8 md:p-10 rounded-3xl hairline flex flex-col justify-between"
              >
                <div className="space-y-6">
                  <div className="flex gap-1 text-secondary text-lg">★★★★★</div>
                  <p className="text-on-surface text-base md:text-lg italic leading-relaxed">
                    &ldquo;{t.quote}&rdquo;
                  </p>
                </div>
                <div className="flex items-center gap-4 mt-10">
                  <div
                    className={`w-12 h-12 rounded-full ${t.bg} ${t.text} flex items-center justify-center text-sm font-bold`}
                  >
                    {t.initials}
                  </div>
                  <div>
                    <p className="text-sm font-semibold">{t.name}</p>
                    <p className="font-mono text-[10px] text-outline uppercase tracking-widest">
                      {t.role}
                    </p>
                  </div>
                </div>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* Comparison */}
      <section className="py-24 md:py-32 bg-white">
        <div className="container mx-auto max-w-[1080px] px-6 md:px-0 grid grid-cols-1 md:grid-cols-2 gap-16 md:gap-24">
          <div>
            <h2 className="text-4xl md:text-5xl text-primary font-bold tracking-tight">
              Why Bayaaz.
            </h2>
            <p className="text-on-surface-variant mt-6 text-lg md:text-xl max-w-sm">
              Other apps carry the same popular kalaams. We go looking for the
              ones that deserve to be heard.
            </p>
          </div>
          <div className="space-y-6">
            {[
              ["Only the famous few", "Underrated poets, given their place."],
              ["Lost in old diaries", "Purane kalaam, preserved and searchable."],
              ["Heard once, never found again", "Anjuman kalaams, kept for everyone."],
              ["Cloud-only access", "Full offline functionality."],
            ].map(([bad, good]) => (
              <div
                key={bad}
                className="flex items-start gap-6 p-6 hairline rounded-2xl group hover:bg-surface transition-colors"
              >
                <span className="text-red-500 text-xl leading-none">✕</span>
                <div>
                  <p className="text-outline line-through">{bad}</p>
                  <p className="text-primary font-semibold group-hover:translate-x-2 transition-transform">
                    {good}
                  </p>
                </div>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* Closer */}
      <section
        id="get-started"
        className="relative bg-primary text-white py-24 md:py-32 overflow-hidden scroll-mt-24"
      >
        <div className="absolute inset-0 opacity-10 pointer-events-none">
          <div className="grid-bg w-full h-full" />
        </div>
        <div className="container mx-auto max-w-[1080px] px-6 md:px-0 flex flex-col items-center text-center relative z-10">
          <span className="font-[family-name:var(--font-naskh)] text-[80px] md:text-[120px] leading-none mb-6 md:mb-8 font-bold">
            بیاض
          </span>
          <h2 className="text-[44px] md:text-[64px] lg:text-[96px] leading-[0.95] tracking-tight mb-10 md:mb-12 font-extrabold">
            Make your bayaaz.
          </h2>
          <p className="max-w-[520px] text-base md:text-lg opacity-80 -mt-4 md:-mt-6 mb-10 md:mb-12">
            Know a kalaam that deserves to be heard? Send it to us and we&apos;ll
            add it to the collection.
          </p>
          <div className="flex flex-col sm:flex-row gap-4 md:gap-6">
            <a
              href="mailto:kumailappdev@gmail.com?subject=BAYAAZ%20%E2%80%94%20Beta%20access%20request&body=Hi%20BAYAAZ%20team%2C%0A%0AI%E2%80%99d%20love%20early%20access%20to%20BAYAAZ.%20Please%20add%20me%20to%20the%20beta%20and%20let%20me%20know%20how%20I%20can%20start%20using%20it.%0A%0A(Optional)%20A%20bit%20about%20me%3A%0A%E2%80%A2%20Name%3A%0A%E2%80%A2%20I%E2%80%99m%20a%3A%20zakir%20%2F%20poet%20%2F%20listener%20%2F%20other%0A%E2%80%A2%20Device%3A%20iPhone%20%2F%20Android%0A%0AThank%20you!"
              className="bg-white text-primary px-8 py-4 rounded-2xl text-base md:text-lg font-semibold hover:bg-secondary-fixed-dim transition-colors text-center"
            >
              Get Started for free
            </a>
            <a
              href="mailto:kumailappdev@gmail.com?subject=BAYAAZ%20%E2%80%94%20Kalaam%20suggestion&body=Kalaam%20title%3A%0APoet%20%2F%20anjuman%3A%0ACategory%20(nauha%20%2F%20marsiya%20%2F%20qasida%20%2F%20qata)%3A%0ALyrics%20or%20a%20link%3A%0A"
              className="bg-primary-container text-on-primary-container border border-white/20 px-8 py-4 rounded-2xl text-base md:text-lg font-semibold hover:bg-white/10 transition-colors text-center"
            >
              Suggest a kalaam
            </a>
          </div>
        </div>
      </section>

      <Footer />
    </>
  );
}
