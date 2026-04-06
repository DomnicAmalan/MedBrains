import { forwardRef } from "react";
import type { MantineLoaderComponent } from "@mantine/core";
import styles from "./EcgLoader.module.scss";

/**
 * Custom Mantine Loader: ECG heartbeat pulse with indigo-teal gradient
 * and mask-based sweep animation (authentic monitor reveal effect).
 */
export const EcgLoader: MantineLoaderComponent = forwardRef(
  ({ style, ...others }, ref) => {
    return (
      <svg
        ref={ref}
        className={styles.ecgLoader}
        viewBox="0 0 120 24"
        fill="none"
        style={{
          width: "var(--loader-size)",
          height: "calc(var(--loader-size) * 0.4)",
          ...style,
        }}
        {...others}
      >
        <defs>
          <linearGradient id="ecgGrad" x1="0%" y1="0%" x2="100%" y2="0%">
            <stop offset="0%" stopColor="var(--mantine-color-indigo-5, #6366f1)" />
            <stop offset="100%" stopColor="var(--mantine-color-teal-5, #0d9488)" />
          </linearGradient>
          <mask id="ecgSweepMask">
            <rect className={styles.sweepRect} x="0" y="0" width="0" height="24" fill="white" />
          </mask>
        </defs>
        <polyline
          className={styles.trace}
          stroke="url(#ecgGrad)"
          strokeWidth="2.5"
          strokeLinecap="round"
          strokeLinejoin="round"
          mask="url(#ecgSweepMask)"
          points="
            0,12  8,12  14,12
            18,10  22,8  26,10  28,12
            32,14  34,18  36,3  38,21  40,8  42,12
            48,12  52,10  56,8  60,10  63,12
            70,12  78,12
            82,10  86,8  90,10  92,12
            95,14  97,18  99,3  101,21  103,8  105,12
            110,12  114,10  118,8  120,10
          "
        />
      </svg>
    );
  },
);

EcgLoader.displayName = "EcgLoader";
