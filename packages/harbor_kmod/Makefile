# Harbor Linux kernel modules
#
# Build out-of-tree:
#   make KDIR=/path/to/linux
#
# Build for installed kernel:
#   make
#
# Install:
#   make install

KDIR ?= /lib/modules/$(shell uname -r)/build

obj-m += gpio/harbor_gpio.o
obj-m += spi/harbor_spi.o
obj-m += i2c/harbor_i2c.o
obj-m += sdio/harbor_sdhci.o
obj-m += dma/harbor_dma.o
obj-m += pwm/harbor_pwm.o
obj-m += watchdog/harbor_wdt.o
obj-m += ethernet/harbor_eth.o
obj-m += usb/harbor_usb.o
obj-m += display/harbor_display.o
obj-m += pmu/harbor_pmu.o
obj-m += pcie/harbor_pcie.o
obj-m += hwmon/harbor_temp.o
obj-m += media/harbor_media.o
obj-m += audio/harbor_audio.o

all:
	$(MAKE) -C $(KDIR) M=$(PWD) modules

clean:
	$(MAKE) -C $(KDIR) M=$(PWD) clean

install:
	$(MAKE) -C $(KDIR) M=$(PWD) modules_install

.PHONY: all clean install
