import {
  Card,
  Container,
  createTheme,
  Loader,
  Paper,
  rem,
  Select,
  type CSSVariablesResolver,
  type MantineColorsTuple,
} from "@mantine/core";
import { EcgLoader } from "./components/EcgLoader";

// ═══════════════════════════════════════════════════════════════════
// ── MedBrains Design System: Healthcare-Optimized Palette ────────
// ═══════════════════════════════════════════════════════════════════
//
// Inspired by: IBM Carbon (authority, accessibility), Stripe (polish),
//              Apple (clarity), clinical UI best practices
//
// Philosophy: trust, calm, clarity — designed for 12-hour clinical shifts
//
// COLOR ROLES:
//   primary   — brand / interactive (healthcare blue — trust, calm)
//   success   — positive states, healthy, normal vitals, completed
//   warning   — attention needed, pending, abnormal values
//   danger    — critical alerts, emergencies, destructive actions
//   info      — informational, neutral-cool for data display
//   violet    — premium features, AI/smart actions
//   orange    — warm accent, billing, revenue, highlights
//   teal      — clinical accent, healthcare-specific, calm trust
//   slate     — elevated neutral for subtle UI elements
// ═══════════════════════════════════════════════════════════════════

// Brand — Healthcare Blue (trustworthy, calm, clinical)
const primary: MantineColorsTuple = [
  "#eff6ff", // 0  ghost
  "#dbeafe", // 1  dimmed / selection
  "#bfdbfe", // 2  subtle
  "#93c5fd", // 3  medium
  "#60a5fa", // 4  strong
  "#2563eb", // 5  accent      ← PRIMARY (clinical blue)
  "#1d4ed8", // 6  hover
  "#1e40af", // 7  pressed
  "#1e3a8a", // 8  deep
  "#172554", // 9  abyss
];

// Success — Clinical Green (normal vitals, healthy, completed, active)
// Higher saturation for unambiguous "all clear" in clinical context
const success: MantineColorsTuple = [
  "#ecfdf5", // 0
  "#d1fae5", // 1
  "#a7f3d0", // 2
  "#6ee7b7", // 3
  "#34d399", // 4
  "#16a34a", // 5  ← success (stronger green, IBM-inspired)
  "#15803d", // 6
  "#166534", // 7
  "#14532d", // 8
  "#052e16", // 9
];

// Warning — Clinical Amber (abnormal values, pending, requires attention)
// Must be clearly distinct from danger red — amber/gold tone
const warning: MantineColorsTuple = [
  "#fffbeb", // 0
  "#fef3c7", // 1
  "#fde68a", // 2
  "#fcd34d", // 3
  "#fbbf24", // 4
  "#eab308", // 5  ← warning (purer gold, less orange)
  "#ca8a04", // 6
  "#a16207", // 7
  "#854d0e", // 8
  "#713f12", // 9
];

// Danger — Clinical Red (critical alerts, emergencies, destructive)
// True red, not rose — must signal urgency unambiguously
const danger: MantineColorsTuple = [
  "#fef2f2", // 0
  "#fee2e2", // 1
  "#fecaca", // 2
  "#fca5a5", // 3
  "#f87171", // 4
  "#dc2626", // 5  ← danger (true red, IBM-inspired)
  "#b91c1c", // 6
  "#991b1b", // 7
  "#7f1d1d", // 8
  "#450a0a", // 9
];

// Info — Sky Blue (informational, data, neutral-cool)
const info: MantineColorsTuple = [
  "#f0f9ff", // 0
  "#e0f2fe", // 1
  "#bae6fd", // 2
  "#7dd3fc", // 3
  "#38bdf8", // 4
  "#0ea5e9", // 5  ← info
  "#0284c7", // 6
  "#0369a1", // 7
  "#075985", // 8
  "#0c4a6e", // 9
];

// Violet — Purple (premium, AI, smart features)
const violet: MantineColorsTuple = [
  "#f5f3ff", // 0
  "#ede9fe", // 1
  "#ddd6fe", // 2
  "#c4b5fd", // 3
  "#a78bfa", // 4
  "#8b5cf6", // 5  ← violet
  "#7c3aed", // 6
  "#6d28d9", // 7
  "#5b21b6", // 8
  "#4c1d95", // 9
];

