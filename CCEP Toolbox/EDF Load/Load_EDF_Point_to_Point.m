%Matthew Woolfe 18-05-17
% Load From single point to single point
% This requires Load_EDF to be used to a Second Accuracy, then trim further
%
% Inputs:   Start The Starting Time
%           Finish The Finishing Time
%           The EDFfilepath
%           CellStr of Channels to load

function [ReferentialEEG,Annotations,BipolarEEG,OutSeqInfo] = Load_EDF_Point_to_Point(Start,Finish,EDFfilepath,Channels)

    %Identify the Sampling Freq
    [FileHeader,~] = Get_EDF_FileHeaders(EDFfilepath);
    if(numel(FileHeader.SamplingFrequency)==0)
        WARNING_ERROR('ERROR','Unkown Sampling Frequency for that EDFfilepath');
    elseif(numel(FileHeader.SamplingFrequency) > 1)
        WARNING_ERROR('WARNING','Number of Sampling Frequices is not equal to 1, using the First');
        FileHeader.SamplingFrequency = FileHeader.SamplingFrequency(1);
    end
    
    %Load all the data
    StartSecond = 0;
    FinishSecond = 0;
    %Round the Start Time to the Nearest Second
    %StartSecond = floor(Start/FileHeader.SamplingFrequency);
    %NumSamplesRMStart = mod(Start,FileHeader.SamplingFrequency);
    
    %FinishSecond = ceil(Finish/FileHeader.SamplingFrequency);
    %NumSamplesRMFinish = FileHeader.SamplingFrequency - mod(Finish,FileHeader.SamplingFrequency); 

    %Identify Which Seconds need to be Loaded, For this we need the
    %Sampling Frequency
    if(nargout == 1)
    ReferentialEEG = Load_EDF(  'EDFfilepath',EDFfilepath,...
                                'Channels',Channels,...
                                'Epochs',[StartSecond FinishSecond]);
    elseif(nargout ==2)
          [ReferentialEEG,Annotations] = Load_EDF(  'EDFfilepath',EDFfilepath,...
                                                    'Channels',Channels,...
                                                    'Epochs',[StartSecond FinishSecond]);
    elseif(nargout == 3)
          [ReferentialEEG,Annotations,BipolarEEG] = Load_EDF(   'EDFfilepath',EDFfilepath,...
                                                                'Channels',Channels,...
                                                                'Epochs',[StartSecond FinishSecond]);
    else
        [ReferentialEEG,Annotations,BipolarEEG,OutSeqInfo] = Load_EDF(  'EDFfilepath',EDFfilepath,...
                                                                        'Channels',Channels,...
                                                                        'Epochs',[StartSecond FinishSecond]);
    end
    
    %Remove the Samples which should not be there but for rounding
    %to each second have been included
    if(exist('ReferentialEEG','var'))
        for Ch = 1:size(ReferentialEEG,2)
            %ReferentialEEG(Ch).EEG = ReferentialEEG(Ch).EEG(NumSamplesRMStart:end-NumSamplesRMFinish);
            ReferentialEEG(Ch).EEG = ReferentialEEG(Ch).EEG(Start:Finish);
        end
    end
    
    if(exist('BipolarEEG','var'))
        for Ch = 1:size(BipolarEEG,2)
            %BipolarEEG(Ch).EEG = BipolarEEG(Ch).EEG(NumSamplesRMStart:end-NumSamplesRMFinish);
            BipolarEEG(Ch).EEG = BipolarEEG(Ch).EEG(Start:Finish);
        end
    end
        
            




end