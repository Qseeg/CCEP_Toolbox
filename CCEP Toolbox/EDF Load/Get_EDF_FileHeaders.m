%Matthew Woolfe 31-03-17
%[FileHeader, SignalHeader, SEEGHeader, OtherHeader] = Get_EDF_FileHeaders(EDFfilepath)

function [FileHeader, SignalHeader, SEEGHeader, OtherHeader] = Get_EDF_FileHeaders(EDFfilepath)

    %Check if the filepath given is legit
    if(~exist(EDFfilepath,'file')==2)
        fprintf('ERROR:\nERROR: Invalid Filepath to EDF_Read\nERROR:\n');
        return;
    end

    %fprintf('Loading EDF Header: ');
    fid = fopen(EDFfilepath,'r','ieee-le');

    % FileHeader
    hdr =                       char(fread(fid,256,'uchar')');
    FileHeader.ver=             str2num(hdr(1:8));                  % 8 ascii : version of this data format (0)
    FileHeader.PatientID =      char(hdr(9:88));                    % 80 ascii : local patient identification
    FileHeader.RecordID  =      char(hdr(89:168));                  % 80 ascii : local recording identification
    FileHeader.Startdate =      char(hdr(169:176));                 % 8 ascii : startdate of recording (dd.mm.yy)
    FileHeader.Starttime =      char(hdr(177:184));                 % 8 ascii : starttime of recording (hh.mm.ss)
    FileHeader.HeaderLength =   str2num (hdr(185:192));             % 8 ascii : number of bytes in header record
    FileHeader.Reserved =       char(hdr(193:236));                 % [EDF+C       ] % 44 ascii : reserved
    FileHeader.NumRecords =     str2num (hdr(237:244));             % 8 ascii : number of data records (-1 if unknown)
    FileHeader.Duration =       str2num (hdr(245:252));             % 8 ascii : duration of a data record, in seconds
    FileHeader.Channels =       str2num (hdr(253:256));             % 4 ascii : number of signals (ns) in data record
    
    if(nargout>1)
        
        % SignalHeader
        SignalHeader = struct(...
                'Label',        cellstr(char(fread(fid,[16,FileHeader.Channels],'char')'))',...             % ns * 16 ascii : ns * label (e.g. EEG FpzCz or Body temp)
                'Transducer',   cellstr(char(fread(fid,[80,FileHeader.Channels],'char')'))',...             % ns * 80 ascii : ns * transducer type (e.g. AgAgCl electrode));
                'units',        cellstr(char(fread(fid,[8,FileHeader.Channels],'char')'))',...              % ns * 8 ascii : ns * physical dimension (e.g. uV or degreeC)
                'physmin',      num2cell(str2num(char(fread(fid,[8,FileHeader.Channels],'char')'))'),...    % ns * 8 ascii : ns * physical minimum (e.g. -500 or 34)
                'physmax',      num2cell(str2num(char(fread(fid,[8,FileHeader.Channels],'char')'))'),...    % ns * 8 ascii : ns * physical maximum (e.g. 500 or 40)
                'digitalmin',   num2cell(str2num(char(fread(fid,[8,FileHeader.Channels],'char')'))'),...    % ns * 8 ascii : ns * digital minimum (e.g. -2048)
                'digitalmax',   num2cell(str2num(char(fread(fid,[8,FileHeader.Channels],'char')'))'),...    % ns * 8 ascii : ns * digital maximum (e.g. 2047)
                'Prefilter',    cellstr(char(fread(fid,[80,FileHeader.Channels],'char')'))',...             % ns * 80 ascii : ns * prefiltering (e.g. HP:0.1Hz LP:75Hz)
                'SamplePerRecord',num2cell(str2num(char(fread(fid,[8,FileHeader.Channels],'char')'))'),...  % ns * 8 ascii : ns * nr of samples in each data record
                'Reserved',     cellstr(char(fread(fid,[32,FileHeader.Channels],'char')'))');               % ns * 32 ascii : ns * reserved


        if (FileHeader.NumRecords<0)                                           % If the quantity of blocks is not known
            fprintf('WARNING:\nWARNING: Missing Data to infer Number of records in EDF file\nWARNING:\n');
            fseek(fid,0,'eof'); %move to the end of the file
            filelength = ftell(fid);
            temp = cast(1,'int16');
            temp = whos('temp');
            NumBytes = temp.bytes;
            R=sum([SignalHeader.SamplePerRecord]);
            FileHeader.NumRecords=fix( ((filelength-FileHeader.HeaderLength)/NumBytes)./R);                     % Quantity of written down blocks
        end

        %Export the Sampling Frequency, but not the EDF Annotation Frequency
        FileHeader.SamplingFrequency = unique([SignalHeader(~strcmp({SignalHeader.Label},'EDF Annotations')).SamplePerRecord]./FileHeader.Duration);

        if(length(FileHeader.SamplingFrequency)>1)
            fprintf('\nWARNING:\nWARNING: Multiple Sampling Frequencys in the Current EDF file\nWARNING:\n');
        end


        %Clean up the Signal Labels
        for Ch = 1:size(SignalHeader,2)

            %SignalHeader(Ch).NewLabel = strrep(SignalHeader(Ch).Label,{'POL ','EEG ','-REF'},'');
            SignalHeader(Ch).NewLabel = strtrim(regexprep(SignalHeader(Ch).Label,{'POL ','EEG ','-REF'},'','ignorecase'));

        end

        %Check that there is only one copy of all the Channels labels
        [UniqueLabels, UniquePositions] = unique({SignalHeader(:).NewLabel});
        if(size(UniqueLabels,2) ~= size(SignalHeader,2))
            temp = 1:size(SignalHeader,2);
            Duplicates = {SignalHeader(temp(setdiff(temp,UniquePositions))).NewLabel};
            for d = 1:size(Duplicates,2)
                DuplicateIndexes = temp(strcmp({SignalHeader(:).NewLabel},Duplicates{d}));
                if(length(DuplicateIndexes)>2)
                    WARNING_ERROR('ERROR',sprintf('Too Many Duplicate Names in the SignalHeader for automatic Correction\n ERROR: Duplicate Entry:%s, Ues EDF_HEADER_EDITOR to change them',Duplicates{d}));
                    SEEGHeader(1).Label = '';
                    OtherHeader(1).Label = '';
                    return;
                end

                EEGChannel = DuplicateIndexes(cell2mat(strfind({SignalHeader(DuplicateIndexes).Label},'EEG')));
                if(isempty(EEGChannel) || length(EEGChannel)>1)
                    WARNING_ERROR('ERROR','Cannot Automatically Resolve Duplicates in Get_EDF_FileHeaders, Use EDF_HEADER_EDITOR');
                    SEEGHeader(1).Label = '';
                    OtherHeader(1).Label = '';
                    return;
                else
                    %Add an EEG to force it as EEG
                    SignalHeader(EEGChannel).NewLabel = ['EEG',SignalHeader(EEGChannel).NewLabel];
                end
            end
        end

        if(nargout>2)

    %         %Create Two Streams of Channels 1) SEEG channels, 2) Everything else
    %         %1) SEEG, String: LETTER[Optional LETTER][Optional ']NUMBER[Optional NUMBER]
    %         for Channel = 1:size(SignalHeader,2)
    %             Label = SignalHeader(Channel).NewLabel;
    %             % l = regexp(Label,'\w.\d*');
    %             %^[a-zA-Z] must start the word
    %             % {1,2} must happen once, but can happen twice
    %             % [']? can happen 0 or 1 time
    %             % [0-9]{1,2} must have atleast one number, but can have two
    %             % $ the last element must be the terminating letter/number
    %             if(isempty(     regexp(Label,'^[a-zA-Z]{1,2}['']?[0-9]{1,2}$','ONCE')   ))
    %                 SignalHeader(Channel).SEEGChannel = 0;
    %             elseif(~isempty(regexp(Label,'DC\d*','ONCE')))
    %                 SignalHeader(Channel).SEEGChannel = 0;
    %             elseif(~isempty(regexp(Label,'^[a-zA-Z]{1,2}['']?[2]{1,1}[0-9]{1,2}$','ONCE')))
    %                 %This Expression is for FD, where a second implantation was
    %                 %attempted. Each of the new Electrodes have a 2 after thier
    %                 %letters. The new Format LETTER[Optional LETTER]2[Optional ']NUMBER[Optional NUMBER]
    %                 SignalHeader(Channel).SEEGChannel = 1;                
    %             else
    %                 SignalHeader(Channel).SEEGChannel = 1;
    %             end
    %         end

            for Channel = 1:size(SignalHeader,2)
                SignalHeader(Channel).SEEGChannel = LabelCheck(SignalHeader(Channel).NewLabel);
            end

            %Allocate the Correct Items into structures
            temp = 1:size(SignalHeader,2);
            SEEGHeader = struct('Label',{SignalHeader(temp([SignalHeader(:).SEEGChannel] == 1)).NewLabel});
            OtherHeader = struct('Label',{SignalHeader(temp([SignalHeader(:).SEEGChannel] == 0)).NewLabel});
            %Sort
            [~,Order] = sort_nat({SEEGHeader(:).Label});
            SEEGHeader = SEEGHeader(Order);
            [~,Order] = sort_nat({OtherHeader(:).Label});
            OtherHeader = OtherHeader(Order);

        end
    end
    
    %Close the file when complete
    fclose(fid);
    
end



% DuplicateIndexes = setdiff(1:size(SignalHeader,2),UniquePositions);
%     for DI = DuplicateIndexes
%         CurrentLabel = SignalHeader(DuplicateIndexes).NewLabel;
% 
%         %Find all copies of the label
%         temp = 1:size(SignalHeader,2);
%         DuplicatePositions = temp(strcmp({SignalHeader(:).NewLabel},CurrentLabel));
% 
%         if(length(DuplicatePositions)>2)
%             WARNING_ERROR('ERROR','More then 2 Duplicates of a single Label, cannot resolve automatically');
%             fprintf('-----%s------ Lin2 82, Get_EDF_FileHeaders\n',CurrentLabel);
%             return;
%         end
% 
%         %Work through them and restore some of the perviously Labelling
%         Edited = false;
%         for k = DuplicatePositions
%             if(~isempty(strfind(SignalHeader(k).Label,'EEG')))
%                 %Restore the EEG Title
%                 SignalHeader(k).NewLabel = sprintf('EEG%s',SignalHeader(k).NewLabel);
%                 Edited = true; %Keep track of how many were Edited
%                 break;
%             end
%         end
% 
%         if(Edited ~= true)
%             WARNING_ERROR('ERROR','Could Not Automatically resolve the duplicate labels');
%             return;
%         end