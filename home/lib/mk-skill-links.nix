# Builds home.file entries linking every shared skill in ../skills into an
# agent's skills directory.
#
# The skill names come from the store copy of ../skills, but each link points at
# `skillsRoot` in the repo working tree, so SKILL.md edits are live.
{ lib }:
{
  mkOutOfStoreSymlink,
  skillsRoot,
  targetPrefix,
}:
lib.mapAttrs' (
  name: _:
  lib.nameValuePair "${targetPrefix}/${name}" {
    source = mkOutOfStoreSymlink "${skillsRoot}/${name}";
  }
) (builtins.readDir ../skills)
