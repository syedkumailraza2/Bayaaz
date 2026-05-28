import type { Metadata } from "next";
import LegalShell from "@/components/LegalShell";

export const metadata: Metadata = {
  title: "Terms & Conditions — BAYAAZ",
  description: "The terms that govern your use of BAYAAZ.",
};

export default function TermsPage() {
  return (
    <LegalShell title="Terms & Conditions" updated="May 28, 2026">
      <p>
        Welcome to BAYAAZ. By creating an account or using the app, you agree
        to these Terms. Please read them carefully — they describe what we
        provide, what we expect from you, and the limits of our
        responsibilities.
      </p>

      <h2>1. The service</h2>
      <p>
        BAYAAZ is a tool to organize, recite, score, and sync poetry —
        primarily Urdu kalaams, marsiyas, and qasidas — across your devices
        and with people you invite to a majlis. We may add, modify, or remove
        features as the product evolves.
      </p>

      <h2>2. Your account</h2>
      <ul>
        <li>You must be at least 13 years old to use BAYAAZ.</li>
        <li>You are responsible for keeping your login credentials safe.</li>
        <li>You are responsible for activity that happens under your account.</li>
        <li>One human, one account. Don&apos;t share accounts.</li>
      </ul>

      <h2>3. Your content</h2>
      <p>
        You retain full ownership of the kalaams, audio, and notes you upload.
        By using BAYAAZ, you grant us a limited, worldwide, royalty-free
        license to store, transmit, and display your content solely so that we
        can deliver the service to you and the majlis participants you invite.
      </p>
      <p>
        You are responsible for ensuring you have the right to upload any
        content you add — particularly reference audio or video that may be
        owned by others. Do not upload material that infringes copyright or
        violates the rights of others.
      </p>

      <h2>4. Acceptable use</h2>
      <p>You agree not to:</p>
      <ul>
        <li>Use BAYAAZ to harass, defame, or harm others.</li>
        <li>Upload illegal, hateful, or sexually explicit material.</li>
        <li>Attempt to reverse engineer, probe, or attack our infrastructure.</li>
        <li>Use bots or scripts to scrape content or abuse the service.</li>
      </ul>

      <h2>5. Subscriptions and pricing</h2>
      <p>
        BAYAAZ is currently free to use. We reserve the right to introduce
        paid plans for advanced features in the future. Any pricing change
        will be announced before it takes effect, and your existing data will
        remain accessible regardless of the plan you choose.
      </p>

      <h2>6. Termination</h2>
      <p>
        You can delete your account at any time from the app settings. We may
        suspend or terminate accounts that violate these Terms or that put
        other users at risk. On termination, your content will be removed in
        line with our Privacy Policy and our backup retention windows.
      </p>

      <h2>7. Disclaimers</h2>
      <p>
        BAYAAZ is provided &ldquo;as is&rdquo; and &ldquo;as available&rdquo;.
        We work hard to keep the service reliable, but we do not guarantee
        uninterrupted access. Practice scores are guidance, not authoritative
        evaluations of recitation quality.
      </p>

      <h2>8. Limitation of liability</h2>
      <p>
        To the maximum extent permitted by law, BAYAAZ and its team are not
        liable for any indirect, incidental, or consequential damages arising
        from your use of the service. Our aggregate liability will not exceed
        the amount you have paid us in the twelve months preceding the claim
        (or, if you are on a free plan, fifty US dollars).
      </p>

      <h2>9. Changes to these terms</h2>
      <p>
        We may update these Terms as the product evolves. Material changes
        will be announced in-app and via email. Continuing to use BAYAAZ after
        a change means you accept the updated Terms.
      </p>

      <h2>10. Governing law</h2>
      <p>
        These Terms are governed by the laws of the jurisdiction where the
        BAYAAZ operating entity is registered. Any disputes will be resolved
        in the courts of that jurisdiction unless local consumer protection
        law gives you a stronger right.
      </p>

      <h2>11. Contact</h2>
      <p>
        Questions about these Terms? Email us at{" "}
        <strong>legal@bayaaz.app</strong>.
      </p>
    </LegalShell>
  );
}
