# Serving Qwen3.8-Flash-Next on Strix Halo: engine comparison

Written 2026-10-05 after a week of testing on avalon (Framework Desktop,
Ryzen AI Max+ 395, Radeon 8060S / gfx1151, 128 GB unified memory, kernel
6.18.44, ROCm 7.2.3 from nixpkgs, Mesa RADV). Raw runs and the harness live in
`~/bench` on avalon (`RESULTS.md`, `bench.py`, `run-llama.sh`, `run-gufo.sh`,
`chain.sh`, `results/*.jsonl`).

## TL;DR

| Engine                                   | Status            | pp tok/s | tg tok/s | Verdict |
|------------------------------------------|-------------------|---------:|---------:|---------|
| llama.cpp 0.5.0 router (Vulkan)          | was production    |  380-450 |    24-27 | Flexible, slow prefill |
| llama.cpp master + MTP (Vulkan)          | crashes at load   |        - |        - | Wait for a Vulkan fix |
| **Gufo + MTP (HIP)**                     | **now production**|**~1200** |**33-47** | 2.7x prefill, 1.3-1.9x decode |
| Unsloth Desktop runtime                  | not tested        |        - |        - | Nothing a stock llama-server lacks except MTP |
| Strata                                   | not tested        |        - |        - | gfx1151 only via unmerged PR; no unified-memory edge |
| halogen-flash-server                     | not tested        |        - |  40-50*  | Candidate for a later round |

`*` user-reported on gfx1151, not measured here.

Gufo replaced the llama.cpp router on avalon (`modules/services/gufo.nix`,
Caddy on 8086, model name `qwen38-flash-next`). The router module
(`llamacpp-gemma.nix`) is commented out in `hosts/avalon.nix`, not deleted.

## Method

