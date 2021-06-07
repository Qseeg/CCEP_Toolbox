% Matthew Woolfe 12-4-17
% Load Excel MAP
% Inputs:   MAPfilepath                 Complete Filepath to the Map
% [optional]BipolarSignalStructure      A Structure with field 'Label' to designate the
%                                       Bipolar Map onto.
% Outputs:  BipolarMapStructure         If No SignalStructre was given, this structure
%                                       will be the complete map useful for adding to 
%                                       another structure in the future
%           BipolarSignalStructure      If a Signal Structure was given, this will
%                                       be the Filled out version, now having the
%                                       Anatomy field filled in
%
%Notes: If you have the PatientName you can get the Map using Get_MAPfilepath

function [BipolarMapStructure, BipolarSignalStructure] = Load_Patient_Map_Bipolar(MAPfilepath, BipolarSignalStructure)

    fprintf('Loading Patient Anatomical Map: ');
    
    %Preallocate
    MapStructure = struct('Label',{''},'Anatomy',{''});
    BipolarMapStructure = struct('Label',{''},'Anatomy',{''});
    
    %Check that the MAPfilepath is a legit file
    if(exist(MAPfilepath,'file')~= 2)
        fprintf('\nERROR:\nERROR: The MAPfilepath specified is not valid.\nERROR:\n');
        return;
    end
    
    %Load the Map
    [~,~,Map] = xlsread(MAPfilepath);
    
    %Identify The Contacts
    count = 1;
    for Row = 2:size(Map,1)
        
        %Electrode Label is in the Leftmost Column
        Label = Map{Row,1:size(Map,2)};
        
        Label(int16(Label) == 8217) = '''';                         %Removing the Silly ' symbol sash creates
        Label = regexp(Label,'[a-zA-Z'']*[2]?','match','once');     %Removing the number of contacts that could be with the designator
       %%%%%%%%%%%%%%%%% Optional [2] at the end of the Label for FD Maps %
        
        for Column = size(Map,2):-1:2
            %Label + Column, Colum(size(Map,2)) == 1, 
            MapStructure(count).Label = strcat(Label,num2str(size(Map,2) - Column + 1));
            MapStructure(count).Anatomy = Map{Row,Column};
            MapStructure(count).Electrode = Label;
            MapStructure(count).Contacts = size(Map,2) - Column + 1;
            count = count + 1;
        end
    end
    
    %Sort for the following algorithm
    [~,NaturalOrder] = sort_nat({MapStructure.Label},'ascend');
    MapStructure = MapStructure(NaturalOrder);
    
    %Counter for Bipolar size
    count =1;
    
    %Create a Bipolar Map structure
    for i = 1:size(MapStructure,2)
        
        %Identify the position of the next contact to make a bipolar Pair
        %See if we should even look at this contact
        if(MapStructure(i).Contacts == 15)
            NextContactIndex = [];
            %Option1 check one contact below (Natural order should speed this up)
        elseif(strcmp(MapStructure(i).Electrode,MapStructure(i+1).Electrode)... Same Electrode
                && MapStructure(i).Contacts == (MapStructure(i+1).Contacts - 1)) %The required contact
            NextContactIndex = i + 1;
        else
            %Perform a full search
            NextContactIndex = find(strcmp({MapStructure.Electrode},MapStructure(i).Electrode) & ([MapStructure.Contacts]+1) == MapStructure(i).Contacts);
        end
        
        %If we couldnt find the next contact then do not create a bipolar
        %entry for the current contact
        if(~isempty(NextContactIndex))
            
            BipolarMapStructure(count).Label = [MapStructure(i).Electrode,num2str(MapStructure(i).Contacts),'-',num2str(MapStructure(NextContactIndex).Contacts)];
            if(strcmp(MapStructure(i).Anatomy,MapStructure(NextContactIndex).Anatomy))
                BipolarMapStructure(count).Anatomy = MapStructure(i).Anatomy;
            else
                BipolarMapStructure(count).Anatomy = [MapStructure(i).Anatomy,'-',MapStructure(NextContactIndex).Anatomy];
            end
            BipolarMapStructure(count).Electrode = MapStructure(i).Electrode;
            BipolarMapStructure(count).Contacts = [MapStructure(i).Contacts,MapStructure(NextContactIndex).Contacts];
            
            count = count + 1;
            
        end
    end
    

    
    if(nargout>1)
        %If no SignalStructrue for the map was given, but one was expected
        %as return ERROR
        if(~nargin>1)
            fprintf('\nERROR:\nERROR: Requested a Allocation of the Map to SignalStructure without \nGiving a SignalStrurcture in Load_Patient_Map_Bipolar\nERROR:\n');
            SignalStructre(1).Label = '';
            return;
        end
        
        
        %If a SignalStructure was given and requested as output, update given the Current Map
        if(nargin == 2)
            
            %Match the BipolarSignalStructure to the MapStructure
            for Index = 1:size(BipolarSignalStructure,2)
                MatchIndex = find(strcmp({BipolarMapStructure.Label},BipolarSignalStructure(Index).Label));
                
                if(~isempty(MatchIndex))
                    BipolarSignalStructure(Index).Anatomy = BipolarMapStructure(MatchIndex).Anatomy;
                else
                    BipolarSignalStructure(Index).Anatomy = 'Unknown';
                end
                
            end
            
            if(~isfield(BipolarSignalStructure,'Contacts'))
            
                BipolarSignalStructure = Fill_Contact_Information_Bipolar(BipolarSignalStructure);
            end
        end
    end
    
    fprintf('Complete\n');
end

    

    
% %     for Index = 1:size(MapStructure,2)-1
% %         CurrentLabel = regexp(MapStructure(Index).Label,'^[a-zA-Z]{1,2}['']?','match','ONCE');
% %         NextLabel =    regexp(MapStructure(Index+1).Label,'^[a-zA-Z]{1,2}['']?','match','ONCE');
% %         
% %         if(strcmp(CurrentLabel,NextLabel))
% %             %Check the Contacts
% %             CurrentContact = str2double(regexp(BipolarMapStructure(Index).Label,'[0-9]{1,2}$','match','ONCE'));
% %             NextContact = str2double(regexp(BipolarMapStructure(Index+1).Label,'[0-9]{1,2}$','match','ONCE'));
% %             
% %             if(CurrentContact+1 == NextContact)
% %                 %These are suitable for bipolar
% %                 BipolarMapStructure(count).Label = [CurrentLabel,num2str(CurrentContact),'-',num2str(NextContact)];
% %                 %BipolarMapStructure(count).Designator = CurrentLabel;
% %                 BipolarMapStructure(count).Contacts = [CurrentContact NextContact];
% %                 
% %                 
% %                 %Create the Anatomy field
% %                 if(strcmp(BipolarMapStructure(Index).Anatomy,BipolarMapStructure(Index+1).Anatomy))
% %                     BipolarMapStructure(count).Anatomy = BipolarMapStructure(Index).Anatomy;
% %                 else
% %                     BipolarMapStructure(count).Anatomy = [BipolarMapStructure(Index).Anatomy,'-',BipolarMapStructure(Index+1).Anatomy];
% %                 end
% %                 
% %                 count = count + 1;
% %             end
% %         end

%Fill the Bipolar Structure
%        [BipolarSignalStructure] = Fill_Contact_Information_Bipolar(BipolarSignalStructure);
    