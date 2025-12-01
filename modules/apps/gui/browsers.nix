{
  flake.darwinModules.browsers-gui = {
    homebrew.casks = [
      "brave-browser" # TODO: move to home-manager when it builds
      "choosy" # multi-browser url launch selector; see also https://github.com/johnste/finicky
      "firefox" # TODO: firefox build is broken on ARM; check to see if fixed
      "orion" # just trying out the Orion browser
    ];
    homebrew.masApps = {
      "Kagi Search" = 1622835804; # Paid private search engine plugin for Safari
      "Save to Reader" = 1640236961; # readwise reader (my pocket replacement)
      "Vimari" = 1480933944;
    };
  };
}
