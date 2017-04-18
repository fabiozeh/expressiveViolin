%% Perform the prediction and analysis
    
%% Load the required libraries

addpath(genpath('miditoolbox'));

%% Load Expert Database
createExpertDB

% exclude small segments (2 notes)
% expertDB = expertDB(arrayfun(@(x) size(expertDB{x,1},1) > 2, 1:size(expertDB,1)),:);

%% calculate expertDB leave-one-out analysis

% calculate the matrix of segment similarities
scores = Inf(size(expertDB, 1));
for jj = 1:size(scores,2)
    for ii = 1:size(scores,1)
        if ii < jj
            scores(ii, jj) = scores(jj, ii); % it is simmetric
        elseif ii > jj % for equal indices, leave it out, so skip.
            [H, tbk] = dtwSig2(expertDB{jj,1}, expertDB{ii,1}, 0, 1, 0, 1, 'no');
            scores(ii, jj) = H(tbk(end,1),tbk(end,2)); %sum(h(sub2ind(size(h),tbk(:,1)+1,tbk(:,2)+1)))
        end
    end
end

clear ii jj H tbk

% Compute dynamic estimations for each segment

% meanVel = { name of piece, mean piece velocity}
meanVel = expertDB([expertDB{:,2}] == 1, 3);
for ii = 1:size(meanVel,1)
    meanVel{ii,2} = mean(cellfun(@(x) mean(x(:,5)), expertDB(...
        cellfun(@(x) strcmp(meanVel{ii,1}, x), expertDB(:,3)), 1)));
end

% preallocation
[expertDB{:,6:12}] = deal(0);

for ii = 1:size(scores,1)
    [expertDB{ii,6}, ind] = min(scores(ii,:)); % for the lowest value of each row (could be column)
    % base level prediction as linear interpolation of matching segment levels
    expertDB{ii,7} = scaleInterpolate(size(expertDB{ii,1},1), expertDB{ind,1}(:,5) - expertDB{ind,4})';
    % matching segment offset from previous
    expertDB{ii,8} = expertDB{ind,5};
    % matching segment mean level
    expertDB{ii,9} = expertDB{ind,4};
    % matching piece mean level
    expertDB{ii,10} = meanVel{cellfun(@(x) strcmp(expertDB{ind,3}, x), meanVel(:,1)),2};
    % normalized melodic distance
    expertDB{ii,11} = expertDB{ii,6}/size(expertDB{ii,1},1);
end
% should interpolation be done in time domain instead of note domain?

% TODO
% more stable algorithm:
% if segment level is > 1 sd from mean, copy neighbor gradient
% else copy deviation from mean

% adjust mean level of segments
% the strategy is as follows:
% - two parameters are saved for each reference segment: the mean level of
% the piece it belongs to (meanVel = expertDB{:,10}) and the offset of the segment mean relative to
% the mean level of previous segment (os = expertDB{:,8}).
% - after determining all predictions, the final piece mean level is adjusted to
% be the mean(meanVel) taking all segments into account and the offset of each
% segment is corrected to os = os - mean(os).
%meanOS = mean([expertDB{:,8}]);
%predVel = mean([expertDB{:,10}]);
%offset = predVel + expertDB{1,8} - meanOS;
%expertDB{1,11} = expertDB{1,7} + offset;
%for ii = 2:size(expertDB,1)
%    offset = expertDB{ii,8} + offset - meanOS;
%    expertDB{ii,11} = expertDB{ii,7} + offset;
%end

%for ii = 1:size(expertDB,1)
%    expertDB{ii,11} = expertDB{ii,7} + expertDB{ii,9};
%end

outMean = mean([expertDB{:,10}]);
for ii = 1:size(expertDB,1)
    expertDB{ii,12} = expertDB{ii,7} + outMean + expertDB{ii,9} - expertDB{ii,10};
end

clear ind outMean meanVel

%% test quality of output according to original performance

% metrics = [segmentCorrelation segmentMeanSqError normalizedSegmentDistance segmentNumberOfNotes]
metrics = zeros(size(expertDB,1),4); % preallocation
for ii = 1:size(expertDB,1)
    metrics(ii,1) = corr(expertDB{ii,1}(:,5), expertDB{ii,12});
    metrics(ii,2) = mean((expertDB{ii,1}(:,5) - expertDB{ii,12}).^2);
    metrics(ii,3) = expertDB{ii,11}; % change to 6 for non-normalized
    metrics(ii,4) = size(expertDB{ii,1},1);
end

% metricsEvolution = [maxDistance meanCorrelation meanSquareError numSegments]
metricsEvolution(:,1) = [-0.05; 0; 0.1; 0.2; 0.4; 0.8; 1.6; 3.2; 6.4; 1000];
metricsEvolution(:,2:4) = deal(NaN); % preallocation
for ii = 2:size(metricsEvolution,1)
    % "for all segments with melodic distance ... < d <= ..."
    f = metrics(:,3) <= metricsEvolution(ii,1) & metrics(:,3) > metricsEvolution(ii-1,1);
    % "the mean correlation between prediction and performance"
    metricsEvolution(ii,2) = mean(metrics(f,1));
    % "the mean squared error between prediction and performance"
    metricsEvolution(ii,3) = mean(metrics(f,2));
    % "the number of segments in this category (distance <= 1st col value)"
    metricsEvolution(ii,4) = sum(f);
