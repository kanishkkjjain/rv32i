# run_tests.py - run on WINDOWS (your conda Python), from PowerShell:
#   $env:Path += ";C:\AMDDesignTools\2025.2\Vivado\bin"   # once per window
#   cd C:\rv32i\rtl
#   (compile + elaborate first: xvlog ... ; xelab tb -s tb_sim)
#   python run_tests.py [HEX_DIR]
#
# Runs every hex in HEX_DIR through the tb_sim snapshot, prints one line
# per test and a summary. Full xsim output of each test goes to logs/.
import glob, os, re, subprocess, sys

HEX_DIR = sys.argv[1] if len(sys.argv) > 1 else "C:/rv32i/riscv-tests/isa/hex"
SIM_DIR = "C:/rv32i/rtl"
LOG_DIR = os.path.join(SIM_DIR, "logs")
os.makedirs(LOG_DIR, exist_ok=True)

results = []
for hexf in sorted(glob.glob(os.path.join(HEX_DIR, "*.hex"))):
    name = os.path.splitext(os.path.basename(hexf))[0]
    path = hexf.replace("\\", "/")
    # shell string with quotes so cmd.exe does not split on '='
    cmd = f'xsim tb_sim -R -testplusarg "HEX={path}"'
    r = subprocess.run(cmd, shell=True, cwd=SIM_DIR, capture_output=True, text=True)
    out = r.stdout + r.stderr
    with open(os.path.join(LOG_DIR, f"{name}.log"), "w") as f:
        f.write(out)
    m = re.search(r"^(PASS.*|FAIL.*|TIMEOUT.*)$", out, re.M)
    status = m.group(1).strip() if m else "NO RESULT - see log (sim error?)"
    results.append((name, status))
    print(f"{name:<10} {status}", flush=True)

passed = [n for n, s in results if s.startswith("PASS")]
failed = [n for n, s in results if not s.startswith("PASS")]
print(f"\n{len(passed)}/{len(results)} passed")
if failed:
    print("Failing:", ", ".join(failed))
