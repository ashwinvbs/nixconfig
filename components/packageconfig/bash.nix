{
  config,
  ...
}:

{
  config = {
    environment.sessionVariables.HISTCONTROL = "erasedups:ignoreboth";
    programs.bash.shellAliases.code = "codium";
  };
}
