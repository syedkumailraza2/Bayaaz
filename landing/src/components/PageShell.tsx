import Nav from "@/components/Nav";
import Footer from "@/components/Footer";

/** Shared chrome for content pages (kalaam, category, browse). */
export default function PageShell({
  eyebrow,
  title,
  subtitle,
  children,
}: {
  eyebrow: string;
  title: string;
  subtitle?: React.ReactNode;
  children: React.ReactNode;
}) {
  return (
    <>
      <Nav />
      <main className="flex-1">
        <section className="relative pt-28 md:pt-32 pb-8 overflow-hidden">
          <div className="absolute inset-0 grid-bg opacity-60 z-0" />
          <div className="container mx-auto max-w-[820px] px-6 md:px-8 relative z-10">
            <div className="inline-flex items-center gap-2 px-3 py-1 bg-[#E8F3EE] rounded-full border border-[#054A29]/10 mb-5">
              <span className="w-1.5 h-1.5 rounded-full bg-[#054A29]" />
              <span className="font-mono text-[11px] tracking-[0.05em] text-[#054A29] font-bold uppercase">
                {eyebrow}
              </span>
            </div>
            <h1 className="text-3xl md:text-5xl font-extrabold tracking-tight text-primary break-words">
              {title}
            </h1>
            {subtitle ? (
              <div className="mt-4 text-on-surface-variant text-base md:text-lg">
                {subtitle}
              </div>
            ) : null}
          </div>
        </section>
        <section className="pb-20 md:pb-28">
          <div className="container mx-auto max-w-[820px] px-6 md:px-8">
            {children}
          </div>
        </section>
      </main>
      <Footer />
    </>
  );
}
