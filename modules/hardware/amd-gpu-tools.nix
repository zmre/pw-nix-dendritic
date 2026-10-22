{
  flake.nixosModules.amd-gpu = {pkgs, ...}: let
    # nixpkgs unstable bumped patchelf to 0.19.2 which aborts with
    # "Assertion `splitIndex == -1' failed" when auto-patchelf fixes
    # RadeonGPUAnalyzer-bin (same regression as cudaPackages, see
    # https://github.com/NixOS/nixpkgs/pull/575979). Force the older
    # stable patchelf onto PATH during fixup until upstream resolves it.
    # Added 2026-10-21; remove once `pkgs.rgp` builds cleanly again.
    rgpFixed = pkgs.rgp.overrideAttrs (old: {
      preFixup =
        (old.preFixup or "")
        + ''
          export PATH=${pkgs.stable.patchelf}/bin:$PATH
        '';
    });
  in {
    environment.systemPackages = with pkgs; [
      # gpu utils
      #rocmPackages.amdsmi
      rocmPackages.rocminfo
      rocmPackages.clr
      rocmPackages.hipblas
      rocmPackages.hipblaslt # BF16 acceleration for llama.cpp
      rocmPackages.rocblas
      rocmPackages.rocm-smi
      amdgpu_top
      radeontop
      radeontools
      vulkan-tools
      nvtopPackages.amd
      rgpFixed # amd workload inspection tool
    ];
  };
}
