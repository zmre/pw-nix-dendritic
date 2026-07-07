# Strix Halo NPU (XDNA2) on NixOS — status and revisit path

Decision (2026-07): **not configured**. Documented here so the path is ready
when it's worth revisiting.

## What the NPU is good for (and not)

The Ryzen AI Max+ 395 has an XDNA2 NPU (~50 TOPS). On Linux it can run LLM
inference, but only in NPU-only mode — the hybrid NPU-prefill + GPU-decode
flow is Windows-only. Decode throughput is ~4-5x slower than the 8060S iGPU
(~60 GB/s effective bandwidth vs ~256 GB/s), so it will never beat the iGPU
for the main llama.cpp server. Its real value:

- **Power**: ~2W vs 10-15W+ for small always-on models
- **Long-prompt prefill**: NPU prefill can beat GPU on long prompts
- **Concurrency sidecar**: Whisper/STT or a small utility model on the NPU
  costs the iGPU almost nothing (~3% latency impact vs ~69% for an
  equivalent iGPU sidecar)

## Why it's blocked on avalon today

1. **Kernel**: avalon runs 6.18. The in-tree `amdxdna` driver (mainline since
   6.14) speaks firmware protocol major 6, but current linux-firmware ships
   protocol-7 firmware (`amdnpu/17f0_11/npu.sbin` for Strix Halo) →
   "Incompatible firmware protocol major 7" mismatch. Needs kernel 7.0+ or
   AMD's out-of-tree DKMS module (github:amd/xdna-driver).
2. **IOMMU**: amdxdna requires the IOMMU on in passthrough mode (`iommu=pt`).
   `strix-halo-memory.nix` sets `amd_iommu=off` for ~6% GPU memory bandwidth
   — every NPU open() returns -ENODEV with that setting.
3. **Userspace**: nothing in nixpkgs (no XRT, no xrt-plugin-amdxdna). AMD's
   Ryzen AI Software Linux release does NOT support Strix Halo (STX-H) —
   only Strix Point/Krackan. The working Linux stack is FastFlowLM +
   Lemonade 10.0+ (confirmed working on Strix Halo by community reports).

## Community flakes (when revisiting)

- `github:noamsto/nix-amd-ai` — full stack: XRT + XDNA plugin + FastFlowLM +
  Lemonade, NixOS module with `enableNPU` toggle (kernel module, iommu=pt,
  udev, memlock). Tested on Strix Point/Strix Halo. Best starting point.
- `github:skitzo2000/nix-xdna` — out-of-tree amdxdna.ko + staging firmware
  (`hardware.amdnpu.enable`) for pre-7.0 kernels.
- `github:robcohen/nix-amd-npu` — nixpkgs-style XRT/plugin packaging with an
  explicit upstreaming path.

## Revisit triggers

- NixOS kernel ≥ 7.x on avalon (in-tree driver + firmware protocol aligned), AND
- willing to trade `amd_iommu=off` (~6% GPU bandwidth) for `iommu=pt`, AND
- a concrete sidecar use case (Whisper transcription, small always-on model)

Verify hardware once enabled: `/dev/accel/accel0` exists, dmesg shows
`Load firmware amdnpu/17f0_11/npu.sbin`, `flm validate` or `xrt-smi examine`.
