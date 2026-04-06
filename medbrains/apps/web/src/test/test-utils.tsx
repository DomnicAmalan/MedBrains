import { MantineProvider } from "@mantine/core";
import { render, type RenderOptions } from "@testing-library/react";
import type { ReactElement, ReactNode } from "react";
import { theme, cssVariableResolver } from "../theme";

function Providers({ children }: { children: ReactNode }) {
  return (
    <MantineProvider theme={theme} defaultColorScheme="light" cssVariablesResolver={cssVariableResolver}>
      {children}
    </MantineProvider>
  );
}

function customRender(ui: ReactElement, options?: Omit<RenderOptions, "wrapper">) {
  return render(ui, { wrapper: Providers, ...options });
}

export { customRender as render };
export { screen, within, waitFor } from "@testing-library/react";
export { default as userEvent } from "@testing-library/user-event";
