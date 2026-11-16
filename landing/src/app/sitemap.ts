import type { MetadataRoute } from "next";
import { siteUrl } from "@/lib/seo";
import { CATEGORIES, getKalaamIndex, kalaamPath, peopleInCategory } from "@/lib/api";

export const revalidate = 3600;

export default async function sitemap(): Promise<MetadataRoute.Sitemap> {
  const now = new Date();
  // getKalaamIndex() returns [] if the API is asleep/unreachable, so the
  // static entries are always served.
  const kalaams = await getKalaamIndex();

  const staticEntries: MetadataRoute.Sitemap = [
    { url: `${siteUrl}/`, lastModified: now, changeFrequency: "weekly", priority: 1 },
    { url: `${siteUrl}/kalaams`, lastModified: now, changeFrequency: "daily", priority: 0.9 },
    ...CATEGORIES.map((c) => ({
      url: `${siteUrl}/${c}`,
      lastModified: now,
      changeFrequency: "daily" as const,
      priority: 0.8,
    })),
    { url: `${siteUrl}/privacy`, changeFrequency: "yearly", priority: 0.3 },
    { url: `${siteUrl}/terms`, changeFrequency: "yearly", priority: 0.3 },
  ];

  const kalaamEntries: MetadataRoute.Sitemap = kalaams.map((k) => ({
    url: `${siteUrl}${kalaamPath(k)}`,
    lastModified: new Date(k.updatedAt),
    changeFrequency: "monthly",
    priority: 0.7,
  }));

  const personEntries: MetadataRoute.Sitemap = CATEGORIES.flatMap((c) => {
    return peopleInCategory(kalaams, c).map(({ slug }) => ({
      url: `${siteUrl}/${c}/${slug}`,
      lastModified: now,
      changeFrequency: "weekly" as const,
      priority: 0.75,
    }));
  });

  return [...staticEntries, ...personEntries, ...kalaamEntries];
}
