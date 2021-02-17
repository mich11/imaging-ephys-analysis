%pulls piezo whisker stim data from ADC channel recorded by OpenEphys
%takes derivative of ADC looking for positive TTL transition
%input arguments:
%   ts:     time vector
%   data:   single ADC channel vector
%output arguments:
%   whisktimes: whisker stim times

function[whiskTimes]=get_whiskstim_times(ts,data)
ddata=diff(data);
[pPeak,pInd]=findpeaks(ddata,'MinPeakProminence',0.05);
if ~isempty(pInd)
    whiskTimes=ts(pInd);
    %plot to make sure events are detected correctly
    figure(6)
    hold on
    plot(ts(2:end),ddata)
    scatter(whiskTimes,pPeak)
    title('Whisker deflection times - piezo monitor')
else
    whiskTimes=[];
end