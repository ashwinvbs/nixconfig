{
  config,
  ...
}:

{
  config = {
    environment.sessionVariables.HISTCONTROL = "erasedups:ignoreboth";
  };
}
