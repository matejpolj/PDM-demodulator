# PDM-demodulator
## VHDL implementacion of PDM demodulator

Implementation of PDM demodulator for master's thesis.  
Implementation uses two different second stage demodulation filters, first architecture uses three FIR halfband filters and second uses FIR filter with decimation factor 8.

CIC filter used as first stage is added as submodule and requires addin files to source manually.
