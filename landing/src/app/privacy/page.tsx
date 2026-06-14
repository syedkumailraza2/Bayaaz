import type { Metadata } from "next";
import LegalShell from "@/components/LegalShell";

export const metadata: Metadata = {
  title: "Privacy Policy",
  description:
    "How BAYAAZ collects, uses, and protects your information — clearly written, with offline-first guarantees and export rights.",
  alternates: { canonical: "/privacy" },
  openGraph: {
    title: "Privacy Policy — BAYAAZ",
    description:
      "How BAYAAZ collects, uses, and protects your information.",
    url: "/privacy",
    type: "article",
  },
  twitter: {
    card: "summary",
    title: "Privacy Policy — BAYAAZ",
    description:
      "How BAYAAZ collects, uses, and protects your information.",
  },
};

export default function PrivacyPage() {
  return (
    <LegalShell title="Privacy Policy" updated="May 28, 2026">
      <p>
        BAYAAZ (&ldquo;we&rdquo;, &ldquo;our&rdquo;, &ldquo;us&rdquo;) is built
        for serious zakireen and poets. We treat your kalaams and practice data
        with the same care that a literary archive demands. This Privacy Policy
        explains what we collect, why we collect it, and how we keep it safe.
      </p>

      <h2>1. Information we collect</h2>
      <p>
        We collect only the information needed to operate the service and to
        keep your bayaaz synced across your devices.
      </p>
      <ul>
        <li>
          <strong>Account information</strong> — your name, email address, and
          authentication tokens.
        </li>
        <li>
          <strong>Content you create</strong> — kalaams, line annotations,
          reference audio or video you attach, and the groups you share them
          to.
        </li>
        <li>
          <strong>Practice data</strong> — session scores, streak counts, and
          aggregate metrics generated while you recite.
        </li>
        <li>
          <strong>Device data</strong> — basic diagnostics (OS version, app
          version, anonymous error reports) used to fix crashes.
        </li>
      </ul>

      <h2>2. How we use your information</h2>
      <ul>
        <li>To deliver core features: storage, sync, practice scoring, and majlis sessions.</li>
        <li>To keep your content available across your phones and tablets.</li>
        <li>To improve reliability and fix bugs you encounter.</li>
        <li>To communicate important changes about the service.</li>
      </ul>
      <p>
        We do <strong>not</strong> sell your data. We do not run advertising
        networks inside BAYAAZ.
      </p>

      <h2>3. Offline-first storage</h2>
      <p>
        BAYAAZ is offline-first. Your kalaams, practice sessions, and
        engagement actions are stored locally on your device first, then synced
        to our servers when a connection is available. If you uninstall the
        app, your local copy is removed; your cloud copy remains available
        when you sign back in.
      </p>

      <h2>4. Sharing</h2>
      <p>
        We share information only in three narrow situations:
      </p>
      <ul>
        <li>
          <strong>With your majlis</strong> — when you start a session,
          participants you invite see the kalaam and current line in real time.
        </li>
        <li>
          <strong>With service providers</strong> — hosting, error tracking,
          and email delivery vendors who process data on our behalf under
          confidentiality obligations.
        </li>
        <li>
          <strong>When required by law</strong> — in response to a valid legal
          request, narrowly scoped to what is required.
        </li>
      </ul>

      <h2>5. Your rights</h2>
      <ul>
        <li>You can export your entire kalaam library at any time.</li>
        <li>You can request deletion of your account and all associated data.</li>
        <li>You can correct or update your profile from the app settings.</li>
      </ul>

      <h2>6. Children</h2>
      <p>
        BAYAAZ is not directed at children under 13. We do not knowingly
        collect personal information from children under 13. If you believe a
        child has provided us with personal information, please contact us and
        we will remove it.
      </p>

      <h2>7. Security</h2>
      <p>
        We use industry-standard encryption in transit and at rest. No system
        is perfectly secure; we work continuously to protect your account and
        will notify you if we ever detect a breach that affects your data.
      </p>

      <h2>8. Changes to this policy</h2>
      <p>
        We may update this policy from time to time. Material changes will be
        announced in-app and via email. The &ldquo;Last updated&rdquo; date at
        the top of this page reflects the most recent revision.
      </p>

      <h2>9. Contact</h2>
      <p>
        Questions, requests, or concerns? Reach us at{" "}
        <strong>kumailappdev@gmail.com</strong>. We aim to respond within five
        business days.
      </p>
    </LegalShell>
  );
}
