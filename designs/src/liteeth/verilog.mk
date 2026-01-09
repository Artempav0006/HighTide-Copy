ROOT_DIR := $(shell git rev-parse --show-toplevel)

-include $(ROOT_DIR)/settings.mk

export LITEETH_DIR=$(BENCH_DESIGN_HOME)/src/liteeth

export PLATFORM_DESIGN_DIR=$(BENCH_DESIGN_HOME)/$(PLATFORM)/$(DESIGN_NICKNAME)

export YML_PATH=$(LITEETH_DIR)/dev/repo/examples

export TARGET_FILE=$(LITEETH_DIR)/dev/$(DESIGN_NAME).v

export GDS_ALLOW_EMPTY:=fakeram*

export BUILD_DIR_NAME:=liteeth_builds

define build
TARGET_YML := $(strip $(1))
PATCH_FILE := $(strip $(2))

YML_FILE_PATH := $$(LITEETH_DIR)/dev/repo/examples/$(TARGET_YML)

$$(TARGET_FILE): $$(YML_FILE_PATH)
	@echo "Starting Generation for $(DESIGN_NAME)..."
	bash "$(LITEETH_DIR)/gen.sh" "$$(TARGET_YML)"
	@echo "Applying patch $(PATCH_FILE)..."
	patch --silent -N -l "$$(TARGET_FILE)" < "$(LITEETH_DIR)/patch/$$(PATCH_FILE)"
	@echo "Converting to ASIC for $(DESIGN_NAME)..."
endef

ifeq ($(PLATFORM),asap7)
    VERILOG_DEFINES = -D USE_ASAP7_CELLS
else ifeq ($(PLATFORM),nangate45)
    VERILOG_DEFINES = -D USE_NANGATE45_CELLS
else ifeq ($(PLATFORM),sky130hd)
    VERILOG_DEFINES = -D USE_SKY130HD_CELLS
endif

ifeq ($(USE_XILINX),1)
    VERILOG_FILES += \
        $(LITEETH_DIR)/libraries/xilinx/BUFG.v \
        $(LITEETH_DIR)/libraries/xilinx/BUFG_GT.v \
        $(LITEETH_DIR)/libraries/xilinx/BUFH.v \
        $(LITEETH_DIR)/libraries/xilinx/FDCE.v \
        $(LITEETH_DIR)/libraries/xilinx/FDPE.v \
        $(LITEETH_DIR)/libraries/xilinx/GTHE4_CHANNEL_DUMMY.v \
        $(LITEETH_DIR)/libraries/xilinx/GTPE2_CHANNEL_DUMMY.v \
        $(LITEETH_DIR)/libraries/xilinx/GTPE2_COMMON_DUMMY.v \
        $(LITEETH_DIR)/libraries/xilinx/IBUF.v \
        $(LITEETH_DIR)/libraries/xilinx/IDDR.v \
        $(LITEETH_DIR)/libraries/xilinx/IDELAYE2.v \
        $(LITEETH_DIR)/libraries/xilinx/MMCME2_DUMMY.v \
        $(LITEETH_DIR)/libraries/xilinx/OBUF.v \
        $(LITEETH_DIR)/libraries/xilinx/ODDR.v \
        $(LITEETH_DIR)/libraries/xilinx/PLLE2_DUMMY.v
else ifeq ($(USE_LATTICE),1)
    VERILOG_FILES += \
        $(LITEETH_DIR)/libraries/lattice/DELAYG.v \
        $(LITEETH_DIR)/libraries/lattice/FD1S3BX.v \
        $(LITEETH_DIR)/libraries/lattice/TRELLIS_IO.v \
        $(LITEETH_DIR)/libraries/lattice/IDDRX1F.v \
        $(LITEETH_DIR)/libraries/lattice/ODDRX1F.v
endif

VERILOG_FILES += $(TARGET_FILE) $(LITEETH_DIR)/macros.v

export VERILOG_DEFINES
export VERILOG_FILES
