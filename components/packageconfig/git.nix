{ config, lib, pkgs, ... }:

{
  config.programs.git.config = {
    commit.verbose = "true";
    diff = {
      algorithm = "histogram";
      colorMoved = "plain";
      mnemonicPrefix = "true";
      renames = "true";
    };
    fetch = {
      prune = "true";
      pruneTags = "true";
      all = "true";
    };
    help.autocorrect = "prompt";
    pull.rebase = "true";
    rebase = {
      autoSquash = "true";
      updateRefs = "true";
    };
    tag.sort = "version:refname";
  };
}
