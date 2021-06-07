function ElectrodeArray = CCEPTissueProbCalc(varargin)
%ElectrodeArray = CCEPTissueProbCalc('Data'|'Electrode',ElectrodeArray,'Labels'|'Indexes',ROIFile,'Neuro'|'TPMFile',TissueLabelImage,'Shape'|'Plot',PlottingOption)
%Take in the Electrodes Structure from the MNICoOrdGrabber function and append the mean
%probabilities to the structure. This also uses an anatomical atlas to
%decide what the tissue label should most likely be from an anatomical
%atlas given to it.


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


%Output:
%ElectrodeArray = Data structure appended to, with the GM/WM and CSF
%probabilities added as well as the likely region that each contact is,
%including the strength of the template match.

%Inputs:
%ElectrodeArray - Takes in the standard output of SPMCoOrdGrabber structure
%
%TissueLabelImage - A Nifti image of the segmented layers of each of the
%anatomical regions.
%
%ROIFile - MatFile with the fields 'Index' and 'Label' Containing the
%labels for the ROI neuroanatomical image that has all of the indexes
%pertaining to the Image you have used.
%
%PlottingOption - 'Shape' can be either of the following:
%       'Cylinder'
%       'Sphere'
%       'Rectangle'
%       'Cube'
%These shapes will be made with a default radius of 2mm and variable number
%of points. If no input is given, a cylinder will be used.


for u = 1:2:length(varargin)
    InputStr = varargin{u};
    if ~isempty(regexpi(InputStr,'lab'))||~isempty(regexpi(InputStr,'ind'))
        ROI = varargin{u+1};
    elseif ~isempty(regexpi(InputStr,'tpm'))||~isempty(regexpi(InputStr,'neur'))
        NeuroLabels = varargin{u+1};
    elseif ~isempty(regexpi(InputStr,'elec'))||~isempty(regexpi(InputStr,'dat'))
        if isstruct(varargin{u+1})
            ElectrodeArray = varargin{u+1};
        elseif ischar(varargin{u+1})
            load(which(varargin{u+1}));
        elseif iscell(varargin{u+1})
            load(which(varargin{u+1}{1}));
        end
        
    elseif ~isempty(regexpi(InputStr,'sha'))||~isempty(regexpi(InputStr,'plot'))
        PlotOption = varargin{u+1};
    end
end

GFig = findobj('Tag', 'Graphics');
if isempty(GFig)
    spm pet;
    pause(3);
end

%******Get the Image file and the other images
OriginalImage = ElectrodeArray(1).ImageFile;
[TempPath,~,~] = fileparts(which(ElectrodeArray(1).ImageFile));
TissueProbImages{1} = which(strcat('c1',OriginalImage)); %GM Image
TissueProbImages{2} = which(strcat('c2',OriginalImage)); %WM Image
TissueProbImages{3} = which(strcat('c3',OriginalImage)); %CSF Image
%****Do error checking to see if the files are found
if isempty(TissueProbImages{1})||isempty(TissueProbImages{2})||isempty(TissueProbImages{1})
    error('Could Not find the tissue probability files');
end

%******Load the labels that have been prepared earlier wihch have been put
%in the same space as the T1 MRI template (MNI space)
%*****Check if the ROIs and indexes were given
if ~exist('ROI','var')
    ROI = load(which('ROIData.mat'));
    ROI = ROI(1).ROI;
    if isempty(ROI)
        error('Could Not find the ROI File specified');
    end
end
%******Check if the neuro regions of interest were given
if ~exist('NeuroLabels','var')
    NeuroLabels = which('labels_Neuromorphometrics.nii');
    V = spm_vol(NeuroLabels);
    [BBox] = spm_get_bbox(V);
    if isempty(NeuroLabels)
        error('Could Not find the Neuro Labels Probability Maps');
    end
end

%*********%Set up the points to select around the electrode
if ~exist('PlotOption','var')
    PlotOption = 'Cylinder';%Default to using a cylinder (since you spent so much fking time on the affine for it)
end

%*****If it is chosen to use a cylinder
if ~isempty(regexpi(PlotOption,'cyl'))
    PlotOption = 'Cylinder';%Default to using a cylinder
    if ~exist('Radius','var')
        Radius = 2; %Set cube size in mm
    end
    if ~exist('NumPoints','var')
        NumPoints = 11;
    end
    %*****Make 2 concentric cylinders
    [BlankCylinder1] = CylinderCreation(Radius,NumPoints);
    Radius = Radius*2; %Set cube size in mm
    [BlankCylinder2] = CylinderCreation(Radius,NumPoints);
    BlankCylinder = [BlankCylinder1; BlankCylinder2];
    
    %*****If a cube or rectangle is chosen
