%% building the battery structure for the storage of the information
Battery = BatteryMaker(2);
%% Setting the Measurement device
SMU_Name = 'B2902A';
%% storage folder
Str_Add = 'PhyNodeEval';
%% bring battery to the standard point
Battery_Neutralize(SMU_Name, Battery, Str_Add); 
PhyNode_V0 = Battery_VCheck(SMU_Name);
save('PhyNode_V0','PhyNode_V0')
%% Main Measurement
UV_Reached = false;
while ~UV_Reached
    [Main,UV_Reached] = Battery_PhyNodeLoadSignle(SMU_Name, Battery,Str_Add);
end