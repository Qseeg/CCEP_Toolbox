%Matthew Woolfe 31-03-17
function [SEEGHeader, OtherHeader] = Get_EDF_Channels(EDFfilepath)
    [~,~,SEEGHeader,OtherHeader] = Get_EDF_FileHeaders(EDFfilepath);
end
