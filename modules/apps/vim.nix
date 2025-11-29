{
  flake-file.inputs.pwnvim.url = "github:zmre/pwnvim";
  flake-file.inputs.pwneovide.url = "github:zmre/pwneovide";
  flake-file.inputs.pwneovide.inputs.pwnvim.follows = "pwnvim";
}
