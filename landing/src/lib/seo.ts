// Single source of truth for SEO constants: canonical site URL,
// brand strings, and the keywords / structured data shared across
// pages. Override the URL at deploy time via NEXT_PUBLIC_SITE_URL.

export const siteUrl = (
  process.env.NEXT_PUBLIC_SITE_URL ?? "https://www.mybayaaz.com"
).replace(/\/$/, "");

export const siteName = "BAYAAZ";

export const siteTagline = "Beyond the kalaams everyone remembers.";

export const siteDescription =
  "Hand-picked nauha, marsiya, qasida and qata lyrics from underrated poets, anjumans and old bayaazes — read, recite and share them in your majlis.";

export const siteShortDescription =
  "Kalaams from underrated poets, anjumans and old bayaazes — not just the popular few.";

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
  "noha lyrics",
  "nauha lyrics",
  "marsiya lyrics",
  "qasida lyrics",
  "manqabat",
  "Roman Urdu noha",
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
    // No aggregateRating: Google only allows real, verifiable review data
    // here. Add it back once there are actual store ratings to cite.
  };
}

export function breadcrumbJsonLd(items: { name: string; path: string }[]) {
  return {
    "@context": "https://schema.org",
    "@type": "BreadcrumbList",
    itemListElement: items.map((it, i) => ({
      "@type": "ListItem",
      position: i + 1,
      name: it.name,
      item: `${siteUrl}${it.path}`,
    })),
  };
}
