{
  flake.nixosModules.amd-gpu = {pkgs, ...}: {
    environment.systemPackages = with pkgs; [
      # gpu utils
      #rocmPackages.amdsmi
      rocmPackages.rocminfo
      rocmPackages.clr
      rocmPackages.hipblas
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
