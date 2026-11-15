"use client";

import { useEffect, useState } from "react";
import { useParams } from "next/navigation";
import AdminGuard from "@/components/admin/AdminGuard";
import KalaamEditor from "@/components/admin/KalaamEditor";
import { getKalaamAdmin } from "@/lib/admin";
import type { Kalaam } from "@/lib/api";

function Editor({ id }: { id: string }) {
  const [kalaam, setKalaam] = useState<Kalaam | null>(null);
  const [error, setError] = useState<string | null>(null);
  useEffect(() => {
    getKalaamAdmin(id).then(setKalaam).catch((e) => setError((e as Error).message));
  }, [id]);
  if (error) return <p className="text-red-700">{error}</p>;
  if (!kalaam) return <p className="text-on-surface-variant">Loading…</p>;
  return <KalaamEditor existing={kalaam} />;
}

export default function EditKalaamPage() {
  const { id } = useParams<{ id: string }>();
  return (
    <AdminGuard>
      {() => (
        <>
          <h1 className="text-2xl font-bold text-primary mb-6">Edit kalaam</h1>
          <Editor id={id} />
        </>
      )}
    </AdminGuard>
  );
}
