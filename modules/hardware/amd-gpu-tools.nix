{
  flake.nixosModules.amd-gpu = {pkgs, ...}: {
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
      rgp # amd workload inspection tool
    ];
  };
}
