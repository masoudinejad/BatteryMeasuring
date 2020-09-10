%% This is the main program for analyzing, modelling and evaluating battery
% All codes written by: mojtaba.masoudinejad@tu-dortmund.de
% Last modification: 2019/05/23 Dortmund
% 
%% General setting
clear 
close all
Bat_No = 4; % define the battery number being measured
IdentRate = 0.02; % C-rate for the identification process (0.02 -> 25mA)
%% building the battery object
Battery = BatteryMaker(Bat_No);
%% Start from shelf condition
DesireVoltage = Battery.VNom; % 3.7 V is the nominal voltage
Battery_ShelfReady(Battery, DesireVoltage)
pause(60*60)
Battery = BatteryMaker(Bat_No); % to assure no problem with params
%% Finding Eta_Current
CurrentList = [100e-3,50e-3]; % currents to be used
Battery_EtaC(Battery, CurrentList)
%% SoC-Vemf Continuous
Battery_StandardTest(Battery) % Run the standard test
Battery_SoCVemf_C(Battery, IdentRate) % identify the contnuous SoC-Vemf relation
Battery = BatteryMaker(Bat_No); % to assure no problem with params
%% SoC-Vemf Stepwise
Battery_StandardTest(Battery) % Run the standard test
Battery_SoCVemf_D(Battery) % identify the StepWise SoC-Vemf relation
%% Random load test
Battery_StandardTest(Battery) % Run the standard test
Battery_RandomLoadTest(Battery) % measure evaluation data with a random load
%% PhyNode load test
Battery_StandardTest(Battery) % Run the standard test
Battery_PhyNodeLoadTest(Battery) % measure evaluation data with PhyNode load
%% Make battery ready for shelf storage
Battery_ShelfReady(Battery)