"use client";

import { useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import Link from "next/link";
import { logout, verifySession, type AdminUser } from "@/lib/admin";

/** Renders children only for a verified admin; otherwise sends to login. */
export default function AdminGuard({
  children,
}: {
  children: (user: AdminUser) => React.ReactNode;
}) {
  const router = useRouter();
  const [user, setUser] = useState<AdminUser | null | undefined>(undefined);

  useEffect(() => {
    verifySession().then((u) => {
      if (!u) router.replace("/admin/login");
      else setUser(u);
    });
  }, [router]);

  if (!user) {
    return <p className="p-8 text-on-surface-variant">Checking admin access…</p>;
  }

  return (
    <>
      <header className="border-b border-outline-variant/40 bg-white">
        <div className="max-w-[1000px] mx-auto px-4 md:px-6 h-14 flex items-center justify-between gap-4">
          <Link href="/admin" className="font-bold text-primary">
            BAYAAZ Admin
          </Link>
          <div className="flex items-center gap-4 text-sm">
            <span className="text-on-surface-variant hidden sm:inline">{user.email}</span>
            <button
              type="button"
              className="underline underline-offset-4"
              onClick={() => {
                logout();
                router.replace("/admin/login");
              }}
            >
              Sign out
            </button>
          </div>
        </div>
      </header>
      <main className="max-w-[1000px] mx-auto px-4 md:px-6 py-8">{children(user)}</main>
    </>
  );
}
