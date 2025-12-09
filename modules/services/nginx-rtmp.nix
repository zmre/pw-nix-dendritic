{
  flake.nixosModules.nginx-rtmp = {pkgs, ...}: let
    handle-new-rtmp-recording = pkgs.writeShellScriptBin "handle-new-rtmp-recording" ''
      dirname="$1"
      basename="$2"
      filename="$3"
      modeldir="/var/lib/whisper-cpp"
      ${pkgs.lib.getExe pkgs.ffmpeg-full} -y -i "$dirname/$filename" -c copy "$dirname/$basename.mp4" && ${pkgs.coreutils}/bin/rm -f "$dirname/$filename"

      ${pkgs.lib.getExe pkgs.ffmpeg-full} -i "$dirname/$basename.mp4" -ar 16000 -ac 1 -c:a pcm_s16le "$dirname/$basename.wav"
      ${pkgs.whisper-cpp-vulkan}/bin/whisper-cli "$dirname/$basename.wav" -m "$modeldir/ggml-large-v3-turbo.bin" -l en --output-vtt >& /dev/null
      # TODO: figure out how to get speaker labeling
      #${pkgs.whisper-cpp-vulkan}/bin/whisper-cli -f "$dirname/$basename.wav" -m "$modeldir/ggml-small.en-tdrz.bin" -tdrz -l en --output-srt >& /dev/null
      ${pkgs.coreutils}/bin/rm "$dirname/$basename.wav"
    '';
  in {
    services.nginx = {
      enable = true;
      additionalModules = [pkgs.nginxModules.rtmp];
      appendConfig = ''
        rtmp {
          server {
            listen 1935;
            chunk_size 4096;
            application live {
              live on;
              # auto-record everything
              record all;
              record_unique on;
              record_path /var/lib/nginx/rtmp-recordings;
              record_suffix _%Y-%m-%d_%H-%M-%S.flv;
              exec_record_done ${handle-new-rtmp-recording}/bin/handle-new-rtmp-recording "$dirname" "$basename" "$filename";
            }
          }
        }
      '';
    };
    systemd.services.nginx.serviceConfig = {
      ReadWritePaths = ["/var/lib/nginx/rtmp-recordings"];
    };
    systemd.tmpfiles.rules = [
      "d /var/lib/nginx/rtmp-recordings 0775 nginx nginx -"
    ];
    networking.firewall.allowedTCPPorts = [1935];

    environment.systemPackages = [
      pkgs.ffmpeg-full
    ];
  };
}
