%Matthew Woolfe 5-4-17
% Get the Electrode,Contact Position and ID for each channel in a
% SignalStructure
% Inputs:   SignalStructure     Structure with field Label
% Outputs:  SignalStructure     The same as input with filled out fields:
%                               Electrode
%                               Contact
%                               ID

function [SignalStructure] = Fill_Contact_Information(SignalStructure)
    
    %Error Checking
    if(~isstruct(SignalStructure))
        fprintf('\nERROR:\nERROR: Incorrect Input, Required a Structure\nERROR:\n');
        return;
    elseif(~isfield(SignalStructure,'Label'))
        fprintf('\nERROR:\nERROR: Input Structure requires a ''Label'' Field to operate along\nERROR:\n');
        return;
    end
    
    for Channel = 1:size(SignalStructure,2)
        [~,SignalStructure(Channel).Electrode, SignalStructure(Channel).Contact] = LabelCheck(SignalStructure(Channel).Label);
    end

end


%     %There must be the Correct Field in the input Structure
%     for Index = 1:size(SignalStructure,2)
%         if(isempty(regexp(SignalStructure(Index).Label,'^[a-zA-Z]{1,2}['']?[0-9]{1,2}$','ONCE')))
%             %Mark Channels that do not fit our SEEG Channel Description as 'Others'
%             SignalStructure(Index).Electrode = 'Other';
%             SignalStructure(Index).Contact = 0;
%         elseif(~isempty(regexp(SignalStructure(Index).Label,'DC\d*','ONCE')))
%             %Mark Channels that do not fit our SEEG Channel Description as 'Others'
%             SignalStructure(Index).Electrode = 'Other';
%             SignalStructure(Index).Contact = 0;
%         elseif(~isempty(regexp(Label,'^[a-zA-Z]{1,2}['']?[2]{1,1}[0-9]{1,2}$','ONCE')))
%                 %This Expression is for FD, where a second implantation was
%                 %attempted. Each of the new Electrodes have a 2 after thier
%                 %letters. The new Format LETTER[Optional LETTER]2[Optional ']NUMBER[Optional NUMBER]
%                 SignalStructure(Index).Electrode = char(regexp(SignalStructure(Index).Label,'^[a-zA-Z]{1,2}[2]{1,1}['']?','match'));
%                 SignalStructure(Index).Contact = str2double(SignalStructure(Index).Label(length(SignalStructure(Index).Electrode)+1:end));
%         else
%             %These Channels Are SEEG channels
%             SignalStructure(Index).Electrode = char(regexp(SignalStructure(Index).Label,'^[a-zA-Z]{1,2}['']?','match'));
%             SignalStructure(Index).Contact = str2double(SignalStructure(Index).Label(length(SignalStructure(Index).Electrode)+1:end));
%         end
%     end
