"use client";

import { useEffect, useState } from "react";

export default function Splash() {
  const [phase, setPhase] = useState<"in" | "out" | "gone">("in");

  useEffect(() => {
    document.body.style.overflow = "hidden";
    const fadeOut = window.setTimeout(() => setPhase("out"), 2400);
    const unmount = window.setTimeout(() => {
      setPhase("gone");
      document.body.style.overflow = "";
    }, 2900);
    return () => {
      window.clearTimeout(fadeOut);
      window.clearTimeout(unmount);
      document.body.style.overflow = "";
    };
  }, []);

  if (phase === "gone") return null;

  return (
    <div
      aria-hidden
      className={`fixed inset-0 z-[100] flex flex-col items-center justify-between py-14 transition-opacity duration-500 ${
        phase === "out" ? "opacity-0 pointer-events-none" : "opacity-100"
      }`}
      style={{
        background:
          "linear-gradient(to bottom, #234547 0%, #55A8AD 100%)",
      }}
    >
      <div className="flex-1" />
      <div className="flex flex-col items-center -translate-y-4">
        <div className="splash-title">
          <span
            className="font-[family-name:var(--font-naskh)] font-medium leading-none"
            style={{
              fontSize: "64px",
              letterSpacing: "-1.28px",
              backgroundImage:
                "linear-gradient(to bottom, #FDA43F, #FDBA55)",
              WebkitBackgroundClip: "text",
              backgroundClip: "text",
              color: "transparent",
              direction: "rtl",
              display: "inline-block",
            }}
          >
            بیاض
          </span>
        </div>
        <div className="h-[18px]" />
        <p
          dir="rtl"
          className="splash-subtitle font-[family-name:var(--font-naskh)] text-white text-center"
          style={{
            fontSize: "14px",
            fontWeight: 600,
            letterSpacing: "-0.56px",
          }}
        >
          اسلام علیکم بیاز میں خوش آمدید
        </p>
      </div>
      <div className="flex-1 flex items-end w-full px-6">
        <div
          className="splash-hairline w-full"
          style={{
            height: "0.5px",
            background: "#FDBA55",
          }}
        />
      </div>

      <style>{`
        .splash-title {
          opacity: 0;
          animation: splashFade 770ms ease-out 660ms forwards;
        }
        .splash-subtitle {
          opacity: 0;
          animation: splashFade 660ms ease-out 1210ms forwards;
        }
        .splash-hairline {
          opacity: 0;
          animation: splashFade 510ms ease-out 1584ms forwards;
        }
        @keyframes splashFade {
          from { opacity: 0; }
          to { opacity: 1; }
        }
      `}</style>
    </div>
  );
}
