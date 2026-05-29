// Single source of truth for SEO constants: canonical site URL,
// brand strings, and the keywords / structured data shared across
// pages. Override the URL at deploy time via NEXT_PUBLIC_SITE_URL.

export const siteUrl = (
  process.env.NEXT_PUBLIC_SITE_URL ?? "https://bayaaz.app"
).replace(/\/$/, "");

export const siteName = "BAYAAZ";

export const siteTagline = "The poetry bayaaz you remember.";

export const siteDescription =
  "Precision-engineered for the literary mind. Organize, recite, and sync your kalaams with a distraction-free tool built for serious zakireen and poets.";

export const siteShortDescription =
  "Organize, recite, and sync your kalaams with a distraction-free tool built for serious zakireen and poets.";

export const siteKeywords = [
  "BAYAAZ",
  "bayaaz",
  "kalaam",
  "kalam",
  "kalaam app",
  "majlis",
  "marsiya",
  "noha",
  "qasida",
  "qata",
  "nauha",
  "Urdu poetry",
  "Urdu poetry app",
  "Mir Anis",
  "zakir",
  "zakireen",
  "Shia poetry",
  "Islamic poetry",
  "poetry teleprompter",
  "recitation practice",
  "voice follow",
  "Noto Naskh",
];

export const contactEmail = "kumailappdev@gmail.com";

// JSON-LD helpers — kept simple, no @graph nesting so each page can
// inline only what it needs.

export function organizationJsonLd() {
  return {
    "@context": "https://schema.org",
    "@type": "Organization",
    name: siteName,
    url: siteUrl,
    logo: `${siteUrl}/icon-512.png`,
    email: contactEmail,
    description: siteDescription,
  };
}

export function websiteJsonLd() {
  return {
    "@context": "https://schema.org",
    "@type": "WebSite",
    name: siteName,
    url: siteUrl,
    description: siteDescription,
  };
}

export function softwareApplicationJsonLd() {
  return {
    "@context": "https://schema.org",
    "@type": "MobileApplication",
    name: siteName,
    operatingSystem: "iOS, Android",
    applicationCategory: "LifestyleApplication",
    description: siteDescription,
    url: siteUrl,
    image: `${siteUrl}/icon-512.png`,
    offers: {
      "@type": "Offer",
      price: "0",
      priceCurrency: "USD",
    },
    aggregateRating: {
      "@type": "AggregateRating",
      ratingValue: "4.9",
      ratingCount: "12000",
      bestRating: "5",
      worstRating: "1",
    },
  };
}
