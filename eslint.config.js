import js from "@eslint/js";
import globals from "globals";
import tseslint from "typescript-eslint";

export default tseslint.config(
  {
    ignores: ["**/node_modules/**", "**/dist/**", "docs/**"],
  },
  js.configs.recommended,
  ...tseslint.configs.recommended,
  {
    files: ["**/*.ts"],
    languageOptions: {
      globals: { ...globals.node },
    },
    rules: {
      "@typescript-eslint/consistent-type-imports": [
        "error",
        { prefer: "type-imports", fixStyle: "inline-type-imports" },
      ],
    },
  },
  {
    files: ["packages/domain-*/**/*.ts"],
    rules: {
      "no-restricted-imports": [
        "error",
        {
          paths: [
            {
              name: "manifold",
              message: "I2/NFR-015: domain packages must not import manifold",
            },
            {
              name: "manifold-3d",
              message: "I2/NFR-015: domain packages must not import manifold-3d",
            },
            {
              name: "three",
              message: "I2: domain packages must not import three",
            },
            {
              name: "godot",
              message: "I2: domain packages must not import godot",
            },
          ],
          patterns: [
            {
              group: ["**/manifold*", "**/three*", "**/godot*"],
              message:
                "I2/NFR-015: domain packages must not import manifold / three / godot",
            },
          ],
        },
      ],
    },
  },
);
