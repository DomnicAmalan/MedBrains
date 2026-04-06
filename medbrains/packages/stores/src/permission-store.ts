import { create } from "zustand";
import type { FieldAccessLevel } from "@medbrains/types";

/** Bypass roles — these skip all permission checks */
const BYPASS_ROLES = new Set(["super_admin", "hospital_admin"]);

interface PermissionState {
  userPermissions: Set<string>;
  userRole: string | null;
  fieldAccess: Record<string, FieldAccessLevel>;
  setPermissions: (
    role: string,
    permissions: string[],
    fieldAccess?: Record<string, FieldAccessLevel>,
  ) => void;
  clearPermissions: () => void;
  hasPermission: (code: string) => boolean;
  hasAllPermissions: (codes: string[]) => boolean;
  hasAnyPermission: (codes: string[]) => boolean;
  getFieldAccess: (moduleFieldCode: string) => FieldAccessLevel;
}

export const usePermissionStore = create<PermissionState>()((set, get) => ({
  userPermissions: new Set<string>(),
  userRole: null,
  fieldAccess: {},

  setPermissions: (role, permissions, fieldAccess) =>
    set({
      userRole: role,
      userPermissions: new Set(permissions),
      fieldAccess: fieldAccess ?? {},
    }),

  clearPermissions: () =>
    set({ userRole: null, userPermissions: new Set(), fieldAccess: {} }),

  hasPermission: (code) => {
    const { userRole, userPermissions } = get();
    if (userRole && BYPASS_ROLES.has(userRole)) return true;
    return userPermissions.has(code);
  },

  hasAllPermissions: (codes) => {
    const { userRole, userPermissions } = get();
    if (userRole && BYPASS_ROLES.has(userRole)) return true;
    return codes.every((c) => userPermissions.has(c));
  },

  hasAnyPermission: (codes) => {
    const { userRole, userPermissions } = get();
    if (userRole && BYPASS_ROLES.has(userRole)) return true;
    return codes.some((c) => userPermissions.has(c));
  },

  getFieldAccess: (moduleFieldCode) => {
    const { userRole, fieldAccess } = get();
    // Bypass roles always get edit
    if (userRole && BYPASS_ROLES.has(userRole)) return "edit";
    return fieldAccess[moduleFieldCode] ?? "edit";
  },
}));
