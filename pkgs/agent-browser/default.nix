{
  lib,
  stdenv,
  buildNpmPackage,
  fetchzip,
  autoPatchelfHook,
  glibc,
  versionCheckHook,
  writableTmpDirAsHomeHook,
}:

buildNpmPackage (finalAttrs: {
  pname = "agent-browser";
  version = "0.27.0";

  src = fetchzip {
    url = "https://registry.npmjs.org/agent-browser/-/agent-browser-${finalAttrs.version}.tgz";
    hash = "sha256-H7v7QI/rRp7YhVQagPEIOYiwAoOArKC+oWn26b45GEo=";
  };

  npmDepsHash = "sha256-PboVmg7v7ObncE285cX5rM//PvV62DGOwr/1krO22zM=";

  strictDeps = true;

  nativeBuildInputs = [ autoPatchelfHook ];
  buildInputs = [ glibc ];

  postPatch = ''
    cp ${./package-lock.json} package-lock.json
  '';

  dontNpmBuild = true;

  preInstall = ''
    mkdir -p node_modules
  '';

  doInstallCheck = true;
  nativeInstallCheckInputs = [
    writableTmpDirAsHomeHook
    versionCheckHook
  ];
  versionCheckKeepEnvironment = [ "HOME" ];
  versionCheckProgramArg = "--version";

  preferLocalBuild = true;
  allowSubstitutes = false;

  meta = {
    description = "Browser automation CLI for AI agents";
    homepage = "https://agent-browser.dev";
    downloadPage = "https://www.npmjs.com/package/agent-browser";
    license = lib.licenses.asl20;
    mainProgram = "agent-browser";
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
    ];
  };
})
