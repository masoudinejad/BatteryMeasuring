function Battery_SoCVemf_D(Battery)
%% Setting the Measurement device
SMU_Name = 'B2902A';
%% storage folder
Str_Add = ['Data',filesep,'SoCVemf',filesep,'StepWise'];
%% Go to the Init point
Battery_Initialize(SMU_Name, Battery, Str_Add, 'Full'); 
%% Apply steps till the Vmin is reached
VoltageLevel =[];
Ready4Break = false;
LastVFinish = Battery.VMax; % Discharge starts from the full state
while ~Ready4Break
    [~, ~, Ready4Break, VFinish] = Battery_Step_Rest(SMU_Name, Battery, 'discharge', 50e-3, Str_Add, LastVFinish);
    LastVFinish = VFinish;
    Temp_VoltageLevel = Battery_VCheck(SMU_Name);
    VoltageLevel = [VoltageLevel;Temp_VoltageLevel];
end
disp('Break point passed by!')

End_Reached = false;
while ~End_Reached
    [~, End_Reached, ~, VFinish] = Battery_Step_Rest(SMU_Name, Battery, 'discharge', 25e-3, Str_Add, LastVFinish);
    LastVFinish = VFinish;
    Temp_VoltageLevel = Battery_VCheck(SMU_Name);
    VoltageLevel = [VoltageLevel;Temp_VoltageLevel];
end
%% Store Vemf measured after secondary rest
SaveM(['Data',filesep,'SoCVemf',filesep,'VemfData'], VoltageLevel);