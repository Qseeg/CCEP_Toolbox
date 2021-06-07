function CCEPSafetyEstimate(varargin)
%CCEPSafetyEstimate
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


%Electrode details and figure
CCEPStimSafetyFig = findobj('Tag','CCEPStimSafetyFig');
ElectrodeTypeButton = findobj('Tag','ElectrodeTypeButton');
ElectrodeLength = findobj('Tag','ElectrodeLength');
ElectrodeDiameter= findobj('Tag','ElectrodeDiameter');


%Pulse parameters and estimations
StimFrequency = findobj('Tag','StimFrequency');
MaxCurrent = findobj('Tag','MaxCurrent');
MaxPW = findobj('Tag','MaxPW');
ChargeDensityText = findobj('Tag','ChargeDensityText');
ChargeDensityRateText = findobj('Tag','ChargeDensityRateText');

%Get the axes to plot into
PlotAxes = findall(CCEPStimSafetyFig, 'Type','Axes');
StudyList = findobj(CCEPStimSafetyFig,'Tag','StudyList');
StudyDetails = CCEPStimSafetyFig.UserData;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%    %If the electrode type chosen is SEEG         %%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if ElectrodeTypeButton.Value == 1
    
    %Do the string prep for electrode details
    Ind = isstrprop(ElectrodeDiameter.String ,'digit')|isstrprop(ElectrodeDiameter.String ,'punct');
    Dia = str2num(ElectrodeDiameter.String(Ind));
    Ind = isstrprop(ElectrodeLength.String ,'digit')|isstrprop(ElectrodeLength.String ,'punct');
    Len = str2num(ElectrodeLength.String(Ind));
    
    %For the area, convert mm into cm (divide by 10) and calculate the area
    %in cm^2 as most papers have done
    Area = pi*(Dia/10)*(Len/10);
    
    %Do the string prep for pulse details
    Ind = isstrprop(MaxCurrent.String ,'digit')|isstrprop(MaxCurrent.String ,'punct');
    Cur = str2num(MaxCurrent.String(Ind));
    Ind = isstrprop(MaxPW.String ,'digit')|isstrprop(MaxPW.String ,'punct');
    PW = str2num(MaxPW.String(Ind));
    Ind = isstrprop(StimFrequency.String ,'digit')|isstrprop(StimFrequency.String ,'punct');
    Freq = str2num(StimFrequency.String(Ind));
    
    %For the charge, convert to mA and ms (divide by 1000)
    Charge = Cur * PW;
%     ChargeRate = Charge*Freq;
    
    %Perfrom the calculations and put them into the
    ChargeDensity = Charge/Area;
    ChargeDensityText.String = (sprintf('Charge Density: %3.1f uC/(square cm)',ChargeDensity));
    
    %Electrode Area Safety
    XLim = PlotAxes.XLim;
    XData = PlotAxes.XLim(1):0.01:PlotAxes.XLim(2);
    YData = (57*Area)./XData; %57uC/cm2 was the safe charge density from Gordon et al (1990). I just rearranged to get the max current for all Pulse Widths
    
    %Prep the plot axes (main axes)
    axes(PlotAxes);
    delete(PlotAxes.Children);
    delete(PlotAxes.Legend);
    Ind = StudyList.Value;
    Temp = StudyDetails(Ind);
    
    
    %For studies included with multiples of the same charge parameters,
    %only get the unique charges and then get rid of the rest so that the
    %text is not too cluttered
    for a = 1:length(Temp)
        Temp(a).Valid = 0;
    end
    SearchCharge = double(unique(single([Temp.PulseCharge]))); %There was a formatting issue with unique and some charge levels, converting to a single seemed to solve it
    for a = 1:length(SearchCharge)
        FoundInds= find(arrayfun(@(x) (single(x.PulseCharge) == single(SearchCharge(a))),Temp));
        Temp(FoundInds(1)).Valid = 1;
        if length(FoundInds) > 1
            Temp(FoundInds(1)).Publication= sprintf('%i Studies',length(FoundInds)); %Give the number of duplicate studies
            for b = 2:length(FoundInds)
                Temp(FoundInds(b)).Valid = 0;
            end
        end
    end
    %Only keep the valid unique datapoints (with amended titles)
    Ind = find([Temp.Valid]);
    Temp = Temp(Ind);
    
    %Plot the unique studies which are selected in the list
    for a = 1:length(Ind)
        plot(Temp(a).PW,Temp(a).MaxCurrent,'k*','MarkerSize',10);
        
        %For the text, decide if it is too close to the edges of your plot,
        %then put the near the datapoint
        if Temp(a).PW > 2.7 && Temp(a).MaxCurrent>12
            text(Temp(a).PW*0.9,(Temp(a).MaxCurrent-0.5),Temp(a).Publication,'FontSize',15);
        elseif Temp(a).PW > 2.7
            text(Temp(a).PW*0.9,Temp(a).MaxCurrent*1.1,Temp(a).Publication,'FontSize',15);
        elseif Temp(a).MaxCurrent>12
            text((Temp(a).PW+0.01),(Temp(a).MaxCurrent-1),Temp(a).Publication,'FontSize',15);
        else
            text((Temp(a).PW+0.01),Temp(a).MaxCurrent*1.025,Temp(a).Publication,'FontSize',15);
        end
    end
    
    
    %Plot your data on the plot
    plot(XData,YData,'r');
    plot(PW,Cur,'r*','MarkerSize',10);
    text((PW*1.025),(Cur*1.025), 'Your Study','FontSize',15);
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%    %If the electrode type chosen is ECoG         %%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
else
    
    %Do the string prep for electrode details
    Ind = isstrprop(ElectrodeDiameter.String ,'digit')|isstrprop(ElectrodeDiameter.String ,'punct');
    Dia = str2num(ElectrodeDiameter.String(Ind));
    
    %For the area, convert mm into cm (divide by 10) and calculate the area
    %in cm^2 as most papers have done
    Area = pi*(((Dia/10)/2)^2);
    
    
    %Do the string prep for pulse details
    Ind = isstrprop(MaxCurrent.String ,'digit')|isstrprop(MaxCurrent.String ,'punct');
    Cur = str2num(MaxCurrent.String(Ind));
    Ind = isstrprop(MaxPW.String ,'digit')|isstrprop(MaxPW.String ,'punct');
    PW = str2num(MaxPW.String(Ind));
    Ind = isstrprop(StimFrequency.String ,'digit')|isstrprop(StimFrequency.String ,'punct');
    Freq = str2num(StimFrequency.String(Ind));
    
    %For the charge, convert to mA and ms (divide by 1000)
    Charge = Cur * PW;
