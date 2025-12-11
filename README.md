# unified local masking Radix-4 NTT/INTT

## Introduction
This design proposes a unified local mask Radix-4 NTT/INTT structure, which includes complete source code, testing platform, testing vectors, and vivado project files

## Catalogue
├── project_vivado           # The folder project_vivado stores Vivado project files. \
├── seed.txt                 # Test vector (coefficient).\
├── zetas.txt                # Twiddle factor.\
├── NTT_TOP.v                # Unified NTT/INTT architecture Top Level.\
├── OP_TSET_sca.v            # This module is mainly responsible for data scheduling (testing the unified NTT/INTT architecture).\
├── op_test_tb.v             # Testbench.\
├── PRNG.v                   # Generate pseudo-random numbers.\
└── other                    # Other design documents with a unified NTT/INTT architecture.

## Requirements
System: Windows 11\
Simulation and synthesis tool: Vivado 2018.3 \
Hardware description language: Verilog HDL

## Running simulation and synthesis
### Running simulation
1.Modify the BRAM file read address on line 27 of the file OP_TSET_sca.v, as well as the BRAM file read addresses on lines 105, 107, and 109 of the file NTT_TOP.v.\
2.Open Vivado 2018.3.\
3.Load project file: project-vivado/project-vivado.xpr.\
4.Set op_test_tb.v as the top-level simulation module.\
5.Simulation.\
6.Check the correctness of waveform verification function.\
<img width="1665" height="895" alt="9f706974b89c235da08593fcd347d3f5" src="https://github.com/user-attachments/assets/b0081f3e-50bc-44de-813c-4aa77aa10055" />
<img width="1618" height="837" alt="c7370e42cdcfb9a30858c21601e5e60b" src="https://github.com/user-attachments/assets/e11adc4c-672b-4a15-90c8-82e575035fe7" />
<img width="1629" height="850" alt="5234477cdbd3f23385f167f165986762" src="https://github.com/user-attachments/assets/e7c4c624-3c89-4417-8a00-eee91c51ccbb" />

### Running synthesis
1.Modify the BRAM file read address on line 27 of the file OP_TSET_sca.v, as well as the BRAM file read addresses on lines 105, 107, and 109 of the file NTT_TOP.v.\
2.Set NTT_TOP.v as the top-level.\
3.Remove the 23rd line of the NTT_TOP.v code and add the 49th line. The purpose of this operation is to integrate the area of NTT.\
4.View resource utilization report.
<img width="1378" height="635" alt="ae40e1669c9b3a9fa1d33d61c5270b8f" src="https://github.com/user-attachments/assets/60fea53a-29ef-4aaf-8c8a-0a1edb268b16" />
<img width="1650" height="265" alt="e3f1c38661a57d73ca6c79c02238995e" src="https://github.com/user-attachments/assets/bd15118b-22d0-460b-869c-b3d9cc28dc0e" />

