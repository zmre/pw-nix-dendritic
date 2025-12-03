{
  # This crazy modules is here so we can post-process recorded TV shows and then
  # mark the commercials (as chapters) so they can be skipped. We could cut them
  # but I don't know how good of a job it does.
  flake.nixosModules.comskip = {
    pkgs,
    lib,
    ...
  }: {
    # Only evaluate on Linux systems to avoid cross-platform check issues
    config = lib.mkIf pkgs.stdenv.isLinux (let
      argtable = pkgs.stdenv.mkDerivation rec {
        pname = "argtable2";
          version = "2.13";

        NIX_CFLAGS_COMPILE = toString [
          "-Wno-error=implicit-function-declaration"
          "-Wno-other-warning"
        ];

        configureFlags = ["CFLAGS=-Wno-error=implicit-function-declaration"];

        src = pkgs.fetchurl {
          url = "http://prdownloads.sourceforge.net/argtable/argtable2-13.tar.gz";
          sha256 = "sha256-j3fop87VMBr24i9HMC/bw7H/QfK4PEPHeuXKBBdx3b8=";
        };

        nativeBuildInputs = [];

        meta = with pkgs.lib; {
          description = "A library for parsing GNU style command line arguments";
          homepage = "http://argtable.sourceforge.net/";
          license = licenses.bsd3;
          platforms = platforms.unix;
        };
      };
      comskip = pkgs.stdenv.mkDerivation rec {
        pname = "comskip";
        version = "0.83";

        src = pkgs.fetchFromGitHub {
          owner = "erikkaashoek";
          repo = "Comskip";
          rev = "55b0bcd018ddb9dacfad79addc48df55c1411073";
          sha256 = "sha256-3bgwS+9agi0BkhOF+Hr593k0BRRCFiCGltgxoRqjT18=";
        };

        buildInputs = with pkgs; [
          ffmpeg_4 # Comskip relies heavily on ffmpeg libraries
          argtable # A common dependency for CLI parsing
        ];

        nativeBuildInputs = with pkgs; [
          # These are often implicitly handled by stdenv for autoconf projects,
          # but good to be aware of.
          autoconf
          automake
          libtool
          # This automatically runs to generate config
          autoreconfHook
          pkg-config
        ];

        meta = with pkgs.lib; {
          description = "Comskip: Detect and mark commercials in video files";
          homepage = "https://github.com/erikkaashoek/Comskip";
          license = licenses.gpl2Plus; # Check Comskip's actual license
          platforms = platforms.linux; # Or other platforms it supports
        };
      };
      # Below script taken from https://github.com/BrettSheleski/comchap/blob/master/comchap
      # I've modified it enough that I don't want to use the version in the repo
      comchap = pkgs.writeShellApplication {
        name = "comchap";
        runtimeInputs = with pkgs; [comskip gawk ffmpeg mktemp];
        text = ''
              #LD_LIBRARY_PATH is set and will mess up ffmpeg, unset it, then re-set it when done
              ldPath=$LD_LIBRARY_PATH
              unset LD_LIBRARY_PATH

              exitcode=0

              ffmpegPath="${pkgs.ffmpeg}/bin/ffmpeg"
              comskipPath="${comskip}/bin/comskip"

              if [[ $# -lt 1 ]]; then

                exename=$(basename "$0")

                echo "Add chapters to video file using EDL file"
                echo "     (If no EDL file is found, comskip will be used to generate one)"
                echo ""
                echo "Usage: $exename infile [outfile]"

                exit 1
              fi

              comskipini=/tmp/comskip.ini

              deleteedl=true
              deletemeta=true
              deletelog=true
              deletelogo=true
              deletetxt=true
              verbose=false
              lockfile=""
              workdir=""

              while [[ $# -gt 0 ]]
              do
              key="$1"
              case $key in
                  --keep-edl)
                  deleteedl=false
                  shift
                  ;;
                  --keep-meta)
                  deletemeta=false
                  shift
                  ;;
                  --verbose)
                  verbose=true
                  shift
                  ;;
                  --ffmpeg=*)
                  ffmpegPath="''${key#*=}"
                  shift
                  ;;
                  --comskip=*)
                  comskipPath="''${key#*=}"
                  shift
                  ;;
                  --comskip-ini=*)
                  comskipini="''${key#*=}"
                  shift
                  ;;
                  --lockfile=*)
                  lockfile="''${key#*=}"
                  shift
                  ;;
                  --work-dir=*)
                  workdir="''${key#*=}"
                  shift
                  ;;
                  -*)
                  echo "Option $1 doesn't exist, please check the documentation"
                  exit 1
                  ;;
                  *)
                  if [ -z "$infile" ]; then
                    infile=$1
                    if [ ! -f "$infile" ]; then
                      echo "Inputfile '$infile' doesn't exist. Please check."
                      exit 1
                    fi
                  else
                    if [ -z "$outfile" ]; then
                      outfile=$1
                    else
                      echo "Error: too many parameters. Inputfile and Outputfile already defined. Please check your command."
                      exit 1
                    fi
                  fi
                  shift
                  ;;
              esac
              done

        # Setup for verbose
              exec 3>&1
              exec 4>&2

              if ! $verbose; then
                exec 1>/dev/null
                exec 2>/dev/null
              fi

              if [ ! -z "$lockfile" ]; then

                echo "lockfile: $lockfile" 1>&3 2>&4
                while [[ -f "$lockfile" ]]; do
                  echo "Waiting" 1>&3 2>&4
                  sleep 5
                done

                touch "$lockfile"
              fi

              if [ ! -f "$comskipini" ]; then
                echo "output_edl=1" > "$comskipini"
              elif ! grep -q "output_edl=1" "$comskipini"; then
                echo "output_edl=1" >> "$comskipini"
              fi

              if [[ -z "$outfile" ]]; then
                outfile="$infile"
              fi

              outdir=$(dirname "$outfile")

              outextension="''${outfile##*.}"

              if [[ ! -z "$workdir" ]]; then
                case "$workdir" in
                  */)
                    ;;
                  *)
                    # PW: below is unused elsewhere...
                    #comskipoutput="--output=$workdir"
                    workdir="$workdir/"
                    ;;
                esac
              infileb=$(basename "$infile")
              edlfile="$workdir''${infileb%.*}.edl"
              metafile="$workdir''${infileb%.*}.ffmeta"
              logfile="$workdir''${infileb%.*}.log"
              logofile="$workdir''${infileb%.*}.logo.txt"
              txtfile="$workdir''${infileb%.*}.txt"
              else
              edlfile="$workdir''${infile%.*}.edl"
              metafile="$workdir''${infile%.*}.ffmeta"
              logfile="$workdir''${infile%.*}.log"
              logofile="$workdir''${infile%.*}.logo.txt"
              txtfile="$workdir''${infile%.*}.txt"
              fi

              if [ ! -f "$edlfile" ]; then
                $comskipPath --ini="$comskipini" "$infile"

                if [ ! -f "$edlfile" ] ; then
                  echo "Error running comskip. EDL File not found: $infile"  1>&3 2>&4 >&2
                  exitcode=-1
                fi
              fi

              start=0
              i=0
              hascommercials=false

              echo ";FFMETADATA1" > "$metafile"
              # Reads in from $edlfile, see end of loop.
              while IFS=$'\t' read -r -a line
              do
                ((i++))

                end=$(awk -vp="''${line[0]}" 'BEGIN{printf "%.0f" ,p*1000}')
                startnext=$(awk -vp="''${line[1]}" 'BEGIN{printf "%.0f" ,p*1000}')
                hascommercials=true

              { echo "[CHAPTER]"
                echo "TIMEBASE=1/1000"
                echo "START=$start"
                echo "END=$end"
                echo "title=Chapter $i"

                echo "[CHAPTER]"
                echo "TIMEBASE=1/1000"
                echo "START=$end"
                echo "END=$startnext"
                echo "title=Commercial $i"
              } >> "$metafile"

                start=$startnext
              done < "$edlfile"

              if $hascommercials ; then
                ((i++))
              { echo "[CHAPTER]"
                echo "TIMEBASE=1/1000"
                echo "START=$start"
                echo END="$($ffmpegPath -i "$infile" 2>&1 | grep Duration | awk '{print $2}' | tr -d , | awk -F: '{ print ($1*3600)+($2*60)+$3 }' | awk '{printf "%.0f",$1*1000}')"
                echo "title=Chapter $i"
              } >> "$metafile"

                if [ "$infile" -ef "$outfile" ] ; then

                  tempfile=$(mktemp --suffix=."$outextension" "$outdir"/XXXXXXXX)

                  echo "Writing file to temporary file: $tempfile"
                  if $ffmpegPath -loglevel error -hide_banner -nostdin -i "$infile" -i "$metafile" -map_metadata 1 -codec copy -y "$tempfile" 1>&3 2>&4; then
                    mv -f "$tempfile" "$outfile"
                    echo Saved to: "$outfile"
                  else
                    echo "Error running ffmpeg: $infile" 1>&3 2>&4 >&2
                    exitcode=-1
                  fi
                else
                  if $ffmpegPath -loglevel error -hide_banner -nostdin -i "$infile" -i "$metafile" -map_metadata 1 -codec copy -y "$outfile" 1>&3 2>&4; then
                    echo "Saved to: $outfile"
                  else
                    echo "Error running ffmpeg: $infile" 1>&3 2>&4 >&2
                    exitcode=-1
                  fi
                fi

                if [ ! -f "$outfile" ]; then
                  echo "Error, $outfile does not exist." 1>&3 2>&4 >&2
                  exitcode=-1
                fi
              else
                echo "No commercials found: $infile" 1>&3 2>&4 >&2
              fi

              if [ "$deleteedl" == true ] ; then
                if [ -f "$edlfile" ] ; then
                  rm "$edlfile";
                fi
              fi

              if [ "$deletemeta" == true ] ; then
                if [ -f "$metafile" ]; then
                  rm "$metafile";
                fi
              fi

              if [ "$deletelog" == true ] ; then
                if [ -f "$logfile" ]; then
                  rm "$logfile";
                fi
              fi

              if [ "$deletelogo" == true ] ; then
                if [ -f "$logofile" ]; then
                  rm "$logofile";
                fi
              fi

              if [ "$deletetxt" == true ] ; then
                if [ -f "$txtfile" ]; then
                  rm "$txtfile";
                fi
              fi

              if [ ! -z "$ldPath" ] ; then
                #re-set LD_LIBRARY_PATH
                export LD_LIBRARY_PATH="$ldPath"
              fi

              if [ ! -z "$lockfile" ]; then
                rm "$lockfile"
              fi

              exit $exitcode
        '';
      };
    in {
      environment.systemPackages = [
        comchap
      ];
    });
  };
}
