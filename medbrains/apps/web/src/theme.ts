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
// ── MedBrains Design System: Modern Semantic Color Palette ───────
// ═══════════════════════════════════════════════════════════════════
//
// Inspired by: Linear, Vercel Geist, Stripe
// Philosophy: purpose-driven colors, not just "a blue and some grays"
//
// COLOR ROLES:
//   primary   — brand / interactive (indigo-violet, sophisticated)
//   success   — positive states, healthy, active, completed
//   warning   — attention needed, pending, in-progress
//   danger    — errors, destructive actions, critical alerts
//   info      — informational, neutral-blue for data display
//   violet    — premium features, AI/smart actions
//   orange    — warm accent, billing, revenue, highlights
//   teal      — clinical, healthcare-specific, calm trust
//   slate     — elevated neutral for subtle UI elements
// ═══════════════════════════════════════════════════════════════════

// Brand — Indigo Violet (sophisticated, modern, not generic blue)
const primary: MantineColorsTuple = [
  "#f0f0ff", // 0  ghost
  "#e0e0ff", // 1  dimmed
  "#c7c7ff", // 2  subtle
  "#a5a5ff", // 3  medium
  "#8b8bf5", // 4  strong
  "#6366f1", // 5  accent      ← PRIMARY (Stripe-like indigo)
  "#5558e3", // 6  hover
  "#4547d0", // 7  pressed
  "#3538a8", // 8  deep
  "#252780", // 9  abyss
];

// Success — Emerald (growth, healthy, completed, active)
const success: MantineColorsTuple = [
  "#ecfdf5", // 0
  "#d1fae5", // 1
  "#a7f3d0", // 2
  "#6ee7b7", // 3
  "#34d399", // 4
  "#10b981", // 5  ← success
  "#059669", // 6
  "#047857", // 7
  "#065f46", // 8
  "#064e3b", // 9
];

// Warning — Amber (attention, pending, caution)
const warning: MantineColorsTuple = [
  "#fffbeb", // 0
  "#fef3c7", // 1
  "#fde68a", // 2
  "#fcd34d", // 3
  "#fbbf24", // 4
  "#f59e0b", // 5  ← warning
  "#d97706", // 6
  "#b45309", // 7
  "#92400e", // 8
  "#78350f", // 9
];

// Danger — Rose (errors, destructive, critical)
const danger: MantineColorsTuple = [
  "#fff1f2", // 0
  "#ffe4e6", // 1
  "#fecdd3", // 2
  "#fda4af", // 3
  "#fb7185", // 4
  "#f43f5e", // 5  ← danger
  "#e11d48", // 6
  "#be123c", // 7
  "#9f1239", // 8
  "#881337", // 9
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
      h1: { fontSize: rem("28px"), lineHeight: "1.2" },
      h2: { fontSize: rem("22px"), lineHeight: "1.25" },
      h3: { fontSize: rem("18px"), lineHeight: "1.3" },
      h4: { fontSize: rem("15px"), lineHeight: "1.35" },
    },
  },

  // Soft floating shadows — layered for realistic depth
  shadows: {
    xs: "0 1px 2px rgba(0, 0, 0, 0.03), 0 1px 3px rgba(0, 0, 0, 0.04)",
    sm: "0 1px 3px rgba(0, 0, 0, 0.04), 0 4px 8px rgba(0, 0, 0, 0.04)",
    md: "0 2px 4px rgba(0, 0, 0, 0.03), 0 8px 20px rgba(0, 0, 0, 0.06)",
    lg: "0 4px 8px rgba(0, 0, 0, 0.03), 0 12px 32px rgba(0, 0, 0, 0.08)",
    xl: "0 8px 16px rgba(0, 0, 0, 0.04), 0 20px 48px rgba(0, 0, 0, 0.1)",
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
      "--mantine-color-body": "#fafafa",
      "--mb-bg-content": "#f4f4f5",
      "--mb-sidebar-bg": "#ffffff",
      "--mb-header-bg": "rgba(255, 255, 255, 0.85)",
      "--mb-card-bg": "#ffffff",
      "--mb-input-bg": "#ffffff",

      // ── Borders ──
      "--mb-border": "#e4e4e7",
      "--mb-border-subtle": "#f0f0f2",

      // ── Text hierarchy (4 levels) ──
      "--mb-text-primary": "#09090b",
      "--mb-text-secondary": "#52525b",
      "--mb-text-muted": "#a1a1aa",
      "--mb-text-faint": "#d4d4d8",

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
      "--mb-table-header-bg": "#fafafa",
      "--mb-table-hover": "#f4f4f5",
      "--mb-table-border": "#e4e4e7",

      // ── Shimmer ──
      "--mb-shimmer-from": "#f4f4f5",
      "--mb-shimmer-mid": "#e4e4e7",

      // ── Shadows ──
      "--mb-float-shadow": "0 1px 3px rgba(0,0,0,0.04), 0 4px 8px rgba(0,0,0,0.04)",
    },
    dark: {
      "--mantine-color-body": "#09090b",
      "--mb-bg-content": "#18181b",
      "--mb-sidebar-bg": "#18181b",
      "--mb-header-bg": "rgba(24, 24, 27, 0.85)",
      "--mb-card-bg": "#1c1c20",
      "--mb-input-bg": "#1c1c20",

      "--mb-border": "#27272a",
      "--mb-border-subtle": "#1f1f23",

      "--mb-text-primary": "#fafafa",
      "--mb-text-secondary": "#a1a1aa",
      "--mb-text-muted": "#71717a",
      "--mb-text-faint": "#3f3f46",

      "--mb-selection-bg": p[8],
      "--mb-focus-ring": p[4],
      "--mb-link": p[4],
      "--mb-link-hover": p[3],

      "--mb-success-bg": "#052e16",
      "--mb-success-text": s[3],
      "--mb-success-accent": s[4],
      "--mb-warning-bg": "#451a03",
      "--mb-warning-text": w[3],
      "--mb-warning-accent": w[4],
      "--mb-danger-bg": "#4c0519",
      "--mb-danger-text": d[3],
      "--mb-danger-accent": d[4],
      "--mb-info-bg": "#0c4a6e",
      "--mb-info-text": i[3],
      "--mb-info-accent": i[4],

      "--mb-table-header-bg": "#1c1c20",
      "--mb-table-hover": "#1f1f23",
      "--mb-table-border": "#27272a",

      "--mb-shimmer-from": "#1f1f23",
      "--mb-shimmer-mid": "#27272a",

      "--mb-float-shadow": "0 1px 3px rgba(0,0,0,0.2), 0 4px 8px rgba(0,0,0,0.2)",
    },
  };
};
