import Image from "next/image";
import Link from "next/link";

export default function Nav() {
  return (
    <nav className="fixed top-0 w-full h-16 z-50 bg-surface/80 backdrop-blur-md border-b border-outline-variant/30">
      <div className="flex justify-between items-center px-6 md:px-8 max-w-[1200px] mx-auto h-full">
        <Link
          href="/"
          className="group flex items-center gap-2.5"
          aria-label="BAYAAZ — home"
        >
          <Image
            src="/icon.png"
            alt=""
            width={36}
            height={36}
            priority
            className="rounded-[8px] ring-1 ring-black/5 shadow-sm transition-transform group-hover:scale-105"
          />
          <span className="font-[family-name:var(--font-naskh)] text-[28px] leading-none font-bold text-primary tracking-tight">
            BAYAAZ
          </span>
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
