import Image from "next/image";
import Link from "next/link";

export default function Footer() {
  return (
    <footer className="bg-white border-t border-outline-variant/30 py-16">
      <div className="container mx-auto max-w-[1080px] px-6 md:px-8 flex flex-col items-center gap-8">
        <Link
          href="/"
          className="flex items-center gap-3"
          aria-label="BAYAAZ — home"
        >
          <Image
            src="/icon.png"
            alt=""
            width={40}
            height={40}
            className="rounded-[9px] ring-1 ring-black/5 shadow-sm"
          />
          <span className="font-[family-name:var(--font-naskh)] text-[28px] font-bold text-primary">
            BAYAAZ
          </span>
        </Link>
        <div className="flex flex-wrap items-center justify-center gap-x-8 gap-y-3 text-sm">
          <Link
            href="/privacy"
            className="text-on-surface-variant hover:text-primary transition-colors"
          >
            Privacy Policy
          </Link>
          <Link
            href="/terms"
            className="text-on-surface-variant hover:text-primary transition-colors"
          >
            Terms &amp; Conditions
          </Link>
        </div>
        <p className="text-outline text-sm text-center">
          © {new Date().getFullYear()} BAYAAZ. Engineered for the literary mind.
        </p>
      </div>
    </footer>
  );
}
