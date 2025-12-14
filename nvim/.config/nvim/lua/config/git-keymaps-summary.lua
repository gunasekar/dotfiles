-- Git Keymaps Summary
-- This file is just for reference - keymaps are defined in the plugin files

--[[

GIT FEATURES SUMMARY
====================

🚀 LAZYGIT (Main Git Interface)
--------------------------------
<Space>gg   - Open LazyGit (see all changed files, stage, commit, push, etc.)
<Space>gc   - LazyGit current file only

Once in Lazygit:
  j/k or ↑/↓  - Navigate
  Space       - Stage/unstage file
  a           - Stage all
  c           - Commit
  P           - Push
  p           - Pull
  d           - View diff
  ?           - Help
  q           - Quit


📊 VISUAL INDICATORS (Gitsigns)
--------------------------------
Look for these on the left side of your files:
  │ (green)   - Added lines
  │ (yellow)  - Modified lines
  _ (red)     - Deleted lines


🔍 NAVIGATE CHANGES
-------------------
]c          - Next change (hunk)
[c          - Previous change (hunk)


👁️  PREVIEW & VIEW
------------------
<Space>gp   - Preview hunk (see what changed)
<Space>gb   - Blame line (who wrote this?)
<Space>gd   - Diff this file


📝 STAGE/UNSTAGE (Gitsigns)
---------------------------
<Space>gs   - Stage hunk (change under cursor)
<Space>gS   - Stage entire file
<Space>gu   - Unstage hunk
<Space>gr   - Reset hunk (undo change)
<Space>gR   - Reset entire file (undo all changes)


💻 GIT COMMANDS (Fugitive)
--------------------------
<Space>gG   - Git status (Fugitive interface)
<Space>gB   - Git blame (full file)
<Space>gD   - Git diff split
<Space>gw   - Git write (stage file)
<Space>gr   - Git read (checkout file)


📊 DIFFVIEW (Advanced Diffs)
----------------------------
<Space>gdo  - Open Diffview (see all changes side-by-side)
<Space>gdc  - Close Diffview
<Space>gdh  - File history (all commits)
<Space>gdf  - Current file history


⚡ CONFLICT RESOLUTION
----------------------
]x          - Next conflict
[x          - Previous conflict
<Space>gco  - Choose Ours (keep your changes)
<Space>gct  - Choose Theirs (take their changes)
<Space>gcb  - Choose Both
<Space>gcn  - Choose None
<Space>gcl  - List all conflicts


🎯 RECOMMENDED WORKFLOW
-----------------------
1. Edit your files
2. Press <Space>gg to open Lazygit
3. Review changes (navigate with j/k, press Enter to see diff)
4. Stage files (press Space on each file, or 'a' for all)
5. Commit (press 'c', type message, press Enter)
6. Push (press 'P')
7. Quit (press 'q')


💡 QUICK TIPS
-------------
- Use <Space>gg for most Git operations (easiest!)
- Use ]c and <Space>gp to review changes while editing
- Use <Space>gb to see who wrote problematic code
- Look at the statusline for current branch and change count

]]

return {}
