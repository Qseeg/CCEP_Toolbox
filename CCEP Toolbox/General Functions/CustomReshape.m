function [DataOut] = CustomReshape(DataIn,XDim,YDim)

%Default to using 3 columns, as you will probably be using this for MRI CoOrds
if ~exist('XDim','var')
    XDim = round((length(DataIn)/3));
    
end

%Default to 3 columns, as you will probably be using this for MRI CoOrds
if ~exist('YDim','var')
    YDim = 3;
end

DataOut = reshape(DataIn', [YDim, XDim])';