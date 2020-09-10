%% This is the main charging program
% There are two types of charging: Fast, Full
% Fast charging is the typical chargin process used for normal operation
% Full charging is for the identification cases (infinitesimal current)
function Battery_Initialize(SMU_Name, Battery, Str_Add, Type)
%% Settings
Neut_Str_Add = [Str_Add,filesep,'Initialize']; % storage folder address
%% Fast charge
Battery.Ts  = 0.2;
Battery_CCV_T(SMU_Name, Battery, 'charge', 0.8, Battery.Ts, 20*60, Neut_Str_Add);
if strcmp(Type, 'Full')
    pause(5*60) % a short recovery pause
    %% Middle charge
    % this is to balance charge time and charge current
    Battery.Ts = 0.1;
    for MidChargeRate = [0.2, 0.1, 0.05, 0.02]
        Battery_CC(SMU_Name, Battery, 'charge', MidChargeRate, Battery.Ts, Neut_Str_Add);
        pause(5*60) % a short recovery pause
    end
    pause(10*60) % a short recovery pause
    %% Infinitesimal charge
    Battery_CC(SMU_Name, Battery, 'charge', Battery.IInfiniRatio, Battery.Ts, Neut_Str_Add);
    % Do not pause here!
    %% Hysteresis removal by Chirp
    Battery.Ts = 0.2;
    Battery_Chirp02(SMU_Name, Battery, Battery.VMax, Neut_Str_Add);
end
%% Final recovery
pause(60*60) % wait for 1 Hour rest time