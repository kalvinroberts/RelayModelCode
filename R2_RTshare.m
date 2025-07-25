%% Figure 2: RT-share Manipulation and Violation Effects
% This script visualises how varying the first-stage RT-share in the relay model
% affects predicted CDFs, RSE, and Miller bound violations.

clear; clc; close all;

% Add custom function directory to path
addpath(fullfile(pwd, 'Functions'));

writedata = false;

%% Load Empirical Data and Fitted Parameters from Previous Analysis

paramsFile = fullfile(pwd, 'FittedParameters', 'params_uni_miller_82.mat');
load(paramsFile);

% Extract parameters for convenience
aMU      = params_82(1,1);
vMU      = params_82(2,1);
avMU     = params_82(3,1);

aLAMBDA  = params_82(1,2);
vLAMBDA  = params_82(2,2);
avLAMBDA = params_82(3,2);

% Load in empirical data from digitised CDF taken from Figure 1 Miller (1982)
empData_82 = readmatrix(fullfile(pwd, 'EmpiricalData', 'Miller82', 'miller_82.xlsx'));

%% Make CDFs of interest

xx = linspace(100, 700, 100);  % RT values for CDF evaluation

a_cdf  = getUniCDF(xx, aMU, aLAMBDA);
v_cdf  = getUniCDF(xx, vMU, vLAMBDA);

grice_cdf = getGriceCDF(xx, aMU, vMU, aLAMBDA, vLAMBDA); % calculate Grice's Bound
raab_cdf = getRaabCDF(xx, aMU, vMU, aLAMBDA, vLAMBDA); % calculate Raab's Race Model
miller_cdf = getMillerCDF(xx, aMU, vMU, aLAMBDA, vLAMBDA); % calculate RMI

%% Fit the RT share parameter to the empirical data

[opt_w, rmse.rtshare] = getRTshare(empData_82(:,[3,4]), aMU, vMU, aLAMBDA, vLAMBDA);

%% Get time for component stages

realA.firstStageMean = aMU * opt_w;
realA.firstStageSD = sqrt((realA.firstStageMean^3)/(aLAMBDA * opt_w));
realA.secondStageMean = aMU * (1-opt_w);
realA.secondStageSD = sqrt((realA.secondStageMean^3)/(aLAMBDA * (1-opt_w)));

realV.firstStageMean = vMU * opt_w;
realV.firstStageSD = sqrt((realV.firstStageMean^3)/(vLAMBDA * opt_w));
realV.secondStageMean = vMU * (1-opt_w);
realV.secondStageSD = sqrt((realV.secondStageMean^3)/(vLAMBDA * (1-opt_w)));

%% Data for Figure 1 b,c,d

numWeights = 100;                  % Number of weight steps
weights    = linspace(0, 0.5, numWeights);

modelCDFs = nan(length(xx), numWeights);
rse       = nan(1, numWeights);
violation = nan(1, numWeights);

% Parallel loop speeds up independent CDF evaluations
parfor idx = 1:numWeights

    w = weights(idx);
    modelCDFs(:,idx) = getRelayCDF(xx, aMU, vMU, aLAMBDA, vLAMBDA, w, 1-w, w, 1-w);

    % Redundancy gain (RSE) and violation metric
    rse(idx)       = getRSE_fromCDF(xx, modelCDFs(:,idx), grice_cdf);
    violation(idx) = getViolation_fromCDF(xx, modelCDFs(:,idx), miller_cdf);

end

pred.rse = rse; clear rse;
pred.violation = violation; clear violation;

%% Plotting: CDF Evolution with Weight

plotOpts = createPlotOpts([100 700], 3, [0 1], 3);

figure;
t = tiledlayout(1, 4, 'TileSpacing','compact', 'Padding','compact');
ax1 = nexttile(t, [1 2]); hold(ax1,'on');

% Unisensory CDFs
plot(xx, a_cdf, 'Color',plotOpts.audCol, 'LineWidth',plotOpts.linewidth);
plot(xx, v_cdf, 'Color',plotOpts.visCol, 'LineWidth',plotOpts.linewidth);

