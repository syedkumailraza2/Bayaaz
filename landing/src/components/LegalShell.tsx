import Nav from "@/components/Nav";
import Footer from "@/components/Footer";

export default function LegalShell({
  title,
  updated,
  children,
}: {
  title: string;
  updated: string;
  children: React.ReactNode;
}) {
  return (
    <>
      <Nav />
      <section className="relative pt-32 pb-12 overflow-hidden">
        <div className="absolute inset-0 grid-bg opacity-60 z-0" />
        <div className="container mx-auto max-w-[820px] px-6 md:px-8 relative z-10">
          <div className="inline-flex items-center gap-2 px-3 py-1 bg-[#E8F3EE] rounded-full border border-[#054A29]/10 mb-6">
            <span className="w-1.5 h-1.5 rounded-full bg-[#054A29]" />
            <span className="font-mono text-[11px] tracking-[0.05em] text-[#054A29] font-bold uppercase">
              Legal
            </span>
          </div>
          <h1 className="text-4xl md:text-6xl font-extrabold tracking-tight text-primary">
            {title}
          </h1>
          <p className="mt-4 font-mono text-xs tracking-widest text-outline uppercase">
            Last updated · {updated}
          </p>
        </div>
      </section>

      <section className="pb-24 md:pb-32">
        <div className="container mx-auto max-w-[820px] px-6 md:px-8">
          <div className="legal-prose">{children}</div>
        </div>
      </section>

      <Footer />
    </>
  );
}
