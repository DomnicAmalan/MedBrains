/** Format a date string for display */
export function formatDate(dateStr: string): string {
	const date = new Date(dateStr);
	return date.toLocaleDateString("en-IN", {
		year: "numeric",
		month: "long",
		day: "numeric",
	});
}

/** Format a date for datetime attribute */
export function formatDateISO(dateStr: string): string {
	return new Date(dateStr).toISOString();
}

/** Format reading time */
export function formatReadingTime(minutes: number): string {
	if (minutes <= 1) return "1 min read";
	return `${minutes} min read`;
}

/** Truncate text to a maximum length */
export function truncate(text: string, maxLength: number): string {
	if (text.length <= maxLength) return text;
	return `${text.slice(0, maxLength).trimEnd()}...`;
}

/** Extract headings from HTML for table of contents */
export function extractHeadings(html: string): Array<{ id: string; text: string; level: number }> {
	const headingRegex = /<h([23])[^>]*>([^<]+)<\/h[23]>/g;
	const headings: Array<{ id: string; text: string; level: number }> = [];
	let match: RegExpExecArray | null;

	while ((match = headingRegex.exec(html)) !== null) {
		const level = parseInt(match[1], 10);
		const text = match[2].trim();
		const id = text
			.toLowerCase()
			.replace(/[^a-z0-9]+/g, "-")
			.replace(/^-|-$/g, "");
		headings.push({ id, text, level });
	}

	return headings;
}

/** Add IDs to headings in HTML for anchor linking */
export function addHeadingIds(html: string): string {
	return html.replace(/<h([23])([^>]*)>([^<]+)<\/h([23])>/g, (_match, level, attrs, text, closeLevel) => {
		const id = text
			.trim()
			.toLowerCase()
			.replace(/[^a-z0-9]+/g, "-")
			.replace(/^-|-$/g, "");
		return `<h${level}${attrs} id="${id}">${text}</h${closeLevel}>`;
	});
}

/** Get the primary tag slug from a post (used as category) */
export function getPostCategory(post: { primary_tag: { slug: string } | null }): string {
	return post.primary_tag?.slug ?? "uncategorized";
}

/** Build the canonical URL for a post */
export function getPostUrl(post: { primary_tag: { slug: string } | null; slug: string }): string {
	const category = getPostCategory(post);
	return `/${category}/${post.slug}/`;
}

/** Build the canonical URL for an author */
export function getAuthorUrl(slug: string): string {
	return `/author/${slug}/`;
}
