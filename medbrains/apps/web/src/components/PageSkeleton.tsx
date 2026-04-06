import { Center } from "@mantine/core";
import styles from "./PageSkeleton.module.scss";

// Anatomically accurate PQRST waveform × 2 beats
const ECG_POINTS = [
  // lead-in flat
  "0,20", "10,20", "20,20",
  // P wave
  "26,18", "32,14", "38,18", "42,20",
  // QRS complex
  "46,22", "49,28", "52,2", "55,38", "58,14", "61,20",
  // T wave
  "68,20", "74,17", "80,14", "86,17", "90,20",
  // flat between beats
  "100,20", "110,20",
  // second P wave
  "116,18", "122,14", "128,18", "132,20",
  // second QRS
  "136,22", "139,28", "142,2", "145,38", "148,14", "151,20",
  // second T wave
  "158,20", "164,17", "170,14", "176,17", "180,20",
  // flat tail
  "190,20", "200,20",
].join(" ");

export function PageSkeleton() {
  return (
    <Center h="100vh" className={styles.wrapper}>
      <div className={styles.container}>
        <svg
          className={styles.ecg}
          viewBox="0 0 200 40"
          fill="none"
        >
          <defs>
            <linearGradient id="pageSkelGrad" x1="0%" y1="0%" x2="100%" y2="0%">
              <stop offset="0%" stopColor="var(--mantine-color-indigo-5, #6366f1)" />
              <stop offset="100%" stopColor="var(--mantine-color-teal-5, #0d9488)" />
            </linearGradient>
            <linearGradient id="pageSkelGradFaint" x1="0%" y1="0%" x2="100%" y2="0%">
              <stop offset="0%" stopColor="var(--mantine-color-indigo-3, #a5b4fc)" />
              <stop offset="100%" stopColor="var(--mantine-color-teal-3, #5eead4)" />
            </linearGradient>
            <mask id="pageSkelMask">
              <rect className={styles.sweepRect} x="0" y="0" width="0" height="40" fill="white" />
            </mask>
          </defs>
          {/* Faint shadow trace (always visible, slight offset) */}
          <polyline
            className={styles.shadowLine}
            stroke="url(#pageSkelGradFaint)"
            strokeWidth="2"
            strokeLinecap="round"
            strokeLinejoin="round"
            points={ECG_POINTS}
          />
          {/* Main trace with mask sweep */}
          <polyline
            className={styles.mainLine}
            stroke="url(#pageSkelGrad)"
            strokeWidth="2.5"
            strokeLinecap="round"
            strokeLinejoin="round"
            mask="url(#pageSkelMask)"
            points={ECG_POINTS}
          />
        </svg>
        <span className={styles.text}>MedBrains</span>
      </div>
    </Center>
  );
}
