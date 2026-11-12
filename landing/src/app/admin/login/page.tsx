"use client";

import { useEffect, useRef, useState } from "react";
import { useRouter } from "next/navigation";
import Script from "next/script";
import { loginWithGoogle, loginWithPassword } from "@/lib/admin";

// Same Google OAuth *Web* client the app uses as serverClientId; the server
// verifies ID tokens against it. The site's origin must be listed under
// "Authorized JavaScript origins" for this client in Google Cloud Console.
const GOOGLE_CLIENT_ID =
  process.env.NEXT_PUBLIC_GOOGLE_CLIENT_ID ??
  "484047874388-53lrv3vjscls2nfooiq1nb6a6l1a4b6v.apps.googleusercontent.com";

type GoogleId = {
  accounts: {
    id: {
      initialize: (o: { client_id: string; callback: (r: { credential: string }) => void }) => void;
      renderButton: (el: HTMLElement, o: Record<string, unknown>) => void;
    };
  };
};

export default function AdminLogin() {
  const router = useRouter();
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);
  const [gisReady, setGisReady] = useState(false);
  const googleBtn = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const g = (window as unknown as { google?: GoogleId }).google;
    if (!gisReady || !g || !googleBtn.current) return;
    g.accounts.id.initialize({
      client_id: GOOGLE_CLIENT_ID,
      callback: async ({ credential }) => {
        setError(null);
        setBusy(true);
        try {
          await loginWithGoogle(credential);
          router.replace("/admin");
        } catch (e) {
          setError((e as Error).message);
        } finally {
          setBusy(false);
        }
      },
    });
    g.accounts.id.renderButton(googleBtn.current, { theme: "outline", size: "large", width: 320 });
  }, [gisReady, router]);

  async function onSubmit(e: React.FormEvent) {
    e.preventDefault();
    setError(null);
    setBusy(true);
    try {
      await loginWithPassword(email.trim(), password);
      router.replace("/admin");
    } catch (err) {
      setError((err as Error).message);
    } finally {
      setBusy(false);
    }
  }

  return (
    <div className="min-h-screen flex items-center justify-center px-4">
      <Script
        src="https://accounts.google.com/gsi/client"
        strategy="afterInteractive"
        onLoad={() => setGisReady(true)}
        onReady={() => setGisReady(true)}
      />
      <div className="w-full max-w-[360px] bg-white rounded-2xl hairline p-6 shadow-sm">
        <h1 className="text-2xl font-bold text-primary">BAYAAZ Admin</h1>
        <p className="text-sm text-on-surface-variant mt-1">Sign in with an admin account.</p>

        <div ref={googleBtn} className="mt-6 min-h-[44px]" />

        <div className="flex items-center gap-3 my-5 text-xs text-outline">
          <span className="flex-1 h-px bg-outline-variant/50" /> or <span className="flex-1 h-px bg-outline-variant/50" />
        </div>

        <form onSubmit={onSubmit} className="space-y-3">
          <input
            type="email"
            required
            autoComplete="email"
            placeholder="Email"
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            className="w-full rounded-lg hairline px-3 py-2.5 bg-white"
          />
          <input
            type="password"
            required
            autoComplete="current-password"
            placeholder="Password"
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            className="w-full rounded-lg hairline px-3 py-2.5 bg-white"
          />
          <button
            type="submit"
            disabled={busy}
            className="w-full bg-primary text-on-primary rounded-lg py-2.5 font-semibold disabled:opacity-60"
          >
            {busy ? "Signing in…" : "Sign in"}
          </button>
        </form>
        {error ? <p className="mt-4 text-sm text-red-700" role="alert">{error}</p> : null}
      </div>
    </div>
  );
}
