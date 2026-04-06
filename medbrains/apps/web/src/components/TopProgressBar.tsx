import { useEffect, useRef, useState } from "react";
import { useLocation } from "react-router";
import styles from "./TopProgressBar.module.scss";

// Smoother vital-signs blip waveform (sine + sharp peaks)
const WAVE_POINTS = [
  // lead-in flat
  "0,12", "10,12", "18,12",
  // gentle P bump
  "22,10", "26,8", "30,10", "32,12",
  // sharp QRS spike
  "35,14", "37,18", "39,2", "41,22", "43,8", "45,12",
  // T recovery
  "50,12", "54,10", "58,8", "62,10", "65,12",
  // flat gap
  "72,12", "80,12",
  // second P bump
  "84,10", "88,8", "92,10", "94,12",
  // second QRS
  "97,14", "99,18", "101,2", "103,22", "105,8", "107,12",
  // second T recovery
  "112,12", "116,10", "120,8", "124,10", "127,12",
  // flat tail
  "132,12", "140,12",
].join(" ");

export function TopProgressBar() {
  const location = useLocation();
  const [visible, setVisible] = useState(false);
  const timers = useRef<ReturnType<typeof setTimeout>[]>([]);

  useEffect(() => {
    for (const t of timers.current) clearTimeout(t);
    timers.current = [];

    setVisible(true);

    timers.current.push(
      setTimeout(() => setVisible(false), 1600),
    );

    return () => {
      for (const t of timers.current) clearTimeout(t);
    };
  }, [location.pathname]);

  if (!visible) return null;

  return (
    <div className={styles.track}>
      <div className={styles.baseline} />
      <div className={styles.pulseContainer}>
        <svg
          className={styles.heartbeat}
          viewBox="0 0 140 24"
          preserveAspectRatio="none"
          fill="none"
        >
          <defs>
            <linearGradient id="topBarGrad" x1="0%" y1="0%" x2="100%" y2="0%">
              <stop offset="0%" stopColor="var(--mantine-color-indigo-5, #6366f1)" />
              <stop offset="100%" stopColor="var(--mantine-color-teal-5, #0d9488)" />
            </linearGradient>
          </defs>
          <polyline
            className={styles.ecgLine}
            stroke="url(#topBarGrad)"
            strokeWidth="2.5"
            strokeLinecap="round"
            strokeLinejoin="round"
            points={WAVE_POINTS}
          />
        </svg>
      </div>
    </div>
  );
}
