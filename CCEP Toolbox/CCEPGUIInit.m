%Create the Main Menu Figure and initialise the file trees for the 


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                     %
%%%         Main Figure Initiation section          %%%
%                                                     %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
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


%Initialise the main figure properties and load the default settings for
%the parameters.

%First add all of the downstream folders from this functions location, 
%then add load in the default settings.
%***  The CCEPGUIInit file must be in the CCEP toolbox location folder ***%   
[MainFolder, ~,~] = fileparts(which('CCEPGUIInit')); 
addpath(genpath(MainFolder)); %If an error occurs here, check that the CCEPGUIInit file is in the "CCEP Toolbox" folder
CCEPGUIParams = CCEPInitialisationParams;

%Initialise the Main Figure and close down/restart all of the windows which
%could already exist.
if ~isempty(findobj('Tag','CCEPGUIMainFig'))
    DeleteFig = findobj('Tag','CCEPGUIMainFig');
   for a = 1:length(DeleteFig)
       close(DeleteFig(a));
   end 
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%           CCEPGUI Main Menu Figure Init         %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
MainFig = figure('name','CCEPGUIMainFig','Tag','CCEPGUIMainFig','units','pixels', 'position',[50 200 500 650]);
MainFig.UserData = CCEPGUIParams; 

%Intialise the GUI panel trees for each of the different subtree operations
CCEPGUIText = uicontrol('tag','CCEPGUIText','style','text',...
          'Units','Normalized','Position',[0.025 0.90 0.95 0.10],...
          'String','CCEP GUI Main Menu','FontSize',20);
      

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%      Alter the default parameters               %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%      
%This button will simply open the CCEPInitialisationParams script 
%to be allow users to able to change the defaults
uicontrol('tag', 'ParamOpenButton', 'style', 'pushbutton',...
          'Units', 'Normalized', 'Position', [0.025 0.86 0.95 0.07],...
          'String', 'Alter and set default parameters',...
          'FontSize',14, 'callback', 'edit CCEPInitialisationParams');
      
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%      Stim safety computation                    %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Bring up an SEEG data viewer in order to get the windows and ERP trigger
%times from the SEEG viewer.
uicontrol('style', 'pushbutton','Tag', 'CCEPStimSafetyButton',...
          'Units', 'Normalized','Position', [0.025 0.79 0.95 0.07],...
          'String', 'Check recommended stimulation parameters',...
          'FontSize', 14, 'Callback', @CCEPStimSafetyGUI);      
      
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%                 Add Folder Button               %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%Create a button to add the button to the file tree (matlab path)

%This button will then open up a dialog where you can add folders to the
%path (either for this session or as a permanent action)
uicontrol('tag', 'PathAddButton', 'style', 'pushbutton',...
          'Units', 'Normalized', 'Position', [0.025 0.72 0.95 0.07],...
          'String', 'Add files and folders to the path',...
          'FontSize',14, 'callback', @FilePathMenu);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  MRI and CT coregistration and Image manipulation   %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Acquire the MRI and CT files in which to get the electrode co-ordinates.
%This is a  menu that may not actually be neccessary (Matt's file GUI might
%be more useful to acquire the MRI and CT positions. Initialise the buttons 
%for callbacks and the text

%The Image processing heading text
    uicontrol('tag','CCEPGUIText','style','text',...
        'Units','Normalized','Position',[0.025 0.63 0.95 0.08],...
        'String','Image processing','FontSize',18);
    
%The pre-processing intialisation button
    uicontrol('tag', 'SPMMRCTPreProcess','style', 'pushbutton',...
        'Units', 'Normalized','Position',[0.025 0.58 0.95 0.07],...
        'String', sprintf('Preprocess an MRI and CT'),...
        'FontSize', 14, 'callback', 'CCEPMRICTPreprocessing;');      
%Acquire the CoOrds    
    uicontrol('tag', 'SPMCoOrdAcquire','style', 'pushbutton',...
        'Units', 'Normalized','Position',[0.025 0.51 0.95 0.07],...
        'String', sprintf('Acquire electrode positions and create electrode file'),...
        'FontSize', 14, 'callback', 'CCEPSPMCoOrdGUIInit;');
%Show the electrode surface for a single patient
    uicontrol('tag', 'SPMMRCTPreProcess','style', 'pushbutton',...
        'Units', 'Normalized','Position',[0.025 0.44 0.95 0.07],...
        'String', sprintf('Display processed electrodes for a patient'),...
        'FontSize', 14, 'callback', 'CCEPElectrodePlotter;');
    
    

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%              Data  processing menu              %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Section contains the CCEPSEEGViewer and the CCEPProcess RMS File menus.
%These are used to check the SEEG data and alter and create CCEP
%annotations in the file. This will also be where RMS files are processed
%to be viewed later on.

%The SEEG data processing and viewing heading text
    uicontrol('tag','CCEPGUIText','style','text',...
        'Units','Normalized','Position',[0.025 0.35 0.95 0.08],...
        'String','SEEG data processing','FontSize',18);
    
%The SEEG data viewing and annotation editor callback
    uicontrol('tag', 'CCEPSEEGView','style', 'pushbutton',...
        'Units', 'Normalized','Position',[0.025 0.3 0.95 0.07],...
        'String', sprintf('View SEEG files and alter annotations'),...
        'FontSize', 14, 'callback', @CCEPSEEGViewerCallback);      
%Acquire the CoOrds    
    uicontrol('tag', 'CCEPProcessRMS','style', 'pushbutton',...
        'Units', 'Normalized','Position',[0.025 0.23 0.95 0.07],...
        'String', sprintf('Process CCEP data files'),...
        'FontSize', 14, 'callback', @CCEPProcessRMS);    


% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% %%%            Stimulation repository Menu          %%%
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% %Generate the menu to be able to create and alter the stimulation
% %repository and other look through the compiled results files that have
% been added to it

%The CCEP repository and results viewing heading text
    uicontrol('tag','CCEPGUIText','style','text',...
        'Units','Normalized','Position',[0.025 0.15 0.95 0.07],...
        'String','Create repository and view results','FontSize',18);
    
%The SEEG data viewing and annotation editor callback
    uicontrol('tag', 'CCEPSEEGView','style', 'pushbutton',...
        'Units', 'Normalized','Position',[0.025 0.09 0.95 0.07],...
        'String', sprintf('Add file to CCEP repository'),...
        'FontSize', 14, 'callback', @CCEPRepositoryUpdateIndividual);      
%Acquire the CoOrds    
    uicontrol('tag', 'CCEPProcessRMS','style', 'pushbutton',...
        'Units', 'Normalized','Position',[0.025 0.02 0.95 0.07],...
        'String', sprintf('View results and perfrom connectivity analyses'),...
        'FontSize', 14, 'callback', @CCEPReposGUI);  



