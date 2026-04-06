/**
 * MedBrains Expression Language (MBX)
 *
 * A sandboxed expression engine with three tiers:
 *   Tier 1: mbx:template — Print templates & display text (Handlebars)
 *   Tier 2: mbx:expr     — Computed fields & formulas (expr-eval)
 *   Tier 3: mbx:logic    — Conditions, visibility rules (JSON Logic)
 *
 * Security guarantees:
 *   - No eval(), no Function constructor
 *   - Whitelisted functions only
 *   - Frozen, proxy-wrapped contexts
 *   - AST size limits (max 100 nodes)
 *   - No prototype access, no global access
 *   - HTML-escaping by default in templates
 *   - Read-only data, no side effects
 */

// Tier 1: Templates
export { compileTemplate, renderTemplate, validateTemplate } from "./template.js";

// Tier 2: Computed Fields
export { evaluateComputed, validateComputed, extractVariables } from "./computed.js";

// Tier 3: Logic / Conditions
export {
  evaluateLogic,
  validateLogic,
  evaluateFieldCondition,
  fieldConditionToJsonLogic,
} from "./logic.js";

// Sandbox utilities
export {
  createSandboxedContext,
  resolveContextPath,
  validateExpressionString,
  validateTemplateString,
  validateJsonLogicRule,
} from "./sandbox.js";

// Function registry
export {
  FUNCTION_REGISTRY,
  getFunctionMap,
  getFunctionsByCategory,
  isFunctionRegistered,
} from "./functions.js";

// Types
export type {
  SafeFunction,
  FunctionCategory,
  FunctionMeta,
  FunctionParam,
  ValidationResult,
  EvaluationResult,
  ExpressionContext,
  TemplateOptions,
  CompiledTemplate,
  ComputedOptions,
  JsonLogicRule,
  JsonLogicData,
  ExpressionTier,
  MbxErrorCode,
} from "./types.js";

export { MbxError, BLOCKED_KEYS, MAX_AST_NODES, MAX_DEPTH, MAX_EVAL_MS } from "./types.js";
