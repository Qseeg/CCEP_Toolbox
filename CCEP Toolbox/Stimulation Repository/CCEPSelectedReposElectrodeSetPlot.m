
function CCEPSelectedReposElectrodeSetPlot(varargin)
%SelectedElectrodeSetPlot
%Scatter Set section plotting callback


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


%Allocate the required data
StimSelectFig = findobj('Tag','StimSelectFig');
ElectrodeFig = findobj('Tag','SelectedElectrodes');

%Check if the caller is the CCEP GUI - if it is, then delete the figure and
%handles
if iscell(varargin{2}.Source.String)
    ActionSource = varargin{2}.Source.String{1};
else
    ActionSource = varargin{2}.Source.String;
end

%Check if the figure is present
if ~isempty(ElectrodeFig) && ~strcmp(ActionSource,'Plot Selected Electrodes') 
    figure(ElectrodeFig);
    PlotAx = findall(gcf, 'Type','Axes');
    cla(PlotAx);
    
else
    close(ElectrodeFig);
    figure('Units','Normalized','Position',[0 0 1 1],'Name','Selected Electrodes Plot','Tag','SelectedElectrodes');
end

CCEPRepository = StimSelectFig.UserData.CCEPRepository;
ElectrodeFig = findobj('Tag','SelectedElectrodes');
PlotAx = findall(ElectrodeFig, 'Type','Axes');
PointSeriesList = findobj('Tag','PointSeriesList');
ResetButton = findobj('Tag','ResetButton');
CoOrdSpaceButton = findobj('Tag','CoOrdSpace');



%Take the top list if there is more than 1
if length(PointSeriesList)>1
    PointSeriesList = PointSeriesList(1);
end

%CoOrdspace to use
if ~exist('CoOrdSpace', 'var')
    CoOrdSpace = 'MNI';
end
if ~exist('ElectrodeArray', 'var')
    ElectrodeArray = StimSelectFig.UserData.ElectrodeStruct;
end

%If the UI components don't exist, initialise them here
if isempty(PointSeriesList)
    PointSeriesText = uicontrol('style','text','units','normalized','position',[0.01, 0.88, 0.1, 0.1],'String','Patient electrodes to plot','FontSize',20,'HorizontalAlignment','Center');
    PointSeriesList = uicontrol('style','list','units','normalized','position',[0.01, 0.575, 0.1, 0.3],'String',{ElectrodeArray.Patient},'Max',2','Min',0,'Tag','PointSeriesList','Value',1:length(StimSelectFig.UserData.ElectrodeStruct),'FontSize',20,'CallBack',@CCEPSelectedReposElectrodeSetPlot);
end

if isempty(ResetButton)
    ResetText = uicontrol('style','text','units','normalized','position',[0.01, 0.45, 0.1, 0.1],'String','Reset the GUI to show stim locations only','FontSize',20,'HorizontalAlignment','Center');
    ResetButton = uicontrol('style','pushbutton','units','normalized','position',[0.01, 0.37, 0.1, 0.07],'String','Reset','Tag','ResetButton','FontSize',20,'CallBack',@CCEPSelectedReposElectrodePlot);
end

if isempty(CoOrdSpaceButton)
    CoOrdText = uicontrol('style','text','units','normalized','position',[0.01, 0.25, 0.1, 0.1],'String','Select the Co-Ordinate space','FontSize',20,'HorizontalAlignment','Center');
    CoOrdSpaceButton = uicontrol('style','popupmenu','units','normalized','position',[0.01, 0.15, 0.1, 0.1],'String',{'Patient','MNI'},'Tag','CoOrdSpace','FontSize',20,'CallBack',@CCEPSelectedReposElectrodeSetPlot);
else
    CoOrdSpaceButton.Callback = @CCEPSelectedReposElectrodeSetPlot;
end

%Choose the CoOrd Space
if isempty(CoOrdSpaceButton)
    CoOrdSpace = 'Patient';
else
    CoOrdSpace = CoOrdSpaceButton.String{CoOrdSpaceButton.Value};
end


%Clear the axes and plot back on what is required
cla(PlotAx);

%Electrodes data
%Cycle through each of the electrodes
Radius = 50;
LegendStr = {};
for r = 1:length(PointSeriesList.Value)
    %*****If plotting CoOrds in Patient Space
    if strcmp(CoOrdSpace ,'Patient')
        TempX = ElectrodeArray(PointSeriesList.Value(r)).CoOrdSet(:,1);
        TempY = ElectrodeArray(PointSeriesList.Value(r)).CoOrdSet(:,2);
        TempZ = ElectrodeArray(PointSeriesList.Value(r)).CoOrdSet(:,3);
        %*****If plotting CoOrds in MNI Space
    elseif strcmp(CoOrdSpace ,'MNI')
        TempX = ElectrodeArray(PointSeriesList.Value(r)).MNICoOrdSet(:,1);
        TempY = ElectrodeArray(PointSeriesList.Value(r)).MNICoOrdSet(:,2);
        TempZ = ElectrodeArray(PointSeriesList.Value(r)).MNICoOrdSet(:,3);
    end
    scatter3(TempX, TempY, TempZ, Radius, 'filled');
    if r == 1
        TitleString = sprintf('All Electrodes in %s Space',CoOrdSpace);
        title(TitleString,'FontSize',35);
    end
    hold on;
    clearvars TempX TempY TempZ
    LegendStr{r} = ElectrodeArray(PointSeriesList.Value(r)).Patient;
end

%Import the example single patient surface (not amazingly accurate, but
%it's not too bad!)
if ~exist('SurfFile','var')
    SurfFile = which('ExampleBrainSurface.mat');
    if isempty(SurfFile)
        SurfFile = uigetfile('*.mat','Get the Brain Surface File (couldn''t find "ExampleBrainSurface.mat")'); %Get the Surface File as a Gifti
    end
end
load(SurfFile);

%Plot the surface too
if exist('BrainSurf','var')
    BoundingBox = [-78 -112 -70;...
        78 76 85];
    hold on;
    patch('Faces',BrainSurf.faces,'Vertices',BrainSurf.vertices,'EdgeColor','none', 'FaceAlpha',0.1);
    %Rescale the Axes to the normalised images
    axis([BoundingBox(1,1), BoundingBox(2,1), BoundingBox(1,2), BoundingBox(2,2), BoundingBox(1,3), BoundingBox(2,3) ]);
    axis('square');
    xlabel('X Axis (Left-Right)');
    ylabel('Y Axis (Ant-Post)');
    zlabel('Z Axis (Sup-Inf)');
end

%Add the legend
legend(LegendStr,'FontSize',25,'Location','NorthEast');