// Orange — Warm (billing, revenue, engagement)
const orange: MantineColorsTuple = [
  "#fff7ed", // 0
  "#ffedd5", // 1
  "#fed7aa", // 2
  "#fdba74", // 3
  "#fb923c", // 4
  "#f97316", // 5  ← orange
  "#ea580c", // 6
  "#c2410c", // 7
  "#9a3412", // 8
  "#7c2d12", // 9
];

// Teal — Healthcare (clinical, calm, trust)
const teal: MantineColorsTuple = [
  "#f0fdfa", // 0
  "#ccfbf1", // 1
  "#99f6e4", // 2
  "#5eead4", // 3
  "#2dd4bf", // 4
  "#14b8a6", // 5  ← teal
  "#0d9488", // 6
  "#0f766e", // 7
  "#115e59", // 8
  "#134e4a", // 9
];

// Slate — Elevated Neutral (subtle UI, backgrounds, borders)
const slate: MantineColorsTuple = [
  "#f8fafc", // 0
  "#f1f5f9", // 1
  "#e2e8f0", // 2
  "#cbd5e1", // 3
  "#94a3b8", // 4
  "#64748b", // 5  ← slate
  "#475569", // 6
  "#334155", // 7
  "#1e293b", // 8
  "#0f172a", // 9
];

// ── Container Sizes ────────────────────────────────────────────

const CONTAINER_SIZES: Record<string, string> = {
  xxs: rem("200px"),
  xs: rem("300px"),
  sm: rem("400px"),
  md: rem("500px"),
  lg: rem("600px"),
  xl: rem("1400px"),
  xxl: rem("1600px"),
};

// ── Theme ──────────────────────────────────────────────────────

