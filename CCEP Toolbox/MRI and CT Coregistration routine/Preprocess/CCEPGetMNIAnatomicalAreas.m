%Get Tissue Types
function MNIStruct = CCEPGetMNIAnatomicalAreas(varargin)
%MNIStruct = CCePGetMNIAnatomicalAreas('MNI'|'Data',MNICoOrds,'Labels'|'Indexes',ROIFile, 'TPM'|'NeuroMorphometrics',LookupTemplateImage)
%Use this function to get the anatomical labels of MNI CoOrds (probably the
%Bipolar CoOrds
%Inputs:
%MNICoOrds - Input these as a matrix of each CoOrd in a row, otherwise pass
%a structure with the MNI CoOrds in each row of the structure
%Outputs:
%MNIStruct - each row contains the MNI coOrd (MNIStruct.MNICoOrds) and the
%corresponding TemplateLabel (MNIStruct.TemplateLabel)
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


%Parse the inputs
for u = 1:2:length(varargin)
    InputStr = varargin{u};
    if ~isempty(regexpi(InputStr,'lab'))||~isempty(regexpi(InputStr,'ind')) %Get the ROI input file if given
        ROI = varargin{u+1};
    elseif ~isempty(regexpi(InputStr,'tpm'))||~isempty(regexpi(InputStr,'neur'))
        NeuroLabels = varargin{u+1};
    elseif ~isempty(regexpi(InputStr,'MNI'))||~isempty(regexpi(InputStr,'dat'))
        if isstruct(varargin{u+1})
            if isfield(varargin{u+1}, 'MNICoOrds')
                TempCoOrds = [varargin{u+1}.MNICoOrds];
                InputMNICoOrds = reshape(TempCoOrds, [3,length(TempCoOrds)/3]);
                InputMNICoOrds = InputMNICoOrds';
            end
        elseif isnumeric(varargin{u+1})
            InputMNICoOrds = varargin{u+1};
        end
    end
end

%Load spm if not already done
GraphicsFig = findall(0, 'Name', 'SPM12 (6470): Graphics');
if isempty(GraphicsFig)
    spm pet;
    pause(10);
end

%Read in the lookup table
if ~exist('ROI','var')
    ROI = load(which('ROIData.mat'));
    ROI = ROI(1).ROI;
    if isempty(ROI)
        error('Could Not find the ROI File specified');
    end
end
%Get the correct Image for the lookup
if ~exist('NeuroLabels','var')
    NeuroLabels = which('labels_Neuromorphometrics.nii');
    V = spm_vol(NeuroLabels);
    [BBox] = spm_get_bbox(V);
    if isempty(NeuroLabels)
        error('Could Not find the Neuro Labels Probability Maps');
    end
end

%Call up the anatomical image lookup
spm_image('Display',NeuroLabels); %Load the TPM regions
InterpCall = findall(gcf,'String',char('NN interp.','Trilinear interp.','Sinc interp.')); %Find the display interpolation call back
set(InterpCall,'Value',1); %Use nearest neighbour interpolation to reduce blurring
spm_orthviews('Interp',InterpCall.UserData(InterpCall.Value)); %Apply the interpolation value to be 0 to get only that voxel's values
GraphicsFig = findall(0, 'Name', 'SPM12 (6470): Graphics'); %Update the graphics figure

%Find all of the regions located at the MNI CoOrds given
for w = 1:size(InputMNICoOrds,1)
    
    %Change the position of the cursor and then read off the tissue label
    spm_mm = findall(GraphicsFig, 'Tag','spm_image:mm');
    spm_Intensity = findall(GraphicsFig,'Tag','spm_image:intensity');
    set(spm_mm, 'String', num2str(InputMNICoOrds(w,:))); %Set the poisition of the cursor in the image
    spm_image('setposmm'); %move the cursor to change the value using the callback in spm
    TempInd = round(single(str2double(get(spm_Intensity,'string')))); %Get the intensity of the voxel
    
    %Lookup the anatomical region in the ROI index structure
    if TempInd ~= 0
        ROIInd = find([ROI.Index] == TempInd);
        AnatomicalRegion{w} = ROI(ROIInd).Label; %Get the label
    else
        AnatomicalRegion{w} = 'OUT'; %Set Label to be nothing
    end
    
    %Allocate the CoOrds and labels to an outgoing structure
    MNIStruct(w).MNICoOrds = InputMNICoOrds(w,:);
    MNIStruct(w).TemplateLabels = AnatomicalRegion{w};
end
end