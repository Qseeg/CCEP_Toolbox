%Matthew Woolfe %%%%%%%%%%%%%%%%%
%Example Scrips for EDF_Load    %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%
%Filepath
    EDFfilepath = which('Patient 49 Shane CCEPs 1.edf');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Load Some Channels labels (Only the first 10)
    [SEEGHeader, OtherHeader] = Get_EDF_Channels(EDFfilepath);
    Channels = {SEEGHeader(1:10).Label};

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Which times you are looking for
    Epochs = [0 0]; %This is the ALL command
    %Epochs = [0 1]; %1 full second of data
    %Epochs = [5 100]; %95Seconds of data
    %Epochs = [100 inf]; %All Data after the 100th second


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%If you know the Channel labels 
    [Header,SignalHeader,ReferentialEEG,Annotations] = EDF_Read(EDFfilepath,Channels,Epochs);
%Otherwise this will load them all
    [Header,SignalHeader,ReferentialEEG,Annotations] = EDF_Read(EDFfilepath); 
    
%%%%%%%%%%%%%%%%%%%%
% Convert to Bipolar
    [BipolarEEG] = Create_BipolarEEG(ReferentialEEG);
    
%%%%%%%%%%%%%%%%%%%%
% Load the anatomy
    MAPfilepath = which('Patient 49 Map.xlsx');
    %Referential => if no SEEG structure is provided the entire MAP is returned => [MapStructure] = Load_Patient_Map(MAPfilepath);    
    %            => Provide a Structure so that only it is populated
    [~, ReferentialEEG] = Load_Patient_Map(MAPfilepath, ReferentialEEG);

    %Bipolar => if no SEEG structure is provided the entire MAP is returned => [MapStructure] = Load_Patient_Map_Bipolar(MAPfilepath);    
    %            => Provide a Structure so that only it is populated
    [~, BipolarEEG] = Load_Patient_Map_Bipolar(MAPfilepath, BipolarEEG);



