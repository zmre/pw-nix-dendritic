{
  flake.modules.homeManager.prose = {config, ...}: {
    # Prose linting
    home.file = {
      "${config.xdg.configHome}/proselint/config.json".text = ''
        {
          "checks": {
            "typography.symbols.curly_quotes": false,
            "typography.symbols.ellipsis": false
          }
        }
      '';
      ".styles".source = ../../dotfiles/vale-styles;
      ".vale.ini".text = ''
        StylesPath = .styles

        # alert level options: suggestion, warning or error
        MinAlertLevel = suggestion

        Packages = proselint, alex, Readability

        IgnoredScopes = code, tt
        SkippedScopes = script, style, pre, figure

        [*]
        BasedOnStyles = Vale, proselint, Openly
        Google.FirstPerson = NO
        Google.We = NO
        Google.Acronyms = NO
        Google.Units = NO
        Google.Spacing = NO
        Google.Exclamation = NO
        Google.Headings = NO
        Google.Parens = NO
        Google.DateFormat = NO
        Google.Ellipses = NO
        proselint.Typography = NO
        proselint.DateCase = NO
        Vale.Spelling = NO
        Openly.E-Prime = NO
        Openly.Spelling = NO
        proselint.But = NO
      '';
    };
  };
}
