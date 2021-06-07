function CCEPGUIParams = CCEPInitialisationParams
%CCEPGUIParams = CCEPInitialisationParams;
%   This function gets the saved parameters from the menu 
%   so that you don't have to adjust the parameters time and time again. 
%   It also gets the directory of the CCEPs repository and the other
%   locations. 
%
%****To adjust the default parameters, look for the critical parameters
%midway through this function and change them. Then follow the instructions
%to delete the previous parameter structure and create a new structure ****
%

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


%Load the currently saved default parameters
try 
    load(which('Current CCEP GUI Init Parameters.mat'));
    addpath(CCEPGUIParams.CurrentPath);
    if CCEPGUIParams.Verbosity == 1
     fprintf('Loaded current default paramters\n');
    end
    
%If there is a problem loading the deault parameters (in case the file was
%deleted or corrupted during a save - make a new defaults file and inform
%the user
catch 
    fprintf('There was a problem with the default parameters .mat file.\nCreated a new file for the default parameters\nAll previous CCEPGUI paths erased (ignore this if it''s the first time run)\n')
    [MainFolder, ~,~] = fileparts(which('CCEPGUIInit'));
    
    %Set the default parameters based
    CCEPGUIParams.MainFolder = MainFolder;
    CCEPGUIParams.Verbosity = 1;
    CCEPGUIParams.RepositoryLocation = MainFolder;
    CCEPGUIParams.ParameterFile = fullfile(MainFolder, filesep, 'Parameters and intialisation', filesep,'Current CCEP GUI Init Parameters.mat');
    
    %File path parameters
    CCEPGUIParams.StartFolder = MainFolder;
    CCEPGUIParams.CurrentPath = genpath(MainFolder);
    addpath(genpath(MainFolder));
    
    %Current CCEP repository location and file - if one does not exist, then
    %create one
    [RepositoryFolder, ~,~] = fileparts(which('CurrentCCEPRepository.mat'));
    if isempty(RepositoryFolder)
       CCEPRepository = []; 
       CurrentRepository = fullfile(MainFolder, filesep, 'Stimulation Repository', filesep,'CurrentCCEPRepository.mat');
       save(CurrentRepository,'CCEPRepository','-v6'); 
    end
    CCEPGUIParams.CurrentRepository = which('CurrentCCEPRepository.mat');
    
    %********************CRITICAL PARAMETERS****************
    %*** If changing parameters, please first delete the existing "CCEPGUIParamsFile" using the line below, then run this code again ***%
    %TempFile = which('Current CCEP GUI Init Parameters.mat'); if ~isempty(TempFile); delete(TempFile); fprintf('Deleted Current Params File\n'); end
    
    %Data importing settings 
    CCEPGUIParams.DefaultSamplingRate = 1000; %Allocate a default sampling rate (change to your sampling rate)
    CCEPGUIParams.DefaultStimLabel = 'DC09'; %If you use a trigger (sync) channel concurrent with the EEG data, put the label in here
    
    %Notch filtering settings
    PowerFreq = 50; %Set the powerline frequency to 50Hz (default to Australia/Europe)
    CCEPGUIParams.Notch = [PowerFreq-2 PowerFreq+2]; 
    
    %Define the highpass filter (HPF) and low pass filter (LPF) cutoffs
    CCEPGUIParams.HPF = 1; %Above 1Hz
    CCEPGUIParams.LPF = round(0.3*CCEPGUIParams.DefaultSamplingRate); %Below ~300Hz
   
    
    %Nominate the channel labels in the acquisition montage to ignore
    %(because they are system channels or scalp channels or similar)
    %****CHANNELS CONTAINING THESE STRING FRAGMENTS IN THE EDF MONTAGE WILL BE IGNORED AND NOT IMPORTED****
    BadChannelLabels = {'DC','ECG','EKG','SP','$','FZ','CZ','PZ','CO2'}; %Feel free to change this or add to it and send me an email to ask what it means 
    for a = 1:length(BadChannelLabels)
        if a == 1
            CompiledString = BadChannelLabels{a};
        else
        CompiledString = sprintf('%s|%s',CompiledString,BadChannelLabels{a});
        end
    end
    %Get the default string for the list of channels which are reference or system channels, not SEEG/ECoG channels
    CCEPGUIParams.BadLabels = CompiledString; 
    
    %Input the minimum number of pulses for a valid pulse train (tailor to
    %your study). Five pulses are the default
    CCEPGUIParams.MinPulses = 5; 
    
    %Give a list of the default channels to be excluded from the analysis
    %of all anatomical sites
    CCEPGUIParams.AnatomicalExclude = {'CYST','lesion','IH','Ventricle','Heterotopia','hamartoma','gliosis','flat signal','WM','tissue','sylfis'};
    
    %Get some of the stim safety data tables - these should be fine for
    %your computer (just locations and filenames)
    CCEPGUIParams.CCEPSafetyXLSheet = 'CCEP Studies Supplementary Tables and Papers.xlsx';
    CCEPGUIParams.CCEPStimSafetyTable = 'CCEPStimSafetyTable.mat';
    
    %Save the CCEP GUI parameters
    save(CCEPGUIParams.ParameterFile, 'CCEPGUIParams','-v6');
   
end
    
    





