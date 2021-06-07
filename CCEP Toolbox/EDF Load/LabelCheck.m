% Matthew Woolfe 01-08-17
% Check for Electrode Labels            ****** REFERENTIAL *********
% Input: Label                          ****** REFERENTIAL *********
% Outputs:              SEEGChannel Logical (1 = Is SEEG, 0 = Other type)
%           [optional]  ElectrodeLabel
%           [Optional]  ContactNumber

function [IsSEEGChannel, ElectrodeLabel, ContactNumber] = LabelCheck(Label)
    
    %First, Identify What type the Channel is SEEG or Other
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %               SEEG Channels are in the Format 
    %       LETTER[Optional LETTER][Optional ']NUMBER[Optional NUMBER]
    %
    %               For FD, the Format is slightly changed
    %       LETTER[Optional LETTER]2[Optional ']NUMBER[Optional NUMBER]
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %          Remove DC Channels as they do not fit the SEEG Description
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    if(~isempty(regexp(Label,'DC\d*','ONCE')))                                       %Identify The DC Channels
        IsSEEGChannel = false;
    elseif(~isempty(regexp(Label,'^[a-zA-Z]{1,2}['']?[0-9]{1,2}$','ONCE')   ))      %Normal SEEG Label Format
        IsSEEGChannel = true;
    elseif(~isempty(regexp(Label,'^[a-zA-Z]{1,2}['']?[2]{1,1}[0-9]{1,2}$','ONCE'))) %Optional SEEG Label Format
        IsSEEGChannel = true;
    else
        IsSEEGChannel = false;
    end
    
    %If you Continue, we are looking to get the actual Label and its
    %contact value from the Label
    if(nargout>1)
        
        if(~isempty(regexp(Label,'DC\d*','ONCE')))                                      %Identify the DC Channels
            ElectrodeLabel = 'Other';
            ContactNumber = 0;
        elseif(~isempty(regexp(Label,'^[a-zA-Z]{1,2}['']?[2]{1,1}[0-9]{1,2}$','ONCE')))     %Optional SEEG Label Format
            ElectrodeLabel = char(regexp(Label,'^[a-zA-Z]{1,2}[2]{1,1}['']?','match'));
            ContactNumber = str2double(Label(length(ElectrodeLabel)+1:end));
        elseif(~isempty(regexp(Label,'^[a-zA-Z]{1,2}['']?[0-9]{1,2}$','ONCE')   ))          %Normal SEEG Label Format
            ElectrodeLabel = char(regexp(Label,'^[a-zA-Z]{1,2}['']?','match'));
            ContactNumber = str2double(Label(length(ElectrodeLabel)+1:end));
        else
            ElectrodeLabel = 'Other';
            ContactNumber = 0;
        end
        
    end
end
        
        