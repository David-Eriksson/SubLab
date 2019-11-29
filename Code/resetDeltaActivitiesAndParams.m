% David Eriksson, 2019

global g_deltaActivities;

for dai=1:length(g_deltaActivities)
    g_deltaActivities{dai}(:) = 0;
end

for dai=1:length(g_deltaParameters)
    g_deltaParameters{dai}(:) = 0;
end
