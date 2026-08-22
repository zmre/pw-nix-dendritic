{lib, ...}: {
  # curl-cffi is broken on darwin in nixpkgs-unstable as of 2026-08-20, which
  # breaks yt-dlp (and therefore mpv's ytdl hook).  Introduced by nixpkgs
  # 6bab5512f "curl-impersonate: 1.5.6 -> 2.1.0" (2026-08-16).
  #
  # curl-impersonate never ran fixDarwinDylibNames, so its dylib keeps
  # upstream's "@rpath/libcurl-impersonate.4.dylib" install name.  Consumers
  # therefore record an @rpath reference with no LC_RPATH to resolve it, and
  # curl-cffi's extension module dies during pythonImportsCheck:
  #
  #   ImportError: dlopen(.../curl_cffi/_wrapper.abi3.so, 0x0002):
  #     Library not loaded: @rpath/libcurl-impersonate.4.dylib
  #     Reason: no LC_RPATH's found
  #
  # Upstream fix is https://github.com/NixOS/nixpkgs/pull/554592, which adds
  # fixDarwinDylibNames to curl-impersonate.  We deliberately do NOT do that
  # here: curl-impersonate 2.1.0 substitutes from the binary cache, and
  # overriding it would force a from-source rebuild of its vendored boringssl /
  # nghttp2 / ngtcp2 stack.  Adding the rpath to curl-cffi instead is
  # equivalent at load time and only rebuilds a package we already rebuild.
  #
  # TODO: delete this whole file once #554592 (or the 0.16.0 bump in #554482)
  # lands in nixpkgs-unstable.
  flake.darwinModules.system = {
    nixpkgs.overlays = [
      (final: _prev: {
        pythonPackagesExtensions =
          _prev.pythonPackagesExtensions
          ++ [
            (pfinal: pprev: {
              curl-cffi = pprev.curl-cffi.overridePythonAttrs (old: {
                postFixup =
                  (old.postFixup or "")
                  + ''
                    for so in $out/${pfinal.python.sitePackages}/curl_cffi/*.so; do
                      install_name_tool -add_rpath ${lib.getLib final.curl-impersonate}/lib "$so"
                    done
                  '';

                # Backport of https://github.com/NixOS/nixpkgs/pull/554405,
                # which is merged to master but has not reached the
                # nixpkgs-unstable channel our lock is pinned to.  These fail
                # against the newer http3 in this nixpkgs.
                disabledTestPaths =
                  (old.disabledTestPaths or [])
                  ++ [
                    "tests/unittest/test_async_session.py::test_verify"
                    "tests/unittest/test_curl.py::test_verify"
                    "tests/unittest/test_requests.py::test_verify"
                    "tests/unittest/test_requests.py::test_delete_cookies"
                  ];

                # Large websocket frames fail against curl-impersonate 2.1.0's
                # libcurl with "(43) [WS] unaligned frame size (sending 65536
                # instead of 8730)".  Same family as the large-message
                # websocket tests nixpkgs already disables upstream, and it
                # only shows up now that the import check gets far enough to
                # run the suite.  Not a defect in anything we use yt-dlp for.
                disabledTests =
                  (old.disabledTests or [])
                  ++ [
                    "test_large_message_echo"
                  ];
              });
            })
          ];
      })
    ];
  };
}
