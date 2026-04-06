import rss from "@astrojs/rss";
import type { APIRoute } from "astro";
import { getAllPosts } from "@healthpulse/ghost-client";
import { getPostUrl } from "@/lib/utils";

export const GET: APIRoute = async ({ site }) => {
	const { data: posts } = await getAllPosts(1, 50);

	return rss({
		title: "HealthPulse",
		description: "Healthcare news, insights, and innovation from India's leading healthcare publishing platform.",
		site: site?.toString() ?? "https://healthpulse.medbrains.in",
		items: posts.map((post) => ({
			title: post.title,
			pubDate: new Date(post.published_at),
			description: post.custom_excerpt ?? post.excerpt ?? "",
			link: getPostUrl(post),
			author: post.primary_author.name,
			categories: post.tags.map((t) => t.name),
		})),
		customData: "<language>en-in</language>",
	});
};
