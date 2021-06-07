function [StimPulseEventTimes] = StimPulseFinder(StimPulseData)
%[StimPulseEventTimes] = StimPulseFinder(StimPulseData)
%Get the times of the Stim pulses from the channel data handed to the
%function

%This event will parse through the Stim channel and get each of the times
%when a stim pulse occurs
TimePosition = 2; %Begin at the 2nd sampling instant (since we look behind 1 sample for changes)

StimPulseEventTimes = zeros(1,numel(StimPulseData));
%*************************************************************************
%signalCell refers to the actual EEG data from the SEEG file
%*************************************************************************
%Create an empty matrix of the size of the time data in order to record the
%stim pulses into (pre-allocate to save time)

StimPulseCounter = 1;
%Count the number of stim pulses

%Initialise the change detection buffer
ChangeDetectionBuffer = [StimPulseData(2) StimPulseData(1)];

%Loop through the signal from start to end
while (TimePosition < numel(StimPulseData))
    %Check that the time being analysed is less than the total time in the
    %stimulation time series
    
    %Read the time data into the comparison buffer
    ChangeDetectionBuffer(1) = StimPulseData(TimePosition);
    ChangeDetectionBuffer(2) = StimPulseData(TimePosition-1);
    
    %Check whether the time data has increased markedly
    PulseDetection = ChangeDetectionBuffer(1) - ChangeDetectionBuffer(2);
    %Pulse detection = current - previous
    
    if (abs(PulseDetection)> 400000 && (sign(PulseDetection) == 1)) 
        %Check that the change is large and is also a positive edge
        %transition
        
        StimPulseEventTimes(StimPulseCounter) = TimePosition; %Take the time of the positive edge of the stimulation
        
        StimPulseCounter = StimPulseCounter +1; %Increment the stim pulse counter
        
        TimePosition = TimePosition + 10; %When a positive edge is found, move 100ms further in time, since it will remain high for a while
        
        ChangeDetectionBuffer = [StimPulseData(TimePosition) StimPulseData(TimePosition-1)]; %Reset the change detection buffer to be zeros again
        
    else
        %Do this if a positive edge is not detected
                
        ChangeDetectionBuffer(2) = ChangeDetectionBuffer(1);
        %Shift the sample from current to previous in the sampling buffer
        %************* Make sure to shift the right way *******************
        
        TimePosition = TimePosition + 1; 
        %Go to the next sample in order to 
        
    end

    
end

%Retrieve only the non-zero elements of the stimulation pulse time series.
StimPulseEventTimes = nonzeros(StimPulseEventTimes);

end



