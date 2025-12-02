{
  flake.nixosModules.amd-gpu = {pkgs, ...}: {
    environment.systemPackages = with pkgs; [
      # gpu utils
      rocmPackages.amdsmi
      rocmPackages.rocminfo
      amdgpu_top
      vulkan-tools
      rgp # amd workload inspection tool
    ];
    services.ollama.package = pkgs.ollama-rocm;
    services.ollama.rocmOverrideGfx = "11.0.2";
  };
}
