function CCEPERPReference(varargin)

% Copyright 2020 QIMR Berghofer Medical Research Institute
% Author: David Prime
% 
% This program is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
% 
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
% 
% You should have received a copy of the GNU General Public License
% along with this program.  If not, see <https://www.gnu.org/licenses/>.


%Get the figure and relevant uicontrols
CCEPERPFig = findobj('Tag','CCEPERPFig');
FileMenu = findobj(CCEPERPFig,'Tag','FileMenu');

%If a different datafile is needed, continue to load everything in
StimSelectFig = findobj('Tag','StimSelectFig');
ReferenceButton = findobj(CCEPERPFig,'Tag','ReferenceButton');
PlotChannelList = findobj(CCEPERPFig,'Tag','PlotChannelList');
TempRepos = CCEPERPFig.UserData.CCEPRepository;


%Toggle the label on the reference button
if strcmp(ReferenceButton.String,'Unipolar')
   ReferenceButton.String = 'Bipolar'; 
else
    ReferenceButton.String = 'Unipolar'; 
end

%Load in the data form the ERP File    
DataStruct = CCEPERPFig.UserData.DataStruct;

%Create the list for the channel information to plot the ERPs relevant to
%the File and Reference chosen

%First find if there are contact selected in the current referencing
%arrangement
%*************Do this later************
if strcmp(ReferenceButton.String,'Unipolar')
    PlotChannelList.Value = [];
    TempStr = {};
    for a = 1:length(DataStruct.Uni)
        TempStr{a} = sprintf('%s (%s)',DataStruct.Uni(a).Label,DataStruct.Uni(a).Anatomical);
    end
    PlotChannelList.String = TempStr;
    
    %For the Bipolar case
else
    PlotChannelList.Value = [];
    TempStr = {};
    for a = 1:length(DataStruct.Bi)
        TempStr{a} = sprintf('%s (%s)',DataStruct.Bi(a).Label,DataStruct.Bi(a).Anatomical);
    end
    PlotChannelList.String = TempStr;
end


