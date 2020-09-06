function Battery_Neutralize(SMU_Name, Battery, Str_Add)
close all
% make storage folder if not available
Neut_Str_Add = strcat(Str_Add,'\Neutralize');

Battery.Ts = 0.2;
% Assure to start from discharged condition
VoltageLevel = Battery_VCheck(SMU_Name);
if VoltageLevel >= 3.1
    Battery_CC(SMU_Name, Battery, 'discharge', 0.2, Battery.Ts, Neut_Str_Add); %250mA
    pause(5*60)
end
% Charge to the near goal
Battery_CC(SMU_Name, Battery, 'charge', 0.8, Battery.Ts, Neut_Str_Add); %1A
pause(5*60)
Battery_CCV(SMU_Name, Battery, 'charge', 0.2, Battery.Ts, 60*60, Neut_Str_Add); %250mA
% Distruction of hyst using the chirp -------------------------------------
Battery_Chirp02(SMU_Name, Battery, Battery.VMax, Neut_Str_Add);
% End of chirp ------------------------------------------------------------
pause(60*60) % wait for 1 Hour rest time