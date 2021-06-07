function [FigHandle, PlotHandles] = CCEPCustomSubplot(varargin)
%[FigHandle, PlotHandles] = CustomSubplot('Figure',FigureToWriteTo,'NumPlots',NumPlots,'NumX',NumberofXAxes,'NumY',NumberofYAxes,'Border',[XBorder,YBorder],'XGap',GapInXPlots,'YGap',GapInYPlots,'PlotOffset',[OffsetXStart OffsetXStop OffsetYStart OffsetYStop]);
%
%FigureToWriteTo = Tag of the figure to write to
%NumX = Num Plots in X dim
%NumY = Num Plots in Y dim
%BorderDims = Borders of plot ([BorderX, BorderY])
%XGap = Gap between plots in X dimension
%YGap = Gap between plots in Y dimension
%
%FigHandle = Figure that was plotted into
%PlotHandles = plot handles to the axes that were created


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


%Parse the inputs
for i = 1:2:length(varargin) %Go through every 2nd value of the name-value pair argument
    InputStr = varargin{i};
    if ~isempty(regexpi(InputStr,'ax')) %Num PLots in total
        NumAxes = varargin{i+1};
    elseif ~isempty(regexpi(InputStr,'numx')) %Num PLots in X Dim
        NumX = varargin{i+1};
    elseif ~isempty(regexpi(InputStr,'numy')) %Num PLots in Y Dim
        NumY = varargin{i+1};
    elseif ~isempty(regexpi(InputStr,'bord')) %Border Lengths
        BorderDims = varargin{i+1};
    elseif ~isempty(regexpi(InputStr,'xgap')) %Gaps in X plots ( if more than 1 plot in X)
        XGap = varargin{i+1};
    elseif ~isempty(regexpi(InputStr,'ygap')) %Gaps in Y plots ( if more than 1 plot in Y)
        YGap = varargin{i+1};
    elseif ~isempty(regexpi(InputStr,'off')) %Offsets of X and Y plotting locations
        PlotOffset = varargin{i+1};
    elseif ~isempty(regexpi(InputStr,'Fig')) %Try to find the name or tag of the figure if requested to plot into a different one
        if isnumeric(varargin{i+1})
            FigHandle = findobj('Number',varargin{i+1}); %Check the number of the figure passed to the Function
        elseif ischar(varargin{i+1})
            FigHandle = findobj('Tag',varargin{i+1}); %Check the name and tags if they were passed to the
            if isempty(FigHandle)
                FigHandle = findobj('Name',varargin{i+1});
            end
        end
    end
end

%Get the number of plots to be a function of X and Y inputs
if ~exist('NumAxes','var')
    NumAxes = NumX * NumY;
end

%Allocate defaults if no params are given
if exist('BorderDims','var')
    if length(BorderDims) == 1
        XBorderDims = BorderDims; %If only 1 number given for a border, make X and Y borders the same
        YBorderDims = BorderDims;
    else
        XBorderDims = BorderDims(1); %If both dims given, change the X and Y borders simulataneously
        YBorderDims = BorderDims(2);
    end
else
    XBorderDims = 0.045;
    YBorderDims = 0.075;
end
if ~exist('PlotOffset','var')
    PlotOffset = [0 1 0 1];
end
if ~exist('XGap','var')
    XGap = ((PlotOffset(2) - PlotOffset(1))/NumX)/5;
end
if ~exist('YGap','var')
    YGap = ((PlotOffset(4) - PlotOffset(3))/NumY)/5;
end
if ~exist('FigHandle','var')
    FigHandle = figure('name','CustomSubPlot','units','normalized');
end

%Make the figure to plot into current (whether it be one you just made)
figure(FigHandle);

%Allocate the widths depending on the assignment
XWidth = (PlotOffset(2) - PlotOffset(1) - ((XBorderDims*2) + (XGap*(NumX-1))))/NumX;
YWidth = (PlotOffset(4) - PlotOffset(3) - ((YBorderDims*2) + (YGap*(NumY-1))))/NumY;

%Make the axes and plots
Counter = 1;
for p = 1:NumY
    YOff = YBorderDims + PlotOffset(3) + ((p-1)*YWidth) + (YGap*(p-1));
    for q = 1:NumX
        XOff = XBorderDims + PlotOffset(1) + ((q-1)*XWidth) + (XGap*(q-1));
        TPos = [XOff, YOff, XWidth, YWidth];
        TagName = sprintf('CustomPlot %i',Counter);
        PlotHandles(Counter) = axes('Tag', TagName,'units','normalized','position',TPos,'NextPlot','replacechildren');
        Counter = Counter + 1;
    end
end

%Sort the axes by top to bottom and then sort them by left to right
A = gcf;
Ax = findall(A,'Type','Axes');
LeftPos = arrayfun(@(x) x.Position(1),Ax);
[~,Inds] = sort(LeftPos,'ascend');
Ax = Ax(Inds);
UpPos = arrayfun(@(x) x.Position(3),Ax);
[~,Inds] = sort(LeftPos,'descend');
Ax = Ax(Inds);
clearvars PlotHandles;

% clearvars PlotHandles;
% for r = length(Ax):-1:1
%     TPos = Ax(r).Position;
%     TempTag = sprintf('Custom Subplot %i',r);
% %    Ax(r).Tag  = sprintf('Custom Subplot %i',r);
%    delete(Ax(r));
%    axes('Tag', TempTag,'units','normalized','position',TPos,'NextPlot','replacechildren');
%    PlotHandles(r) = gca;
%    title(TempTag);
% end

%Create a numbering system for plots based on their position
AllAxes = findall(FigHandle, 'Type','Axes');
Y = arrayfun(@(x) x.Position(2), AllAxes);
TempY = unique(Y);
[~,Ind] = sort(TempY,'descend');
TempY = TempY(Ind);
Counter = 1;
for a =  1:length(TempY)
    Row{a} = AllAxes(find(Y == TempY(a)));
    TempX = arrayfun(@(x) x.Position(1), Row{a});
    [~,Ind] = sort(TempX,'ascend');
    Row{a} = Row{a}(Ind);
    for b = 1:length(Ind)
        Row{a}(b).Tag = sprintf('Custom Subplot %i',Counter);
        axes(Row{a}(b));
        title(Row{a}(b).Tag);
        if Counter > NumAxes
            delete(Row{a}(b));
        else
            PlotHandles(Counter) = Row{a}(b);
        end
        Counter = Counter +1;
    end
end