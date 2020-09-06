%% This function generates an object including all related infrmation about the battery
%  User is supposed to modify these information according to the battery
%  To enable measurement of different battery from same series there is a single input to this function
%  Input has to be an integer related to the battery number
function Battery = BatteryMaker(Item)
Battery = struct; % Make an empty object
Battery.Manufacturer = 'Shenzhen Blue TaiYang new energy technology Co., LTD';
Battery.Model = 'LP632670';
Battery.Item = Item;
Battery.Capacity = 1.25; % capacity in [Ah]
Battery.VMax = 4.2; % Maximum allowed voltage in [V]
Battery.VNom = 3.7; % nominal voltage of the battery in [V]
Battery.VMin = 3.0; % cut off voltage of the battery in [V]
Battery.IStandardRatio = 0.20; % standard current according to the C in [ratio]
Battery.IMaxRatio = 1; % maximum allowed current according to the C in [ratio]