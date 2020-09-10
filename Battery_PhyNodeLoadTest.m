% This is to test the battery under PhyNode load signal
% Load profile is stored in a mat file named "PhyNodeLoads"
function Battery_PhyNodeLoadTest(Battery)
%% Setting the Measurement device
SMU_Name = 'B2902A';
%% storage folder
Str_Add = ['Data',filesep,'Evaluation',filesep,'PhyNodeLoad'];
%% bring battery to the standard point
Battery_Initialize(SMU_Name, Battery, Str_Add, 'Full');
%% Find initial Vemf before applying the load
PhyNode_V0 = Battery_VCheck(SMU_Name); % measure
SaveM(['Data',filesep,'Evaluation',filesep,'PhyNode_V0'], PhyNode_V0); % store
%% Main Measurement
UV_Reached = false;
while ~UV_Reached
    [~,UV_Reached] = Battery_PhyNodeLoadSignle(SMU_Name, Battery, Str_Add);
end