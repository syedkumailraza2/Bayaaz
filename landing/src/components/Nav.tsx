import Link from "next/link";

export default function Nav() {
  return (
    <nav className="fixed top-0 w-full h-16 z-50 bg-surface/80 backdrop-blur-md border-b border-outline-variant/30">
      <div className="flex justify-between items-center px-6 md:px-8 max-w-[1200px] mx-auto h-full">
        <Link
          href="/"
          className="font-[family-name:var(--font-naskh)] text-[28px] leading-none font-bold text-primary tracking-tight"
        >
          BAYAAZ
        </Link>
        <a
          href="/#get-started"
          className="bg-primary text-on-primary px-5 py-2 rounded-lg text-[14px] font-medium active:scale-95 transition-all"
        >
          Get Started
        </a>
      </div>
    </nav>
  );
}
