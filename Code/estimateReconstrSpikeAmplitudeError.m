% David Eriksson, 2019

function [timeErr, meanError, reconstrCorr] = estimateReconstrSpikeAmplitudeError(reconstr, spikeMask) 
  goalSpikes = find(spikeMask==1);
  
    reconstr = double(reconstr);
    
    chanceError = mean(reconstr);
    meanVals = [];
    stdVals = [];
    maxVals = [];
    minVals = [];
    timeErrs = [];
    spikeVals = [];
    spaceVals = [];
    
    for i = 1:length(goalSpikes)
        index = goalSpikes(i);
        
        if (index > 0) && (index < length(reconstr))
            % Find previous spike
            previousIndex = 1;
            if i>1
                previousIndex = goalSpikes(i-1);
            end
            MinIndex = round((previousIndex+index)/2);
            MinIndex = max([1 MinIndex]);
            
            nextIndex = length(reconstr);
            if i<length(goalSpikes)
                spaceVals = [spaceVals reconstr(round((goalSpikes(i)+goalSpikes(i+1))/2))];   
                nextIndex = goalSpikes(i+1);
            end
            MaxIndex = round((nextIndex+index)/2);
            MaxIndex = min([length(reconstr) MaxIndex]);
            
            if (i>1) && (i<length(goalSpikes))
                if ((previousIndex+index)/2 > 0) && ((nextIndex+index)/2 <= length(reconstr))
                    if (MaxIndex - MinIndex) > 1
                        [maxVal maxTime] = max(reconstr(MinIndex:MaxIndex));
                        maxTime = maxTime + MinIndex - 1;
                        meanVals = [meanVals mean(reconstr(MinIndex:MaxIndex))];
                        stdVals = [stdVals std(reconstr(MinIndex:MaxIndex))];
                        maxVals = [maxVals maxVal];
                        minVals = [minVals min(reconstr(MinIndex:MaxIndex))];
                        if maxTime <= index
                            timeErr = (index-maxTime)/(index-MinIndex)-0.5;
                        else
                            timeErr = -(index-maxTime)/(MaxIndex-index)-0.5;
                        end
                        if ~isnan(timeErr)
                            timeErrs = [timeErrs timeErr];
                        end
                        spikeVals = [spikeVals reconstr(index)];
                    end
                    
                end
            end
        end
    end
    if isempty(spikeVals)
        timeErr = 0;
        meanError = 0;
        reconstrCorr = 0;
    else
        %[chanceError mean(meanVals) std(meanVals)/sqrt(length(meanVals)) length(meanVals) mean(spikeVals) std(spikeVals)/sqrt(length(spikeVals)) length(spikeVals)]
        
        % Spike time performance (local in time)
        if 0
            % AAAA Problem: One problem with the following code is that a constantly high curve which once in a while drops down with a negative spike will always produce a close to perfact correlation!
            E = spikeVals-meanVals;
            meanError = mean(E)/(std(E)/sqrt(length(E)));
            
            normFactors = (E>=0).*(maxVals-meanVals)+(E<0).*(meanVals - minVals);
            corrFactors = E./normFactors;
            reconstrCorr = mean(corrFactors);
            
            reconstrErr = mean((maxVals - spikeVals)./(2*2*stdVals));
        else   
            %timeErr = mean(timeErrs)/(std(timeErrs)/sqrt(length(timeErrs)));
            timeErr = mean(timeErrs);
            E = spikeVals-meanVals;
            meanError = mean(E)/(std(E)/sqrt(length(E)));
            
            normFactors = (maxVals-minVals)/2; % Could put standard deviation here but that causes the estimated correlation to blow up for the problem AAAA above.
            corrFactors = E./(normFactors+2.2204e-16); % number from eps in octave
            corrFactors = corrFactors(find(~isinf(corrFactors)));
            if isempty(corrFactors)
                reconstrCorr = NaN;
            else
                reconstrCorr = mean(corrFactors);
            end
            
            % New rank based correlationIndex
            if ~isempty(goalSpikes)
                [vs is] = sort(reconstr);
                ranked = reconstr*0;
                ranked(is) = (1:length(is))/length(is);
                reconstrCorr = (mean(ranked(goalSpikes))-0.5)/0.5;             
            else
                reconstrCorr = NaN;
            end
            
            reconstrErr = mean((maxVals - spikeVals)./(2*2*stdVals));
        end
        
        
        % Spike rate performance (global across the whole trace)
        rtE = spikeVals-mean(reconstr);
        rtMeanError = mean(rtE)/(std(rtE)/sqrt(length(rtE)));
        
        rtNormFactors = (rtE>=0)*(max(reconstr)-mean(reconstr))+(rtE<0)*(mean(reconstr) - min(reconstr));
        rtCorrFactors = rtE./rtNormFactors;
        rtReconstrCorr = mean(rtCorrFactors);
        
        rtReconstrErr = mean((max(reconstr) - spikeVals)./(2*2*std(reconstr)));
        
    end
     
end




