# Synthesis export

`QR_decomp_syn.v` is the archived mapped design connectivity. It defines the QR top, CORDIC, multiplier, divider and back-substitution hierarchy and references external cells by name. The CORDIC port width is 22 bits in this export. The 25-bit behavioral RTL testbench checks a different elaboration.

The accompanying source RTL on the lab server matches the checked-in source (SHA-256 `a7259450fdbb5965409f2af872726810cd652b9e4f7ef2f5748b1843552697d7`). The netlist hash is `d9dc26a9edddb4df841b9a2f8e3f67617424c55b92bcee52be70f2e53f311cf3`. To inspect the gate-level design in a circuit simulator, use the matching cell models in the authorized lab environment.

## Companion artifacts on the lab server

| Artifact | SHA-256 |
| --- | --- |
| QR_decomp_syn.sdf | fb9e62fd9dd66a0d2fd9bf2b37699cceb101d081aa8534a3fc88482f96a1a1a4 |
| QR_decomp_syn.ddc | 59f955bdc1caf0a81b82685cc81c13b192dbb4cbe4b868bd4da538dd75b72349 |

These files are part of the same server export. The checked-in constraints document the synthesis target; the RTL regression uses behavioral delays.
