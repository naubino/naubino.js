# Naubino

- This is a CoffeeScript project built for the browser with Deno.
- Use Deno tasks for project commands. Do not use npm or npx.
- Avoid comments. Add them only when absolutely necessary to explain non-obvious behavior.
- Run `deno task check` to validate CoffeeScript syntax without bundling.
- Run `deno task build` when a change needs full bundle validation.
- Run `deno task lint` to run the CoffeeLint linter.
- Run `deno task test` for the regression tests.
- Writing and modifying tests is allowed. Prefer repeatable tests in files over inline shell test harnesses.
- Discuss designs and contracts in TypeScript interface terms. The codebase will move to TypeScript later.
- `doc/types.d.ts` holds shadow types for the target architecture. CoffeeScript objects and classes should match those shapes. Plain object literals are fine if their shape is named there. Update it when a contract changes. It is not compiled or imported.
- Use object shorthand when key and value share a name: `{value}`, not `{value: value}`.
