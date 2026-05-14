{
  lib,
  buildNpmPackage,
  fetchurl,
}:

buildNpmPackage rec {
  pname = "excalidraw-cli";
  version = "0.0.2";

  src = ./.;

  npmDepsHash = "sha256-7xlTiOpjfFIIjxLhXrCvuVUtjRM6PPG/mYkQLr25CRk=";
  dontNpmBuild = true;

  postPatch = ''
    tar -xzf ${fetchurl {
      url = "https://registry.npmjs.org/excalidraw-cli/-/excalidraw-cli-${version}.tgz";
      hash = "sha512-9CX3DF6R4SRDqUg88OTAo0OaD3L9f0D0xTs1/hkw07zm3vIyEieNSv+v62ztsJn6UtcxifdzdkSWqH8jrLLGOg==";
    }} --strip-components=1 package/dist package/README.md
  '';

  meta = {
    description = "Create hand-drawn Excalidraw diagrams from the command line";
    homepage = "https://github.com/ahmadawais/excalidraw-cli";
    license = lib.licenses.mit;
    mainProgram = "excalidraw";
  };
}
