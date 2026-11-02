"""Verify the candidate, then program one powered KU5P over JTAG."""
import subprocess
import sys
from sim_utils import B,R
from verify_candidate import verify

if __name__=='__main__':
    verify()
    subprocess.run([str(B/'vivado.bat'),'-mode','batch','-source',
                    str(R/'scripts/program_candidate.tcl'),
                    '-log',str(R/'reports/system_build/program.log'),
                    '-journal',str(R/'reports/system_build/program.jou'),
                    '-tclargs',sys.executable],cwd=R,check=True)
