{
  stdenv,
  lib,
  writeScript,
  sqlite,
  sqlcipher,
}:

{ version, src, ... }:

stdenv.mkDerivation (finalAttrs: {
  pname = "sqlite3";
  inherit version src;
  inherit (src) passthru;

  setupHook = writeScript "${finalAttrs.pname}-setup-hook" ''
    sqliteFixupHook() {
      runtimeDependencies+=('${lib.getLib sqlite}')
      runtimeDependencies+=('${lib.getLib sqlcipher}')
    }

    preFixupHooks+=(sqliteFixupHook)
  '';

  postPatch =
    if lib.versionAtLeast version "3.5.0" then
      ''
        substituteInPlace lib/src/hook/compile/description.dart \
          --replace-fail "return fromGitHub(LibraryType.sqlite3);" "return LookupSystem('sqlite3');"
        substituteInPlace lib/src/hook/compile/description.dart \
          --replace-fail "return fromGitHub(LibraryType.sqlcipher);" "return LookupSystem('sqlcipher');"
      ''
    else
      lib.optionalString (lib.versionAtLeast version "3.2.0") ''
        substituteInPlace lib/src/hook/description.dart \
          --replace-fail "return PrecompiledFromGithubAssets(LibraryType.sqlite3);" "return LookupSystem('sqlite3');"
      '';

  installPhase = ''
    runHook preInstall

    cp --recursive . "$out"

    runHook postInstall
  '';
})
