import 'package:rohd/rohd.dart';
import 'package:rohd_bridge/rohd_bridge.dart';

/// Hardware performance event types.
enum HarborHpmEvent {
  /// No event (counter disabled).
  none,

  /// Clock cycles.
  cycles,

  /// Instructions retired.
  instret,

  /// L1I cache misses.
  l1iMiss,

  /// L1D cache misses.
  l1dMiss,

  /// L1D cache writebacks.
  l1dWriteback,

  /// L2 cache misses.
  l2Miss,

  /// Branch mispredictions.
  branchMispredict,

  /// Branch instructions retired.
  branchRetired,

  /// TLB misses (instruction).
  itlbMiss,

  /// TLB misses (data).
  dtlbMiss,

  /// Load instructions retired.
  loadRetired,

  /// Store instructions retired.
  storeRetired,

  /// AMO instructions retired.
  amoRetired,

  /// CSR instructions retired.
  csrRetired,

  /// Pipeline stall cycles (front-end).
  stallFrontend,

  /// Pipeline stall cycles (back-end).
  stallBackend,

  /// Interrupt taken.
  interruptTaken,

  /// Exception taken.
  exceptionTaken,

  /// Page table walks.
  pageTableWalk,
}

/// RISC-V Hardware Performance Monitor counters.
///
/// Implements mhpmcounter3-mhpmcounter31 and mhpmevent3-mhpmevent31
/// CSRs. Each counter can be configured to count a specific event
/// type via its corresponding event selector register.
///
/// Also provides the mandatory mcycle and minstret counters.
///
/// The counter values are exposed both via CSR access (for the CPU)
/// and via a bus interface (for external monitoring / PMU driver).
class HarborHpmCounters extends BridgeModule {
  /// Number of configurable HPM counters (max 29: hpmcounter3-31).
  final int numCounters;

  /// Counter width (32 or 64 bits).
  final int counterWidth;

  /// Supported events.
  final List<HarborHpmEvent> supportedEvents;

  HarborHpmCounters({
    this.numCounters = 8,
    this.counterWidth = 64,
    this.supportedEvents = const [
      HarborHpmEvent.cycles,
      HarborHpmEvent.instret,
      HarborHpmEvent.l1iMiss,
      HarborHpmEvent.l1dMiss,
      HarborHpmEvent.branchMispredict,
      HarborHpmEvent.itlbMiss,
      HarborHpmEvent.dtlbMiss,
      HarborHpmEvent.stallFrontend,
      HarborHpmEvent.stallBackend,
    ],
    super.name = 'hpm',
  }) : super('HarborHpmCounters') {
    assert(numCounters >= 1 && numCounters <= 29);

    createPort('clk', PortDirection.input);
    createPort('reset', PortDirection.input);

    // Fixed counters
    addOutput('mcycle', width: counterWidth);
    addOutput('minstret', width: counterWidth);

    // Configurable counters
    for (var i = 0; i < numCounters; i++) {
      addOutput('hpmcounter${i + 3}', width: counterWidth);
    }

    // Event inputs from pipeline
    for (final event in HarborHpmEvent.values) {
      if (event != HarborHpmEvent.none) {
        createPort('event_${event.name}', PortDirection.input);
      }
    }

    // CSR interface
    createPort('csr_addr', PortDirection.input, width: 12);
    createPort('csr_write', PortDirection.input);
    createPort('csr_wdata', PortDirection.input, width: 64);
    addOutput('csr_rdata', width: 64);

    // Counter inhibit (mcountinhibit CSR)
    createPort('countinhibit', PortDirection.input, width: 32);

    final clk = input('clk');
    final reset = input('reset');

    // mcycle counter
    final mcycle = Logic(name: 'mcycle_reg', width: counterWidth);

    // minstret counter
    final minstret = Logic(name: 'minstret_reg', width: counterWidth);
    createPort(
      'retire_valid',
      PortDirection.input,
    ); // instruction retired this cycle

    // HPM counters and event selectors
    final counters = <Logic>[
      for (var i = 0; i < numCounters; i++)
        Logic(name: 'hpmcounter${i + 3}_reg', width: counterWidth),
    ];
    final events = <Logic>[
      for (var i = 0; i < numCounters; i++)
        Logic(name: 'hpmevent${i + 3}_reg', width: 64),
    ];

    output('mcycle') <= mcycle;
    output('minstret') <= minstret;
    for (var i = 0; i < numCounters; i++) {
      output('hpmcounter${i + 3}') <= counters[i];
    }

    Sequential(clk, [
      If(
        reset,
        then: [
          mcycle < Const(0, width: counterWidth),
          minstret < Const(0, width: counterWidth),
          for (final c in counters) c < Const(0, width: counterWidth),
          for (final e in events) e < Const(0, width: 64),
        ],
        orElse: [
          // mcycle: always counts unless inhibited
          If(~input('countinhibit')[0], then: [mcycle < mcycle + 1]),

          // minstret: counts retired instructions
          If(
            ~input('countinhibit')[2] & input('retire_valid'),
            then: [minstret < minstret + 1],
          ),

          // Configurable counters: count based on event selector
          for (var i = 0; i < numCounters; i++) ...[
            If(
              ~input('countinhibit')[i + 3],
              then: [
                // Match event selector against event inputs
                for (var j = 0; j < HarborHpmEvent.values.length; j++)
                  if (HarborHpmEvent.values[j] != HarborHpmEvent.none)
                    If(
                      events[i].getRange(0, 8).eq(Const(j, width: 8)) &
                          input('event_${HarborHpmEvent.values[j].name}'),
                      then: [counters[i] < counters[i] + 1],
                    ),
              ],
            ),
          ],

          // CSR writes (event selector registers)
          If(
            input('csr_write'),
            then: [
              for (var i = 0; i < numCounters; i++)
                // mhpmevent3 = 0x323, mhpmevent4 = 0x324, ...
                If(
                  input('csr_addr').eq(Const(0x323 + i, width: 12)),
                  then: [events[i] < input('csr_wdata')],
                ),
            ],
          ),
        ],
      ),
    ]);

    // CSR read mux
    final csrAddr = input('csr_addr');
    Logic csrRdata = Const(0, width: 64);

    // mcycle = 0xB00, minstret = 0xB02
    csrRdata = mux(
      csrAddr.eq(Const(0xB00, width: 12)),
      mcycle.zeroExtend(64),
      csrRdata,
    );
    csrRdata = mux(
      csrAddr.eq(Const(0xB02, width: 12)),
      minstret.zeroExtend(64),
      csrRdata,
    );

    // mhpmcounter3-31 = 0xB03-0xB1F
    for (var i = 0; i < numCounters; i++) {
      csrRdata = mux(
        csrAddr.eq(Const(0xB03 + i, width: 12)),
        counters[i].zeroExtend(64),
        csrRdata,
      );
    }

    // mhpmevent3-31 = 0x323-0x33F
    for (var i = 0; i < numCounters; i++) {
      csrRdata = mux(
        csrAddr.eq(Const(0x323 + i, width: 12)),
        events[i],
        csrRdata,
      );
    }

    output('csr_rdata') <= csrRdata;
  }
}
