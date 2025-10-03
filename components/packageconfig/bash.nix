{ config, lib, pkgs, ... }:

{
  config = {
    environment.sessionVariables.HISTCONTROL = "erasedups:ignoreboth";

    programs.bash = {
      promptInit = ''
        PS1="[\[\e[01;32m\]\h\[\e[m\] \[\e[01;34m\]\w\[\e[m\]]$ "
      '';
      shellAliases.code = "codium";
    };
  };
}
