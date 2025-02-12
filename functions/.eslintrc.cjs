// /Users/gtai/gnt/p3/sweetpad/tiktok/functions/.eslintrc.cjs
module.exports = {
  root: true,
  env: {
    es2020: true, // Use es2020, and match tsconfig.json target if you change it
    node: true,
  },
  extends: [
    "eslint:recommended",
    "plugin:@typescript-eslint/recommended", // Add this line
    "google",
  ],
  parser: "@typescript-eslint/parser",  // Add this line
  plugins: [
    "@typescript-eslint", // Add this
  ],
  parserOptions: {
    ecmaVersion: 2020, // Keep this consistent with your tsconfig.json target
    sourceType: "module", // Add this back for your SOURCE files.
    project: ['./tsconfig.json'], //  Add this line VERY IMPORTANT
  },
  rules: {
    "quotes": ["error", "double"],
    "object-curly-spacing": ["error", "always"],
    "indent": ["error", 2],
    "no-unused-vars": ["warn"],
    "@typescript-eslint/no-unused-vars": ["warn"], // Add this line,
    "max-len": ["error", { "code": 120 }]
  },
  ignorePatterns: [ // Add this to prevent linting of compiled files
      "/lib/**/*"
  ]
};