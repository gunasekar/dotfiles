-- Load core configurations
require("config.blackbox")     -- Must be first: captures errors from all subsequent requires
require("config.options")
require("config.keymaps")
require("config.autocmds")
require("config.lazy")

-- Load utility modules
require("config.utils")        -- Helper functions and commands
require("config.health-check") -- Health check command
