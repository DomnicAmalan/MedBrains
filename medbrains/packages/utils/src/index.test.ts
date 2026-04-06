import { describe, expect, it } from "vitest";
import { capitalize, snakeToTitle, truncate } from "./index";

describe("capitalize", () => {
  it("capitalizes the first letter", () => {
    expect(capitalize("hello")).toBe("Hello");
  });

  it("returns empty string unchanged", () => {
    expect(capitalize("")).toBe("");
  });

  it("leaves already-capitalized strings unchanged", () => {
    expect(capitalize("World")).toBe("World");
  });
});

describe("snakeToTitle", () => {
  it("converts snake_case to Title Case", () => {
    expect(snakeToTitle("patient_management")).toBe("Patient Management");
  });

  it("handles single word", () => {
    expect(snakeToTitle("dashboard")).toBe("Dashboard");
  });

  it("handles multiple underscores", () => {
    expect(snakeToTitle("out_patient_department")).toBe("Out Patient Department");
  });
});

describe("truncate", () => {
  it("returns short strings unchanged", () => {
    expect(truncate("hello", 10)).toBe("hello");
  });

  it("truncates long strings with ellipsis", () => {
    expect(truncate("hello world", 6)).toBe("hello\u2026");
  });
});
