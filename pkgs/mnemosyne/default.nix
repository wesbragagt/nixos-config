{
  lib,
  python3Packages,
  fetchPypi,
}:

python3Packages.buildPythonApplication {
  pname = "mnemosyne-memory";
  version = "3.15.1";
  pyproject = true;

  src = fetchPypi {
    pname = "mnemosyne_memory";
    version = "3.15.1";
    hash = "sha256-lspUMxc0pUSkhSUrNdiiO5OJ1NMC/S853EYSanXtXKM=";
  };

  build-system = [ python3Packages.setuptools ];
  dependencies = [ python3Packages.pyyaml ];

  meta = {
    description = "Local AI memory command-line interface";
    homepage = "https://github.com/AxDSan/mnemosyne";
    license = lib.licenses.mit;
    mainProgram = "mnemosyne";
  };
}
