import type { ArticleSchema, BreadcrumbItem, SEOMetadata } from "@healthpulse/types";

const SITE_NAME = "HealthPulse";
const SITE_URL = "https://healthpulse.medbrains.in";

/** Build page title with site suffix */
export function buildTitle(pageTitle?: string): string {
	if (!pageTitle) return `${SITE_NAME} — Healthcare News, Insights & Innovation`;
	return `${pageTitle} | ${SITE_NAME}`;
}

/** Generate default SEO metadata */
export function buildSEO(overrides: Partial<SEOMetadata> = {}): SEOMetadata {
	return {
		title: buildTitle(overrides.title),
		description:
			overrides.description ??
			"India's leading healthcare publishing platform. Expert insights on hospital management, clinical excellence, health tech, and patient education.",
		ogType: overrides.ogType ?? "website",
		twitterCard: overrides.twitterCard ?? "summary_large_image",
		...overrides,
	};
}

/** Generate Article schema.org JSON-LD */
export function buildArticleSchema(params: {
	title: string;
	description: string;
	url: string;
	image?: string;
	publishedAt: string;
	updatedAt?: string;
	authorName: string;
	authorSlug: string;
	authorTitle?: string;
	isMedical?: boolean;
	reviewerName?: string;
	reviewerTitle?: string;
}): ArticleSchema {
	const schema: ArticleSchema = {
		"@context": "https://schema.org",
		"@type": params.isMedical ? "MedicalWebPage" : "Article",
		headline: params.title,
		description: params.description,
		image: params.image,
		datePublished: params.publishedAt,
		dateModified: params.updatedAt ?? params.publishedAt,
		author: {
			"@type": "Person",
			name: params.authorName,
			url: `${SITE_URL}/author/${params.authorSlug}/`,
			jobTitle: params.authorTitle,
		},
		publisher: {
			"@type": "Organization",
			name: SITE_NAME,
			logo: {
				"@type": "ImageObject",
				url: `${SITE_URL}/favicon.svg`,
			},
		},
		mainEntityOfPage: `${SITE_URL}${params.url}`,
	};

	if (params.reviewerName) {
		schema.reviewedBy = {
			"@type": "Person",
			name: params.reviewerName,
			jobTitle: params.reviewerTitle,
		};
	}

	return schema;
}

/** Generate BreadcrumbList schema.org JSON-LD */
export function buildBreadcrumbSchema(items: BreadcrumbItem[]) {
	return {
		"@context": "https://schema.org",
		"@type": "BreadcrumbList",
		itemListElement: items.map((item, index) => ({
			"@type": "ListItem",
			position: index + 1,
			name: item.name,
			item: `${SITE_URL}${item.url}`,
		})),
	};
}