%     ChargeRate = Charge*Freq;
    
    %Perfrom the calculations and put them into the
    ChargeDensity = Charge/Area;
    ChargeDensityText.String = (sprintf('Charge Density: %3.1f uC/(square cm)',ChargeDensity));
    
    %Electrode Area Safety
    XLim = PlotAxes.XLim;
    XData = PlotAxes.XLim(1):0.01:PlotAxes.XLim(2);
    YData = (57*Area)./XData; %57uC/cm2 was the safe charge density from Gordon et al (1990). I just rearranged to get the max current for all Pulse Widths
    
    %Prep the plot axes (main axes)
    axes(PlotAxes);
    delete(PlotAxes.Children);
    delete(PlotAxes.Legend);
    Ind = StudyList.Value;
    Temp = StudyDetails(Ind);
    
    
    %For studies included with multiples of the same charge parameters,
    %only get the unique charges and then get rid of the rest so that the
    %text is not too cluttered
    for a = 1:length(Temp)
        Temp(a).Valid = 0;
    end
    SearchCharge = double(unique(single([Temp.PulseCharge]))); %There was a formatting issue with unique and some charge levels, converting to a single seemed to solve it
    for a = 1:length(SearchCharge)
        FoundInds= find(arrayfun(@(x) (single(x.PulseCharge) == single(SearchCharge(a))),Temp));
        Temp(FoundInds(1)).Valid = 1;
        if length(FoundInds) > 1
            Temp(FoundInds(1)).Publication= sprintf('%i Studies',length(FoundInds)); %Give the number of duplicate studies
            for b = 2:length(FoundInds)
                Temp(FoundInds(b)).Valid = 0;
            end
        end
    end
    %Only keep the valid unique datapoints (with amended titles)
    Ind = find([Temp.Valid]);
    Temp = Temp(Ind);
    
    %Plot the unique studies which are selected in the list
    for a = 1:length(Ind)
        plot(Temp(a).PW,Temp(a).MaxCurrent,'k*','MarkerSize',10);
        
        %For the text, decide if it is too close to the edges of your plot,
        %then put the near the datapoint
        if Temp(a).PW > 2.7 && Temp(a).MaxCurrent>12
            text(Temp(a).PW*0.9,(Temp(a).MaxCurrent-0.5),Temp(a).Publication,'FontSize',15);
        elseif Temp(a).PW > 2.7
            text(Temp(a).PW*0.9,Temp(a).MaxCurrent*1.1,Temp(a).Publication,'FontSize',15);
        elseif Temp(a).MaxCurrent>12
            text((Temp(a).PW+0.01),(Temp(a).MaxCurrent-1),Temp(a).Publication,'FontSize',15);
        else
            text((Temp(a).PW+0.01),Temp(a).MaxCurrent*1.025,Temp(a).Publication,'FontSize',15);
        end
    end
    
    
    %Plot your data on the plot
    plot(XData,YData,'r');
    plot(PW,Cur,'r*','MarkerSize',10);
    text((PW*1.025),(Cur*1.025), 'Your Study','FontSize',15);
    
end



