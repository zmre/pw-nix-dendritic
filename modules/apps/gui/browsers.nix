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

  flake.modules.homeManager.browsers-gui = {
    pkgs,
    config,
    ...
  }: let
    browser = ["org.qutebrowser.qutebrowser.desktop"];
    associations = {
      "text/html" = browser;
      "x-scheme-handler/http" = browser;
      "x-scheme-handler/https" = browser;
      "x-scheme-handler/ftp" = browser;
      "x-scheme-handler/chrome" = browser;
      "x-scheme-handler/about" = browser;
      "x-scheme-handler/unknown" = browser;
      "application/x-extension-htm" = browser;
      "application/x-extension-html" = browser;
      "application/x-extension-shtml" = browser;
      "application/xhtml+xml" = browser;
      "application/x-extension-xhtml" = browser;
      "application/x-extension-xht" = browser;

      "text/*" = ["neovide.desktop"];
      "audio/*" = ["mpv.desktop"];
      "video/*" = ["mpv.dekstop"];
      "image/*" = ["feh.desktop"];
      "application/json" = browser; # ".json"  JSON format
      "application/pdf" = browser; # ".pdf"  Adobe Portable Document Format (PDF)
    };
  in {
    xdg.mimeApps = {
      enable = pkgs.stdenv.isLinux;
      associations.added = associations;
      defaultApplications = associations;
    };
    # Backup browser for when Qutebrowser doesn't work as expected
    # currently fails to compile on darwin
    programs.firefox = {
      enable = pkgs.stdenv.isLinux;
      # turns out you have to setup a profile (below) for extensions to install
      profiles = {
        home = {
          extensions = with pkgs.nur.repos.rycee.firefox-addons; [
            ublock-origin
            #https-everywhere
            noscript
            vimium
          ];
          id = 0;
          settings = {
            "app.update.auto" = false; # nix will handle updates
            "browser.search.region" = "US";
            "browser.search.countryCode" = "US";
            "browser.ctrlTab.recentlyUsedOrder" = false;
            "browser.newtabpage.enhanced" = true;
            "devtools.chrome.enabled" = true;
            "devtools.theme" = "dark";
            "extensions.pocket.enabled" = false;
            "network.prefetch-next" = true;
            "nework.predictor.enabled" = true;
            "browser.uidensity" = 1;
            "privacy.trackingprotection.enabled" = true;
            "privacy.trackingprotection.socialtracking.enabled" = true;
            "privacy.trackingprotection.socialtracking.annotate.enabled" = true;
            "privacy.trackingprotection.socialtracking.notification.enabled" = false;
            "services.sync.engine.addons" = false;
            "services.sync.engine.passwords" = false;
            "services.sync.engine.prefs" = false;
            "signon.rememberSignons" = false;
          };
        };
      };
    };

    # currently fails to compile on darwin
    programs.qutebrowser = {
      enable = pkgs.stdenv.isLinux;
      loadAutoconfig = false;
      keyBindings = {
        normal = {
          ",m" = "spawn mpv {url}";
          ",M" = ''hint links spawn mpv "{hint-url}"'';
          ",d" = ''spawn yt-dlp -o "~/Downloads/%(title)s.%(ext)s" "{url}"'';
          ",D" = ''
            hint links spawn yt-dlp -o "~/Downloads/%(title)s.%(ext)s" "{url}"'';
          ",f" = ''spawn firefox "{url}"'';
          # get current page as markdown link
          ",ym" = "yank inline [{title}]({url:pretty})";
          "xt" = "config-cycle tabs.show always never";
          "<f12>" = "inspector";
          # search for link with / then hit enter to follow
          "<return>" = "selection-follow";
        };
        prompt = {"<Ctrl-y>" = "prompt-yes";};
        insert = {
          "<Ctrl-h>" = "fake-key <Backspace>";
          "<Ctrl-a>" = "fake-key <Home>";
          "<Ctrl-e>" = "fake-key <End>";
          "<Ctrl-b>" = "fake-key <Left>";
          "<Mod1-b>" = "fake-key <Ctrl-Left>";
          "<Ctrl-f>" = "fake-key <Right>";
          "<Mod1-f>" = "fake-key <Ctrl-Right>";
          "<Ctrl-p>" = "fake-key <Up>";
          "<Ctrl-n>" = "fake-key <Down>";
          "<Mod1-d>" = "fake-key <Ctrl-Delete>";
          "<Ctrl-d>" = "fake-key <Delete>";
          "<Ctrl-w>" = "fake-key <Ctrl-Backspace>";
          "<Ctrl-u>" = "fake-key <Shift-Home><Delete>";
          "<Ctrl-k>" = "fake-key <Shift-End><Delete>";
          "<Ctrl-x><Ctrl-e>" = "open-editor";
        };
      };
      settings = {
        confirm_quit = ["downloads"]; # only confirm if downloads in progress
        content = {
          blocking = {
            enabled = true;
            method = "both";
            hosts.block_subdomains = true;
            # StevenBlack list pulls from lots of sources; we also update our /etc/hosts
            # with this, but that only gets an update when we rebuild our nix system
            # whereas this should reload more often
            hosts.lists = [
              "https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts"
              "https://raw.githubusercontent.com/uBlockOrigin/uAssets/master/filters/filters-2022.txt"
            ];
            whitelist = ["https://*.reddit.com/*"];
          };
          default_encoding = "utf-8";
          geolocation = false;
          cookies.accept = "no-3rdparty";
          # might break some sites; stops fingerprinting
          canvas_reading = false;
          webrtc_ip_handling_policy = "default-public-interface-only";
          javascript.clipboard = "access";
          site_specific_quirks.enabled = false;
          headers.user_agent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/96.0.4664.45 Safari/537.36";
          pdfjs = true;
          autoplay = false;
        };
        qt.highdpi = true;
        # Disable smooth scrolling on mac because of https://github.com/qutebrowser/qutebrowser/issues/6840
        # Note: this is in home-linux so this if is pointless, but I'm hoping qutebrowser will build on mac soon and this can move
        scrolling.smooth =
          if pkgs.stdenv.isDarwin
          then false
          else true;
        auto_save.session = true; # remember open tabs
        session.lazy_restore = true;
        input.insert_mode = {
          # if input is focused on tab load, allow typing
          auto_load = true;
          # exit insert mode if clicking on non editable item
          auto_leave = true;
        };
        downloads = {
          location.directory = "${
            if pkgs.stdenv.isDarwin
            then "/Users/"
            else "/home/"
          }${config.home.username}/Downloads";

          location.prompt = false;
          position = "bottom";
          remove_finished = 10000;
        };
        completion.use_best_match = true;
        completion.shrink = true;
        colors.webpage = {
          preferred_color_scheme = "dark";
          # enabling darkmode auto-changes website colors and images and often makes things worse instead of better :-(
          #darkmode.enabled = false;
          #bg = "black";
        };
        statusbar.widgets = ["progress" "keypress" "url" "history"];
        tabs = {
          position = "left";
          title.format = "{index}: {audio}{current_title}";
          title.format_pinned = "{index}: {audio}{current_title}";
          last_close = "close";
        };
        spellcheck.languages = ["en-US"];
        editor.command = ["neovide" "{}:{line}"];
        fileselect = {
          handler = "external";
          single_file.command = [
            "alacritty"
            "--class"
            "lf,lf"
            "-t"
            "Chooser"
            "-e"
            "sh"
            "-c"
            "lf -selection-path {}"
          ];
          multiple_files.command = [
            "alacritty"
            "--class"
            "lf,lf"
            "-t"
            "Chooser"
            "-e"
            "sh"
            "-c"
            "lf -selection-path {}"
          ];
        };
      };
      # these create :whatever commands
      aliases = {
        # bookmarklet copied from getpocket.com/add/?ep=1
        pocket = "jseval --url javascript:(function()%7Bvar%20e=function(t,n,r,i,s)%7Bvar%20o=[5725664,2839244,3201831,4395922,8906499,4608765,5885226,5372109,1439837,3633248];var%20i=i%7C%7C0,u=0,n=n%7C%7C[],r=r%7C%7C0,s=s%7C%7C0;var%20a=%7B'a':97,'b':98,'c':99,'d':100,'e':101,'f':102,'g':103,'h':104,'i':105,'j':106,'k':107,'l':108,'m':109,'n':110,'o':111,'p':112,'q':113,'r':114,'s':115,'t':116,'u':117,'v':118,'w':119,'x':120,'y':121,'z':122,'A':65,'B':66,'C':67,'D':68,'E':69,'F':70,'G':71,'H':72,'I':73,'J':74,'K':75,'L':76,'M':77,'N':78,'O':79,'P':80,'Q':81,'R':82,'S':83,'T':84,'U':85,'V':86,'W':87,'X':88,'Y':89,'Z':90,'0':48,'1':49,'2':50,'3':51,'4':52,'5':53,'6':54,'7':55,'8':56,'9':57,'%5C/':47,':':58,'?':63,'=':61,'-':45,'_':95,'&':38,'$':36,'!':33,'.':46%7D;if(!s%7C%7Cs==0)%7Bt=o[0]+t%7Dfor(var%20f=0;f%3Ct.length;f++)%7Bvar%20l=function(e,t)%7Breturn%20a[e[t]]?a[e[t]]:e.charCodeAt(t)%7D(t,f);if(!l*1)l=3;var%20c=l*(o[i]+l*o[u%25o.length]);n[r]=(n[r]?n[r]+c:c)+s+u;var%20p=c%25(50*1);if(n[p])%7Bvar%20d=n[r];n[r]=n[p];n[p]=d%7Du+=c;r=r==50?0:r+1;i=i==o.length-1?0:i+1%7Dif(s==193)%7Bvar%20v='';for(var%20f=0;f%3Cn.length;f++)%7Bv+=String.fromCharCode(n[f]%25(25*1)+97)%7Do=function()%7B%7D;return%20v+'c7a8217062'%7Delse%7Breturn%20e(u+'',n,r,i,s+1)%7D%7D;var%20t=document,n=t.location.href,r=t.title;var%20i=e(n);var%20s=t.createElement('script');s.type='text/javascript';s.src='https://getpocket.com/b/r4.js?h='+i+'&u='+encodeURIComponent(n)+'&t='+encodeURIComponent(r);e=i=function()%7B%7D;var%20o=t.getElementsByTagName('head')[0]%7C%7Ct.documentElement;o.appendChild(s)%7D)()";
      };
      quickmarks = {
        icc = "https://ironcorelabs.com/";
        icweb = "https://github.com/ironcorelabs/website";
        nix = "https://search.nixos.org/";
        hm = "https://nix-community.github.io/home-manager/options.html";
        rd = "https://reddit.com/";
        yt = "https://youtube.com/";
        hn = "https://news.ycombinator.com/";
        tw = "https://twitter.com/";
        td = "https://twitter.com/i/lists/44223630";
        gh = "https://github.com/";
        ghi = "https://github.com/ironcorelabs/";
        ghz = "https://github.com/zmre/";
        ghn = "https://github.com/notifications?participating=true";
        gr = "https://goodreads.com/";
        mg = "https://mail.google.com/";
        mp = "https://mail.protonmail.com/";
        po = "https://getpocket.com/my-list";
      };
      searchEngines = {
        DEFAULT = "https://kagi.com/search?q={}";
        d = "https://duckduckgo.com/?q={}&ia=web";
        k = "https://kagi.com/search?q={}";
        w = "https://en.wikipedia.org/wiki/Special:Search?search={}&go=Go&ns0=1";
        aw = "https://wiki.archlinux.org/?search={}";
        nw = "https://nixos.wiki/index.php?search={}";
        np = "https://search.nixos.org/packages?channel=24.05&from=0&size=100&sort=relevance&type=packages&query={}";
        nu = "https://search.nixos.org/packages?channel=unstable&from=0&size=50&sort=relevance&type=packages&query={}";
        no = "https://search.nixos.org/options?channel=24.05&from=0&size=50&sort=relevance&type=packages&query={}";
        nf = "https://search.nixos.org/flakes?channel=24.05&from=0&size=50&sort=relevance&type=packages&query={}";
        g = "https://www.google.com/search?hl=en&q={}";
        gh = "https://github.com/?q={}";
        yt = "https://www.youtube.com/results?search_query={}";
      };
      extraConfig = ''
        # stolen from reddit; will block or allow skip of ads on youtube
        from qutebrowser.api import interceptor

        def filter_yt(info: interceptor.Request):
            """Block the given request if necessary."""
            url = info.request_url
            if (url.host() == 'www.youtube.com' and url.path() == '/get_video_info' and '&adformat=' in url.query()):
                info.block()

        interceptor.register(filter_yt)

        ${builtins.readFile ../../../dotfiles/qutebrowser-theme-onedark.py}
      '';
    };
  };
}
