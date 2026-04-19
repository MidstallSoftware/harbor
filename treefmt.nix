{ lib, pkgs, ... }:
{
  projectRootFile = "flake.nix";

  programs = {
    # NOTE: actionlint is broken on Darwin
    actionlint.enable = !pkgs.stdenv.hostPlatform.isDarwin && !pkgs.stdenv.hostPlatform.isRiscV;
    nixfmt.enable = !pkgs.stdenv.hostPlatform.isRiscV;
    dart-format = {
      enable = !pkgs.stdenv.hostPlatform.isRiscV;
      package = pkgs.dart;
    };
    yamlfmt.enable = true;
    clang-format.enable = true;
  };
}
