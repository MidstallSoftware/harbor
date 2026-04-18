{ lib, pkgs, ... }:
{
  projectRootFile = "flake.nix";

  programs = {
    # NOTE: actionlint is broken on Darwin
    actionlint.enable = !pkgs.stdenv.hostPlatform.isDarwin;
    nixfmt.enable = true;
    dart-format = {
      enable = true;
      package = pkgs.dart;
    };
    yamlfmt.enable = true;
    clang-format.enable = true;
  };
}
