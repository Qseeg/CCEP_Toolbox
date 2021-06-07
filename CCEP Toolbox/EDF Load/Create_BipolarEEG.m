%Matthew Woolfe 5-4-17
%Subtracts ReferentialEEG to create a Bipolar representation
%The function requires the 'Electrode' and 'Contact' fields be filled
%If this is not filled, Fill_Contact_Information will be run

function [BipolarEEG] = Create_BipolarEEG(ReferentialEEG)
    
    %Preallocation
    BipolarEEG = struct('Label',[],'EEG',[],'Electrode',[],'Contacts',[],'Anatomy',{});

    %Error checking
    if(isempty(ReferentialEEG))
        fprintf('\nERROR:\nERROR: Empty Input structure\nERROR:\n');
        return;
    end
    %Check that the input is correct
    if(~isstruct(ReferentialEEG))
        fprintf('\nERROR:\nERROR: Incorrect Input type\nERROR:\n');
        return;
    end
    
    fprintf('Creating The Bipolar EEG Structure:     ');
    
    %Check that the 'Electrode' and 'Contact' Fields are available
    if(~isfield(ReferentialEEG,{'Electrode','Contact'}))
        %Run Fill_Contact_Inforamtion
        [ReferentialEEG] = Fill_Contact_Information(ReferentialEEG);
    end
    
    count = 1;
    Progress = linspace(0,100- (100/size(ReferentialEEG,2)),size(ReferentialEEG,2));
    for Ch = 1:size(ReferentialEEG,2)-1
        
        %Identify the Channels that are SEEG 
        if(strcmp(ReferentialEEG(Ch).Electrode,ReferentialEEG(Ch+1).Electrode) && (ReferentialEEG(Ch+1).Contact - ReferentialEEG(Ch).Contact == 1))
            
            %Label
            BipolarEEG(count).Label = [ReferentialEEG(Ch).Electrode,num2str(ReferentialEEG(Ch).Contact),'-',num2str(ReferentialEEG(Ch+1).Contact)];
            
            %EEG
            BipolarEEG(count).EEG = ReferentialEEG(Ch).EEG-ReferentialEEG(Ch+1).EEG;
            
            %Anatomy
            if(isfield(ReferentialEEG,'Anatomy'))
                if(strcmp(ReferentialEEG(Ch).Anatomy,ReferentialEEG(Ch+1).Anatomy))
                    BipolarEEG(count).Anatomy = ReferentialEEG(Ch).Anatomy;
                else
                    BipolarEEG(count).Anatomy = [ReferentialEEG(Ch).Anatomy,'-',ReferentialEEG(Ch+1).Anatomy];
                end
            end
            
            %Electrode
            BipolarEEG(count).Electrode = ReferentialEEG(Ch).Electrode;
            
            %Contacts
            BipolarEEG(count).Contacts = [ReferentialEEG(Ch).Contact ReferentialEEG(Ch+1).Contact];
            
            %increment counter
            count = count + 1;
            
         %Remove The Other Channels
        elseif(ReferentialEEG(Ch).Contact == 0)                      %elseif(strcmp(ReferentialEEG(Ch).Electrode,'Other'))
            %Label
            BipolarEEG(count).Label = ReferentialEEG(Ch).Label;
            %EEG
            BipolarEEG(count).EEG = ReferentialEEG(Ch).EEG;
            %Anatomy
            BipolarEEG(count).Anatomy = '';
            %Electrode
            BipolarEEG(count).Electrode = ReferentialEEG(Ch).Electrode;
            %Contacts
            BipolarEEG(count).Contacts = 0;
            %increment counter
            count = count + 1;
        end
        
        fprintf('\b\b\b%3.0f',Progress(Ch));
    end
    
    if(ReferentialEEG(end).Contact == 0)                      
        %Label
        BipolarEEG(count).Label = ReferentialEEG(end).Label;
        %EEG
        BipolarEEG(count).EEG = ReferentialEEG(end).EEG;
        %Anatomy
        BipolarEEG(count).Anatomy = '';
        %Electrode
        BipolarEEG(count).Electrode = ReferentialEEG(end).Electrode;
        %Contacts
        BipolarEEG(count).Contacts = 0;
    end
    
    fprintf('\b\b\bComplete\n');
        
end

% BipolarEEG.Label = '';
% BipolarEEG.EEG = [];
% BipolarEEG.Anatomy = '';
% BipolarEEG.Electrode = '';
% BipolarEEG.Contacts = [];