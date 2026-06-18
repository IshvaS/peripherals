# Timer Peripheral Verification Testbench

This repository contains a SystemVerilog class-based verification environment built to test our **Timer Peripheral** via an APB interface.

---

## 📂 Project Structure

The testbench is organized into three distinct directories to separate the protocol layer, the test scenarios, and the hardware wrapper:

```text
├── apb/
│   ├── apb_if.sv          # APB physical interface & clocking blocks (drv_cb, mon_cb)
│   └── apb_driver.sv      # APB Master Driver (translates software transactions to pin wiggles)
│
├── tests/
│   ├── timer_base_test.sv # Base test class (contains shared properties, check() task, and static counters)
│   ├── reset_test.sv      # Verifies DUT behavior during and after hardware resets
│   ├── rw_test.sv         # Basic register read/write verification
│   ├── timer_func_test.sv # Verifies fundamental timer counting operations
│   ├── cmp_match_test.sv  # Verifies timer reset on compare match values
│   ├── overflow_test.sv   # Verifies timer overflow behaviour
│   ├── regression.sv      # Test runner that executes all test suites in a randomized sequence
│   └── report_summary.sv  # Handles formatting and printing the final pass/fail results
│
└── top/
    └── tb_timer.sv        # Top-level testbench module (generates clocks, instantiates DUT/Interface, starts tests)