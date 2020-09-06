%% This function generates an object to cennect to the SMU
%  Possible inputs are 1 of keysight SMU devices models no:
%       B2902A
%       B2962A
%  Device VISA numbers has to be updated accordingly by user
function obj1=visa_connector(Device_name)
switch Device_name
    case 'B2902A'
        %                                      Object No. vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv                 
        obj1 = instrfind('Type', 'visa-usb', 'RsrcName', 'USB0::0x0957::0x8C18::MY51140778::0::INSTR', 'Tag', '');
        
        if isempty(obj1)
            obj1 = visa('AGILENT', 'USB0::0x0957::0x8C18::MY51140778::0::INSTR');
        else
            fclose(obj1);
            obj1 = obj1(1);
        end
    case 'B2962A'
        %                                      Object No. vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
        obj1 = instrfind('Type', 'visa-usb', 'RsrcName', 'USB0::0x0957::0x9018::MY52350220::0::INSTR', 'Tag', '');
        
        if isempty(obj1)
            obj1 = visa('AGILENT', 'USB0::0x0957::0x9018::MY52350220::0::INSTR');
        else
            fclose(obj1);
            obj1 = obj1(1);
        end
end
obj1.InputBufferSize  = 8500000;
obj1.OutputBufferSize = 8500000;