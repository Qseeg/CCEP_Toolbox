%Matthew Woolfe
% Get_Bipolar_Channels(EDFfilepath)

function [BipolarChannels] = Get_Bipolar_Channels(EDFfilepath)
    
    SEEGChannels    = Get_EDF_Channels(EDFfilepath);
    [SEEGChannels.EEG] = deal(1);
    BipolarChannels = Create_BipolarEEG(SEEGChannels);
end