function OutputCoOrds = RotationalAffine(varargin)
%NewCoOrds = RotationalAffine('Input'|'CoOrd',InputCoOrds,'Rotation'|'Ang',RotationAngles,'Translation',Translation)
%
%This function takes in the angles of translation for a the shape and also
%any translations to apply to it post processing
%
%InputCoOrds = [X Y Z] However many rows of points there are
%
%RotationAngles = [AngleX, AngleY,AngleZ] can be in radians or degrees, IF
%AN ANGLE GREATER THAN 2*PI IS GIVEN, ALL ANGLES WILL BE SCALED DOWN TO
%RADIANS
%
%RotationAngles = [XShift,YShift,ZShift] Give the shift of the origin to
%apply after rotation to the given shape
%
%NewCoOrds = [X Y Z] Same format as input CoOrds

for u = 1:2:length(varargin)
    InputStr = varargin{u};
    if ~isempty(regexpi(InputStr,'Input'))||~isempty(regexpi(InputStr,'Coord'))
        InputCoOrds = varargin{u+1};
        
    elseif ~isempty(regexpi(InputStr,'Rot'))||~isempty(regexpi(InputStr,'Ang'))
        RotationAngles = varargin{u+1};
        if max(max(abs(RotationAngles)))>(2*pi)
            RotationAngles = RotationAngles.* (pi/180)
        end
        RotX = RotationAngles(1);
        RotY = RotationAngles(2);
        RotZ = RotationAngles(3);
    elseif ~isempty(regexpi(InputStr,'tran'))
        Translation = varargin{u+1};
    end
end

if ~exist('RotationAngles','var')
    error('Give the rotation angles in the correct format');
end
T1 = [1      0        0     0;...
    0      cos(RotX) -sin(RotX) 0;...
    0      sin(RotX) cos(RotX)  0;...
    0      0      0       1];

%*****Get the rotation in Y dimension
T2 = [cos(RotY)  0      sin(RotY)   0;...
    0       1      0        0;...
    -sin(RotY) 0      cos(RotY)   0;...
    0      0      0         1];

%*****Get the rotation in the Z dimension
T3 = [cos(RotZ) -sin(RotZ)   0     0;...
    sin(RotZ) cos(RotZ)    0     0;...
    0      0         1     0;...
    0      0         0     1];

TF = T1*T2*T3; %Matrix multiply the transforms

OutputCoOrds = InputCoOrds*TF(1:3,1:3); %Multoply the transform by the rotation matrices

if exist('Translation','var') %Do the translation if it is given
    OutputCoOrds(:,1) = Translation(1)+OutputCoOrds(:,1);
    OutputCoOrds(:,2) = Translation(2)+OutputCoOrds(:,2);
    OutputCoOrds(:,3) = Translation(3)+OutputCoOrds(:,3);
end