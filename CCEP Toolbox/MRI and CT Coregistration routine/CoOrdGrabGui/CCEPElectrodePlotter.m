function CCEPElectrodePlotter(varargin)
%CCEPElectrodePlotter('ElectrodeFile'|'File',ElectrodeMatFile,'SurfaceFile'|'BrainSurf',BrainSurfGiftiFile,'CoOrd'|'Space',PatientorMNISpace)


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

CoOrdSpace = 'Patient'; %Default to plotting patient space CoOrds
if nargin == 0
    [PositionsFile,TempPath] = uigetfile('*.*','Get the Electrodes File'); %Get the CoOrds
    addpath(TempPath);
else
    for i = 1:2:length(varargin) %Go through every 2nd value of the name-value pair argument
        InputStr = varargin{i}; %Pop the inputs into a string to get the information out
        if ~isempty(regexpi(InputStr,'Elec')) || ~isempty(regexpi(InputStr,'file')) %Find the name of all of the files that are coming into each of the files
            if isstruct(varargin{i+1})
                ElectrodeArray = varargin{i+1};
                PositionsFile = ' ';
            else
                PositionsFile = which(varargin{i+1});
            end
        elseif ~isempty(regexpi(InputStr,'Surf'))||~isempty(regexpi(InputStr,'brai')) %Read in the data structures
            SurfFile = varargin{i+1};
        elseif ~isempty(regexpi(InputStr,'Space'))||~isempty(regexpi(InputStr,'CoOrd')) %Read in the data structures
            %Read in which space to plot the CoOrds in, using the default
            %of Patient space from before
            if ~isempty(regexpi(varargin{i+1},'pati'))
                CoOrdSpace = 'Patient';
            elseif ~isempty(regexpi(varargin{i+1},'MNI'))
                CoOrdSpace = 'MNI';
            end
        end
    end
end

%Import the example single patient surface (not amazingly accurate, but
%it's not too bad!)
if ~exist('SurfFile','var')
    SurfFile = which('ExampleBrainSurface.mat');
    if isempty(SurfFile)
        SurfFile = uigetfile('*.mat','Get the Brain Surface File (couldn''t find "ExampleBrainSurface.mat")'); %Get the Surface File as a Gifti
    end
end

if ~exist('PositionsFile','var')
    PositionsFile = uigetfile('*.*','Get the Electrodes File'); %Get the CoOrds
end

BoundingBox = [-78 -112 -70;...
    78 76 85];

if ~exist('ElectrodeArray','var')
    load(PositionsFile);
    DataArray = ElectrodeArray;
else
    DataArray = ElectrodeArray;
end
load(SurfFile);

%Create the figure
figure('name',sprintf('%s Electrodes', ElectrodeArray(1).Patient),'units','normalized','position',[0.01 0.01 0.9 0.9],'Tag','ElectrodePlotFig');

%Add a diclaimer in case people get scared if their electrodes are outside
%of the brain surface
uicontrol('style','text','string','*Surface is generic and is approximate only*','units','normalized','position',[0.8, 0.8 0.15 0.1],'FontSize',20,'ForegroundColor','Red');

%Cycle through each of the electrodes
Radius = 50;
for r = 1:length(DataArray)
    %     Len = length(DataArray(r).Positions);
    %     for u = 1:Len
    %*****If plotting CoOrds in Patient Space
    if strcmp(CoOrdSpace ,'Patient')
        if isfield(DataArray,'Positions')
            TempX = DataArray(r).Positions(:,1);
            TempY = DataArray(r).Positions(:,2);
            TempZ = DataArray(r).Positions(:,3);
        elseif isfield(DataArray,'PosMM')
            TempX = DataArray(r).PosMM(:,1);
            TempY = DataArray(r).PosMM(:,2);
            TempZ = DataArray(r).PosMM(:,3);
        end
        %*****If plotting CoOrds in MNI Space
    elseif strcmp(CoOrdSpace ,'MNI')
        if isfield(DataArray,'PosMNI')
            TempX = DataArray(r).PosMNI(:,1);
            TempY = DataArray(r).PosMNI(:,2);
            TempZ = DataArray(r).PosMNI(:,3);
        end
    end
    scatter3(TempX, TempY, TempZ, Radius, 'filled');
    if r == 1
        TitleString = sprintf('%s Electrodes in %s Space',ElectrodeArray(1).Patient,CoOrdSpace);
        title(TitleString,'FontSize',30);
    end
    hold on;
    
    %Put the lines and text for the electrode names on the electrodes to
    %know which is which
    line([TempX(1), TempX(end)], [TempY(1),TempY(end)], [TempZ(1), TempZ(end)], 'color', 'k', 'linewidth',2);
    if TempX(end)<0
        text(TempX(end) - 3, TempY(end) + 3, TempZ(end) + 3, DataArray(r).ElectrodeName,'FontSize',15);
    else
        text(TempX(end) + 3, TempY(end) + 3, TempZ(end) + 3, DataArray(r).ElectrodeName,'FontSize',15);
    end
    clearvars TempX TempY TempZ;
    
end

if exist('BrainSurf','var')
    hold on;
    patch('Faces',BrainSurf.faces,'Vertices',BrainSurf.vertices,'EdgeColor','none', 'FaceAlpha',0.1);
    %Rescale the Axes to the normalised images
    axis([BoundingBox(1,1), BoundingBox(2,1), BoundingBox(1,2), BoundingBox(2,2), BoundingBox(1,3), BoundingBox(2,3) ]);
    axis('square');
    xlabel('X Axis (Left-Right)');
    ylabel('Y Axis (Ant-Post)');
    zlabel('Z Axis (Sup-Inf)');
end