elseif ~isempty(regexpi(PlotOption,'Box'))||~isempty(regexpi(PlotOption,'Cub'))||~isempty(regexpi(PlotOption,'Rec'))
    if ~isempty(regexpi(PlotOption,'Box'))||~isempty(regexpi(PlotOption,'Cub')) %If a cube or box is chosen, make a cube the option to use
        PlotOption = 'Cube';
    else %If it is a rectangle, make the
        PlotOption = 'Rectangle';
    end
    if ~exist('Radius','var')
        Radius = 2;
    end
    Cube = [1 0 0;...
        1 1 0;...
        0 1 0;...
        0 1 1;...
        0 0 1;...
        1 1 1;...
        1 0 1;...
        0.5 0.5 0.5;... %Pop one in the centre too
        0 0 0];
    Cube = Cube.*Radius;
    Cube = (Cube.*2) -1;
    Rect = Cube;
    Rect(:,1) = Rect(:,1)*1.5; %Distort the cube in the X dimension, similarly to the cylinder
    
    %*****If a sphere or cloud is chosen, use this
elseif ~isempty(regexpi(PlotOption,'sph'))||~isempty(regexpi(PlotOption,'circ'))
    PlotOption = 'Sphere';
    if~exist('Radius','var')
        Radius = 2;
    end
    if~exist('NumPoints','var')
        NumPoints = 50;
    end
    %******* Make a randomly distributed cloud bounded by a sphere
    Sphere = ((rand(NumPoints,3)-0.5)*2).*(Radius/sqrt(3));
end

for h = 1:length(ElectrodeArray)
    Norm = ElectrodeArray(h).Norm; %Get the Norm
    BiNorm = ElectrodeArray(h).BiNorm;
    Tangent = ElectrodeArray(h).Tangent;
    for e = 1:length(ElectrodeArray(h).PosMM) %Cycle through each of the individual contacts
        TempCoOrds = ElectrodeArray(h).PosMM(e,:);
        
        %******For each shapes option, make the require points to perform
        %the probability finding for the shapes
        if strcmp(PlotOption,'Cylinder')
            PointMat = TissueProbCylinderCreate('Shape',BlankCylinder,'Normal',Norm,'Translation',TempCoOrds);
            
        elseif strcmp(PlotOption,'Cube')
            PointMat = ShapeWarp('Shape',Cube,'Translation',TempCoOrds,'Normal',Norm); %Warp the
            
        elseif strcmp(PlotOption,'Rectangle')
            PointMat = ShapeWarp('Shape',Rect,'Translation',TempCoOrds,'Normal',Norm); %Warp the rectangle
            
        elseif strcmp(PlotOption,'Sphere')
            PointMat = Sphere + repmat(TempCoOrds,size(Sphere,1),1); %Tanslate the sphere/cloud
        end
        
        DataMat{h,e} = PointMat;
    end
end


%*****Find the Electrodes Mat File to save the updated data into
TempFName = sprintf('%s%s%s Electrodes.mat',TempPath, filesep, ElectrodeArray(1).Patient);
ElecFile = which(TempFName);
%******If you cannot find the file, just make a copy of it
if isempty(ElecFile)
    sprintf('%s Electrodes.mat',ElectrodeArray(1).Patient)
end

%*****Convert the Electrode CoOrds to true MNI CoOrds
fprintf('Converting MNI CoOrdinates     ');
for h = 1:length(ElectrodeArray)
    tic;
    for e = 1:ElectrodeArray(h).NumContacts
        TempImage = ElectrodeArray(1).ImageFile;
        TempCoOrds = ElectrodeArray(h).PosMM(e,:);
        TempDef = ElectrodeArray(1).DefField;
        NewCoOrds = CCEPROICreateandWarp('Image',which(TempImage),'CoOrds',TempCoOrds,'Deformation',which(TempDef),'BBox',BBox);
        ElectrodeArray(h).PosMNI(e,:) = NewCoOrds;
    end
    Time = toc;
    ProjectedFinishTime(Time,h,length(ElectrodeArray));
end
save(ElecFile,'ElectrodeArray');