export const theme = createTheme({
  primaryColor: "primary",
  colors: {
    primary,
    success,
    warning,
    danger,
    info,
    violet,
    orange,
    teal,
    slate,
  },

  fontFamily:
    "'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif",
  fontSmoothing: true,

  fontSizes: {
    xs: rem("12px"),
    sm: rem("14px"),
    md: rem("16px"),
    lg: rem("18px"),
    xl: rem("20px"),
  },

  spacing: {
    "3xs": rem("4px"),
    "2xs": rem("8px"),
    xs: rem("10px"),
    sm: rem("12px"),
    md: rem("16px"),
    lg: rem("20px"),
    xl: rem("24px"),
    "2xl": rem("28px"),
    "3xl": rem("32px"),
  },

  defaultRadius: "md",

  radius: {
    xs: rem("4px"),
    sm: rem("6px"),
    md: rem("8px"),
    lg: rem("12px"),
    xl: rem("16px"),
  },

  headings: {
    fontFamily:
      "'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif",
    fontWeight: "600",
    sizes: {
      h1: { fontSize: rem("28px"), lineHeight: "1.2", fontWeight: "700" },
      h2: { fontSize: rem("22px"), lineHeight: "1.25" },
      h3: { fontSize: rem("18px"), lineHeight: "1.3" },
      h4: { fontSize: rem("15px"), lineHeight: "1.35", fontWeight: "500" },
    },
  },

  // Stripe-inspired blue-tinted layered shadows for refined depth
  shadows: {
    xs: "0 1px 2px rgba(50, 50, 93, 0.04), 0 1px 3px rgba(0, 0, 0, 0.03)",
    sm: "0 1px 3px rgba(50, 50, 93, 0.06), 0 4px 8px rgba(0, 0, 0, 0.04)",
    md: "0 2px 8px rgba(50, 50, 93, 0.08), 0 6px 20px rgba(0, 0, 0, 0.05)",
    lg: "0 4px 12px rgba(50, 50, 93, 0.1), 0 12px 32px rgba(0, 0, 0, 0.06)",
    xl: "0 8px 20px rgba(50, 50, 93, 0.12), 0 20px 48px rgba(0, 0, 0, 0.08)",
  },

  components: {
    Container: Container.extend({
      vars: (_, { size, fluid }) => ({
        root: {
          "--container-size": fluid
            ? "100%"
            : size !== undefined && size in CONTAINER_SIZES
              ? CONTAINER_SIZES[size]
              : rem(size),
        },
      }),
    }),

    Paper: Paper.extend({
      defaultProps: {
        p: "md",
        shadow: "sm",
        radius: "lg",
        withBorder: false,
      },
    }),

    Card: Card.extend({
      defaultProps: {
        p: "xl",
        shadow: "sm",
        radius: "lg",
        withBorder: false,
      },
    }),

    Select: Select.extend({
      defaultProps: {
        checkIconPosition: "right",
        radius: "md",
        size: "sm",
        variant: "default",
      },
    }),

    Table: {
      defaultProps: {
        striped: false,
        withTableBorder: false,
        withColumnBorders: false,
        highlightOnHover: true,
        verticalSpacing: 10,
        horizontalSpacing: "sm",
        fz: "sm",
      },
    },

    Modal: {
      defaultProps: {
        centered: true,
        overlayProps: { backgroundOpacity: 0.25, blur: 8 },
        radius: "lg",
        shadow: "xl",
        transitionProps: { duration: 200, transition: "fade" },
      },
    },

    Badge: {
      defaultProps: {
        variant: "light",
        radius: "xl",
        size: "md",
        fw: 600,
      },
    },

    TextInput: {
      defaultProps: {
        radius: "md",
        size: "sm",
        variant: "default",
      },
    },

    PasswordInput: {
      defaultProps: {
        radius: "md",
        size: "sm",
        variant: "default",
      },
    },

    Textarea: {
      defaultProps: {
        radius: "md",
        size: "sm",
        variant: "default",
      },
    },

    NumberInput: {
      defaultProps: {
        radius: "md",
        size: "sm",
        variant: "default",
      },
    },

    Button: {
      defaultProps: {
        radius: "md",
        fw: 600,
      },
    },

    NavLink: {
      defaultProps: {
        variant: "subtle",
      },
    },

    Tabs: {
      defaultProps: {
        variant: "pills",
        radius: "md",
        keepMounted: true,
      },
    },

    ActionIcon: {
      defaultProps: {
        variant: "default",
        radius: "md",
      },
    },

    ThemeIcon: {
      defaultProps: {
        variant: "light",
        radius: "lg",
      },
    },

    Divider: {
      defaultProps: {
        color: "slate.1",
      },
    },

    Loader: Loader.extend({
      defaultProps: {
        loaders: { ...Loader.defaultLoaders, ecg: EcgLoader },
        type: "ecg",
      },
    }),

    Skeleton: {
      defaultProps: {
        radius: "lg",
      },
    },

    Tooltip: {
      defaultProps: {
        withArrow: true,
        radius: "md",
        fz: "xs",
        transitionProps: { duration: 150, transition: "fade" },
      },
    },

    Drawer: {
      defaultProps: {
        shadow: "xl",
        transitionProps: { duration: 300 },
      },
    },

    Menu: {
      defaultProps: {
        radius: "lg",
        shadow: "md",
        transitionProps: { duration: 150, transition: "scale-y" },
      },
    },

    Popover: {
      defaultProps: {
        radius: "lg",
        shadow: "md",
      },
    },

    Alert: {
      defaultProps: {
        radius: "lg",
        variant: "light",
      },
    },

    Accordion: {
      defaultProps: {
        radius: "lg",
      },
    },
  },

  other: {
    style: "soft-modern",
  },
});

// ═══════════════════════════════════════════════════════════════════
// ── CSS Variables Resolver: Semantic Token Layer ──────────────────
// ═══════════════════════════════════════════════════════════════════

