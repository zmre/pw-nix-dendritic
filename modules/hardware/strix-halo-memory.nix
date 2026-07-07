{inputs, ...}: {
  flake.nixosModules.strix-halo-memory = {lib, ...}: {
    # Strix Halo memory optimization for AI workloads
    # REQUIRES BIOS CHANGE: Set UMA Frame Buffer Size to 512MB (minimum)
    # This allows TTM to dynamically allocate GPU memory up to ~112GB

    boot.kernelParams = [
      # Better memory bandwidth (~6%). Tradeoff: the XDNA2 NPU (amdxdna
      # driver) requires the IOMMU enabled in passthrough mode (iommu=pt),
      # so any future NPU use means giving this up. Deliberate choice:
      # iGPU inference is the priority on this host (2026-07).
      "amd_iommu=off"
      "ttm.pages_limit=32768000" # ~112 GiB max GPU allocation (4KiB pages)
      "ttm.page_pool_size=32768000" # Match pages_limit
    ];
    boot.extraModprobeConfig = ''
      options amdgpu gttsize=120000      # 120GB GTT for large models (deprecated on 6.18+ in favor of the ttm.* kernel params above; drop once confirmed redundant)
      options amdgpu sg_display=0       # Disable display memory allocation
      options amdgpu vm_fragment_size=9  # VM fragmentation optimization
    '';
    # Ensure amdgpu loads early with proper config
    boot.initrd.kernelModules = ["amdgpu"];
  };
}