% Relay model curves colored by weight
grey = [228 210 231]/255; black = [137 41 133]/255;
colors = [linspace(grey(1),black(1),numWeights)',...
          linspace(grey(2),black(2),numWeights)',...
          linspace(grey(3),black(3),numWeights)'];

for idx = 1:numWeights
    plot(ax1, xx, modelCDFs(:,idx), 'Color', colors(idx,:), 'LineWidth',plotOpts.linewidth);
end

% Reference bounds: Miller and Raab
plot(ax1, xx, miller_cdf, '-', 'LineWidth',plotOpts.linewidth, 'Color', plotOpts.modelCol);
plot(ax1, xx, raab_cdf, '--', 'LineWidth',plotOpts.linewidth, 'Color', plotOpts.modelCol);

% Optimal-weight relay curve
fittedRelayCDF = getRelayCDF(xx,aMU,vMU,aLAMBDA,vLAMBDA,opt_w,1-opt_w,opt_w,1-opt_w);
plot(ax1, xx, fittedRelayCDF, 'Color', plotOpts.audvisCol, 'LineWidth',plotOpts.linewidth);

markerOpts = {'Marker', 'o', 'MarkerSize', plotOpts.markersize, 'LineStyle', 'none', 'MarkerFaceColor', plotOpts.markerfacecol, 'LineWidth', plotOpts.markerlinewidth};

plot(ax1, empData_82(:,1), empData_82(:,4), markerOpts{:}, 'Color', plotOpts.audCol, 'DisplayName', 'A');
plot(ax1, empData_82(:,2), empData_82(:,4), markerOpts{:}, 'Color', plotOpts.visCol, 'DisplayName', 'V');
plot(ax1, empData_82(:,3), empData_82(:,4), markerOpts{:}, 'Color', plotOpts.audvisCol, 'DisplayName', 'AV');

xlabel('Response Time (ms)'); 
ylabel('Cumulative Probability');

% Set axis ticks and other properties
ylim(plotOpts.ylim)
xlim(plotOpts.xlim)
yticks(plotOpts.yticks)
xticks(plotOpts.xticks)

% RSE subplot
plotOpts = createPlotOpts([0 50], 6, [0 80], 5);
ax2 = nexttile(t); hold(ax2,'on');
plot(weights*100, pred.rse, 'k-', 'LineWidth', plotOpts.linewidth);
ylabel('RSE (ms)');
xlabel('RT Share (%)');
raabRSE = getRSE_fromCDF(xx,raab_cdf, grice_cdf);
plot([0 weights(end)*100], raabRSE*[1 1], '--', 'LineWidth', plotOpts.linewidth, 'Color', plotOpts.modelCol);

plot(0, raabRSE, 'Marker', 'o', 'Color', plotOpts.modelCol, markerOpts{:})

xlim(plotOpts.xlim)
ylim(plotOpts.ylim)
xticks(plotOpts.xticks)
yticks(plotOpts.yticks)

% Violation subplot
plotOpts = createPlotOpts([0 50], 6, [0 10], 6);
ax3 = nexttile(t); hold(ax3,'on');
plot(weights*100, pred.violation, 'k-', 'LineWidth', plotOpts.linewidth);
ylabel('Violation (ms)');
xlabel('RT Share (%)');
plot([0 50],[0 0],'--','LineWidth',plotOpts.linewidth, 'Color', plotOpts.modelCol);
plot(0, 0, 'Marker', 'o', 'Color', plotOpts.modelCol, markerOpts{:})
xlim(plotOpts.xlim)
ylim(plotOpts.ylim)
xticks(plotOpts.xticks)
yticks(plotOpts.yticks)

allAx = [ax1, ax2, ax3];

set(allAx, ...
    'Box',      'off', ...                
    'TickDir',  plotOpts.tickdir, ...
    'FontSize', plotOpts.fontsize, ...
    'XColor',   plotOpts.axisCol, ...
    'YColor',   plotOpts.axisCol, ...
    'LineWidth',plotOpts.linewidth);

% Save figure
if writedata
    outFile = fullfile(pwd, 'Figures', 'Figure2.pdf');
    exportgraphics(gcf, outFile, 'ContentType', 'vector');
end