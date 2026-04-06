import type { Category } from "@healthpulse/types";

export const CATEGORIES: Category[] = [
	{
		slug: "hospital-leadership",
		name: "Hospital Leadership & Strategy",
		description:
			"C-suite insights, healthcare business strategy, governance frameworks, and leadership perspectives for hospital administrators and decision-makers.",
		color: "cat-leadership",
		icon: "building-library",
		subcategories: [
			"CEO/CMO Perspectives",
			"Hospital Governance",
			"Healthcare Business Strategy",
			"Mergers & Acquisitions",
			"Board Governance",
		],
		targetAudience: "Hospital CEOs, CMOs, CFOs, Board Members",
		requiresMedicalReview: false,
	},
	{
		slug: "patient-education",
		name: "Patient Education & Wellness",
		description:
			"Evidence-based health information written for patients and caregivers. Every article in this section is reviewed by a qualified medical professional.",
		color: "cat-patient",
		icon: "heart",
		subcategories: [
			"Understanding Your Diagnosis",
			"Treatment Options",
			"Preventive Health",
			"Nutrition & Lifestyle",
			"Mental Wellness",
			"Caregiver Support",
		],
		targetAudience: "Patients, Caregivers, Health-Conscious Readers",
		requiresMedicalReview: true,
	},
	{
		slug: "clinical-excellence",
		name: "Doctor & Clinical Excellence",
		description:
			"Clinical best practices, medical education insights, case discussions, and physician career development for healthcare professionals.",
		color: "cat-clinical",
		icon: "stethoscope",
		subcategories: [
			"Clinical Best Practices",
			"Medical Education",
			"Case Studies",
			"Physician Wellness",
			"Communication Skills",
		],
		targetAudience: "Doctors, Nurses, Allied Health Professionals",
		requiresMedicalReview: false,
	},
	{
		slug: "operations",
		name: "Operations & Efficiency",
		description:
			"Hospital operations optimization, workflow improvement, process engineering, and practical strategies for running efficient healthcare facilities.",
		color: "cat-operations",
		icon: "chart-bar",
		subcategories: [
			"Workflow Optimization",
			"Lean Healthcare",
			"Supply Chain",
			"Revenue Cycle",
			"Facility Management",
			"Staff Scheduling",
		],
		targetAudience: "Hospital Administrators, Operations Managers, Quality Officers",
		requiresMedicalReview: false,
	},
	{
		slug: "technology",
		name: "Technology & Innovation",
		description:
			"Health tech trends, digital transformation, AI in healthcare, telemedicine, and innovation stories from the intersection of medicine and technology.",
		color: "cat-technology",
		icon: "cpu-chip",
		subcategories: [
			"AI & Machine Learning",
			"EHR & HMS",
			"Telemedicine",
			"Medical Devices",
			"Startups & Innovation",
			"Cybersecurity",
		],
		targetAudience: "CIOs, CTOs, Health Tech Professionals, Innovation Leaders",
		requiresMedicalReview: false,
	},
	{
		slug: "regulatory",
		name: "Regulatory & Compliance",
		description:
			"Healthcare regulations, NABH/JCI accreditation updates, legal compliance, and policy analysis for hospitals navigating India's regulatory landscape.",
		color: "cat-regulatory",
		icon: "shield-check",
		subcategories: [
			"NABH/JCI Standards",
			"Legal & Medico-legal",
			"ABDM & Digital Health Policy",
			"Drug Regulations",
			"Patient Rights",
			"Data Protection",
		],
		targetAudience: "Compliance Officers, Legal Teams, Quality Managers, Hospital Administrators",
		requiresMedicalReview: false,
	},
];

/** Look up a category by its slug */
export function getCategoryBySlug(slug: string): Category | undefined {
	return CATEGORIES.find((c) => c.slug === slug);
}

/** Get the Tailwind color class for a category */
export function getCategoryColor(slug: string): string {
	const category = getCategoryBySlug(slug);
	return category?.color ?? "cat-leadership";
}
