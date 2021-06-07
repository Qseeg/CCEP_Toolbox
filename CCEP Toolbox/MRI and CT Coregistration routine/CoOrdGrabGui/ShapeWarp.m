function NewCoOrds = ShapeWarp(varargin)
%NewPoints = ShapeWarp('Shape'|'New',BlankCylinder,'Translation',Translation)
%
%This function takes in information about the cylinder to be plotted as
%well as the vector for plotting it.
%
%Shape = [X Y Z] Of the specified shape, which is ASSUMED TO BE POINTING IN
%THE X DIMENSION.
%
%Tran = Translation in [X Y Z] applied at the end of the rotation. This
%step is performed to move it the specified CoOrds of the electrode centre
%
%NewCoOrds = [X Y Z] Same format as input CoOrds

for u = 1:2:length(varargin)
    InputStr = varargin{u};
    if ~isempty(regexpi(InputStr,'Dir'))||~isempty(regexpi(InputStr,'Nor'))
        DirVec = varargin{u+1};
    elseif ~isempty(regexpi(InputStr,'tran'))
        Translation = varargin{u+1};
    elseif ~isempty(regexpi(InputStr,'sha')) || ~isempty(regexpi(InputStr,'new'))
        Shape = varargin{u+1};
    end
end

%*****Make Get the direction vector of the normal with the electrode
R = sqrt(sum(DirVec.^2));
Azimuth = -atan2(DirVec(2),DirVec(1)); %Positive radians = a CCW rotation about X axis (ZDim)
Elevation = asin(DirVec(3)/R); %Positive rotation here
RotAngs = [0,Elevation,Azimuth];
if ~exist('Translation','var')
NewShape = RotationalAffine('Input',Shape,'Ang',RotAngs); %Warp the new cylinder into the correct space
else
NewShape = RotationalAffine('Input',Shape,'Ang',RotAngs,'Translation',Translation); %Translate  and warp the cylinder
end

NewCoOrds =NewShape;





