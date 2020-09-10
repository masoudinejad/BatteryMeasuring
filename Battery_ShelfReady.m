function Battery_ShelfReady(Battery, DesireVoltage)
%% Setting the Measurement device
SMU_Name = 'B2902A';
%% storage folder
Str_Add = ['Data',filesep,'ShelfReady'];
%% Find current direction
InitV = Battery_VCheck(SMU_Name);
if InitV > DesireVoltage
    Main_VMin = Battery.VMin;
    Battery.VMin = DesireVoltage;
    Battery.Ts = 0.2;
    Battery_CC(SMU_Name, Battery, 'discharge', Battery.IStandardRatio, Battery.Ts, Str_Add);
    Battery.VMin = Main_VMin;
elseif InitV < DesireVoltage
    Main_VMax = Battery.VMax;
    Battery.VMax = DesireVoltage;
    Battery.Ts = 0.2;
    Battery_CC(SMU_Name, Battery, 'charge', Battery.IStandardRatio, Battery.Ts, Str_Add);
    Battery.VMax = Main_VMax;
end
