"use client";

import AdminGuard from "@/components/admin/AdminGuard";
import KalaamEditor from "@/components/admin/KalaamEditor";

export default function NewKalaamPage() {
  return (
    <AdminGuard>
      {() => (
        <>
          <h1 className="text-2xl font-bold text-primary mb-6">New kalaam</h1>
          <KalaamEditor />
        </>
      )}
    </AdminGuard>
  );
}
