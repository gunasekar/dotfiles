# Node.js Development Tools

JavaScript/TypeScript development tools. **Not managed in dotfiles** - install per-project or globally.

## Why Not in Dotfiles?

Node.js tools are:
- **Version-sensitive** - Different projects need different versions
- **Project-specific** - Best managed via `package.json`
- **Ecosystem-specific** - npm/yarn/pnpm handle versioning

## Per-Project Installation (Recommended)

```bash
# Add to package.json
npm install --save-dev eslint eslint_d prettier typescript

# Or with yarn
yarn add -D eslint eslint_d prettier typescript
```

## Global Tools (Optional)

For quick scripts and one-off tasks:

```bash
npm install -g \
  eslint_d \
  jsonlint \
  prettier \
  typescript \
  ts-node \
  @biomejs/biome
```

## Neovim Integration

The nvim configuration expects these linters:

| Language | Linter | Installation |
|----------|--------|--------------|
| JavaScript/TypeScript | eslint_d | Per-project (npm) |
| JSON | jsonlint | Global or per-project |

See: `nvim/.config/nvim/lua/plugins/lint.lua`

## Common Project Setup

```bash
# Initialize project
npm init -y

# Add dev tools
npm install --save-dev \
  eslint \
  eslint_d \
  prettier \
  @typescript-eslint/parser \
  @typescript-eslint/eslint-plugin

# Create .eslintrc.js
npx eslint --init

# Create .prettierrc
echo '{"semi": true, "singleQuote": true}' > .prettierrc
```

## Version Management

Use `.nvmrc` for Node.js version:

```bash
# Create .nvmrc
node -v > .nvmrc

# Use specified version
nvm use
```

## Formatters & Linters

### ESLint (Linting)
```bash
# Per-project
npm install --save-dev eslint eslint_d

# Config
npx eslint --init
```

### Prettier (Formatting)
```bash
# Per-project
npm install --save-dev prettier

# Run
npx prettier --write .
```

### TypeScript
```bash
# Per-project
npm install --save-dev typescript @types/node

# Initialize
npx tsc --init
```
