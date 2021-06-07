function NewCoOrds = TissueProbCylinderCreate(varargin)
%NewPoints = TissueProbCylinderCreate('Cylinder'|'New',BlankCylinder,'Radius',RadSize,'NumPoints',NumPoints,'Translation',Translation)
%
%This function takes in information about the cylinder to be plotted as
%well as the vector for plotting it.
%
%BlankCylinder = [X Y Z] Of the specified cylinder (rotated at 90deg in the
%y axis) so that you can directly translate it to pointing towards the
%origin/direction vector. You can also give a line as the cylinder to check
%that the warps are ok. (2mm and 11 points are default)
%
%Radius = Rad in mm from the centre of the eelctrode, can step this out to
%get more coverage (2mm is default)
%
%NumPoints = Number of points for the cylinder (11 is default)
%
%Tran = Translation in [X Y Z] applied at the end of the rotation. This
%step is performed to move it the specified CoOrds of the electrode centre
%
%NewCoOrds = [X Y Z] Same format as input CoOrds


for u = 1:2:length(varargin)
    InputStr = varargin{u};
    if ~isempty(regexpi(InputStr,'Rad'))
        Radius = varargin{u+1};
    elseif ~isempty(regexpi(InputStr,'num'))||~isempty(regexpi(InputStr,'point'))
        NumPoints = varargin{u+1};
    elseif ~isempty(regexpi(InputStr,'Dir'))||~isempty(regexpi(InputStr,'Nor'))
        DirVec = varargin{u+1};
    elseif ~isempty(regexpi(InputStr,'tran'))
        Translation = varargin{u+1};
    elseif ~isempty(regexpi(InputStr,'Cyl')) || ~isempty(regexpi(InputStr,'New'))
        BlankCylinder = varargin{u+1};
    end
end

%******If no blank cylinder was given
if ~exist('BlankCylinder','var')
    if ~exist('NumPoints','var')
        NumPoints = 11; %Number of points (minus 1 because it starts at the same place
    end
    if ~exist('Radius','var')
        Radius = 2; %Radius of 2mm
    end
    [BlankCylinder] = CylinderCreation(Radius,NumPoints);
end

%*****Make Get the direction vector of the normal with the electrode
R = sqrt(sum(DirVec.^2));
Azimuth = -atan2(DirVec(2),DirVec(1)); %Positive radians = a CCW rotation about X axis (ZDim)
Elevation = asin(DirVec(3)/R); %Positive rotation here
RotAngs = [0,Elevation,Azimuth];
if ~exist('Translation','var')
NewCylinder = RotationalAffine('Input',BlankCylinder,'Ang',RotAngs); %Warp the new cylinder into the correct space
else
NewCylinder = RotationalAffine('Input',BlankCylinder,'Ang',RotAngs,'Translation',Translation); %Translate  and warp the cylinder
end

NewCoOrds =NewCylinder;