Single stream, greedy (`temperature 0`), thinking off, OpenAI
`/v1/completions` with SSE streaming, measured from the client; the servers'
own `timings` agreed within 5%. Two tables per engine: pp2048 / tg128
(Gufo's own methodology) and pp8k / tg128. Median of 3 runs after 1 warmup. A
unique prefix per run defeats prompt caching. Prompt text is a repeated zsh man
page, which is repetitive and inflates MTP draft acceptance on the 8k table.

llama.cpp flags: `-ngl 999 -c 262144 -fa on --load-mode mmap --lazy-mode on
-b 1024 -ub 512`. Gufo flags: `--sessions 1 --context 32768 --think off`
(also re-run at `--context 262144` and `--sessions 2` with identical pp and a
10% decode cost at 2 sessions).

## Results

### Unsloth UD-Q4_K_XL (111 GB, 4 shards; the only quant every engine loads)

| Engine                                  | pp2048 | tg128 | pp8k | tg128 | load  | GPU mem |
|-----------------------------------------|-------:|------:|-----:|------:|------:|--------:|
| llama.cpp master c061df1, Vulkan, AR    |    445 |  24.3 |  454 |  24.5 | 173 s | ~110 GB |
| llama.cpp master + MTP                  |  crash |     - |crash |     - |     - |       - |
| Gufo 23cacbb, AR                        |   1228 |  25.1 | 1260 |  25.0 |  12 s | ~101 GB |
| Gufo 23cacbb, MTP shared-Q8_0 head      |   1202 |  33.0 | 1224 |  46.7 |  17 s | ~101 GB |
| Gufo, ctx 262144, 1 session, MTP        |   1189 |  34.5 | 1206 |  45.6 |  16 s | ~101 GB |
| Gufo, ctx 262144, 2 sessions, MTP       |   1195 |  31.3 | 1187 |  40.1 |  13 s | ~101 GB |

Gufo MTP draft acceptance: 58-65% on the 2k prose prompt, 77-79% on the
repetitive 8k prompt. Expect the low end in real use.

### ISTA-DASLab GSQ-RCO IQ3_S (84 GB, 2 shards, n-gram table lazy-mmapped)

| Engine                                  | pp2048 | tg128 | pp8k | tg128 |
|-----------------------------------------|-------:|------:|-----:|------:|
| llama.cpp 0.5.0 router (production)     |    379 |  26.0 |  389 |  24.9 |
| llama.cpp master c061df1, AR            |    372 |  27.0 |  378 |  26.0 |
| llama.cpp master + MTP                  |  crash |     - |crash |     - |
| Gufo                                    | refuses the file ("unsupported storage type: ffn_gate_exps") |

## Findings per engine

### llama.cpp (nixpkgs 0.5.0 and master c061df1)

- Vulkan/RADV beats the tuned ROCm build on this box for Qwen3.6-27B
  (see `llamacpp-packages.nix`); Flash-Next was only run on Vulkan.
- master without MTP matches 0.5.0 within noise, so a nixpkgs bump alone buys
  nothing.
- Router mode (`--models-preset`) adds no measurable overhead and gives
  on-demand multi-model loading, HF auto-download, and the full llama-server
  API (`/tokenize`, `/slots`, embeddings). None of the other engines offer
  that.
- Loading 110 GB into Vulkan device buffers takes ~3 minutes every restart.
- Qwen4Exp MTP (PR #29761, merged 2026-10-01) aborts at load with
  `GGML_ASSERT(buffer)` in `llama_model_qwen4exp::llm_graph_input_kpool::
  set_input` on both quants, with any of `--parallel 1`, `--lazy-mode off`,
  `-fa off`, draft depth 1-3. The Unsloth "shared" MTP head cannot load on
  mainline (`token_embd.weight` not found); the non-shared head loads but
  then hits the assert. Upstream validated on CUDA only. Retry on a HIP build
  or after the next release. Module: `llamacpp-mtp.nix` (off).

### Gufo (github:gufo-org/gufo, MIT, C++/HIP)

- Purpose-built for gfx1151. Builds in ~2-4 min from its own flake with
  `nixpkgs.follows`; `gufo diagnose` passes on ROCm 7.2.3 / kernel 6.18.
- 2.7x llama.cpp prefill, decode parity without MTP, 1.3-1.9x with MTP. Loads
  in ~15 s because it maps the shards instead of copying them.
- One model per process, no router, no embeddings endpoint, no `/tokenize`.
  OpenAI `/v1/chat/completions`, `/v1/completions`, `/v1/models`, `/health`,
  and Anthropic-style `/v1/messages`. Returns llama-style `timings`.
- Only qualified on Unsloth UD-Q4_K_XL for this model. No IQ3_S kernels, so
  the ISTA quants are out.
- Full native context (262144) with 2 sessions fits: 101 GB GPU, ~18 GB host
  headroom. That leaves no room for a second large model alongside it.

### Unsloth runtime (research only)

- "Unsloth Desktop" is a GUI wrapping their llama.cpp fork; official gfx1151
  support per AMD. No Nix packaging. Their quants already run on stock
  llama-server, so the runtime's only unique value was Qwen4Exp MTP, which is
  now in mainline (and broken on Vulkan, see above). Not worth packaging.

### Strata (github:Niko1221/Strata, MIT; research only)

- ggml-derived engine whose core idea is splitting experts between a 12-24 GB
  card, pinned host RAM, and SSD. Supports the ISTA GSQ quants natively plus
  MTP. Discrete RDNA cards only on main; a maintainer called it "not really
  aimed or scoped for unified memory architectures like gfx1151" and pointed
  at Gufo (issue #612).
- PR #895 (unmerged, 2026-10-05) adds Linux gfx1151. It needs ROCm 7.13+ or
  the 7.17 nightly, newer than nixpkgs. Running by hand also means converting
  GGUFs into Strata's pack format (+55 GB), preparing the MTP runtime with
  three tools, and a Python serving wrapper. Not attempted.
- gfx1151 users on that PR report, with every expert forced into the GPU
  pool: UD-Q4_K_XL 34-48 tok/s decode, UD-IQ4_XS 43-45, prefill 655 tok/s at
  244K depth. The default split layout halves decode there (25-28). So on
  this box it would at best tie Gufo on decode and likely trail on prefill,
  with quant choice (IQ3_S, Q2_0) as its one advantage. Revisit after merge.

### halogen-flash-server (github:peonist-ai/halogen-flash-server; not examined)

- "The fastest way to run Qwen3.8-Flash-Next on Strix Halo." A gfx1151 user
  reports 40-50 tok/s. Shell-based launcher; backend unknown. Worth a round
  if Gufo disappoints in daily use.

## Recommendation and current state

- **Daily driver: Gufo with MTP on UD-Q4_K_XL** (enabled on avalon, port 8086,
  model `qwen38-flash-next`, 2 sessions, full context).
- **Go back to the router** when multi-model switching, embeddings, or the
  ISTA quant matter more than speed: flip the two comment markers in
  `hosts/avalon.nix` and `LLAMA_CPP_HOST` back to 8082.
- **Re-check llama.cpp MTP** at the next nixpkgs llama-cpp bump; if it works on
  Vulkan, the router regains the decode gap and keeps its flexibility.
- **Memory rule:** only one of `llamacpp-gemma`, `llamacpp-mtp`, `gufo` at a
  time; each wants ~100-110 GB of the 128 GB.

## Operational notes learned the hard way

- llama.cpp 0.5.0 removed `--no-mmap`; presets must use `load-mode`. An
  unknown preset key kills the whole router at startup.
- `/var/cache/private` must stay 0700. Loosening it to read a DynamicUser
  cache made every unit with `CacheDirectory=` fail at the next switch.
- ZFS ARC shows as "used" in `free` after large downloads; it is reclaimed
  under pressure and is not a leak.
- The Gufo binary is not a system dependency until the module is enabled, so
  `nix-collect-garbage` removes it between experiments; rebuild takes ~2 min.
