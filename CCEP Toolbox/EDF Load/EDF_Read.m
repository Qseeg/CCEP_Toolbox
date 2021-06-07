% Matthew Woolfe 29-03-17
%
%[ FileHeader, SignalHeader] = EDF_Read(EDFfilepath)
%[ FileHeader, SignalHeader, SignalStructure] = EDF_Read(EDFfilepath)
%[ FileHeader, SignalHeader, SignalStructure, Annotations ] = EDF_Read(EDFfilepath, SignalLabel, Epochs)
%
%Inputs:    EDFfilepath,    Complete filepath the the EDF
%           SignalLabels,   CellArray of SignalLabels to be loaded
%           Epochs,         [SecondsFromTheStart SecondsFromTheStart]
%              "            [0 1] Loads 1 Second of data
%              "            [1 1] Loads no data
%              "            [0 0] Loads all data
%              "            [5 LargeNumber] Loads From the begining of the
%                                           5th second to the end of the
%                                           file
%
%Outputs:   FileHeader,     Header to the Complete file
%           SignalHeader,   Header for the Signals
%           SignalStructure,Structure for the signals
%           Annotations

function [ FileHeader, SignalHeader, SignalStructure, Annotations ] = EDF_Read(EDFfilepath, SignalLabel, Epochs)
 
    %Check if the filepath given is legit
    if(~exist(EDFfilepath,'file')==2)
        fprintf('ERROR:\nERROR: Invalid Filepath to EDF_Read\nERROR:\n');
    end
    
    %Load the Headers
    [FileHeader, SignalHeader] = Get_EDF_FileHeaders(EDFfilepath);
    
    %If only the headers are required, get them and then break the function
    if nargout <= 2
        return;
    end
    
    %Open the File
    FID = fopen(EDFfilepath,'r','ieee-le');
                            
    %Layout of EDF file
    %Header 256bytes
    %SignalHeader 256Bytes * number of signals
    %Uncalibrated data-
    % Record1 = [Block1 Sig1][Block1 sig2][Block1 sig3] ... [Block1 sig"NumberofSignals"]
    % Record2 = [Block2 sig1] ...
    %   ...
    %   ...
    % Record "NumberOfRecords" [Block"NumberOf Records" sig1] ... [Block"NumberOfRecords" Sig"NumOfSignals"]
    
    %SignalStructure
    if(nargout>=3)
        fprintf('Loading EDF Signals:     ');
        
        %Preallocation
        Annotations = struct('Comment',{''},'Times',[]);
        SignalStructure(1).Label = '';
        
        %Set up the Channel Specific offsets
        %fseek(fid,0,'eof'); %move to the end of the file
        %filelength = ftell(fid);
        temp = cast(1,'int16');
        temp = whos('temp');
        NumBytes = temp.bytes;
        RecordLength=sum([SignalHeader.SamplePerRecord])*NumBytes;
        BlockOffsets = cumsum([SignalHeader(:).SamplePerRecord])-SignalHeader(1).SamplePerRecord;
        
        %Identify which of the Channels are to be loaded
        if(exist('SignalLabel','var'))
            if(iscellstr(SignalLabel))
                %Check that any of them actually exist
                for Ch = 1:size(SignalHeader,2)
                    SignalHeader(Ch).LoadChannel = logical(sum(strcmpi(SignalLabel,SignalHeader(Ch).NewLabel))) ;
                end
                if(nargout>3)
                    for Ch = 1:size(SignalHeader,2)
                        if(logical(strcmp(SignalHeader(Ch).Label,'EDF Annotations')))
                            SignalHeader(Ch).LoadChannel = true;
                        end
                    end
                end
                %Check if any matched
                if(~logical(sum([SignalHeader(:).LoadChannel])) || ~nargout>3)
                    fprintf('ERROR:\nERROR: No Signal label matches the input Labels\nERROR:\n');
                    return;
                end
            else
                fprintf('ERROR:\nERROR: Signal Labels must be input as a CellString\nERROR:\n');
                return;
            end
        else
            %Load all signals except the EDF Annotations
            if(nargout<=3)
                for Ch = 1:size(SignalHeader,2)
                    SignalHeader(Ch).LoadChannel = logical(~strcmp(SignalHeader(Ch).Label,'EDF Annotations'));
                end
            else
            %Load all the channels and all the Annotations
                for Ch = 1:size(SignalHeader,2)
                    SignalHeader(Ch).LoadChannel = true;
                end
            end
        end
        
        if(nargin>2)
           %Check the Validity of the Epochs specified
           if(Epochs(2)<Epochs(1) || sum(Epochs < 0)>0)
               fprintf('\nERROR:\nERROR: Epochs need to go in ascending order\nERROR:\n');
               return;
           end
        else
            Epochs = [0 0];
        end
        
        %Identify the sampling Frequency
        temp = 1:size(SignalHeader,2);
        SampleFreq =    1   ./  ( FileHeader.Duration ./ [SignalHeader(temp).SamplePerRecord]);
        
        %Identify the Finish Record
        if(Epochs(2)==0)
            RecordFinish = FileHeader.NumRecords;                       %Including the Last possible Record
            EndTrim = zeros(1,sum([SignalHeader(:).LoadChannel]));
        elseif(Epochs(2)/FileHeader.Duration > FileHeader.NumRecords )
            RecordFinish = FileHeader.NumRecords;
            EndTrim = zeros(1,sum([SignalHeader(:).LoadChannel]));
        else
            RecordFinish = ceil(Epochs(2)/FileHeader.Duration);
            EndTrim = [SignalHeader([SignalHeader(:).LoadChannel]).SamplePerRecord] - mod(Epochs(2),FileHeader.Duration) * [SampleFreq([SignalHeader(:).LoadChannel])];
        end
             
        %Identify the Start Record
        if(Epochs(1) == 0)
            RecordStart = 1;
            StartTrim = zeros(1,sum([SignalHeader(:).LoadChannel]));
        else
            RecordStart = floor(Epochs(1)/FileHeader.Duration)+1;
            StartTrim = mod(Epochs(1),FileHeader.Duration) * [SampleFreq([SignalHeader(:).LoadChannel])];
        end
        StartTrim = round(StartTrim);
        EndTrim = round(EndTrim);
        
        
        %Load only the Channels given in LoadChannel
        count = 1;
        SignalsKept = 1:size(SignalHeader,2);
        SignalsKept = SignalsKept([SignalHeader(:).LoadChannel]);
        for Ch = SignalsKept
                
            %Create the Channel Entry
            SignalStructure(count).Label = SignalHeader(Ch).NewLabel;
            count = count+1;
                
        end
        
        %Load onto the Structure
        SignalStructure = MultiRead(FID,...                                 FileIdentifier for the EDF
                                    SignalStructure,...                     Where to hand the data back too
                                    RecordStart,...                         Which Records should be read Start
                                    RecordFinish,...                        Which Records should be read Finish
                                    FileHeader.HeaderLength,...             Offset that needs to be excluded fromt he front
                                    RecordLength/NumBytes,...               Number of bytes for each Record
                                    [SignalHeader(:).SamplePerRecord],...   How many samples are in each channel for each block
                                    [SignalHeader(:).LoadChannel],...       Which channels need to be loaded
                                    'int16');                               %Filetype to read the EDF 
        
        %Trim the Signals based on the Epochs
        for Ch = 1:size(SignalStructure,2)
            SignalStructure(Ch).EEG = SignalStructure(Ch).EEG(StartTrim(Ch)+1:(length(SignalStructure(Ch).EEG) - EndTrim(Ch)));
        end
                                
                                
        %Calibration Settings
        fprintf('Calibrating EDF Signals: ');
        %Remove EDF Annotations
        temp = 1:size(SignalHeader,2);
        EDFAIndexes = temp(strcmp({SignalHeader(:).Label},'EDF Annotations'));
        SignalsKept = SignalsKept(SignalsKept~=EDFAIndexes);
        
        ScaleFactor = ([SignalHeader(SignalsKept).physmax] - [SignalHeader(SignalsKept).physmin])./([SignalHeader(SignalsKept).digitalmax] - [SignalHeader(SignalsKept).digitalmin]);
        DCoffset = [SignalHeader(SignalsKept).physmax] - ScaleFactor.* [SignalHeader(SignalsKept).digitalmax];
        for Ch = 1:length(SignalsKept)
            SignalStructure(Ch).EEG = SignalStructure(Ch).EEG .* ScaleFactor(Ch) +DCoffset(Ch);
        end  
        fprintf('Complete\n');
    end
    
    %Annotations
    if(nargout > 3)
        
        %Get the entire Char record
        temp = 1:size(SignalStructure,2);
        Annt=char(typecast(int16(SignalStructure(temp(strcmp({SignalStructure(:).Label},'EDF Annotations'))).EEG), 'uint8'))';
        
        %Identify the sampling Frequency
        SampleFreq =    1   /  ( FileHeader.Duration / SignalHeader(temp(strcmp({SignalStructure(:).Label},'EDF Annotations'))).SamplePerRecord);
        

        %Correct Version. It looks for a dual representation and takes the
        %leading marker. The leading marker is the onset, if the first
        %space is not used (The traditional onset) then the duration peice
        %holds the onset. Caputring the Leading Marker esures that we
        %collect the true time all of the time.
        
        %Capture Times stamps in the format +Onset [(Char(21) Optional +Duration] (char 20) Annotation Text (Char 20)(Char 0)
        [Onsets,Offsets] = regexp(Annt',sprintf('[+[0-9.]{1,}[%c-%c]{1,}]?[+[0-9.]{1,}[%c-%c]{1,}]{1,}[%c][%c-%c]{1,}%c*%c'  ,char(20),char(21),char(20),char(21),char(20),char(32),char(127),char(20),char(0)));
        for i = 1:length(Onsets)
            %Mark the Full Comment
            Annotations(i).Comment = Annt(Onsets(i):Offsets(i))';
            %Find the Time of the Event
            [s,f] = regexp(Annotations(i).Comment,sprintf('+[0-9.]{1,}%c',char(20)));
            
            Annotations(i).Times = round(SampleFreq * str2double(Annotations(i).Comment(s(1)+1:f(1)-1)));
            
            %Trim the Comment to remove the Time
            Annotations(i).Comment = regexp(Annotations(i).Comment,sprintf('%c([%c-%c]{1,})%c%c',char(20),char(32),char(127),char(20),char(0)),'Tokens');
            Annotations(i).Comment = Annotations(i).Comment{1}{1};
        end
        
        
        
        
        
        
        
                %Collect the TAL's which have meaningful entries
        % This means that after a +[Numbers]char(20) or char(21)   HERE THERE IS TEXT other then
        % char(20) char(21) or char(0) then find the ending sequence
        % char(20) char(0)
% % % %         % THis Captures the time immediately infront of the TAL,
% not the true onset !!!!
% % % %         [Onsets, Offsets] = regexp(Annt',sprintf('+[.0-9]{1,}[%c-%c]{1,}[%c-%c]{1,}%c*%c',char(20),char(21),char(32),char(127),char(20),char(0)));
% % % %         for i = 1:length(Onsets)
% % % %             %Mark the Full Comment
% % % %             Annotations(i).Comment = Annt(Onsets(i):Offsets(i))';
% % % %             %Find the Time of the Event
% % % %             [s,f] = regexp(Annotations(i).Comment,sprintf('+[0-9.]{1,}%c',char(20)));
% % % %             Annotations(i).Times = round(SampleFreq * str2double(Annotations(i).Comment(s(1)+1:f(1)-1)));
% % % %             %Trim the Comment to remove the Time
% % % %             Annotations(i).Comment = Annotations(i).Comment(f+1:length(Annotations(i).Comment)-2); %2, char(20) char(0)
% % % %         end
     end
        
    %Remove the Annotations entry
    SignalStructure = SignalStructure(~strcmp({SignalStructure(:).Label},'EDF Annotations'));
    
    %Sort The Structure according to the SEEG/OtherChannel Order
    [~, ~,SEEGChannels,OtherChannels] = Get_EDF_FileHeaders(EDFfilepath);
    for LB = 1:size(OtherChannels,2)
        SEEGChannels(size(SEEGChannels,2)+1).Label = OtherChannels(LB).Label;
    end
    temp = 1:size(SEEGChannels,2);
    count = 1;
    for Ch = 1:size(SEEGChannels,2)
        Position = temp(strcmp({SignalStructure(:).Label},SEEGChannels(Ch).Label));
        if(~isempty(Position))
            Order(count) = Position;
            count = count + 1;
        end
    end
    if(exist('Order','var'))
        SignalStructure = SignalStructure(Order);
    end
    
    fclose(FID);
    
    %Change the .EEG fieldname to .Data in order to work with other functions
    for h = 1:length(SignalStructure)
    SignalStructure(h).Data = SignalStructure(h).EEG;
    end
    SignalStructure = rmfield(SignalStructure, 'EEG');
end



function [SignalStruct] = MultiRead(fid, SignalStruct, RecordStart, RecordFinish, HeaderOffset, RecordLength, SamplesPerRecord, LoadChannels, TYPE)
    
    StructureIndexes = 1:length(LoadChannels);
    SignalIndexes = StructureIndexes(LoadChannels);
    
    BlockStartIndexes =  [cumsum(SamplesPerRecord)]-SamplesPerRecord+1;
    BlockFinishIndexes =  [cumsum(SamplesPerRecord)];
    
    BlockStartIndexes = BlockStartIndexes(SignalIndexes);
    BlockFinishIndexes = BlockFinishIndexes(SignalIndexes);
    
    NumLoadRecords = RecordFinish - RecordStart + 1;
    
    %Preallocation
    for Ch = 1:length(SignalIndexes)
        SignalStruct(StructureIndexes(Ch)).EEG = single(zeros(1,NumLoadRecords*SamplesPerRecord(SignalIndexes(Ch))));
    end
    
    %Move to the start of the file
    fseek(fid,HeaderOffset,'bof');
    
    %Move to the Begining of the Records given by RecordStart
    fseek(fid,(RecordStart-1)*RecordLength,'cof');
    
    %Load the Records and Trim
    SamplesPerRecord = SamplesPerRecord(SignalIndexes);
    SignalStartIndexes = ones(1,length(SignalIndexes));
    Progress = [zeros(1,RecordStart-1) linspace(0,100,NumLoadRecords)];
    for rec = RecordStart:RecordFinish
        
        %Read an entire Record
        TempRecord = fread(fid,RecordLength,TYPE);
        
        SignalFinishIndexes = SignalStartIndexes+SamplesPerRecord-1;
        %Assigned to structure
        for Ch = 1:length(SignalIndexes)
            SignalStruct(StructureIndexes(Ch)).EEG(SignalStartIndexes(Ch):SignalFinishIndexes(Ch)) = TempRecord(BlockStartIndexes(Ch):BlockFinishIndexes(Ch));
        end
        SignalStartIndexes = SignalStartIndexes+SamplesPerRecord;
        fprintf('\b\b\b%3.0f',Progress(rec));
    end
    fprintf('\b\b\bComplete\n');
    
    
    %Load entire Dataset then distribute
    %Identify the Indexes that need to be kept
    %Indexes = zeros(max(SamplesPerRecord),length(LoadChannels));
    %Indexes(1,:) = [cumsum(SamplesPerRecord)]-SamplesPerRecord(1)+1;
    
    %for i = [cumsum(LoadChannels)]
    %    Indexes(1:SamplesPerRecord,i) = Indexes(1,i):Indexes(1,i)+SamplesPerRecord(i)-1;
    %end
    
    %Reshape
    %Indexes = reshape(Indexes,1,size(Indexes,1)*size(Indexes,2));
    
    %Remove zeros
    %Indexes = Indexes(Indexes ~=0);
    
    %Preallocate Space for the Output
    %Records = single(zeros(NumRecords,length(Indexes)));
    
    %Load the Records and Trim
    %for rec = 1:NumRecords
        %Read an entire Record
    %    TempRecord = fread(fid,RecordLength,TYPE);
    %    Records(rec,:) = TempRecord(Indexes);
        %Needs reshaping
    %end

end



    
