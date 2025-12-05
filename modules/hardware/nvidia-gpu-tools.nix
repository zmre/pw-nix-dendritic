{
  flake.modules.homeManager.cuda-gpu = {pkgs, ...}: {
    nixpkgs.config.allowUnfree = true;
    home.packages = with pkgs; [
      vulkan-headers
      vulkan-loader
      cudaPackages.cudatoolkit
      #cudaPackages.cudnn
      cudaPackages.nccl
      cudaPackages.cuda_cccl
    ];
    home.sessionVariables = {
      LD_PRELOAD = "/usr/lib/x86_64-linux-gnu/libcuda.so.1:/usr/lib/x86_64-linux-gnu/libnvidia-ptxjitcompiler.so.1";
      # LD_LIBRARY_PATH = "${pkgs.stdenv.cc.cc.lib}/lib:${pkgs.vulkan-loader}/lib:${pkgs.cudatoolkit}/lib:${pkgs.cudaPackages.nccl}/lib:/usr/lib/x86_64-linux-gnu/libcuda.so.1:/usr/lib/x86_64-linux-gnu/libnvidia-ptxjitcompiler.so.1";
      CUDA_PATH = "${pkgs.cudatoolkit}";
      VULKAN_SDK = "${pkgs.vulkan-headers}";
    };
  };
}
