{
  lib,
  stdenv,
  flakever,
  kernel,
  kernelModuleMakeFlags,
}:
stdenv.mkDerivation {
  pname = "harbor-kmod";
  inherit (flakever) version;

  src = lib.fileset.toSource {
    root = ../../packages/harbor_kmod;
    fileset = lib.fileset.unions [
      ../../packages/harbor_kmod/Makefile
      ../../packages/harbor_kmod/gpio
      ../../packages/harbor_kmod/spi
      ../../packages/harbor_kmod/i2c
      ../../packages/harbor_kmod/sdio
      ../../packages/harbor_kmod/dma
      ../../packages/harbor_kmod/pwm
      ../../packages/harbor_kmod/watchdog
      ../../packages/harbor_kmod/ethernet
      ../../packages/harbor_kmod/usb
      ../../packages/harbor_kmod/display
      ../../packages/harbor_kmod/pmu
      ../../packages/harbor_kmod/pcie
      ../../packages/harbor_kmod/hwmon
      ../../packages/harbor_kmod/media
      ../../packages/harbor_kmod/audio
      ../../packages/harbor_kmod/efuse
    ];
  };

  nativeBuildInputs = kernel.moduleBuildDependencies;

  makeFlags = kernelModuleMakeFlags ++ [
    "KDIR=${kernel.dev}/lib/modules/${kernel.modDirVersion}/build"
  ];

  installPhase = ''
    runHook preInstall
    install -D -t $out/lib/modules/${kernel.modDirVersion}/extra/harbor \
      gpio/harbor_gpio.ko \
      spi/harbor_spi.ko \
      i2c/harbor_i2c.ko \
      sdio/harbor_sdhci.ko \
      dma/harbor_dma.ko \
      pwm/harbor_pwm.ko \
      watchdog/harbor_wdt.ko \
      ethernet/harbor_eth.ko \
      usb/harbor_usb.ko \
      display/harbor_display.ko \
      pmu/harbor_pmu.ko \
      pcie/harbor_pcie.ko \
      hwmon/harbor_temp.ko \
      media/harbor_media.ko \
      audio/harbor_audio.ko \
      efuse/harbor_efuse.ko
    runHook postInstall
  '';

  meta = {
    description = "Linux kernel modules for Harbor SoC peripherals";
    homepage = "https://github.com/MidstallSoftware/harbor";
    license = lib.licenses.gpl2Plus;
    platforms = lib.platforms.linux;
  };
}