%*******Perfrom the SPM grabbing of points for each image
for ImageNum = 1:4 %Run the test for GM/WM and CSF and the neurolabels
    if (ImageNum >= 1 && ImageNum <= 3)
        spm_image('Display',TissueProbImages{ImageNum}); %Load up the different tissue prob maps
        InterpCall = findall(gcf,'String',char('NN interp.','Trilinear interp.','Sinc interp.')); %Find the display interpolation call back
        set(InterpCall,'Value',1); %Use nearest neighbour interpolation to reduce blurring
        spm_orthviews('Interp',InterpCall.UserData(InterpCall.Value)); %Apply the interpolation value to be 0 to get only that voxel's values
        GFig = findobj('Tag', 'Graphics'); %Update the graphics figure
    elseif ImageNum ==4
        spm_image('Display',NeuroLabels); %Load the TPM regions
        InterpCall = findall(gcf,'String',char('NN interp.','Trilinear interp.','Sinc interp.')); %Find the display interpolation call back
        set(InterpCall,'Value',1); %Use nearest neighbour interpolation to reduce blurring
        spm_orthviews('Interp',InterpCall.UserData(InterpCall.Value)); %Apply the interpolation value to be 0 to get only that voxel's values
        GFig = findobj('Tag', 'Graphics'); %Update the graphics figure
    end
    fprintf('Image Number %01.0f is being processed      ',ImageNum);
    for h = 1:length(ElectrodeArray)
        tic;
        for e = 1:length(ElectrodeArray(h).PosMM) %Cycle through each of the individual contacts
            PointMat = DataMat{h,e}; %Get the pre-stored coords
            spm_mm = findall(GFig, 'Tag','spm_image:mm');
            spm_Intensity = findall(GFig,'Tag','spm_image:intensity');
            
            %********Set up the Movement sccript for checking electrode
            %co-ordinate tissue probs
            if ImageNum >=1 && ImageNum <= 3
                for g = 1:size(PointMat,1)
                    set(spm_mm, 'String', num2str(PointMat(g,:))); %Set the poisition of the cursor in the image
                    spm_image('setposmm'); %move the cursor to change the value using the callback in spm
                    TissueProb(g) = single(str2double(get(spm_Intensity,'string'))); %Get the intensity of the voxel
                end
            else %Get the same stuff for the ROI labels for only the electrode coOrd centres (in MNI space)
                    set(spm_mm, 'String', num2str(ElectrodeArray(h).PosMNI(e,:))); %Set the poisition of the cursor in the image
                    spm_image('setposmm'); %move the cursor to change the value using the callback in spm
                    TissueProb = single(str2double(get(spm_Intensity,'string'))); %Get the intensity of the voxel
            end
            
            if (ImageNum >= 1 && ImageNum <= 3) %For the GM/WM/CSF lookups
                %*******Get the mean of each tissue probability and record it
                MeanTissueProb = mean(TissueProb); %Get the average tissue prob of 7 points around the electrodes
                ElectrodeArray(h).TissueProb(e,ImageNum) = MeanTissueProb;
                
            elseif ImageNum ==4 %For the anatomical Labels lookup
                %*******Get the most frequently occurring score of the
                %tissue type
                %***%Round the values (they are not integers anymore because of the smoothing kernel applied)
                for t = 1:length(TissueProb)
                    [~, FoundInd] = min(abs(abs(TissueProb(t)) - abs([ROI.Index])));
                    TempRegion(t) = ROI(FoundInd).Index;
                end
                [Region,Freq] = mode(TempRegion); %Get the most frequently occurring scores
                
                %******If the region is valid get the corresponding labels and save them
                if Region ~= 0
                    ROIInd = find([ROI.Index] == Region);
                    ElectrodeArray(h).ROI(e).Label = ROI(ROIInd).Label; %Get the label corresponding to the estimate
                    ElectrodeArray(h).ROI(e).Prob = Freq/((size(PointMat,1))); %Get the reliability of the estimate
                else
                    ElectrodeArray(h).ROI(e).Label = 'OUT'; %Set Label to be nothing
                    ElectrodeArray(h).ROI(e).Prob = 1; %give a probability of 1
                end
                
            end
        end
        save(ElecFile,'ElectrodeArray'); %Save the electrode details array back in to the Mat structure from whence it came
        Time = toc;
        ProjectedFinishTime(Time,h,length(ElectrodeArray));
    end
end

