-- LSP Configuration
return {
  -- Mason: LSP installer
  {
    "williamboman/mason.nvim",
    config = function()
      require("mason").setup({
        ui = {
          icons = {
            package_installed = "✓",
            package_pending = "➜",
            package_uninstalled = "✗"
          }
        },
        -- Reduce network errors on startup
        registries = {
          "github:mason-org/mason-registry",
        },
        -- Don't auto-check for updates on startup
        max_concurrent_installers = 4,
      })
    end
  },

  -- Mason-LSPConfig: Bridge between mason and lspconfig
  {
    "williamboman/mason-lspconfig.nvim",
    dependencies = { "williamboman/mason.nvim" },
    config = function()
      require("mason-lspconfig").setup({
        ensure_installed = {
          "lua_ls",        -- Lua
          "ts_ls",         -- TypeScript/JavaScript
          "pyright",       -- Python
          "gopls",         -- Go
          "rust_analyzer", -- Rust
          "bashls",        -- Bash
          "jsonls",        -- JSON
          "yamlls",        -- YAML
          "jdtls",         -- Java
          "terraformls",   -- Terraform/HCL
          "sqlls",         -- SQL
          "dockerls",      -- Dockerfile
          "docker_compose_language_service", -- Docker Compose
          "graphql",       -- GraphQL
          "lemminx",       -- XML
        },
        automatic_installation = true,
      })
    end
  },

  -- LSPConfig: Configure LSP servers
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      "williamboman/mason-lspconfig.nvim",
    },
    config = function()
      -- Use default LSP capabilities (blink.cmp handles completion)
      local capabilities = vim.lsp.protocol.make_client_capabilities()

      -- Keymaps on LSP attach
      local on_attach = function(client, bufnr)
        local opts = { buffer = bufnr, silent = true }

        vim.keymap.set("n", "gD", vim.lsp.buf.declaration, vim.tbl_extend("force", opts, { desc = "Go to declaration" }))
        vim.keymap.set("n", "gd", vim.lsp.buf.definition, vim.tbl_extend("force", opts, { desc = "Go to definition" }))
        vim.keymap.set("n", "K", vim.lsp.buf.hover, vim.tbl_extend("force", opts, { desc = "Show hover" }))
        vim.keymap.set("n", "gi", vim.lsp.buf.implementation, vim.tbl_extend("force", opts, { desc = "Go to implementation" }))
        vim.keymap.set("n", "gK", vim.lsp.buf.signature_help, vim.tbl_extend("force", opts, { desc = "Signature help" }))
        vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, vim.tbl_extend("force", opts, { desc = "Rename" }))
        vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, vim.tbl_extend("force", opts, { desc = "Code action" }))
        vim.keymap.set("n", "gr", vim.lsp.buf.references, vim.tbl_extend("force", opts, { desc = "References" }))
      end

      -- Configure servers using vim.lsp.config
      local servers = {
        lua_ls = {
          cmd = { "lua-language-server" },
          filetypes = { "lua" },
          root_markers = { ".luarc.json", ".luarc.jsonc", ".luacheckrc", ".stylua.toml", "stylua.toml", "selene.toml", "selene.yml", ".git" },
          settings = {
            Lua = {
              diagnostics = {
                globals = { "vim" }
              },
              workspace = {
                library = vim.api.nvim_get_runtime_file("", true),
                checkThirdParty = false,
              },
              telemetry = {
                enable = false,
              },
            },
          },
        },
        ts_ls = {
          cmd = { "typescript-language-server", "--stdio" },
          filetypes = { "javascript", "javascriptreact", "javascript.jsx", "typescript", "typescriptreact", "typescript.tsx" },
          root_markers = { "package.json", "tsconfig.json", "jsconfig.json", ".git" },
        },
        pyright = {
          cmd = { "pyright-langserver", "--stdio" },
          filetypes = { "python" },
          root_markers = { "pyproject.toml", "setup.py", "setup.cfg", "requirements.txt", "Pipfile", ".git" },
        },
        gopls = {
          cmd = { "gopls" },
          filetypes = { "go", "gomod", "gowork", "gotmpl" },
          root_markers = { "go.work", "go.mod", ".git" },
        },
        rust_analyzer = {
          cmd = { "rust-analyzer" },
          filetypes = { "rust" },
          root_markers = { "Cargo.toml", "rust-project.json" },
        },
        bashls = {
          cmd = { "bash-language-server", "start" },
          filetypes = { "sh" },
          root_markers = { ".git" },
        },
        jsonls = {
          cmd = { "vscode-json-language-server", "--stdio" },
          filetypes = { "json", "jsonc" },
          root_markers = { ".git" },
        },
        yamlls = {
          cmd = { "yaml-language-server", "--stdio" },
          filetypes = { "yaml", "yaml.docker-compose" },
          root_markers = { ".git" },
          settings = {
            yaml = {
              schemas = {
                ["https://raw.githubusercontent.com/awslabs/goformation/master/schema/cloudformation.schema.json"] = {
                  "/*template.yaml",
                  "/*template.yml",
                  "/cloudformation/*.yaml",
                  "/cloudformation/*.yml",
                },
                ["https://raw.githubusercontent.com/aws/serverless-application-model/main/samtranslator/validator/sam_schema/schema.json"] = {
                  "/*sam.yaml",
                  "/*sam.yml",
                  "/sam-template.yaml",
                  "/sam-template.yml",
                },
              },
              format = {
                enable = true,
              },
              validate = true,
              completion = true,
              hover = true,
              -- CloudFormation custom tags (all intrinsic functions)
              customTags = {
                -- Basic intrinsic functions
                "!Base64",
                "!Cidr",
                "!FindInMap sequence",
                "!GetAtt",
                "!GetAZs",
                "!ImportValue",
                "!Join sequence",
                "!Length",
                "!Select sequence",
                "!Split sequence",
                "!Sub",
                "!ToJsonString",
                "!Transform",
                "!Ref",
                -- Condition functions
                "!And",
                "!Equals sequence",
                "!If sequence",
                "!Not sequence",
                "!Or sequence",
                "!Condition",
                -- ForEach (newer function)
                "!ForEach",
              },
            },
          },
        },
        jdtls = {
          cmd = { "jdtls" },
          filetypes = { "java" },
          root_markers = {
            ".git",
            "mvnw",
            "gradlew",
            "pom.xml",
            "build.gradle",
          },
          settings = {
            java = {
              signatureHelp = { enabled = true },
              contentProvider = { preferred = "fernflower" },
              completion = {
                favoriteStaticMembers = {
                  "org.junit.jupiter.api.Assertions.*",
                  "org.junit.Assert.*",
                  "org.mockito.Mockito.*",
                },
              },
              sources = {
                organizeImports = {
                  starThreshold = 9999,
                  staticStarThreshold = 9999,
                },
              },
              codeGeneration = {
                toString = {
                  template = "${object.className}{${member.name()}=${member.value}, ${otherMembers}}",
                },
                useBlocks = true,
              },
            },
          },
        },
        terraformls = {
          cmd = { "terraform-ls", "serve" },
          filetypes = { "terraform", "tf", "hcl" },
          root_markers = { ".terraform", ".git" },
          settings = {
            terraform = {
              validation = {
                enableEnhancedValidation = true,
              },
            },
          },
        },
        sqlls = {
          cmd = { "sql-language-server", "up", "--method", "stdio" },
          filetypes = { "sql", "mysql" },
          root_markers = { ".git" },
        },
        dockerls = {
          cmd = { "docker-langserver", "--stdio" },
          filetypes = { "dockerfile" },
          root_markers = { "Dockerfile", ".git" },
        },
        docker_compose_language_service = {
          cmd = { "docker-compose-langserver", "--stdio" },
          filetypes = { "yaml.docker-compose" },
          root_markers = { "docker-compose.yaml", "docker-compose.yml", "compose.yaml", "compose.yml" },
        },
        graphql = {
          cmd = { "graphql-lsp", "server", "-m", "stream" },
          filetypes = { "graphql", "typescriptreact", "javascriptreact" },
          root_markers = { ".graphqlrc", ".graphql.config.js", "graphql.config.js", ".git" },
        },
        lemminx = {
          cmd = { "lemminx" },
          filetypes = { "xml", "xsd", "xsl", "xslt", "svg" },
          root_markers = { ".git" },
          settings = {
            xml = {
              validation = {
                enabled = true,
              },
              format = {
                enabled = true,
              },
            },
          },
        },
      }

      for server, config in pairs(servers) do
        config.capabilities = capabilities
        config.on_attach = on_attach
        vim.lsp.config[server] = config
      end

      -- Enable the configured servers
      vim.lsp.enable({
        "lua_ls",
        "ts_ls",
        "pyright",
        "gopls",
        "rust_analyzer",
        "bashls",
        "jsonls",
        "yamlls",
        "jdtls",
        "terraformls",
        "sqlls",
        "dockerls",
        "docker_compose_language_service",
        "graphql",
        "lemminx",
      })

      -- Diagnostic configuration
      vim.diagnostic.config({
        -- Hide inline virtual text (those annoying messages on the right)
        -- Use K or <leader>d to see diagnostics when needed
        virtual_text = false,

        -- Show signs in the gutter (left column)
        signs = {
          text = {
            [vim.diagnostic.severity.ERROR] = " ",
            [vim.diagnostic.severity.WARN] = " ",
            [vim.diagnostic.severity.HINT] = " ",
            [vim.diagnostic.severity.INFO] = " ",
          },
        },

        -- Don't update while typing
        update_in_insert = false,

        -- Keep underlines for visual indication
        underline = true,

        -- Sort by severity (errors first)
        severity_sort = true,

        -- Floating window config (when you hover)
        float = {
          border = "rounded",
          source = "always",
        },
      })
    end
  },
}
