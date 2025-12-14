from ranger.api.commands import Command

class code(Command):
  """
  :code
  Opens current directory in Neovim
  """

  def execute(self):
    dirname = self.fm.thisdir.path
    open_codebase_cmd = ["nvim", dirname]
    self.fm.execute_command(open_codebase_cmd)
