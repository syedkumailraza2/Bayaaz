import Image from "next/image";
import Link from "next/link";
import { CATEGORIES, CATEGORY_INFO } from "@/lib/api";

export default function Nav() {
  return (
    <nav className="fixed top-0 w-full h-16 z-50 bg-surface/80 backdrop-blur-md border-b border-outline-variant/30">
      <div className="flex justify-between items-center gap-3 px-4 sm:px-6 md:px-8 max-w-[1200px] mx-auto h-full">
        <Link
          href="/"
          className="group flex items-center gap-2 sm:gap-2.5 shrink-0"
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
          <span className="font-[family-name:var(--font-naskh)] text-[24px] sm:text-[28px] leading-none font-bold text-primary tracking-tight">
            BAYAAZ
          </span>
        </Link>

        <div className="flex items-center gap-3 sm:gap-5">
          {/* Desktop: categories inline */}
          <ul className="hidden md:flex items-center gap-6">
            {CATEGORIES.map((c) => (
              <li key={c}>
                <Link
                  href={`/${c}`}
                  className="text-[14px] font-medium text-on-surface-variant hover:text-primary transition-colors"
                >
                  {CATEGORY_INFO[c].label}
                </Link>
              </li>
            ))}
          </ul>

          {/* Mobile: categories in a dropdown (no JS needed) */}
          <details className="md:hidden relative group">
            <summary className="list-none cursor-pointer select-none whitespace-nowrap text-[14px] font-medium text-on-surface-variant hover:text-primary flex items-center gap-1 [&::-webkit-details-marker]:hidden">
              Kalaams
              <span className="text-[10px] transition-transform group-open:rotate-180">
                ▼
              </span>
            </summary>
            <ul className="absolute right-0 mt-3 w-44 rounded-xl bg-surface hairline shadow-lg py-2">
              {CATEGORIES.map((c) => (
                <li key={c}>
                  <Link
                    href={`/${c}`}
                    className="block px-4 py-2 text-[14px] text-on-surface-variant hover:bg-surface-container hover:text-primary"
                  >
                    {CATEGORY_INFO[c].label}
                  </Link>
                </li>
              ))}
            </ul>
          </details>

          <a
            href="/#get-started"
            className="bg-primary text-on-primary px-3.5 sm:px-5 py-2 rounded-lg text-[13px] sm:text-[14px] font-medium whitespace-nowrap active:scale-95 transition-all"
          >
            Get Started
          </a>
        </div>
      </div>
    </nav>
  );
}
