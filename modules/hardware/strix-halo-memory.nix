{inputs, ...}: {
  flake.nixosModules.strix-halo-memory = {lib, ...}: {
    # Strix Halo memory optimization for AI workloads
    # REQUIRES BIOS CHANGE: Set UMA Frame Buffer Size to 512MB (minimum)
    # This allows TTM to dynamically allocate GPU memory up to 112GB

    boot.kernelParams = [
      "amd_iommu=off" # Better memory bandwidth (~6%)
      "ttm.pages_limit=32768000" # 112 GiB max GPU allocation
      "ttm.page_pool_size=32768000" # Match pages_limit
    ];
    boot.extraModprobeConfig = ''
      options amdgpu gttsize=120000      # 120GB GTT for large models
      options ttm pages_limit=32768000  # TTM page limit
      options ttm page_pool_size=32768000  # TTM page pool
      options amdgpu sg_display=0       # Disable display memory allocation
      options amdgpu vm_fragment_size=9  # VM fragmentation optimization
    '';
    # Ensure amdgpu loads early with proper config
    boot.initrd.kernelModules = ["amdgpu"];
  };
}
