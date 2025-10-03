{
  pkgs,
  self,
}: let
  ## A wrapper around `pkgs.runCommand` that uses `bash-strict-mode`.
  runStrictCommand = name: attrs: cmd:
    pkgs.checkedDrv (pkgs.runCommand name attrs cmd);

  ## A command where we don’t preserve any output can be more lax than most
  ## derivations. By turning it into a fixed-output derivation based on the
  ## command, we can weaken some of the sandbox constraints.
  ##
  ## The tradeoff is that this uses IFD, so it should only be used for
  ## derivations that would otherwise not be sandboxable.
  runEmptyCommand = name: attrs: command: let
    outputHashAlgo = "sha256";
    ## Runs a command and returns its output as a string.
    exec = nativeBuildInputs: cmd:
      builtins.readFile
      (builtins.toString
        (runStrictCommand "exe" {inherit nativeBuildInputs;}
          "{ ${cmd} } > $out"));
    hashInput = str:
      runStrictCommand "emptyCommand-hash-input" {} ''
        ## Base64-encode the command to avoid having any path references in the
        ## output.
        echo ${pkgs.lib.escapeShellArg str} | base64 > $out
      '';
    getHash = str:
      pkgs.lib.removeSuffix "\n" (exec [pkgs.nix] ''
        nix-hash --type ${outputHashAlgo} --base64 ${hashInput str}
      '');
  in
    runStrictCommand name (attrs
      // {
        inherit outputHashAlgo;
        outputHash = getHash command;
        outputHashMode = "recursive";
      }) ''
      ${command}
      cp ${hashInput command} "$out"
    '';
in {
  inherit runStrictCommand runEmptyCommand;

  checks = import ./checks {inherit pkgs runEmptyCommand self;};

  elisp = import ./elisp {inherit pkgs;};
}
