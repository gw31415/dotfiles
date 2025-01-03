{ pkgs ? import <nixpkgs> { system = builtins.currentSystem; }
}:
let
  Bun2Yarn = { bunLockb }:
    pkgs.runCommand "bun2yarn"
      {
        nativeBuildInputs = [ pkgs.bun ];
      }
      ''
        cp ${bunLockb} bun.lockb
        bun bun.lockb > $out
      '';
  yarnLock = (Bun2Yarn { bunLockb = ./bun.lockb; });
  mkYarnNix =
    pkgs.runCommand "yarn.nix" { }
      "${pkgs.yarn2nix}/bin/yarn2nix --lockfile ${yarnLock} --no-patch --builtin-fetchgit > $out";
  offlineMirror = (pkgs.callPackage mkYarnNix { }).offline_cache;
  nodeModules = pkgs.runCommand "node_modules"
    {
      nativeBuildInputs = [
        pkgs.yarn
        pkgs.fixup_yarn_lock
      ];
    }
    ''
      cp -r ${./.}/package.json .
      install -m 644 ${yarnLock} yarn.lock

      export HOME=$TMP
      fixup_yarn_lock ./yarn.lock
      yarn config --offline set yarn-offline-mirror ${offlineMirror}
      yarn install --frozen-lockfile --ignore-platform --ignore-scripts --no-progress --non-interactive --offline

      mv node_modules $out
    '';
  bunBuild = pkgs.runCommand "dot"
    {
      nativeBuildInputs = [ pkgs.bun pkgs.rsync ];
    }
    ''
      rsync -av --exclude="node_modules" --exclude="out" ${./.}/* .
      cp -r ${ nodeModules } node_modules
      bun build index.ts --minify --compile --outfile=./out
      cp out $out
    '';
in
pkgs.stdenvNoCC.mkDerivation {
  name = "dot";
  src = ./.;

  buildPhase = ''
    runHook preBuild

    cp ${bunBuild} dot

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin
    cp dot $out/dot
    cp dot $out/bin/dot

    runHook postInstall
  '';
}
