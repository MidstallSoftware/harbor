# mkTapeout - ASIC tapeout flow: synthesis, PnR, GDS generation.
#
# Supports both flat and hierarchical (macro-based) flows.
# In hierarchical mode, specified modules are hardened as macros
# first, then assembled into the top-level chip.
#
# Usage:
#   harbor.mkTapeout {
#     name = "my-soc-tapeout";
#     ip = myIp;                  # Output of mkIp
#     topCell = "MySoC";
#     pdk = sky130-pdk;           # PDK package
#     cellLib = "sky130_fd_sc_hd";
#     clockPeriodNs = 20;
#     # Optional hierarchical hardening
#     macros = [ "RiverCore" "L2Cache" ];
#   }
#
# Outputs:
#   $out/<top>_final.def    - Routed layout (DEF)
#   $out/<top>_final.v      - Post-PnR netlist
#   $out/<top>.gds           - Final GDS (if KLayout available)
#   $out/macros/             - Per-macro artifacts (LEF, LIB, DEF, GDS)
#   $out/timing.rpt          - Timing report
#   $out/area.rpt            - Area report
#   $out/power.rpt           - Power report
{
  lib,
  stdenv,
  yosys,
  openroad,
  klayout,
}:

lib.extendMkDerivation {
  constructDrv = stdenv.mkDerivation;

  excludeDrvArgNames = [
    "ip"
    "topCell"
    "pdk"
    "cellLib"
    "clockPeriodNs"
    "coreUtilization"
    "macros"
    "macroUtilization"
    "macroHaloUm"
    "dieWidthUm"
    "dieHeightUm"
    "topRoutingMinLayer"
    "topPlacementDensity"
    "detailedRouteIter"
    "analogGdsPaths"
  ];

  extendDrvArgs =
    finalAttrs:
    {
      name ? "harbor-tapeout",
      ip,
      topCell ? "top",
      pdk,
      cellLib ? pdk.cellLib or "default",
      clockPeriodNs ? 20,
      coreUtilization ? 0.5,
      macros ? [ ],
      macroUtilization ? 0.6,
      macroHaloUm ? 10,
      dieWidthUm ? null,
      dieHeightUm ? null,
      topRoutingMinLayer ? 2,
      topPlacementDensity ? 0.5,
      detailedRouteIter ? 8,
      analogGdsPaths ? [ ],
      ...
    }@args:

    assert lib.assertMsg (clockPeriodNs > 0) "mkTapeout: clockPeriodNs must be > 0";
    assert lib.assertMsg (
      coreUtilization > 0.0 && coreUtilization <= 1.0
    ) "mkTapeout: coreUtilization must be in (0, 1]";

    let
      isHierarchical = macros != [ ];

      pdkPath = "${pdk}/${pdk.pdkPath or ""}";
      libsRef = "${pdkPath}/libs.ref/${cellLib}";

      # Build a single macro
      mkMacro =
        macroModule:
        stdenv.mkDerivation {
          name = "harbor-macro-${lib.toLower macroModule}-${topCell}";

          dontUnpack = true;
          dontConfigure = true;

          nativeBuildInputs = [
            yosys
            openroad
          ];

          buildPhase = ''
            runHook preBuild

            LIB_FILE=$(find ${libsRef}/lib -name '*tt*' -name '*.lib' -print -quit 2>/dev/null)
            if [ -z "$LIB_FILE" ]; then
              LIB_FILE=$(find ${libsRef}/lib -name '*.lib' -print -quit)
            fi
            TECH_LEF=$(find ${libsRef}/lef -name '*tech*.lef' -print -quit)

            echo "=== Synthesizing macro: ${macroModule} ==="
            if [ -f "${ip}/macros/${macroModule}_synth.tcl" ]; then
              SV_FILE=$(find ${ip}/rtl -name '*.sv' -print -quit 2>/dev/null || find ${ip} -name '*.sv' -print -quit)
              export SV_FILE LIB_FILE
              yosys -c ${ip}/macros/${macroModule}_synth.tcl 2>&1 | tee yosys.log
            fi

            echo "=== PnR macro: ${macroModule} ==="
            if [ -f "${ip}/macros/${macroModule}_pnr.tcl" ] && [ -f "${macroModule}_synth.v" ]; then
              export LIB_FILE TECH_LEF
              export CELL_LEF_DIR="${libsRef}/lef"
              export SITE_NAME="${pdk.siteName or "unit"}"
              export TILE_UTIL="${toString macroUtilization}"
              openroad -threads $NIX_BUILD_CORES -exit ${ip}/macros/${macroModule}_pnr.tcl \
                2>&1 | tee openroad.log
            fi

            runHook postBuild
          '';

          installPhase = ''
            runHook preInstall
            mkdir -p $out
            cp ${macroModule}_synth.v $out/ 2>/dev/null || true
            cp ${macroModule}_final.def $out/ 2>/dev/null || true
            cp ${macroModule}.lef $out/ 2>/dev/null || true
            cp ${macroModule}.lib $out/ 2>/dev/null || true
            cp ${macroModule}_timing.rpt $out/ 2>/dev/null || true
            cp ${macroModule}_area.rpt $out/ 2>/dev/null || true
            cp yosys.log $out/ 2>/dev/null || true
            cp openroad.log $out/ 2>/dev/null || true
            runHook postInstall
          '';
        };

      macroDerivations = builtins.listToAttrs (
        map (mod: {
          name = mod;
          value = mkMacro mod;
        }) macros
      );

      # Top-level synthesis
      topSynth = stdenv.mkDerivation {
        name = "harbor-top-synth-${topCell}";

        dontUnpack = true;
        dontConfigure = true;

        nativeBuildInputs = [ yosys ];

        buildPhase = ''
          runHook preBuild

          LIB_FILE=$(find ${libsRef}/lib -name '*tt*' -name '*.lib' -print -quit 2>/dev/null)
          if [ -z "$LIB_FILE" ]; then
            LIB_FILE=$(find ${libsRef}/lib -name '*.lib' -print -quit)
          fi

          SV_FILE=$(find ${ip}/rtl -name '*.sv' -print -quit 2>/dev/null || find ${ip} -name '*.sv' -print -quit)
          export SV_FILE LIB_FILE

          ${lib.optionalString isHierarchical ''
            # Provide stubs for blackboxed macros
            export STUBS_V="${ip}/stubs.v"
          ''}

          echo "=== Top-level synthesis ==="
          yosys -c ${ip}/synth.tcl 2>&1 | tee yosys.log

          runHook postBuild
        '';

        installPhase = ''
          runHook preInstall
          mkdir -p $out
          cp ${topCell}_synth.v $out/ 2>/dev/null || true
          cp yosys.log $out/ 2>/dev/null || true
          runHook postInstall
        '';
      };

      # Top-level PnR
      topPnr = stdenv.mkDerivation {
        name = "harbor-top-pnr-${topCell}";

        dontUnpack = true;
        dontConfigure = true;

        nativeBuildInputs = [ openroad ];

        buildPhase = ''
          runHook preBuild

          LIB_FILE=$(find ${libsRef}/lib -name '*tt*' -name '*.lib' -print -quit 2>/dev/null)
          if [ -z "$LIB_FILE" ]; then
            LIB_FILE=$(find ${libsRef}/lib -name '*.lib' -print -quit)
          fi
          TECH_LEF=$(find ${libsRef}/lef -name '*tech*.lef' -print -quit)

          ${lib.optionalString isHierarchical (
            lib.concatMapStringsSep "\n" (mod: ''
              cp ${macroDerivations.${mod}}/${mod}.lef . 2>/dev/null || true
              cp ${macroDerivations.${mod}}/${mod}.lib . 2>/dev/null || true
            '') macros
          )}

          cat > constraints.sdc << EOF
          create_clock [get_ports clk] -name clk -period ${toString clockPeriodNs}
          set_input_delay 0 -clock clk [all_inputs]
          set_output_delay 0 -clock clk [all_outputs]
          EOF

          echo "=== Top-level PnR ==="
          export LIB_FILE TECH_LEF
          export CELL_LEF_DIR="${libsRef}/lef"
          export SYNTH_V="${topSynth}/${topCell}_synth.v"
          export SDC_FILE="constraints.sdc"
          export SITE_NAME="${pdk.siteName or "unit"}"
          export UTILIZATION="${toString coreUtilization}"
          export MACRO_HALO="${toString macroHaloUm}"
          export PLACEMENT_DENSITY="${toString topPlacementDensity}"
          export DROUTE_END_ITER="${toString detailedRouteIter}"
          ${lib.optionalString (dieWidthUm != null && dieHeightUm != null) ''
            export DIE_AREA="0 0 ${toString dieWidthUm} ${toString dieHeightUm}"
          ''}

          openroad -threads $NIX_BUILD_CORES -exit ${ip}/pnr.tcl \
            2>&1 | tee openroad.log

          runHook postBuild
        '';

        installPhase = ''
          runHook preInstall
          mkdir -p $out
          cp ${topCell}_final.def $out/ 2>/dev/null || true
          cp ${topCell}_final.v $out/ 2>/dev/null || true
          cp timing.rpt $out/ 2>/dev/null || true
          cp area.rpt $out/ 2>/dev/null || true
          cp power.rpt $out/ 2>/dev/null || true
          cp openroad.log $out/ 2>/dev/null || true
          runHook postInstall
        '';
      };
    in
    builtins.removeAttrs args [
      "ip"
      "topCell"
      "pdk"
      "cellLib"
      "clockPeriodNs"
      "coreUtilization"
      "macros"
      "macroUtilization"
      "macroHaloUm"
      "dieWidthUm"
      "dieHeightUm"
      "topRoutingMinLayer"
      "topPlacementDensity"
      "detailedRouteIter"
      "analogGdsPaths"
    ]
    // {
      dontUnpack = true;
      dontConfigure = true;

      nativeBuildInputs = (args.nativeBuildInputs or [ ]) ++ [
        klayout
      ];

      buildPhase = ''
        runHook preBuild

        if [ -f "${topPnr}/${topCell}_final.def" ]; then
          echo "=== DEF to GDS ==="

          ${lib.optionalString isHierarchical ''
            mkdir -p macro_gds
            ${lib.concatMapStringsSep "\n" (mod: ''
              cp ${macroDerivations.${mod}}/${mod}_final.gds macro_gds/ 2>/dev/null || true
            '') macros}
          ''}

          if [ -f "${ip}/klayout/def2gds.py" ]; then
            QT_QPA_PLATFORM=offscreen \
            klayout -b -r ${ip}/klayout/def2gds.py 2>&1 | tee klayout.log || true
          fi

          ${lib.optionalString (analogGdsPaths != [ ]) ''
            echo "=== Merge analog GDS ==="
            if [ -f "${ip}/klayout/gds_merge.py" ]; then
              QT_QPA_PLATFORM=offscreen \
              klayout -b -r ${ip}/klayout/gds_merge.py 2>&1 | tee -a klayout.log || true
            fi
          ''}

          echo "=== DRC ==="
          if [ -f "${ip}/klayout/drc.py" ]; then
            QT_QPA_PLATFORM=offscreen \
            klayout -b -r ${ip}/klayout/drc.py 2>&1 | tee -a klayout.log || true
          fi
        fi

        runHook postBuild
      '';

      installPhase = ''
        runHook preInstall
        mkdir -p $out

        # Macro artifacts
        ${lib.optionalString isHierarchical ''
          mkdir -p $out/macros
          ${lib.concatMapStringsSep "\n" (mod: ''
            cp -r ${macroDerivations.${mod}}/* $out/macros/ 2>/dev/null || true
          '') macros}
        ''}

        # Top-level synthesis
        cp ${topSynth}/${topCell}_synth.v $out/ 2>/dev/null || true
        cp ${topSynth}/yosys.log $out/yosys.log 2>/dev/null || true

        # Top-level PnR
        cp ${topPnr}/${topCell}_final.def $out/ 2>/dev/null || true
        cp ${topPnr}/${topCell}_final.v $out/ 2>/dev/null || true
        cp ${topPnr}/timing.rpt $out/ 2>/dev/null || true
        cp ${topPnr}/area.rpt $out/ 2>/dev/null || true
        cp ${topPnr}/power.rpt $out/ 2>/dev/null || true
        cp ${topPnr}/openroad.log $out/ 2>/dev/null || true

        # GDS + verification
        cp ${topCell}.gds $out/ 2>/dev/null || true
        cp ${topCell}_merged.gds $out/ 2>/dev/null || true
        cp ${topCell}_drc.xml $out/ 2>/dev/null || true
        cp klayout.log $out/ 2>/dev/null || true

        runHook postInstall
      '';

      passthru = {
        inherit
          ip
          pdk
          cellLib
          topCell
          clockPeriodNs
          coreUtilization
          topSynth
          topPnr
          ;
        inherit (finalAttrs) name;
      }
      // lib.optionalAttrs isHierarchical {
        inherit macroDerivations;
      }
      // (args.passthru or { });
    };
}
