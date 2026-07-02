{
  lib,
  stdenv,
  buildNpmPackage,
  fetchurl,
  bun,
}:

buildNpmPackage (finalAttrs: {
  pname = "openpencil-cli";
  version = "0.13.2";

  src = fetchurl {
    url = "https://registry.npmjs.org/@open-pencil/cli/-/cli-${finalAttrs.version}.tgz";
    hash = "sha256-L1Jm7kxVaPIbOgVaUCqwWU2mlquDgv2yPH3LOeMl5S8=";
  };

  npmDepsHash = "sha256-f/3QXD0wST/9IneElf/aa35DzhFzWESMuNG9Yptn3WI=";

  postPatch = ''
    cp ${./package-lock.json} package-lock.json
  '';

  dontNpmBuild = true;

  postInstall = ''
    # Upstream 0.13.2 serializes newly-created offline nodes with sessionID 1,
    # which makes .fig round-trips drop/detach those nodes. Keep local-created
    # node GUIDs in session 0 so `openpencil eval -o` persists authored nodes.
    substituteInPlace \
      $out/lib/node_modules/@open-pencil/cli/node_modules/@open-pencil/core/dist/kiwi/fig/node-change/export-node.js \
      --replace-fail 'sessionID: 1,' 'sessionID: 0,'

    rm -f $out/bin/openpencil
    printf '%s\n' \
      '#!${stdenv.shell}' \
      'exec ${bun}/bin/bun "'$out'/lib/node_modules/@open-pencil/cli/bin/openpencil.js" "$@"' \
      > $out/bin/openpencil
    chmod +x $out/bin/openpencil
  '';

  meta = {
    description = "CLI for inspecting, exporting, scripting, and converting OpenPencil design files";
    homepage = "https://openpencil.dev";
    downloadPage = "https://www.npmjs.com/package/@open-pencil/cli";
    changelog = "https://github.com/open-pencil/open-pencil/releases/tag/v${finalAttrs.version}";
    license = lib.licenses.mit;
    mainProgram = "openpencil";
  };
})
