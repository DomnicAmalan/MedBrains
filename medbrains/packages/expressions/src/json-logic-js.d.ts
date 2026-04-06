declare module "json-logic-js" {
  export type RulesLogic = Record<string, unknown> | boolean | string | number | null;
  export function apply(logic: RulesLogic, data?: Record<string, unknown>): unknown;
  export function add_operation(name: string, fn: (...args: unknown[]) => unknown): void;
  export function rm_operation(name: string): void;

  const jsonLogic: {
    apply: typeof apply;
    add_operation: typeof add_operation;
    rm_operation: typeof rm_operation;
  };

  export default jsonLogic;
}
