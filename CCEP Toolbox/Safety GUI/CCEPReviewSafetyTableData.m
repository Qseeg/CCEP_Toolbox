%Table for Age of Patients with info

%% Donos 2016
clearvars Age Sex NumPulses AD Mean StDev
Age = [ 17; 39; 47; 40; 35; 24; 24; 25; 46; 33; 11];
Sex = {'F', 'M', 'M', 'F','F','F','M','F','F','M','F'};
NumPulses = 20;
AD ='None';
Mean = mean(Age);
StDev = std(Age);
Range = [max(Age), min(Age)];
WaveForm = {'Cathode Leading Biphasic Variable Amplitude','Alternating Monophasic Variable Amplitude','Cathode Leading Biphasic Variable duration'};
Sampling = 4096;
Filtering = 'Disabled';
StimFreq = 0.066;

%% Boido et al 2014
clearvars Age Sex NumPulses AD Mean StDev
Age = [ 28; 26; 32; 25; 17;16;33;19;29;39;36;27];
Sex = {'M','F','M','M','M','F','M','M','F','M','F','M'};
Sex = Sex';
NumPulses = 30;
AD ='None';
Mean = mean(Age);
StDev = std(Age);
Range = [max(Age), min(Age)];
WaveForm = {'Biphasic'};
Filtering = [0.016 300];
Sampling = 1000;
%% Van't Klooster 2011
clearvars Age Sex NumPulses AD Mean StDev
Age = [31; 23; 29; 9; 11; 26; 42; 25; 13; 13; 8; 22; 23];
Sex = {'F','F','M','M','M','F','M','F','F','M','M','F','M'};
Sex = Sex';
NumPulses = 10;
AD ='None';
Mean = mean(Age);
StDev = std(Age);
Range = [min(Age), max(Age)];
WaveForm = {'Monophasic'};
Filtering = [0 538];
Sampling = 2048;
%% Valentin 2002
clearvars Age Sex NumPulses AD Mean StDev
NumPatients = 45;
NumPulses = 10-40;
AD ='None';
MeanAge = 33.8
Range = [14, 58];
WaveForm = {'Monophasic'};
Filtering = [0.3 70];
Sampling = 200;
Reference = 'Not Listed';
StimFreq = [0.1];

%% Kokkinos 2013
clearvars Age Sex NumPulses AD Mean StDev
NumPatients = 12;
NumPulses = 5-20;
AD ='None';
MeanAge = 33
Range = [12, 52];
WaveForm = {'Alternating Monophasic'};
Filtering = [0.3 70]; 
Sampling = 500;
Reference = 'Not Listed';
StimFreq = [0.2];

%% Munari 1993
clearvars Age Sex NumPulses AD Mean StDev
NumPatients = 24;
AgeAdd = (27.3*19 + 23*5)/24;
NumPulses = 40;
AD ='None';
Range = [12, 52];
WaveForm = {'Alternating Monophasic'};
Filtering = 'na'; 
Sampling = 500;
Reference = 'Not Listed';
StimFreq = 1;


%% Flanagan 2009
clearvars Age Sex NumPulses AD Mean StDev
NumPatients = 35; %(Children)
NumPulses = 10;
AD ='None';
MedianAge = 14.16;
Range = [0.75, 17.5];
WaveForm = {'Alternating Monophasic'};
Filtering = [0.3 70]; 
Sampling = 200; %(assumed)
Reference = 'Not Listed';
StimFreq = [0.2; 0.1];



%% Valentin 2008
clearvars Age Sex NumPulses AD Mean StDev
NumPatients = 125;
NumPulses% = >=10;
AD ='None';
MedianAge %= Not Given;
Range = [0.75, 17.5];
WaveForm = {'Alternating Monophasic'};
Filtering = [0.3 70];  %assumed
Sampling = 200; %(assumed)
Reference = 'Not Listed';
StimFreq = [0.2; 0.1];

%% Alarcon 2012
clearvars Age Sex NumPulses AD Mean StDev
NumPatients = 11;
NumPulses% = >=10;
AD ='None';
MedianAge %= Not Given;
Range = [0.75, 17.5];
WaveForm = {'Monophasic'};
Filtering = [0.5 50];  %assumed
Sampling = 'Unknown'; %(assumed)
Reference = 'Not Listed';
StimFreq = [0.1];

%% Iwasaki 2010
clearvars Age Sex NumPulses AD Mean StDev
NumPatients = 11;
NumPulses = 10-54;
Age = [27; 15; 47; 24; 45; 36; 36; 9; 35; 12; 52];
Sex = {'F'; 'M'; 'F'; 'M'; 'M'; 'M'; 'M'; 'F'; 'M'; 'F'};
AD ='None';
MedianAge %= Not Given;
Range = [9, 52];
WaveForm = {'Alternating Monophasic'};
Filtering = [1 800];  %assumed
Sampling = 2000; %(assumed)
Reference = 'Contralateral Mastiod (extracranial)';
StimFreq = [1];

%% Matsumoto 2007
clearvars Age Sex NumPulses AD Mean StDev
NumPatients = 7;
NumPulses = 20-100;
Age = [28; 46; 1.6; 39; 20; 17; 15];
Sex = {'F'; 'M';'M';'M'; 'M';'M';'M'};
AD ='None';
MedianAge %= Not Given;
Range = [1.6, 46];
WaveForm = {'Alternating Monophasic'};
Filtering = [1 1000];  
Sampling = 2500;
Reference = 'Contralateral Mastiod (extracranial)';
StimFreq = [1];



