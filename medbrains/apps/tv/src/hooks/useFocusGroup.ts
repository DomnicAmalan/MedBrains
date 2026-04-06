import { useCallback, useRef, useState } from "react";
import type { View } from "react-native";

/**
 * Manages D-pad focus for a group of focusable elements on Android TV.
 * Returns the currently focused index and refs to attach to each focusable view.
 */
export function useFocusGroup(itemCount: number) {
  const [focusedIndex, setFocusedIndex] = useState(0);
  const refs = useRef<(View | null)[]>([]);

  const setRef = useCallback(
    (index: number) => (el: View | null) => {
      refs.current[index] = el;
    },
    [],
  );

  const onFocus = useCallback(
    (index: number) => () => {
      setFocusedIndex(index);
    },
    [],
  );

  const focusItem = useCallback(
    (index: number) => {
      const clamped = Math.max(0, Math.min(index, itemCount - 1));
      refs.current[clamped]?.setNativeProps?.({ hasTVPreferredFocus: true });
      setFocusedIndex(clamped);
    },
    [itemCount],
  );

  return { focusedIndex, setRef, onFocus, focusItem };
}
