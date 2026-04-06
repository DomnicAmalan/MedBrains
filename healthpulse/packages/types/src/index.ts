/** Content type classification */
export type ContentType = "article" | "quick-post" | "opinion" | "interview" | "case-study";

/** Medical review status for patient-facing content */
export type MedicalReviewStatus = "pending" | "in-review" | "approved" | "needs-revision";

/** Author credential types */
export type AuthorCredential =
	| "MD"
	| "MBBS"
	| "MS"
	| "MCh"
	| "DM"
	| "DNB"
	| "PhD"
	| "MPH"
	| "MBA"
	| "MHA"
	| "RN"
	| "BSN";

/** Category definition for the 6 core verticals */
export interface Category {
	slug: string;
	name: string;
	description: string;
	color: string;
	icon: string;
	subcategories: string[];
	targetAudience: string;
	requiresMedicalReview: boolean;
}

/** SEO metadata for any page */
export interface SEOMetadata {
	title: string;
	description: string;
	canonicalUrl?: string;
	ogImage?: string;
	ogType?: "article" | "website" | "profile";
	twitterCard?: "summary" | "summary_large_image";
	publishedTime?: string;
	modifiedTime?: string;
	author?: string;
	section?: string;
	tags?: string[];
	noindex?: boolean;
}

/** Schema.org Article structured data */
export interface ArticleSchema {
	"@context": "https://schema.org";
	"@type": "Article" | "MedicalWebPage";
	headline: string;
	description: string;
	image?: string;
	datePublished: string;
	dateModified?: string;
	author: {
		"@type": "Person";
		name: string;
		url?: string;
		jobTitle?: string;
	};
	publisher: {
		"@type": "Organization";
		name: string;
		logo?: {
			"@type": "ImageObject";
			url: string;
		};
	};
	mainEntityOfPage?: string;
	reviewedBy?: {
		"@type": "Person";
		name: string;
		jobTitle?: string;
	};
}

/** Breadcrumb item for structured data */
export interface BreadcrumbItem {
	name: string;
	url: string;
}

/** Newsletter subscriber form data */
export interface NewsletterFormData {
	email: string;
	name?: string;
}

/** HMS demo request form data */
export interface HMSDemoRequestData {
	name: string;
	email: string;
	phone?: string;
	hospitalName?: string;
	role?: string;
	message?: string;
	utmSource?: string;
	utmMedium?: string;
	utmCampaign?: string;
}
