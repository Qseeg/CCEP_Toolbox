% Matthew Woolfe 5-4-17
% Load Excel MAP
% Inputs:   MAPfilepath         Complete Filepath to the Map
%           SignalStructure     A Structure with field 'Label' to designate the
%                               Map onto.
% Outputs:  MapStructure        If No SignalStructre was given, this structure
%                               will be the complete map useful for adding to 
%                               another structure in the future
%           SignalStructure     If a Signal Structure was given, this will
%                               be the Filled out version, now having the
%                               Anatomy field filled in
%
%Notes: If you have the PatientName you can get the Map using Get_MAPfilepath

function [MapStructure, SignalStructure] = Load_Patient_Map(MAPfilepath, SignalStructure)

    fprintf('Loading Patient Anatomical Map: ');
    
    %Preallocate
    MapStructure(1).Label = '';
    MapStructure(1).Anatomy = '';
    
    if(isempty(MAPfilepath))
        fprintf('No MAP filepath\n');
        return;
    end
    
    %Check that the MAPfilepath is a legit file
    if(exist(MAPfilepath,'file')~= 2)
        WARNING_ERROR('WARNING','The MAPfilepath specified is not valid');
        return;
    end
    
    %Load the Map
    [~,~,Map] = xlsread(MAPfilepath);
    
    %Remove Nan columns
    for C = size(Map,2):-1:1
        if( any(~ cellfun(@(x) isnan(x(1)), Map(:,C))) )
            break;
        else
            Map = Map(:,1:C-1);
        end
    end
    
    %Identify The Contacts
    count = 1;
    for Row = 2:size(Map,1)
        
        %Electrode Label is in the Leftmost Column
        Label = Map{Row,1:size(Map,2)};
        
        %Check that it is a valid row
        if(isnan(Label))
            continue;
        end
        
        Label(int16(Label) == 8217) = '''';                   %Removing the Silly ' symbol sash creates
        Label = regexp(Label,'[a-zA-Z'']*[2]?','match','once');   %Removing the number of contacts that could be with the designator
       %%%%%%%%%%%%%%%%% Optional [2] at the end of the Label for FD Maps %
            
        for Column = size(Map,2):-1:2
            %Check that the entry is not a nan
            if(isnan(Map{Row,Column}))
                continue;
            end
            
            MapStructure(count).Label = strcat(Label,num2str(size(Map,2) - Column + 1));
            MapStructure(count).Anatomy = Map{Row,Column};
            count = count + 1;
        end
    end
    
    
    if(nargout>1)
        %If no SignalStructrue for the map was given, but one was expected
        %as return ERROR
        if(~nargin>1)
            fprintf('\nERROR:\nERROR: Requested a Allocation of the Map to SignalStructure without \nGiving a SignalStrurcture in Load_Patient_Map\nERROR:\n');
            SignalStructre(1).Label = '';
            return;
        end
        
        %If a SignalStructure was given and requested as output, update
        %given the Current Map
        if(nargin == 2)
           %Update the SignalStructure Through matching
           MapString = {MapStructure(:).Label};
           temp = 1:size(MapString,2);
           for Ch = 1:size(SignalStructure,2)
               Index = temp(strcmp(MapString,SignalStructure(Ch).Label));
               if(~isempty(Index))
                   SignalStructure(Ch).Anatomy = MapStructure(Index).Anatomy;
               end
           end
        end
    end
    
    fprintf('Complete\n');
end

    
    
    
    %         %Get Number of Contacts for that electrode
%         Contacts = isstrprop(MapStructure(Row-1).RawLabel,'digit');
%         if(sum(Contacts)==0)
%             MapStructure(Row-1).Label = MapStructure(Row-1).RawLabel;
%             MapStructure(Row-1).Contacts = 15; %Default number
%         else
%             MapStructure(Row-1).Label = MapStructure(Row-1).RawLabel(~Contacts);
%             MapStructure(Row-1).Contacts = str2num(MapStructure(Row-1).RawLabel(Contacts));
%         end
%         
%         %Anatomy
%         for Column = size(Map,2):-1:2
%             MapStructure(Row-1).Anatomy{Map{1,Column}} = Map{Row,Column};
%         end
    
        %Remove the RawLabel field as it is useless after here
    %MapStructure = rmfield(MapStructure,'RawLabel');