end
metricsEvolution = metricsEvolution(2:end,:);

metricsCumulative = metricsEvolution; % preallocation
for ii = 2:size(metricsCumulative,1)
    % "for all segments with melodic distance d <= ..."
    f = metrics(:,3) <= metricsCumulative(ii,1);
    % "the mean correlation between prediction and performance"
    metricsCumulative(ii,2) = mean(metrics(f,1));
    % "the mean squared error between prediction and performance"
    metricsCumulative(ii,3) = mean(metrics(f,2));
    % "the number of segments in this category (distance <= 1st col value)"
    metricsCumulative(ii,4) = sum(f);
end

notesEvolution(:,1) = [0; 2; 4; 6; 8; 10; 12; 16; 100];
notesEvolution(:,2:4) = deal(NaN); % preallocation
for ii = 2:size(notesEvolution,1)
    % "for all segments with number of notes ... < n <= ..."
    f = metrics(:,4) <= notesEvolution(ii,1) & metrics(:,4) > notesEvolution(ii-1,1);
    % "the mean correlation between prediction and performance"
    notesEvolution(ii,2) = mean(metrics(f,1));
    % "the mean squared error between prediction and performance"
    notesEvolution(ii,3) = mean(metrics(f,2));
    % "the number of segments in this category"
    notesEvolution(ii,4) = sum(f);
end
notesEvolution = notesEvolution(2:end,:);

% calculate overall mean level for comparison
trivialLevel = mean([expertDB{:,4}]);

% generate performed dynamics curve from concatenation of all segments in DB
performedDyn = vertcat(expertDB{:,1});
performedDyn = performedDyn(:,5);

% generate predicted dynamics curve from concatenation of all segments in DB
predictedDyn = vertcat(expertDB{:,12});

trivialMse = (performedDyn - trivialLevel).^2;
predictedMse = (predictedDyn - performedDyn).^2;

trivialSegmentMse = arrayfun(@(x) mean((expertDB{x,1}(:,5) - trivialLevel).^2), 1:size(expertDB,1));

% mseTrivDistCumulative(i) = the mean squared error between trivial model and performance for all
% segments with distance d <= ccEvolution(i,1).
mseTrivDistCumulative(1,:) = arrayfun(@(x)mean(trivialSegmentMse(metrics(:,3)<=x)), metricsEvolution(:,1));

clear f ii trivialLevel trivialSegmentMse

% This graph shows how mean squared error between prediction and
% performance within segments changes as the melodic distance of the match
% for each segment increases.
figure
hold on
plot(metricsEvolution(:,3));
plot(mseTrivDistCumulative);
hold off

% This graph shows how mean correlation between prediction vs. performance
% loudness varies as we take into account segments for which the matching
% sample is increasingly distant melodically (thus worse).
figure
plot(metricsCumulative(:,2));

% the melodic distance of each note, for plotting against output curve
melDistance = Inf(size(performedDyn,1),1);
for ii = 1:size(expertDB,1)
    melDistance(expertDB{ii,2}:(expertDB{ii,2}+size(expertDB{ii,1},1)-1),1) = ...
        deal(expertDB{ii,6});
end
clear ii

% correlation between computed distance of a segment and the correlation
% value between prediction and performance of the same segment.
corr_corrXmelDist = corr(metrics(:,1),metrics(:,3));

% correlation between the mean squared error between prediction and
% performance of a segment and the computed distance between score segment
% and reference segment.
corr_errXmelDist = corr(metrics(:,2),metrics(:,3));

% correlation between prediction vs. performance correlation and number of
% notes in segment. (desired = 0)
corr_corrXnotes = corr(metrics(:,1),metrics(:,4));

% correlation between prediction vs. performance mean squared error and
% number of notes in segment. 
corr_errXnotes = corr(metrics(:,2),metrics(:,4));

x = metrics(metrics(:,3)<=0.4,1);
SEM = std(x)/sqrt(length(x));               % Standard Error
ts = tinv([0.025  0.975],length(x)-1);      % T-Score
PLMIN = ts*SEM;
CI = mean(x) + PLMIN;                       % Confidence Interval

x = metrics(:,1);
SEM = std(x)/sqrt(length(x));               % Standard Error
ts = tinv([0.025  0.975],length(x)-1);      % T-Score
PLMINall = ts*SEM;
CIall = mean(x) + PLMINall;                 % Confidence Interval

%addpath('util');
%writeall(segments, [dataFolder sep 'analysis']);

clear x SEM ts PLMIN PLMINall dataFolder sep