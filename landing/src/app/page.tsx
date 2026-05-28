import Image from "next/image";
import Nav from "@/components/Nav";
import Footer from "@/components/Footer";

export default function Home() {
  return (
    <>
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
              The bayaaz <br />
              for poetry you{" "}
              <i className="text-secondary-fixed-dim italic font-extrabold">
                remember
              </i>
              .
            </h1>
            <p className="max-w-[540px] text-base md:text-lg leading-relaxed text-on-surface-variant">
              Precision-engineered for the literary mind. Organize, recite, and
              sync your kalaams with a distraction-free tool built for serious
              zakireen and poets.
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
              <span>★ 4.9/5</span>
              <span className="text-primary-fixed-dim">·</span>
              <span>Offline-First</span>
              <span className="text-primary-fixed-dim">·</span>
              <span>1,240 Kalaams</span>
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
        <div className="marquee-content flex items-center gap-12 px-6">
          {[0, 1].map((i) => (
            <div key={i} className="inline-flex items-center gap-12">
              <span className="font-mono text-xs tracking-widest text-on-surface-variant">
                PRACTICE SCORING
              </span>
              <span className="w-2 h-2 rounded-full bg-secondary-fixed-dim" />
              <span className="font-[family-name:var(--font-naskh)] text-xl text-primary font-bold">
                ضایب
              </span>
              <span className="w-2 h-2 rounded-full bg-secondary-fixed-dim" />
              <span className="font-mono text-xs tracking-widest text-on-surface-variant">
                QATA
              </span>
              <span className="w-2 h-2 rounded-full bg-secondary-fixed-dim" />
              <span className="font-mono text-xs tracking-widest text-on-surface-variant">
                MAJLIS SYNC
              </span>
              <span className="w-2 h-2 rounded-full bg-secondary-fixed-dim" />
            </div>
          ))}
        </div>
        <div className="marquee-content flex items-center gap-12 px-6">
          {[0, 1].map((i) => (
            <div key={i} className="inline-flex items-center gap-12">
              <span className="font-mono text-xs tracking-widest text-on-surface-variant">
                PRACTICE SCORING
              </span>
              <span className="w-2 h-2 rounded-full bg-secondary-fixed-dim" />
              <span className="font-[family-name:var(--font-naskh)] text-xl text-primary font-bold">
                ضایب
              </span>
              <span className="w-2 h-2 rounded-full bg-secondary-fixed-dim" />
              <span className="font-mono text-xs tracking-widest text-on-surface-variant">
                QATA
              </span>
              <span className="w-2 h-2 rounded-full bg-secondary-fixed-dim" />
              <span className="font-mono text-xs tracking-widest text-on-surface-variant">
                MAJLIS SYNC
              </span>
              <span className="w-2 h-2 rounded-full bg-secondary-fixed-dim" />
            </div>
          ))}
        </div>
      </div>

      {/* Stats */}
      <section className="py-24 md:py-[120px] bg-white">
        <div className="container mx-auto max-w-[1080px] px-6 md:px-0">
          <h2 className="text-center text-[36px] md:text-[56px] text-primary mb-12 md:mb-20 tracking-tight font-bold">
            The digital home for tradition.
          </h2>
          <div className="grid grid-cols-2 md:grid-cols-4 hairline-t">
            {[
              ["1,240", "VERIFIED KALAAMS"],
              ["12k+", "RECITERS WORLDWIDE"],
              ["0", "LATENCY SYNC"],
              ["∞", "STORAGE SPACE"],
            ].map(([value, label], idx, arr) => (
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

      {/* Bento */}
      <section className="py-16 md:py-20">
        <div className="container mx-auto max-w-[1080px] px-6 md:px-0">
          <div className="grid grid-cols-1 md:grid-cols-4 md:grid-rows-3 gap-4 h-auto md:h-[800px]">
            {/* A */}
            <div className="md:col-span-2 md:row-span-2 bento-card hairline rounded-2xl p-8 flex flex-col justify-between group overflow-hidden">
              <div>
                <h3 className="text-3xl mb-2 text-primary font-bold tracking-tight">
                  Follow my voice
                </h3>
                <p className="text-on-surface-variant max-w-[280px]">
                  Real-time waveform tracking keeps you on beat during
                  recitations.
                </p>
              </div>
              <div className="mt-8 bg-surface-container rounded-xl p-4 hairline group-hover:scale-105 transition-transform duration-500">
                <div className="flex items-center gap-4 mb-4">
                  <span className="text-secondary text-xl">≡</span>
                  <div className="flex-1 h-1 bg-outline-variant rounded-full overflow-hidden">
                    <div className="h-full bg-secondary w-2/3" />
                  </div>
                </div>
                <div className="font-[family-name:var(--font-naskh)] text-xl text-center opacity-80">
                  سر جھکا کر جو کھڑے ہیں
                </div>
              </div>
            </div>

            {/* B */}
            <div className="md:col-span-1 md:row-span-2 bg-[#054A29] rounded-2xl p-8 flex flex-col justify-between text-white overflow-hidden relative">
              <div className="relative z-10">
                <h3 className="text-2xl mb-4 font-bold tracking-tight">
                  Everyone on the same line.
                </h3>
                <p className="text-on-primary-container text-sm opacity-80">
                  Synchronize tablets and phones for seamless group sessions.
                </p>
              </div>
              <div className="mt-12 flex flex-col gap-2 relative z-10">
                {[0, 1, 2].map((i) => (
                  <div
                    key={i}
                    className="w-full h-8 bg-white/10 rounded-lg flex items-center px-4 gap-2"
                  >
                    <div className="w-2 h-2 rounded-full bg-secondary-fixed-dim" />
                    <div className="flex-1 h-1 bg-white/20 rounded-full" />
                  </div>
                ))}
              </div>
              <div className="absolute -bottom-12 -right-12 w-48 h-48 bg-secondary-fixed-dim/20 blur-3xl" />
            </div>

            {/* C */}
            <div className="md:col-span-1 md:row-span-1 bento-card hairline rounded-2xl p-8 flex flex-col items-center justify-center text-center group">
              <div className="w-16 h-16 rounded-full bg-surface-container flex items-center justify-center mb-4 group-hover:bg-primary transition-colors text-primary group-hover:text-white text-2xl">
                ●
              </div>
              <h4 className="text-primary font-semibold">Practice scoring</h4>
            </div>

            {/* D */}
            <div className="md:col-span-1 md:row-span-1 bento-card hairline rounded-2xl p-8 flex flex-col items-center justify-center text-center group">
              <div className="w-16 h-16 rounded-full bg-surface-container flex items-center justify-center mb-4 group-hover:bg-primary transition-colors text-primary group-hover:text-white text-2xl">
                ⌀
              </div>
              <h4 className="text-primary font-semibold">Works offline</h4>
            </div>

            {/* E */}
            <div className="md:col-span-2 md:row-span-1 bg-surface-container-low rounded-2xl p-8 flex flex-col justify-between">
              <div>
                <h3 className="text-2xl mb-2 text-primary font-bold tracking-tight">
                  Bring your own reference.
                </h3>
                <p className="text-on-surface-variant text-sm">
                  Attach audio or video files to any bayaaz entry.
                </p>
              </div>
              <div className="flex flex-wrap gap-3 mt-4">
                {["MP3 MASTER", "MP4 REFERENCE", "WAV HIGH-RES"].map((t) => (
                  <span
                    key={t}
                    className="px-3 py-1 bg-white hairline rounded-full font-mono text-[10px] tracking-wider"
                  >
                    {t}
                  </span>
                ))}
              </div>
            </div>

            {/* F */}
            <div className="md:col-span-2 md:row-span-1 bento-card hairline rounded-2xl p-8 flex flex-col justify-between">
              <div>
                <h3 className="text-2xl mb-2 text-primary font-bold tracking-tight">
                  Write in Urdu or Roman
                </h3>
                <p className="text-on-surface-variant text-sm">
                  Instant transliteration for easy reading during recitations.
                </p>
              </div>
              <div className="flex flex-wrap gap-2 mt-4">
                <span className="px-4 py-1 bg-secondary text-on-secondary rounded-full font-mono text-[11px] tracking-wider">
                  URDU (NASKH)
                </span>
                <span className="px-4 py-1 bg-surface-container hairline rounded-full font-mono text-[11px] tracking-wider">
                  ROMAN URDU
                </span>
                <span className="px-4 py-1 bg-surface-container hairline rounded-full font-mono text-[11px] tracking-wider">
                  PHONETIC
                </span>
              </div>
            </div>
          </div>
        </div>
      </section>

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
                  body: "Your entire library, organized by poet, theme, or recent session. Instant access when the majlis starts.",
                  active: true,
                },
                {
                  step: "Tap.",
                  body: "Start a session with one tap. Sync with fellow reciters and prepare your audio recording environment.",
                  active: false,
                },
                {
                  step: "Practice.",
                  body: "Recite in practice mode and get real-time scoring on accuracy, flow, and pause. Track weak lines across sessions.",
                  active: false,
                },
                {
                  step: "Recite.",
                  body: "Focus only on the words. Our distraction-free interface highlights the active line as you breathe.",
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
                  <h3 className="text-3xl md:text-4xl text-primary font-bold tracking-tight">
                    {s.step}
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
              We&apos;re not building a social network. We&apos;re building a
              tool for your craft.
            </p>
          </div>
          <div className="space-y-6">
            {[
              ["Algorithmic feed", "Your bayaaz, sorted by you."],
              ["Distracting notifications", "Focus mode by default."],
              ["Cloud-only access", "Full offline functionality."],
              ["Locked data", "Export your collection anytime."],
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
            ضایب
          </span>
          <h2 className="text-[44px] md:text-[64px] lg:text-[96px] leading-[0.95] tracking-tight mb-10 md:mb-12 font-extrabold">
            Make your bayaaz.
          </h2>
          <div className="flex flex-col sm:flex-row gap-4 md:gap-6">
            <a
              href="mailto:kumailappdev@gmail.com?subject=BAYAAZ%20%E2%80%94%20Beta%20access%20request&body=Hi%20BAYAAZ%20team%2C%0A%0AI%E2%80%99d%20love%20early%20access%20to%20BAYAAZ.%20Please%20add%20me%20to%20the%20beta%20and%20let%20me%20know%20how%20I%20can%20start%20using%20it.%0A%0A(Optional)%20A%20bit%20about%20me%3A%0A%E2%80%A2%20Name%3A%0A%E2%80%A2%20I%E2%80%99m%20a%3A%20zakir%20%2F%20poet%20%2F%20listener%20%2F%20other%0A%E2%80%A2%20Device%3A%20iPhone%20%2F%20Android%0A%0AThank%20you!"
              className="bg-white text-primary px-8 py-4 rounded-2xl text-base md:text-lg font-semibold hover:bg-secondary-fixed-dim transition-colors text-center"
            >
              Get Started for free
            </a>
            <a
              href="mailto:kumailappdev@gmail.com?subject=BAYAAZ%20support%20request"
              className="bg-primary-container text-on-primary-container border border-white/20 px-8 py-4 rounded-2xl text-base md:text-lg font-semibold hover:bg-white/10 transition-colors text-center"
            >
              Contact Support
            </a>
          </div>
        </div>
      </section>

      <Footer />
    </>
  );
}