%% Brugge 2004
clearvars Age Sex NumPulses AD Mean StDev
Range = [19 46];
NumPatients = 7;
MedianAge = 38;
NumPulses = 50-100;
AD ='None';
WaveForm = {'Biphasic'};
Filtering = [2 500]; [60];
Sampling = [1000 2000];
Reference = 'Common Average';
StimFreq = [0.5; 1];

%% Afif 2010
clearvars Age Sex NumPulses AD Mean StDev
Range = [11 53];
NumPatients = 25;
MeanAge = 29.36;
NumPulses = 12.54;
AD ='None';
WaveForm = {'Biphasic'};
Filtering = 'Unknown';
Sampling = 'Unknown';
Reference = 'Common Average';
StimFreq = [1];

%% Alarcon 2012
clearvars Age Sex NumPulses AD Mean StDev
Range = [11 53];
NumPatients = 11;
MeanAge = 29.36;
NumPulses = 12.54;
AD ='None';
WaveForm = {'Biphasic'};
Filtering = [0.5 50];
Sampling = 'Unknown';
Reference = 'Common Average';
StimFreq = [1];


%% Freestone 2011
clearvars Age Sex NumPulses AD Mean StDev
NumPatients = 7;
NumPulses = 100;
Age = 'Not given';
Sex = 'Not given';
AD ='None';
MedianAge %= Not Given;
WaveForm = {'Biphasic'};
Filtering = [0  95];   50;
Sampling = 5000;
Reference = 'Contralateral Mastiod (extracranial)';
StimFreq = [0.33];

%% Enatsu 2012
clearvars Age Sex NumPulses AD Mean StDev
NumPatients = 15;
NumPulses = 20-70;
MedianAge = 25;
Range = [6 52];
WaveForm = {'Alternating Monophasic'};
Filtering = [1  300];
Sampling = 2000;
Reference = 'Contralateral Mastiod (extracranial)';
StimFreq = [0.33];



%% Keller 2011
clearvars Age Sex NumPulses AD Mean StDev
Age = [22;21;36;48;17;23;38;31;5;5;22;25;30;25;60;26];
Sex = {'F','M','F','F','F','F','F','M','F','M','F','F','F','M','F'};
Sex = Sex';
NumPulses = 20;
AD ='None';
Mean = mean(Age);
StDev = std(Age);
Range = [min(Age), max(Age)];
WaveForm = {'Monophasic'};
Filtering = [0.1 1000]; [60];
Sampling = 2000;
Reference = 'Common Average';
StimFreq = [0.5; 1];

%% Lega 2015
NumPatients = 37;
MeanAge = 36;
Range = [15 60];
Male = 17;
Female = 20;
Filtering = [1 300]; [60];
Sampling = 1000;
AD = 'Used as threshold but not given';
PurposeofStudy = 'Seizure Spread';
NumPulses = 30;
PW = '0.3ms';
Waveform = 'ALternating Monohpasic';

%% Catenoix 2011

NumPatients = 7;
MeanAge = 32.4;
SDAge = 11.5;
Range = [15 47];
Male = 6;
Female = 1;
Filtering = [0.53 250]; [60];
Sampling = 512;
AD = 'Used as threshold but not given';
PurposeofStudy = 'Hippocampus Connections';
NumPulses = 25;
PW = '1ms';
Waveform = 'ALternating Monohpasic';
StimFreq = '0.2Hz';
MaxCurrent = '3mA';
ElectrodeArea = '0.503cm^2';


%% Conner 2011
NumPatients = 7;
Age = [61; 37; 39; 17; 30; 42; 28]; 
MeanAge = mean(Age); %36.3
Range = [17 61];
Male = 2;
Female = 5;
Filtering = [1 300];
Sampling = 1000;
AD = 'Used as threshold but not given';
PurposeofStudy = 'Correlate with Language Area';
NumPulses = 50;
PW = '0.3ms';
Waveform = 'Biphasic (Assumed)';
StimFreq = '1Hz';
MaxCurrent = '10mA';
Modality = 'ECoG';
ElectrodeArea = 'Not Given';
Reference = 'CommonAverage'

%% Donos 2016 
NumPatients = 16;
Age = [40; 35; 24; 24; 24; 25; 46; 33; 11; 28; 39; 47; 37; 36; 42; 30; 42]; 
MeanAge = mean(Age); %33.12
Range = [11 47];
Male = 7;
Female = 9;
Filtering = 'Assumed turned off, 100-250Hz for HFO';
Sampling = 4096;
AD = 'Not given';
PurposeofStudy = 'Correlate with HFO and DR''s';
NumPulses = 20;
PW = '3ms';
Waveform = 'Biphasic (Assumed)';
StimFreq = '0.067Hz';
MaxCurrent = '5mA';
Modality = 'SEEG';
Reference = 'Not given';


%% Enatsu 2015 
NumPatients = 28;
MedianAge = 30; %33.12
Range = [15; 68];
Male = 15;
Female = 13;
Filtering = [1 300];
Sampling = 1000;
AD = 'Not given';
PurposeofStudy = 'Limbic Connectivity';
NumPulses = '40-60';
PW = '0.3ms';
Waveform = 'Alternating Monophasic';
StimFreq = '1Hz';
MaxCurrent = '8mA';
Modality = 'SEEG';
Reference = 'Not Given';

%% Enatsu 2011
NumPatients = 14;
MedianAge = 25;
Range = [6-52];
Male = 7;
Female = 7;
Filtering = [1 300];
Sampling = 1000;
AD = 'Used as theshold but not given';
PurposeofStudy = 'Localize EZ';
NumPulses = '20-70';
PW = '0.3ms';
Waveform = 'Alternating Monophasic';
StimFreq = '1Hz';
MaxCurrent = '15mA';
Modality = 'ECoG';
ElectrodeArea = pi*(3.97*0.1)^2;
Reference = 'Not Given';




