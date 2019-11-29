% David Eriksson, 2019

global g_deltaActivities;

for dai=1:length(g_deltaActivities)
    g_deltaActivities{dai}(:) = 0;
end

for dpi=1:length(g_deltaParameters)
    g_deltaParameters{dpi}(:) = 0;
end
