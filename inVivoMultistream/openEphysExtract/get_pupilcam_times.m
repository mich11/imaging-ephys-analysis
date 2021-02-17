%pulls pupil cam exposure data from ADC channel recorded by OpenEphys
%takes derivative of ADC looking for positive TTL transition
%input arguments:
%   ts:     time vector
%   data:   single ADC channel vector
%output argument:
%   expTimes: frame times

function[expTimes]=get_pupilcam_times(ts,data)
ddata=diff(data);
[pPeak,pInd]=findpeaks(ddata,'MinPeakProminence',0.05);
if ~isempty(pInd)
    expTimes=ts(pInd);
    %plot to make sure events are detected correctly
    figure(6)
    hold on
    plot(ts(2:end),ddata)
    scatter(expTimes,pPeak)
    title('PupilCam exposure times')
else
    expTimes=[];
end