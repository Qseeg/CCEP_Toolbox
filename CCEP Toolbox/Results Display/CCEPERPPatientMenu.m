function CCEPERPFileMenu(varargin)
%CCEPERPPatientMenu - works with CCEPERPViewer

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
StimSelectFig = findobj('Tag','StimSelectFig');
PulseTrainSelectList = findobj(CCEPERPFig,'Tag','PulseTrainSelectList');
PatientMenu = findobj(CCEPERPFig,'Tag','PatientMenu');
TempRepos = CCEPERPFig.UserData.CCEPRepository;

%Select the repos relevant to the patients which are used and only use them
Ind = strcmp({TempRepos.Name},PatientMenu.String{PatientMenu.Value});
TempRepos = TempRepos(Ind);
CCEPERPFig.UserData.TempRepository = TempRepos;

%Allocate the strings to put in the temp repository list
for a = 1:length(TempRepos)
TempStr{a} = sprintf('%s %s (%s) at %2.1gmA and %2.1gHz ',TempRepos(a).Name,TempRepos(a).Label,TempRepos(a).Anatomical,TempRepos(a).Level,TempRepos(a).Frequency);
end

%Allocate this to the CCEPERPFig and PulseTrainList
CCEPERPFig.UserData.PulseTrainString = TempStr;
PulseTrainSelectList.Value = 1;
PulseTrainSelectList.String = TempStr;