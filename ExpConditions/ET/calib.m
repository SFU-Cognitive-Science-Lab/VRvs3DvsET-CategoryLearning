%% if this doesn't work I give up.

sca;
close all;
clearvars;

PsychDefaultSetup(2); % change this to reflect how we usually do setup

Screen('Preference', 'SkipSyncTests', 1); % skipping sync tests

% get eytracker
Tobii = EyeTrackingOperations();

eyetracker = Tobii.find_all_eyetrackers();

if isa(eyetracker,'EyeTracker')
    disp(['Address:',eyetracker.Address]);
    disp(['Name:',eyetracker.Name]);
    disp(['Serial Number:',eyetracker.SerialNumber]);
    disp(['Model:',eyetracker.Model]);
    disp(['Firmware Version:',eyetracker.FirmwareVersion]);
else
    disp('Eye tracker not found!');
end