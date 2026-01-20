# LiteEth Cores

## Quick Start

### Setup & Generate Cores
Setup repo in `designs/src/liteeth` with:
```bash
./setup.sh
```

Then run:
```bash
make DESIGN_CONFIG=designs/nangate45/liteeth/<DESIGN_NAME>/config.mk
```

### Run ASIC Flow
```bash
make DESIGN_CONFIG=designs/nangate45/liteeth/<DESIGN>/config.mk

make DESIGN_CONFIG=designs/nangate45/liteeth/liteeth_mac_axi_mii/config.mk

```

---

## Generated Cores

- liteeth_mac_axi_mii
- liteeth_mac_wb_mii
- liteeth_udp_stream_sgmii
- liteeth_udp_stream_rgmii
- liteeth_udp_raw_rgmii
- liteeth_udp_usp_gth_sgmii