export const cssVariableResolver: CSSVariablesResolver = (t) => {
  const p = t.colors.primary ?? primary;
  const s = t.colors.success ?? success;
  const w = t.colors.warning ?? warning;
  const d = t.colors.danger ?? danger;
  const i = t.colors.info ?? info;

  return {
    variables: {
      "--mb-radius": t.radius?.xl ?? rem("16px"),
    },
    light: {
      // ── Surfaces ──
      "--mantine-color-body": "#fafbfc",
      "--mb-bg-content": "#f4f5f7",
      "--mb-sidebar-bg": "#ffffff",
      "--mb-header-bg": "rgba(255, 255, 255, 0.82)",
      "--mb-card-bg": "#ffffff",
      "--mb-input-bg": "#ffffff",

      // ── Borders (blue-tinted, Stripe-inspired) ──
      "--mb-border": "#e3e8ef",
      "--mb-border-subtle": "#eef1f6",

      // ── Text hierarchy (4 levels) ──
      "--mb-text-primary": "#0a0d14",
      "--mb-text-secondary": "#4b5563",
      "--mb-text-muted": "#9ca3af",
      "--mb-text-faint": "#d1d5db",

      // ── Interactive ──
      "--mb-selection-bg": p[1],
      "--mb-focus-ring": p[5],
      "--mb-link": p[5],
      "--mb-link-hover": p[6],

      // ── Semantic status colors (bg / text pairs) ──
      "--mb-success-bg": s[0],
      "--mb-success-text": s[7],
      "--mb-success-accent": s[5],
      "--mb-warning-bg": w[0],
      "--mb-warning-text": w[7],
      "--mb-warning-accent": w[5],
      "--mb-danger-bg": d[0],
      "--mb-danger-text": d[7],
      "--mb-danger-accent": d[5],
      "--mb-info-bg": i[0],
      "--mb-info-text": i[7],
      "--mb-info-accent": i[5],

      // ── Table ──
      "--mb-table-header-bg": "#f8f9fb",
      "--mb-table-hover": "#f4f5f7",
      "--mb-table-border": "#e3e8ef",

      // ── Shimmer ──
      "--mb-shimmer-from": "#f4f5f7",
      "--mb-shimmer-mid": "#e3e8ef",

      // ── Shadows (blue-tinted) ──
      "--mb-float-shadow":
        "0 1px 3px rgba(50,50,93,0.06), 0 4px 8px rgba(0,0,0,0.04)",

      // ── Clinical status (high-visibility for patient safety) ──
      "--mb-critical-bg": "#fef2f2",
      "--mb-critical-text": "#991b1b",
      "--mb-critical-border": "#fecaca",
      "--mb-abnormal-bg": "#fffbeb",
      "--mb-abnormal-text": "#854d0e",
      "--mb-abnormal-border": "#fde68a",
      "--mb-normal-bg": "#ecfdf5",
      "--mb-normal-text": "#14532d",
      "--mb-normal-border": "#a7f3d0",
    },
    dark: {
      "--mantine-color-body": "#0a0a0c",
      "--mb-bg-content": "#111114",
      "--mb-sidebar-bg": "#111114",
      "--mb-header-bg": "rgba(17, 17, 20, 0.82)",
      "--mb-card-bg": "#191a1e",
      "--mb-input-bg": "#191a1e",

      "--mb-border": "#28292e",
      "--mb-border-subtle": "#1e1f24",

      "--mb-text-primary": "#f0f1f3",
      "--mb-text-secondary": "#a0a4ab",
      "--mb-text-muted": "#6b7078",
      "--mb-text-faint": "#3a3d44",

      "--mb-selection-bg": p[8],
      "--mb-focus-ring": p[4],
      "--mb-link": p[4],
      "--mb-link-hover": p[3],

      "--mb-success-bg": "#052e16",
      "--mb-success-text": s[2],
      "--mb-success-accent": s[4],
      "--mb-warning-bg": "#422006",
      "--mb-warning-text": w[2],
      "--mb-warning-accent": w[4],
      "--mb-danger-bg": "#450a0a",
      "--mb-danger-text": d[2],
      "--mb-danger-accent": d[4],
      "--mb-info-bg": "#0c4a6e",
      "--mb-info-text": i[2],
      "--mb-info-accent": i[4],

      "--mb-table-header-bg": "#15161a",
      "--mb-table-hover": "#1e1f24",
      "--mb-table-border": "#28292e",

      "--mb-shimmer-from": "#1e1f24",
      "--mb-shimmer-mid": "#28292e",

      "--mb-float-shadow":
        "0 1px 3px rgba(0,0,0,0.3), 0 4px 12px rgba(0,0,0,0.25)",

      // ── Clinical status (dark mode — high-visibility) ──
      "--mb-critical-bg": "#450a0a",
      "--mb-critical-text": "#fecaca",
      "--mb-critical-border": "#7f1d1d",
      "--mb-abnormal-bg": "#422006",
      "--mb-abnormal-text": "#fde68a",
      "--mb-abnormal-border": "#854d0e",
      "--mb-normal-bg": "#052e16",
      "--mb-normal-text": "#a7f3d0",
      "--mb-normal-border": "#14532d",
    },
  };
};
