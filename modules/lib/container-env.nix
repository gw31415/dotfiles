{
  pkgs,
  env,
  activationPackage,
}:
let
  lib = pkgs.lib;
  gccLib = pkgs.lib.getLib pkgs.gcc.cc;
  containerHome = "/home/${env.username}";
  containerConfigHome = "${containerHome}/.config";
  containerStateHome = "${containerHome}/.local/state";
  homeManagerActivate = "${activationPackage}/activate";
  homeManagerHomePath = "${activationPackage}/home-path";
  repoPath = "${containerConfigHome}/home-manager";
  caCertPath = "/etc/ssl/certs/ca-bundle.crt";
  caEnvVarNames = [
    "SSL_CERT_FILE"
    "NIX_SSL_CERT_FILE"
    "GIT_SSL_CAINFO"
    "CURL_CA_BUNDLE"
  ];
  runtimeEnv =
    {
      HOME = containerHome;
      USER = env.username;
      SHELL = "${pkgs.fish}/bin/fish";
      TERM = "xterm-256color";
      XDG_CONFIG_HOME = containerConfigHome;
      XDG_STATE_HOME = containerStateHome;
      HOME_MANAGER_ACTIVATE = homeManagerActivate;
      HOME_MANAGER_HOME_PATH = homeManagerHomePath;
      LD_LIBRARY_PATH = "${gccLib}/lib";
      PATH = "${homeManagerHomePath}/bin:${pkgs.nix}/bin:${pkgs.fish}/bin:${pkgs.coreutils}/bin:${pkgs.bashInteractive}/bin";
    }
    // lib.genAttrs caEnvVarNames (_: caCertPath);
in
{
  inherit
    caCertPath
    caEnvVarNames
    containerConfigHome
    containerHome
    containerStateHome
    homeManagerActivate
    homeManagerHomePath
    repoPath
    runtimeEnv
    ;

  envList = lib.mapAttrsToList (name: value: "${name}=${value}") runtimeEnv;
}
