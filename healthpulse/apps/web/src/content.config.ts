import { defineCollection, z } from "astro:content";

const posts = defineCollection({
	type: "content",
	schema: z.object({
		title: z.string(),
		description: z.string(),
		category: z.enum([
			"hospital-leadership",
			"patient-education",
			"clinical-excellence",
			"operations",
			"technology",
			"regulatory",
		]),
		author: z.string(),
		date: z.coerce.date(),
		updatedDate: z.coerce.date().optional(),
		featured: z.boolean().default(false),
		image: z.string().optional(),
		imageAlt: z.string().optional(),
		tags: z.array(z.string()).default([]),
		readingTime: z.number().optional(),

		// Medical review (required for patient-education)
		medicalReviewer: z.string().optional(),
		medicalReviewerCredentials: z.string().optional(),
		medicalReviewDate: z.coerce.date().optional(),

		// SEO overrides
		metaTitle: z.string().optional(),
		metaDescription: z.string().optional(),
		ogImage: z.string().optional(),
		noindex: z.boolean().default(false),

		// Content flags
		draft: z.boolean().default(false),
	}),
});

const authors = defineCollection({
	type: "data",
	schema: z.object({
		name: z.string(),
		bio: z.string(),
		credentials: z.string().optional(),
		avatar: z.string().optional(),
		location: z.string().optional(),
		website: z.string().url().optional(),
		twitter: z.string().optional(),
		linkedin: z.string().optional(),
	}),
});

export const collections = { posts, authors };
