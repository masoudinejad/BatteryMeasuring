# Battery measuring 
These are a set of programs which can be used to measure batteries with high accuracy.
Main focus is on measurments for low-budget batteries supplying low-power loads.

Implementations are in MATLAB .m controlling a *Keysight* Source Measurment Unit (SMU).
Measurements are programmed to be done using 4-wire Kelvin connections.

Two possible Keysight devices can be used with the model numbers as:
* [B2902A][1]
* [B2962A][2]
However, B2902A is suggested (and used) here.

All programs use *Standard Commands for Programmable Instruments (SCPI)* protocol to communicate with the SMU.

Extra information for programming these devices can be found from:

* [B2902A][3]
* [B2962A][4]


[1]: https://www.keysight.com/en/pd-1983585-pn-B2902A/precision-source-measure-unit-2-ch-100-fa-210-v-3-a-dc-105-a-pulse?cc=DE&lc=ger
[2]: https://www.keysight.com/en/pd-2149912-pn-B2962A/65-digit-low-noise-power-source?cc=DE&lc=ger
[3]: http://example.com/
[4]: http://example.org/