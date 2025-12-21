{
  flake.darwinModules.system = {pkgs, ...}: {
    # Fix "Too many open files" problems.
    # IMPORTANT: As of macOS 13.5+, `launchctl limit maxfiles` is blocked by SIP.
    # Instead, we use SoftResourceLimits/HardResourceLimits plist keys which
    # set kern.maxfiles and kern.maxfilesperproc sysctl values directly.
    # See: https://developer.apple.com/forums/thread/735798
    # Needs reboot to take effect.
    environment.launchDaemons.ulimitMaxFiles = {
      enable = true;
      target = "limit.maxfiles"; # suffix .plist
      text = ''
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
                  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
          <dict>
            <key>Label</key>
            <string>limit.maxfiles</string>
            <key>ProgramArguments</key>
            <array>
              <string>/usr/bin/true</string>
            </array>
            <key>RunAtLoad</key>
            <true/>
            <key>ServiceIPC</key>
            <false/>
            <key>SoftResourceLimits</key>
            <dict>
              <key>NumberOfFiles</key>
              <integer>524288</integer>
            </dict>
            <key>HardResourceLimits</key>
            <dict>
              <key>NumberOfFiles</key>
              <integer>524288</integer>
            </dict>
          </dict>
        </plist>
      '';
    };
  };
}
