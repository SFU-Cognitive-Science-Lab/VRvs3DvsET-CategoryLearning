function ETnew
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Kat trying to figure out the eyetracker on the new computers
% Tobii eyetracker package is Tobii SDK pro
% find examples on line here: http://developer.tobiipro.com/matlab/matlab-sdk-reference-guide.html

ptb_RootPath = '/Applications/Psychtoolbox/';
ptb_ConfigPath = '/Applications/Psychtoolbox/';

Screen('Preference', 'SkipSyncTests', 1);

%% Parameters

% Options
expName = 'vrTest';
factors = 3; % ???


screenDim = [0 0 1680 1050]; % note: 0,0 is the top left corner of the screen
screenDim = [0 0 1440 900]; % MB coordinates
debugging = 1; % A skip flag.
eyetracking = 1; % Run with or without eye tracking
preCalib = 0; % Can use a stock calibration if set to 1.
requireSpaceBar = 1; %if 1, participants need to tap space after answering to move on
InputDevice = 1; % Gamepad = 1, Mouse click = 2;


% Environment
addpath(genpath(('helpers'))); % contains colour, gamepad and ET support.
addpath(genpath(('images')));
addpath(genpath(('../../library')));
rand('twister',sum(100*clock)); % reset random seeeeeed.
format long g
resX = screenDim(3);
% might need to change resolution lol
resY = screenDim(4); % max screen size (should be resolution of your computer)
bgArea = screenDim; %This sets the coordinate space of the screen window, WHICH MAY HAVE A DIFFERENT SIZE
pauseTimeInSeconds = 1/120;

if InputDevice ==1
    %clear JoyMEX; % May contain information from previous use.
    %JoyMEX('init',0);
end


%% Parameters

trialNums = 480; % ??
featureNums = 3;
numBlocks = 20;
numTrialsPerBlock = trialNums/numBlocks; % 24 is necessary for comparison with 5to1 experiment.
binaryFeatureValues = featureNums*2;
stimuliNum = 2^featureNums; %should be 8
referenceAngle = 0;  % This makes reference to location 1. Angle = 0 is horizontally left from fixation, as is 360.


% Colour settings

white = [255 255 255];
black = [0 0 0];
red = [255 0 0];
green = [0 255 0];
blue = [0 0 255];
grey = [100 100 100]+50;
featureSideLength = 30;
boxStartColour = blue;
backgroundColour = white;
colourSpace = 2; % Lab = 1, HSV =2

equalColours = zeros(binaryFeatureValues,3);

if colourSpace==1
    
    lVal = 75;
    for colourInd = 1:size(equalColours,1)
        
        aVal = sind(30*colourInd) * 32;
        bVal = cosd(30*colourInd) * 32;
        [rVal gVal bVal] = Lab2RGB(lVal, aVal, bVal);
        equalColours(colourInd,:) = [rVal, gVal, bVal];
        
    end
    equalColours = equalColours*255;
    
elseif colourSpace==2
    equalColours = hsv(6);
end




inputOK = 0;
while inputOK == 0
    ok = 1;
    %answer = inputdlg({'Participant ID number:'}, 'Please input participant details...', 1.5, {''});
    subjectNumber = input('Participant ID? '); %was getting errors on experiment room 2009b
    
    
    if ~isnumeric(subjectNumber)
        ok = 0; disp('Invalid participant ID')
    end
    
    if ok == 1, inputOK = 1;
    end
end






% Hide cursor
%HideCursor();

if eyetracking
    
    %% Initialize eyetracker
    
        
    disp('Initializing eyetracker...');
    t = EyeTrackingOperations();
    eyetracker = t.find_all_eyetrackers();
        
    fprintf('Connecting to tracker "%s"...\n', trackerId);

end



% *************************************************************************
%
% Calibration of a participant
%
% *************************************************************************

if ~preCalib && ~debugging

        
    % Make a call to the Tobii provided calibration setup function
    Calib = ScreenBasedCalibration(eyetracker);
        
    disp('Starting TrackStatus');
    % Display the track status window showing the participant's eyes (to position the participant).
    TrackStatus(Calib, InputDevice); % Track status window will stay open until user key press.
    disp('TrackStatus stopped');
        
    disp('Starting Calibration workflow');
    % Perform calibration
    %fig = gcf
    %uistack(gcf,'top') %{We need this to happen DURING or
    %INSIDE HandleCalibWorkflow or somehow set a condition for when Fig = 1
    %appears
    HandleCalibWorkflow(Calib);
    disp('Calibration workflow stopped');

    
end

% Show cursor
ShowCursor();




%% Experiment Calculations and Counterbalancing

%Condition, relavance locations, location colours, and background images,
%all need counterbalancing. With 4 conditions, 6 relevance combinations, 6
%colours and 2 background images (unused in covertLearning), this yields 48
%possible combinations:

crossingMat = nan(trueConditionNumber,factors);

crossingMat(:,1) = repmat(conditions', length(crossingMat)/length(conditions),1);
crossingMat(:,2) = repmat(kron(relevanceLocations,ones(1,length(conditions)))', length(crossingMat)/(length(conditions)*length(relevanceLocations)),1);
crossingMat(:,3) = kron(locationColours,ones(1,(length(conditions)*length(relevanceLocations))))';

% We can randomize by permuting rows ...
crossingMat = crossingMat(randperm(trueConditionNumber),:);


% What condition are they in? There are 4 conditions:
conditionCode = crossingMat(mod(subjectNumber,trueConditionNumber)+1,1); % this will create 1 2 3 4 1 2 3 4...

%% TO FIX COUNTERBALANCING
conditionCode = 3;

%% TO FIX COUNTERBALANCING
% anything but '213' for condition 1 and '312' for condition 3
subjectCondition = 'cl3';

%%


% Set some condition information. Trial durations will be selected uniform
% randomly from this distribution of durations. They're all the same in the fast
% and constant conditions - this is to facilitate the variable time condition.

switch conditionCode
    
    %'sshrcfar'
    case 1, subjectCondition = 'cl1';
        
    %'sshrcnumberfar'
    case 2, subjectCondition = 'cl2';
        
    %'sshrcclose'
    case 3, subjectCondition = 'cl3';
        
    %'sshrcnumberclose'
    case 4, subjectCondition = 'cl4';
        
end



% Categories

Feature1 = [0 0 0 0 1 1 1 1]';
Feature2 = [0 0 1 1 0 0 1 1]';
Feature3 = [0 1 0 1 0 1 0 1]';

if conditionCode == 1 || conditionCode == 3 %Easy
    
    Category = [1 1 2 2 3 3 4 4]';
    categoryAlignment = ['A' 'B' 'C' 'D' 'A' 'B' 'C' 'D'];
    
elseif conditionCode == 2 || conditionCode == 4 %Hard
    
    Category = [1 2 3 4 5 6 7 8]';
    categoryAlignment = [{'A1'} {'A2'} {'B1'} {'B2'} {'C1'} {'C2'} {'D1'} {'D2'}];
    
end

standardRelevanceMatrix = [Feature1 Feature2 Feature3];


relevanceCode = crossingMat(mod(subjectNumber,trueConditionNumber)+1,2);


if relevanceCode==3 && strcmp(subjectCondition,'cl1')
    relevanceCode = randsample([1:2 4:6],1)
elseif relevanceCode==5 && strcmp(subjectCondition,'cl3')
    relevanceCode = randsample([1:4 6],1)
end
%%


switch relevanceCode
    case 1, rel = '123'; % that means location1=F1, location2=F2, location3=F3
    case 2, rel = '132';
    case 3, rel = '213';
    case 4, rel = '231';
    case 5, rel = '312';
    case 6, rel = '321';
end




Location1Relevance = str2num(rel(1));
Location2Relevance = str2num(rel(2));
Location3Relevance = str2num(rel(3));

rearrangedRelevanceMatrix = [standardRelevanceMatrix(:,Location1Relevance) standardRelevanceMatrix(:,Location2Relevance) standardRelevanceMatrix(:,Location3Relevance)];


% The old Latin Square method.
%latinsquarerelevancecode = '126354231465342516453621564132615243'; %latin square courtesy of bill. thanks bill!
latinsquarerelevancecode = '123456234561345612456123561234612345'; %Another way of doing it.
%[M R] = latsq(4);


% Now let's counterbalance the colours.

colourCode = crossingMat(mod(subjectNumber,trueConditionNumber)+1,3);

colourPairIndex = randi(size(equalColours,1));
colourPairs = latinsquarerelevancecode((colourPairIndex-1)*(6)+1:(colourPairIndex-1)*(6)+6)

colourPairs = arrayfun(@str2num,colourPairs);

shuffleColours = randperm(6);

shuffledColours = [equalColours(colourPairs(shuffleColours(1)),:); equalColours(colourPairs(shuffleColours(2)),:); equalColours(colourPairs(shuffleColours(3)),:); equalColours(colourPairs(shuffleColours(4)),:); equalColours(colourPairs(shuffleColours(5)),:); equalColours(colourPairs(shuffleColours(6)),:)];

featureOptions = {};
for i = 1:2:length(equalColours)
    [iscolor clrs] = fuzzycolor(shuffledColours(i,:));
    [iscolor1 clrs1] = fuzzycolor(shuffledColours(i+1,:));
    featureOptions{i} = strcat(clrs(find(iscolor==1,1)), '/', clrs1(find(iscolor1==1,1)));
    
end

newcategory = [];
newstim = [];

unitBlockCount = trialNums/stimuliNum;

for i = 1:unitBlockCount %34 for 272, 45 for 360, 60 for 480
    idx = randperm(length(rearrangedRelevanceMatrix));
    newcategory = [newcategory;Category(idx',:)];
    newstim = [newstim;rearrangedRelevanceMatrix(idx', :)];
end

display(subjectNumber);display(rel);display(conditionCode)

% location calculations
fixationXY = [resX resY]/2;

% start box:
startArea = [fixationXY(1)-(featureSideLength/2) fixationXY(2)-(featureSideLength/2) fixationXY(1)+(featureSideLength/2) fixationXY(2)+(featureSideLength/2)]; % start box

% Feature spacing condition:
if conditionCode == 3 || conditionCode == 4 %Close
    distanceFromFixation = 400; % Distance of features from fixation
    distanceFromFixation1 = 400; %this puts the F1 feature at 21cm from the other features, as it is in the other condition.
else % Far
    distanceFromFixation1 = 400;
    distanceFromFixation = 600;
end

Location1Radian = (referenceAngle+30/360)*pi*2;
Location1Centre = [round(cos(Location1Radian)*distanceFromFixation1)+fixationXY(1) (round(sin(Location1Radian)*distanceFromFixation))+fixationXY(2)]; % contains X & Y of centre
Location1Coords = [Location1Centre-(featureSideLength/2) Location1Centre+(featureSideLength/2)]'; % Given the centre, restore the X/Y coordinates for actual screen coords

Location2Radian = (mod(referenceAngle+180, 360)/360)*pi*2; % 120 because there are 3 features, each 120 deg (of a circle) apart; mod 360 because we wrap if we're over
Location2Centre = [(round(cos(Location2Radian)*distanceFromFixation1))+fixationXY(1) (round(sin(Location2Radian)*distanceFromFixation1))+fixationXY(2)];
Location2Coords = [Location2Centre-(featureSideLength/2) Location2Centre+(featureSideLength/2)]';

Location3Radian = (mod(referenceAngle+330, 360)/360)*pi*2;
Location3Centre = [(round(cos(Location3Radian)*distanceFromFixation1))+fixationXY(1) (round(sin(Location3Radian)*distanceFromFixation))+fixationXY(2)];
Location3Coords = [Location3Centre-(featureSideLength/2) Location3Centre+(featureSideLength/2)]';

AllLocationCoords = [Location1Coords Location2Coords Location3Coords]; % indexing into column c gets you feature c




%% IO Setup

% Create the output directory if it doesn't exist.

if ~exist([subjectCondition 'ExpLvl.txt'])
    expHeader = {'Subject', 'Cond', 'Location1Feature', 'Location2Feature', 'Location3Feature', 'Location1Relevance', 'Location2Relevance', 'Location3Relevance'}
    txt=sprintf('%s\t',expHeader{:});
    txt(end)='';
    dlmwrite([subjectCondition 'ExpLvl.txt'],txt,'delimiter','', 'newline', 'pc');
end
fid=fopen([subjectCondition 'ExpLvl.txt'],'at');
fprintf(fid, sprintf('%s',[num2str(subjectNumber) '	' subjectCondition '	' featureOptions{1}{1} '	' featureOptions{3}{1} '	' featureOptions{5}{1} '	' num2str(Location1Relevance) '	' num2str(Location2Relevance) '	' num2str(Location3Relevance) '\n']));
fclose(fid);

if ~exist([subjectCondition expName '-' num2str(subjectNumber) '.txt'])
    trialHeader = {'Subject', 'TrialId', 'Feature1Value', 'Feature2Value', 'Feature3Value', 'CorrectResponse', 'Response', 'TrialAccuracy', 'StimulusRT', 'FeedbackRT', 'StartTime', 'FixationOnset', 'StimulusOnset', 'ColourOnset', 'FixCrossLocationX', 'FixCrossLocationY', 'FeedbackOnset', 'FixationNumber'};
    txt=sprintf('%s\t',trialHeader{:});
    txt(end)='';
    dlmwrite([subjectCondition expName '-' num2str(subjectNumber) '.txt'],txt,'delimiter','', 'newline', 'pc')
end

if ~exist([subjectCondition expName '-' num2str(subjectNumber) '-1.gazedata'])
    gazeHeader = {'Subject', 'Session', 'ID', 'TETTime', 'XGazePosLeftEye', 'YGazePosLeftEye', 'DiameterPupilLeftEye', 'ValidityLeftEye', 'XGazePosRightEye', 'YGazePosRightEye', 'DiameterPupilRightEye', 'ValidityRightEye', 'TrialID', 'TrialPhase','CursorX','CursorY','EyeCursorX','EyeCursorY'};
    txt=sprintf('%s\t',gazeHeader{:});
    txt(end)='';
    dlmwrite([subjectCondition expName '-' num2str(subjectNumber) '-1.gazedata'],txt, 'delimiter','', 'newline', 'pc')
else
    display('Gaze file for this subject already exists')
    return
end



%% Setup Display

% Here we call some default settings for setting up Psychtoolbox
% PsychDefaultSetup(2);

[theScreen theScreenArea] = Screen('OpenWindow', 0, backgroundColour, screenDim); % % open a screen
Screen('Preference', 'ConserveVRAM', 2);
HideCursor(theScreen)
Screen('Preference', 'SkipSyncTests', 1); % This prevents crashes due to sub-par video cards failing screen tests.

% Cross hair cursor
%ShowCursor('CrossHair');

% Font information
Screen('TextFont', theScreen, 'Arial');
Screen('TextSize', theScreen, 24);
Screen('TextStyle', theScreen, 1);

% Load in images
imgDungeon = imread('images/Dungeon','jpg');
imgDoor = imread('images/doorwithpanel','png');

% Texturize images for psychtoolbox
texImgDungeon = Screen('MakeTexture', theScreen, imgDungeon);
texImgDoor = Screen('MakeTexture', theScreen, imgDoor);

% Set the Trajectory Storage Cell Header: be consistent when saving at the end of each trial
TrajStorageHeader = {'X', 'Y', 'Timestamp', 'Location'};


%% Begin Experiment

%% 1. Instructions

if ~debugging
    
    if InputDevice ==1
        subfunctionTextScreen(theScreen, {'Bad news! You are stuck in a dungeon!!'},2);
    elseif InputDevice ==2
        subfunctionTextScreen(theScreen, {'Bad news! You are stuck in a dungeon!!'},1);
    end
    Screen('DrawTexture', theScreen, texImgDungeon, [], bgArea);
    Screen('Flip', theScreen);
    pause(4);
    
    instructionsScreen1 = {'In order to escape you will have to keep your wits about you.'};
    
    if InputDevice ==1
        subfunctionTextScreen(theScreen, instructionsScreen1,2);
    elseif InputDevice ==2
        subfunctionTextScreen(theScreen, instructionsScreen1,1);
    end
    
    
    
    instructionsScreen2 = {'As you try to nagivate out of the dungeon you will\n\n frequently come across rooms with a locked door.'};
    
    subfunctionTextScreen(theScreen, instructionsScreen2,2);
    
    
    
    Screen('FillRect', theScreen, black, screenDim)
    imgScaler = 2.5;
    
    Screen('DrawTexture', theScreen, texImgDoor, [], [(bgArea(3)/2 - size(imgDoor,2)*imgScaler/2) (bgArea(4)/2- size(imgDoor,1)*imgScaler/2) (bgArea(3)/2 + size(imgDoor,2)*imgScaler/2) (bgArea(4)/2 + size(imgDoor,1)*imgScaler/2)]);
    
    Screen('FillRect', theScreen, blue, [(bgArea(3)/2 - size(imgDoor,2)*imgScaler/2)+(82*imgScaler) (bgArea(4)/2- size(imgDoor,1)*imgScaler/2)+(140*imgScaler) (bgArea(3)/2 - size(imgDoor,2)*imgScaler/2)+(82*imgScaler)+10 (bgArea(4)/2- size(imgDoor,1)*imgScaler/2)+(140*imgScaler)+10])
    Screen('FillRect', theScreen, green, [(bgArea(3)/2 - size(imgDoor,2)*imgScaler/2)+(92*imgScaler) (bgArea(4)/2- size(imgDoor,1)*imgScaler/2)+(125*imgScaler) (bgArea(3)/2 - size(imgDoor,2)*imgScaler/2)+(92*imgScaler)+10 (bgArea(4)/2- size(imgDoor,1)*imgScaler/2)+(125*imgScaler)+10])
    Screen('FillRect', theScreen, red, [(bgArea(3)/2 - size(imgDoor,2)*imgScaler/2)+(102*imgScaler) (bgArea(4)/2- size(imgDoor,1)*imgScaler/2)+(140*imgScaler) (bgArea(3)/2 - size(imgDoor,2)*imgScaler/2)+(102*imgScaler)+10 (bgArea(4)/2- size(imgDoor,1)*imgScaler/2)+(140*imgScaler)+10])
    
    instructionsScreen3 = {'Notice the box just to the left of the door?\n\n This is actually the mechanism that will unlock the door.\n\nThe combination of colours is actually a code that tells \n\nyou the correct button to push in order to open the door.\n\nLet''s take a closer look.'};
    DrawFormattedText(theScreen, instructionsScreen3{1}, 'center', resY-(1/3)*resY, white, 100)
    Screen('Flip',theScreen,[],1);
    pause(2)
    
    
    if InputDevice ==1
        DrawFormattedText(theScreen, '(Press any button on the controller to continue.)', 'center', (19/20)*resY, white, 150)
        Screen('Flip',theScreen);
        getGamePadAll;
    elseif InputDevice ==2
        subfunctionTextScreen(theScreen, instructionsScreen0,1);
    end
    
    
    Screen('FillRect', theScreen, white, screenDim)
    if conditionCode == 1  || conditionCode == 3
        instructionsScreen4 = {' Let''s call these buttons A,B,C & D. \n\nYou''ll see them as the top trigger buttons on the controller.'};
        triggerButtons = imread('images/bothButtons','jpg');
    else
        instructionsScreen4 = {'Let''s call these buttons A,B,C & D. \n\nYou''ll see them as the top trigger buttons on the controller.\n\nIn addition, you will need to specify whether it as an A1 or A2, or B1 or B2 etc..\n\n by using the numbers 1 and 2 on the front of the controller.'};
        triggerButtons = imread('images/bothButtons1','jpg');
    end
    instructionsScreen4a = {'If you push the correct button, the door will open and you can safely pass through.'}
    
    
    triggerButtonsTex = Screen('MakeTexture', theScreen, triggerButtons);
    Screen('DrawTexture', theScreen, triggerButtonsTex);
    
    %{
    Screen('FillRect', theScreen, grey, [(resX/4) 3*(resY/10) (3/4)*(resX) (4/5)*(resY)])
    Screen('FillRect', theScreen, 255*(shuffledColours(1,:)), Location1Coords)
    Screen('FillRect', theScreen, 255*(shuffledColours(3,:)), Location2Coords)
    Screen('FillRect', theScreen, 255*(shuffledColours(5,:)), Location3Coords)
    %}
    
    DrawFormattedText(theScreen, instructionsScreen4{1}, 'center', resY-(19/20)*resY, black, 150)
    DrawFormattedText(theScreen, instructionsScreen4a{1}, 'center', (5/6)*resY, black, 150)
    Screen('Flip',theScreen,[],1);
    pause(5)
    DrawFormattedText(theScreen, '(Press any button on the controller to continue.)', 'center', (19/20)*resY, black, 150)
    Screen('Flip',theScreen);
    getGamePadAll;
    %%
    
    instructionsScreen5 = {'There is always only one correct button that will open the door.\n\n Also notice how each part of the code is different from the others.\n\n Before we learn how to select a button, let''s learn a little more about the code.'};
    Screen('FillRect', theScreen, grey, [(resX/10) 2*(resY/10) (9/10)*(resX) (4/5)*(resY)])
    Screen('FillRect', theScreen, 255*(shuffledColours(1,:)), Location1Coords)
    Screen('FillRect', theScreen, 255*(shuffledColours(3,:)), Location2Coords)
    Screen('FillRect', theScreen, 255*(shuffledColours(5,:)), Location3Coords)
    DrawFormattedText(theScreen, instructionsScreen5{1}, 'center', resY-(19/20)*resY, black, 150)
    Screen('Flip',theScreen,[],1);
    pause(5)
    DrawFormattedText(theScreen, '(Press any button on the controller to continue.)', 'center', (19/20)*resY, black, 150)
    Screen('Flip',theScreen);
    getGamePadAll;
    
    
    
    %%
    instructionsScreen6 = {'In each of the three parts of the code you will be seeing one of two possible colours.\n\n Below shows you what the possible colours are that you may see in each position.'};
    DrawFormattedText(theScreen, instructionsScreen6{1}, 'center', (resY/6), black, 200)
    part1 = 'Part 1:';
    width=Screen(theScreen,'TextBounds',part1);
    DrawFormattedText(theScreen, part1, 1.5*(resX/7)-width(3)/2, 2.5*(resY/6), black, 20)
    part2 = 'Part 2:';
    width=Screen(theScreen,'TextBounds',part2);
    DrawFormattedText(theScreen, 'Part 2:', 3.5*(resX/7)-width(3)/2, 2.5*(resY/6), black, 20)
    part2 = 'Part 3:';
    width=Screen(theScreen,'TextBounds',part2);
    DrawFormattedText(theScreen, 'Part 3:', 5.5*(resX/7)-width(3)/2, 2.5*(resY/6), black, 20)
    
    Screen('FillRect', theScreen, 255*(shuffledColours(1,:)), [(resX/7) 3*(resY/6) 2*(resX/7) 4*(resY/6)])
    DrawFormattedText(theScreen, 'or', 1.5*(resX/7)-13, 4.1*(resY/6), black, 20)
    Screen('FillRect', theScreen, 255*(shuffledColours(2,:)), [(resX/7) 4.5*(resY/6) 2*(resX/7) 5.5*(resY/6)])
    Screen('FillRect', theScreen, 255*(shuffledColours(3,:)), [3*(resX/7) 3*(resY/6) 4*(resX/7) 4*(resY/6)])
    DrawFormattedText(theScreen, 'or', 3.5*(resX/7)-13, 4.1*(resY/6), black, 20)
    Screen('FillRect', theScreen, 255*(shuffledColours(4,:)), [3*(resX/7) 4.5*(resY/6) 4*(resX/7) 5.5*(resY/6)])
    Screen('FillRect', theScreen, 255*(shuffledColours(5,:)), [5*(resX/7) 3*(resY/6) 6*(resX/7) 4*(resY/6)])
    DrawFormattedText(theScreen, 'or', 5.5*(resX/7)-13, 4.1*(resY/6), black, 20)
    Screen('FillRect', theScreen, 255*(shuffledColours(6,:)), [5*(resX/7) 4.5*(resY/6) 6*(resX/7) 5.5*(resY/6)])
    
    Screen('Flip',theScreen,[],1);
    pause(5)
    DrawFormattedText(theScreen, '(Press any button on the controller to continue.)', 'center', (19/20)*resY, black, 150)
    Screen('Flip',theScreen);
    getGamePadAll;
    %%
    
    instructionsScreen7 = {'Now we''re going to show you how the code is presented and how you can make your button choice.'};
    
    subfunctionTextScreen(theScreen, instructionsScreen7,2);
    
    %%
    %instructionsScreen8 = {'First, you''ll see a blue dot at the center of the screen.\n\nMove the mouse cursor to the blue dot and click on it.'};
    instructionsScreen8 = {'First, you''ll see a number at the center of the screen.\n\nPress that number on the controller.'};
    %Screen('FillOval', theScreen, boxStartColour, [startArea(1) startArea(2) startArea(3) startArea(4)]); % start box is actually start circle
    DrawFormattedText(theScreen, '4', 'center', 'center', blue, 200)
    DrawFormattedText(theScreen, instructionsScreen8{1}, 'center', (resY/6), black, 200)
    Screen('Flip', theScreen);
    
    getGamePadAll(4);
    %{
    inStart = 0;
    while ~inStart
        [x y buttons] = GetMouse; % update position
        if x > startArea(1) && x < startArea(3) && y > startArea(2) && y < startArea(4)
            if any(buttons)
                while ~any(buttons) % wait for press
                    [x y buttons] = GetMouse;
                end
                while any(buttons) % wait for release
                    [x y buttons] = GetMouse;
                end
                inStart = 1; % stop monitoring
                             
            end
        end
    end
    %}
    
    %%
    
    instructionsScreen9 = {'Next you will see the code, and it will look something like this.'};
    
    Screen('FillRect', theScreen, 255*(shuffledColours(1,:)), Location1Coords)
    Screen('FillRect', theScreen, 255*(shuffledColours(3,:)), Location2Coords)
    Screen('FillRect', theScreen, 255*(shuffledColours(5,:)), Location3Coords)
    
    DrawFormattedText(theScreen, instructionsScreen9{1}, 'center', resY-(9/10)*resY, black, 150)
    Screen('Flip',theScreen,[],1);
    pause(5)
    if conditionCode ==1  || conditionCode == 3
        DrawFormattedText(theScreen, '(Press any trigger button on the controller to guess a category.)', 'center', (19/20)*resY, black, 150)
    else
        DrawFormattedText(theScreen, '(Press any trigger button followed by "1" or "2" to guess a category.)', 'center', (19/20)*resY, black, 150)
    end
    
    Screen('Flip',theScreen);
    
    buttonPressed = 0;
    buttonPressed1 = 0;
    while ~buttonPressed
        %[joystick a] = JoyMEX(0);
        [joystick a] = getGamePadAll;
        if conditionCode == 1  || conditionCode == 3
            
            if sum(a(5:8))==1
                buttonPressed =1;
            end
            if buttonPressed
                [dontCare Response] = max(a(5:8));
            end
            
        else
            
            if sum(a(5:8))==1
                buttonPressed1 =1;
                [dontCare Response1] = max(a(5:8));
            end
            
            if buttonPressed1 && sum(a(1:2))==1
                [dontCare Response2] = max(a(1:2));
                
                switch Response1
                    case 1
                        switch Response2
                            case 1
                                Response = 1;
                            case 2
                                Response = 2;
                        end
                    case 2
                        switch Response2
                            case 1
                                Response = 3;
                            case 2
                                Response = 4;
                        end
                    case 3
                        switch Response2
                            case 1
                                Response = 5;
                            case 2
                                Response = 6;
                        end
                    case 4
                        switch Response2
                            case 1
                                Response = 7;
                            case 2
                                Response = 8;
                        end
                        
                end
                buttonPressed = 1;
                
            end
        end
    end
    
    
    %%
    
    instructionsScreen10 = {'After choosing you''ll get feedback that looks like this.'};
    DrawFormattedText(theScreen, instructionsScreen10{1}, 'center', resY-(9/10)*resY, black, 150)
    Screen('FillRect', theScreen, 255*(shuffledColours(1,:)), Location1Coords)
    Screen('FillRect', theScreen, 255*(shuffledColours(3,:)), Location2Coords)
    Screen('FillRect', theScreen, 255*(shuffledColours(5,:)), Location3Coords)
    feedbackScreenInstructions(theScreen, Response,'X')
    Screen('Flip',theScreen,[],1);
    pause(4)
    DrawFormattedText(theScreen, '(Press any button on the controller to continue.)', 'center', (19/20)*resY, black, 150)
    Screen('Flip',theScreen);
    getGamePadAll;
    %%
    
    
    if conditionCode == 1 || conditionCode == 3
        
        
        %%
        
        instructionsScreen11 = {'Now we''re going to show you which categories go with which buttons.\n\n It''s easy! So category A is simply the top left trigger button.\n\nTry it now!!'};
        
        DrawFormattedText(theScreen, instructionsScreen11{1}, 'center', resY-(9/10)*resY, black, 150)
        Screen('Flip',theScreen,[],1);
        pause(2)
        DrawFormattedText(theScreen, '(Press the top left trigger on the controller to guess Category A.)', 'center', (19/20)*resY, black, 150)
        Screen('Flip',theScreen);
        getGamePadAll(5);
        
        %%
        
        instructionsScreen12 = {'Good job!\n\n Now let''s try Category B.'};
        
        DrawFormattedText(theScreen, instructionsScreen12{1}, 'center', resY-(9/10)*resY, black, 150)
        Screen('Flip',theScreen,[],1);
        pause(2)
        DrawFormattedText(theScreen, '(Press the top right trigger on the controller to guess Category B.)', 'center', (19/20)*resY, black, 150)
        Screen('Flip',theScreen);
        getGamePadAll(6);
        
        %%
        
        instructionsScreen13 = {'Great! Now Category C.'};
        
        DrawFormattedText(theScreen, instructionsScreen13{1}, 'center', resY-(9/10)*resY, black, 150)
        Screen('Flip',theScreen,[],1);
        pause(2)
        DrawFormattedText(theScreen, '(Press the bottom left trigger on the controller to guess Category C.)', 'center', (19/20)*resY, black, 150)
        Screen('Flip',theScreen);
        getGamePadAll(7);
        
        %%
        
        instructionsScreen14 = {'Radical! Let''s see how you do with Category D.'};
        
        DrawFormattedText(theScreen, instructionsScreen14{1}, 'center', resY-(9/10)*resY, black, 150)
        Screen('Flip',theScreen,[],1);
        pause(2)
        DrawFormattedText(theScreen, '(Press the bottom right trigger on the controller on the controller to guess Category D.)', 'center', (19/20)*resY, black, 150)
        Screen('Flip',theScreen);
        getGamePadAll(8);
        
        
    elseif conditionCode == 2 || conditionCode == 4
        
        
        instructionsScreen11 = {'Now we''re going to show you which categories go with which buttons.\n\n It''s easy! So category A1 is simply the top left trigger button\n\nfollowed by the number "1" on the controller.\n\nTry it now!!'};
        
        DrawFormattedText(theScreen, instructionsScreen11{1}, 'center', resY-(9/10)*resY, black, 150)
        Screen('Flip',theScreen,[],1);
        pause(2)
        DrawFormattedText(theScreen, '(Press the top left trigger and "1" on the controller to guess Category A1.)', 'center', (19/20)*resY, black, 150)
        Screen('Flip',theScreen);
        getGamePadAll(9);
        
        %%
        
        instructionsScreen12 = {'Good job!\n\n Now let''s try Category A2.'};
        
        DrawFormattedText(theScreen, instructionsScreen12{1}, 'center', resY-(9/10)*resY, black, 150)
        Screen('Flip',theScreen,[],1);
        pause(2)
        DrawFormattedText(theScreen, '(Press the top left trigger and "2" on the controller to guess Category A2.)', 'center', (19/20)*resY, black, 150)
        Screen('Flip',theScreen);
        getGamePadAll(10);
        
        %%
        
        instructionsScreen13 = {'Great! Now Category B1.'};
        
        DrawFormattedText(theScreen, instructionsScreen13{1}, 'center', resY-(9/10)*resY, black, 150)
        Screen('Flip',theScreen,[],1);
        pause(2)
        DrawFormattedText(theScreen, '(Press the top right trigger and "1" on the controller to guess Category B1.)', 'center', (19/20)*resY, black, 150)
        Screen('Flip',theScreen);
        getGamePadAll(11);
        
        %%
        
        instructionsScreen14 = {'Radical! Let''s see how you do with Category B2.'};
        
        DrawFormattedText(theScreen, instructionsScreen14{1}, 'center', resY-(9/10)*resY, black, 150)
        Screen('Flip',theScreen,[],1);
        pause(2)
        DrawFormattedText(theScreen, '(Press the top right trigger and "2" on the controller to guess Category B2.)', 'center', (19/20)*resY, black, 150)
        Screen('Flip',theScreen);
        getGamePadAll(12);
        
        %%
        instructionsScreen11 = {'Superb! You''re really getting this! C1 GO!'};
        
        DrawFormattedText(theScreen, instructionsScreen11{1}, 'center', resY-(9/10)*resY, black, 150)
        Screen('Flip',theScreen,[],1);
        pause(2)
        DrawFormattedText(theScreen, '(Press the bottom left trigger and "1" on the controller to guess Category C1.)', 'center', (19/20)*resY, black, 150)
        Screen('Flip',theScreen);
        getGamePadAll(13);
        
        %%
        
        instructionsScreen12 = {'Now let''s give it up for Category C2!!!!!!!!'};
        
        DrawFormattedText(theScreen, instructionsScreen12{1}, 'center', resY-(9/10)*resY, black, 150)
        Screen('Flip',theScreen,[],1);
        pause(2)
        DrawFormattedText(theScreen, '(Press the bottom left trigger and "2" on the controller to guess Category C2.)', 'center', (19/20)*resY, black, 150)
        Screen('Flip',theScreen);
        getGamePadAll(14);
        
        %%
        instructionsScreen12 = {'Show us how you D1!'};
        
        DrawFormattedText(theScreen, instructionsScreen12{1}, 'center', resY-(9/10)*resY, black, 150)
        Screen('Flip',theScreen,[],1);
        pause(2)
        DrawFormattedText(theScreen, '(Press the bottom right trigger and "1" on the controller to guess Category D1.)', 'center', (19/20)*resY, black, 150)
        Screen('Flip',theScreen);
        getGamePadAll(15);
        
        %%
        instructionsScreen13 = {'And finally, hit us with some D2'};
        
        DrawFormattedText(theScreen, instructionsScreen13{1}, 'center', resY-(9/10)*resY, black, 150)
        Screen('Flip',theScreen,[],1);
        pause(2)
        DrawFormattedText(theScreen, '(Press the bottom right trigger and "2" on the controller to guess Category D2.)', 'center', (19/20)*resY, black, 150)
        Screen('Flip',theScreen);
        getGamePadAll(16);
        
        %%
        
        
        
        
        
        
    end
    
    instructionsScreen15 = {'Okay, let''s run you through a practice trial to \n\nmake sure you''re gonna get out of this alive.\n\n\n\nRemember, press the number you see, then guess\n\n your category and look at the feedback.'};
    
    DrawFormattedText(theScreen, instructionsScreen15{1}, 'center', resY-(9/10)*resY, black, 150)
    Screen('Flip',theScreen,[],1);
    pause(2)
    DrawFormattedText(theScreen, '(Press any button on the controller to start your practice trial.)', 'center', (19/20)*resY, black, 150)
    Screen('Flip',theScreen);
    getGamePadAll;
    
    
    %%
    
    
    
    
    %Screen('FillOval', theScreen, boxStartColour, [startArea(1) startArea(2) startArea(3) startArea(4)]); % start box is actually start circle
    DrawFormattedText(theScreen, '2', 'center', 'center', blue, 200)
    Screen('Flip', theScreen,[],1);
    getGamePadAll(2);
    %%
    Screen('Flip', theScreen);
    Screen('FillRect', theScreen, 255*(shuffledColours(1,:)), Location1Coords)
    Screen('FillRect', theScreen, 255*(shuffledColours(3,:)), Location2Coords)
    Screen('FillRect', theScreen, 255*(shuffledColours(5,:)), Location3Coords)
    Screen('Flip',theScreen,[],1);
    buttonPressed = 0;
    buttonPressed1 = 0;
    while ~buttonPressed
        %[joystick a] = JoyMEX(0);
        [joystick a] = getGamePadAll;
        if conditionCode == 1  || conditionCode == 3
            
            if sum(a(5:8))==1
                buttonPressed =1;
            end
            if buttonPressed
                [dontCare Response] = max(a(5:8));
            end
            
        else
            
            if sum(a(5:8))==1
                buttonPressed1 =1;
                [dontCare Response1] = max(a(5:8));
            end
            
            if buttonPressed1 && sum(a(1:2))==1
                [dontCare Response2] = max(a(1:2));
                
                switch Response1
                    case 1
                        switch Response2
                            case 1
                                Response = 1;
                            case 2
                                Response = 2;
                        end
                    case 2
                        switch Response2
                            case 1
                                Response = 3;
                            case 2
                                Response = 4;
                        end
                    case 3
                        switch Response2
                            case 1
                                Response = 5;
                            case 2
                                Response = 6;
                        end
                    case 4
                        switch Response2
                            case 1
                                Response = 7;
                            case 2
                                Response = 8;
                        end
                        
                end
                buttonPressed = 1;
                
            end
        end
    end
    
    %%
    
    feedbackScreenInstructions(theScreen,Response,'Y')
    Screen('Flip',theScreen,[],1);
    pause(2)
    DrawFormattedText(theScreen, '(Press any button on the controller to continue.)', 'center', (19/20)*resY, black, 150)
    Screen('Flip',theScreen);
    getGamePadAll;
    
    %%
    
    instructionsScreen16 = {'Don''t worry if you have no idea what button to push right now.\n\nAfter seeing many many codes and trying to open many doors, you''ll get the hang of it.'};
    subfunctionTextScreen(theScreen, instructionsScreen16,2);
    
    %%
    
    instructionsScreen17 = {'You will have as much time as you need in order to study the combinations.\n\nAlso you will occasionally be given feedback about your eye position.\n\nPlease try to keep your eyes centered.'};
    subfunctionTextScreen(theScreen, instructionsScreen17,2);
    
    
    
    %%
    
    if eyetracking
        TrackStatusScreen(theScreen,screenDim,eyetrackerType, InputDevice)
    end
    Screen('Flip',theScreen);
    %%
    
    instructionsScreen18 = {'One last note: As you improve your performance,\n\n the monster in the dungeon will change form.\n\nBy getting better at cracking the door code you end \n\nup changing the monster into a kinder, more gentle creature.\n\nBe careful though, because if you get worse,\n\n the monster will quickly change back to a scarier form.\n\nGood luck!'};
    subfunctionTextScreen(theScreen, instructionsScreen18,2);
    
    %%
    screen('Close',texImgDungeon)
    Screen('Close',texImgDoor)
    Screen('Close',triggerButtonsTex)
    
end % end the debugging


%TrackStatusScreen(theScreen,screenDim,eyetrackerType, InputDevice)


%% 2. Trials

Accuracy = [];

Screen('TextStyle', theScreen, 1);
% Cross hair cursor
%ShowCursor('CrossHair');

for trialNum = 1:trialNums
    disp(['Presenting trial ' num2str(trialNum) '...']);
    
    % ----------------------------- %
    % Phase 1 - click on the centre %
    % ----------------------------- %
    
    %ShowCursor('CrossHair');
    
    
    % Background colour & start area
    Screen('Flip', theScreen);
    %Screen('FillOval', theScreen, boxStartColour, [startArea(1) startArea(2) startArea(3) startArea(4)]); % start box is actually start circle
    fixNum = num2str(randi(4));
    Screen('TextSize', theScreen, 20);
    DrawFormattedText(theScreen, fixNum, 'center', 'center', blue, 25)
    Screen('Flip', theScreen);
    
    %Start tracking
    if eyetracking
        if eyetrackerType==1
            tetio_startTracking;
        elseif eyetrackerType==2
            success = eyetribe_start_recording(connection);
        end
        
        leftEyeAll = [];
        rightEyeAll = [];
        timeStampAll = [];
        timestamp=[];
    end
    
    CursorX = [];
    CursorY = [];
    
    % wait for them to enter start area and click
    inStart = 0;
    
    while ~inStart
        
        [x y buttons] = GetMouse;
        
        if eyetracking
            
            if eyetrackerType==1
                [lefteye, righteye, timestamp] = tetio_readGazeData;
            elseif eyetrackerType==2
                
                [success, x, y] = eyetribe_sample(connection);
                [success, pupil_size] = eyetribe_pupil_size(connection);
                disp(['x=' num2str(x) ', y=' num2str(y) ', s=' num2str(pupil_size)])
                
            end
            
            
            if ~isempty(lefteye) && ~isempty(righteye) && ~isempty(timestamp)
                if size(timestamp,1) ==1
                    tempTimeStamp = num2str(timestamp(1,:));
                    timeStampAll = [timeStampAll; str2num(tempTimeStamp(3:16))];
                    leftEyeAll = [leftEyeAll; lefteye(1,:)];
                    rightEyeAll = [rightEyeAll; righteye(1,:)];
                else
                    goodRows = find(lefteye(:,12)~=-1);
                    if isempty(goodRows)
                        tempTimeStamp = num2str(timestamp(1,:));
                        timeStampAll = [timeStampAll; str2num(tempTimeStamp(3:16))];
                        leftEyeAll = [leftEyeAll; lefteye(1,:)];
                        rightEyeAll = [rightEyeAll; righteye(1,:)];
                    else
                        tempTimeStamp = num2str(timestamp(goodRows(1),:));
                        timeStampAll = [timeStampAll; str2num(tempTimeStamp(3:16))];
                        leftEyeAll = [leftEyeAll; lefteye(goodRows(1),:)];
                        rightEyeAll = [rightEyeAll; righteye(goodRows(1),:)];
                    end
                end
                CursorX = [CursorX;x];
                CursorY = [CursorY;y];
            end
            
        end
        %[joystick a] = JoyMEX(0);
        [joystick a] = getGamePadAll;
        if a(str2num(fixNum)) && length(timestamp==1)
            inStart =1;
            strFixationOnset = num2str(timestamp(1,1))
            fixationOnset = str2num(strFixationOnset(3:16));
        end
        
    end
    
    
    
    phase1RT = timeStampAll(end,1) - timeStampAll(1,1);
    phase1Vec = ones(length(timeStampAll),1);
    
    % ----------------------------- %
    % Phase 2 - respond to stimulus %
    % ----------------------------- %
    
    Feature1Value = newstim(trialNum,1);
    Feature2Value = newstim(trialNum,2);
    Feature3Value = newstim(trialNum,3);
    CorrectResponse = newcategory(trialNum);
    
    Screen('FillRect', theScreen, 255*shuffledColours(1+Feature1Value,:), Location1Coords)
    Screen('FillRect', theScreen, 255*shuffledColours(3+Feature2Value,:), Location2Coords)
    Screen('FillRect', theScreen, 255*shuffledColours(5+Feature3Value,:), Location3Coords)
    
    Screen('Flip', theScreen, [], 1);
    
    buttonPressed = 0;
    buttonPressed1 = 0;
    strStimulusOnset = num2str(timestamp(1,1))
    stimulusOnset = str2num(strStimulusOnset(3:16));
    
    while ~buttonPressed
        
        [x y buttons] = GetMouse;
        
        if eyetracking
            
            if eyetrackerType==1
                [lefteye, righteye, timestamp, trigSignal] = tetio_readGazeData;
            elseif eyetrackerType==2
                [succes, x, y] = eyetribe_sample(connection);
                [succes, pupil_size] = eyetribe_pupil_size(connection);
            end
            
            if ~isempty(lefteye) && ~isempty(righteye) && ~isempty(timestamp)
                if size(timestamp,1) ==1
                    tempTimeStamp = num2str(timestamp(1,:));
                    timeStampAll = [timeStampAll; str2num(tempTimeStamp(3:16))];
                    leftEyeAll = [leftEyeAll; lefteye(1,:)];
                    rightEyeAll = [rightEyeAll; righteye(1,:)];
                else
                    goodRows = find(lefteye(:,12)~=-1);
                    if isempty(goodRows)
                        tempTimeStamp = num2str(timestamp(1,:));
                        timeStampAll = [timeStampAll; str2num(tempTimeStamp(3:16))];
                        leftEyeAll = [leftEyeAll; lefteye(1,:)];
                        rightEyeAll = [rightEyeAll; righteye(1,:)];
                    else
                        tempTimeStamp = num2str(timestamp(goodRows(1),:));
                        timeStampAll = [timeStampAll; str2num(tempTimeStamp(3:16))];
                        leftEyeAll = [leftEyeAll; lefteye(goodRows(1),:)];
                        rightEyeAll = [rightEyeAll; righteye(goodRows(1),:)];
                    end
                end
                
            end
        end
        
        CursorX = [CursorX;x];
        CursorY = [CursorY;y];
        
        
        
        
        
        %[joystick a] = JoyMEX(0);
        [joystick a] = getGamePadAll;
        
        if conditionCode == 1  || conditionCode == 3
            
            if sum(a(5:8))==1 && length(timestamp==1)
                buttonPressed =1;
            end
            if buttonPressed
                [dontCare Response] = max(a(5:8));
            end
            
        else
            
            if sum(a(5:8))==1 && length(timestamp==1)
                buttonPressed1 =1;
                [dontCare Response1] = max(a(5:8));
            end
            
            if buttonPressed1 && sum(a(1:2))==1 && ~isempty(timestamp)
                [dontCare Response2] = max(a(1:2));
                
                switch Response1
                    case 1
                        switch Response2
                            case 1
                                Response = 1;
                            case 2
                                Response = 2;
                        end
                    case 2
                        switch Response2
                            case 1
                                Response = 3;
                            case 2
                                Response = 4;
                        end
                    case 3
                        switch Response2
                            case 1
                                Response = 5;
                            case 2
                                Response = 6;
                        end
                    case 4
                        switch Response2
                            case 1
                                Response = 7;
                            case 2
                                Response = 8;
                        end
                        
                end
                buttonPressed = 1;
                
            end
            
            
        end% end phase 2 loop
    end
    
    phase2RT = timeStampAll(end,1) - timeStampAll(length(phase1Vec)+1,1);
    phase2Vec = 2*ones(length(timeStampAll) - length(phase1Vec),1);
    
    
    % ----------------------------- %
    % Phase 4 - respond to feedback %
    % ----------------------------- %
    
    if Response == CorrectResponse
        TrialAccuracy = 1;
        Accuracy = [Accuracy;TrialAccuracy];
    else
        TrialAccuracy = 0;
        Accuracy = [Accuracy;TrialAccuracy];
    end
    
    feedbackScreen(theScreen,Response==CorrectResponse,Response,CorrectResponse)
    Screen('Flip',theScreen,[],1);
    
    
    pause(0.3)
    
    buttonPressed = 0;
    strFeedbackOnset = num2str(timestamp(1,1))
    feedbackOnset = str2num(strFeedbackOnset(3:16));
    
    [x y buttons] = GetMouse;
    while ~buttonPressed
        if eyetracking
            
            if eyetrackerType==1
                [lefteye, righteye, timestamp, trigSignal] = tetio_readGazeData;
            elseif eyetrackerType==2
                [succes, x, y] = eyetribe_sample(connection);
                [succes, pupil_size] = eyetribe_pupil_size(connection);
            end

            if ~isempty(lefteye) && ~isempty(righteye) && ~isempty(timestamp)
                if size(timestamp,1) ==1
                    tempTimeStamp = num2str(timestamp(1,:));
                    timeStampAll = [timeStampAll; str2num(tempTimeStamp(3:16))];
                    leftEyeAll = [leftEyeAll; lefteye(1,:)];
                    rightEyeAll = [rightEyeAll; righteye(1,:)];
                else
                    goodRows = find(lefteye(:,12)~=-1);
                    if isempty(goodRows)
                        tempTimeStamp = num2str(timestamp(1,:));
                        timeStampAll = [timeStampAll; str2num(tempTimeStamp(3:16))];
                        leftEyeAll = [leftEyeAll; lefteye(1,:)];
                        rightEyeAll = [rightEyeAll; righteye(1,:)];
                    else
                        tempTimeStamp = num2str(timestamp(goodRows(1),:));
                        timeStampAll = [timeStampAll; str2num(tempTimeStamp(3:16))];
                        leftEyeAll = [leftEyeAll; lefteye(goodRows(1),:)];
                        rightEyeAll = [rightEyeAll; righteye(goodRows(1),:)];
                    end
                end
            end
        end % end phase 4 loop
        
        CursorX = [CursorX;x];
        CursorY = [CursorY;y];
        
        %[joystick a] = JoyMEX(0);
        [joystick a] = getGamePadAll;
        if sum(a)==1 && length(timestamp==1)
            buttonPressed =1;
        end
    end
    
    
    phase4RT = timeStampAll(end,1) - timeStampAll(length(phase1Vec)+length(phase2Vec)+1,1);
    phase4Vec = 4*ones(length(timeStampAll) - (length(phase1Vec)+length(phase2Vec)),1);
    
    tetio_stopTracking;
    
    % BLOCK BREAK?
    if mod(trialNum, numTrialsPerBlock) == 0
        
        Screen('Close')
        
        %if trialNum==3
        if trialNum ~= numTrialsPerBlock*numBlocks
            %blockAcc = 0.25;
            blockAcc = sum(Accuracy(length(Accuracy)-numTrialsPerBlock+1:length(Accuracy)))/numTrialsPerBlock;
            Screen('Flip',theScreen)
            blockText = {'Let''s have a look at the monster then.'};
            subfunctionTextScreen(theScreen,blockText,2);
            Screen('Flip',theScreen)
            blockAccText = [num2str(round(blockAcc*100)) '%'];
            
            if blockAcc<0.3
                blockText1 = ['Your accuracy is about ' blockAccText '\n\nYou''re not doing so well so your monster looks pretty rough...'];
                monsterImg = imread('images/monster1','jpg');
                monsterTex = Screen('MakeTexture', theScreen, monsterImg);
                Screen('DrawTexture', theScreen, monsterTex);
                DrawFormattedText(theScreen, blockText1, 'center', resY-(29/30)*resY, grey, 150)
                Screen('Flip',theScreen,[],1);
                pause(5)
                DrawFormattedText(theScreen, '(Press any button on the controller to continue.)', 'center', (19/20)*resY, [1, 0.4, .6], 150)
                Screen('Flip',theScreen);
                getGamePadAll;
                Screen('Close',monsterTex)
                Screen('Flip',theScreen)
                
            elseif (blockAcc < 0.4) && (blockAcc >= 0.3)
                blockText1 = ['Your accuracy is about ' blockAccText '\n\nThat monster is still looking pretty scary, keep going you''ll get better soon.'];
                monsterImg = imread('images/monster2','jpg');
                monsterTex = Screen('MakeTexture', theScreen, monsterImg);
                Screen('DrawTexture', theScreen, monsterTex);
                DrawFormattedText(theScreen, blockText1, 'center', resY-(29/30)*resY, grey, 150)
                Screen('Flip',theScreen,[],1);
                pause(5)
                DrawFormattedText(theScreen, '(Press any button on the controller to continue.)', 'center', (19/20)*resY, grey, 150)
                Screen('Flip',theScreen);
                getGamePadAll;
                Screen('Close',monsterTex)
                Screen('Flip',theScreen)
                
            elseif (blockAcc < 0.5) && (blockAcc >= 0.4)
                blockText1 = ['Your accuracy is about ' blockAccText '\n\nYou''re doing alright so the monster is not looking quite as bad...'];
                monsterImg = imread('images/monster3','jpg');
                monsterTex = Screen('MakeTexture', theScreen, monsterImg);
                Screen('DrawTexture', theScreen, monsterTex);
                DrawFormattedText(theScreen, blockText1, 'center', resY-(29/30)*resY, grey, 150)
                Screen('Flip',theScreen,[],1);
                pause(5)
                DrawFormattedText(theScreen, '(Press any button on the controller to continue.)', 'center', (19/20)*resY, grey, 150)
                Screen('Flip',theScreen);
                getGamePadAll;
                Screen('Close',monsterTex)
                Screen('Flip',theScreen)
                
            elseif (blockAcc < 0.6) && (blockAcc >= 0.5)
                blockText1 = ['Your accuracy is about ' blockAccText '\n\nYou''re on the right track, this monster is scary but not nearly as big as he used to be...'];
                monsterImg = imread('images/monster4','jpg');
                monsterTex = Screen('MakeTexture', theScreen, monsterImg);
                Screen('DrawTexture', theScreen, monsterTex);
                DrawFormattedText(theScreen, blockText1, 'center', resY-(29/30)*resY, grey, 150)
                Screen('Flip',theScreen,[],1);
                pause(5)
                DrawFormattedText(theScreen, '(Press any button on the controller to continue.)', 'center', (19/20)*resY, grey, 150)
                Screen('Flip',theScreen);
                getGamePadAll;
                Screen('Close',monsterTex)
                Screen('Flip',theScreen)
                
            elseif (blockAcc < 0.7) && (blockAcc >= 0.6)
                blockText1 = ['Your accuracy is about ' blockAccText '\n\nAlmost there, you''re getting good with those codes.'];
                monsterImg = imread('images/monster5','jpg');
                monsterTex = Screen('MakeTexture', theScreen, monsterImg);
                Screen('DrawTexture', theScreen, monsterTex);
                DrawFormattedText(theScreen, blockText1, 'center', resY-(29/30)*resY, grey, 150)
                Screen('Flip',theScreen,[],1);
                pause(5)
                DrawFormattedText(theScreen, '(Press any button on the controller to continue.)', 'center', (19/20)*resY, grey, 150)
                Screen('Flip',theScreen);
                getGamePadAll;
                Screen('Close',monsterTex)
                Screen('Flip',theScreen)
                
            elseif (blockAcc < 0.8) && (blockAcc >= 0.7)
                blockText1 = ['Your accuracy is about ' blockAccText '\n\nThat monster is looking pretty tired!'];
                monsterImg = imread('images/monster6','jpg');
                monsterTex = Screen('MakeTexture', theScreen, monsterImg);
                Screen('DrawTexture', theScreen, monsterTex);
                DrawFormattedText(theScreen, blockText1, 'center', resY-(29/30)*resY, grey, 150)
                Screen('Flip',theScreen,[],1);
                pause(5)
                DrawFormattedText(theScreen, '(Press any button on the controller to continue.)', 'center', (19/20)*resY, grey, 150)
                Screen('Flip',theScreen);
                getGamePadAll;
                Screen('Close',monsterTex)
                Screen('Flip',theScreen)
                
            elseif (blockAcc < 0.9) && (blockAcc >= 0.8)
                blockText1 = ['Your accuracy is about ' blockAccText '\n\nYou''ve got this, just a little better and you''re there...'];
                monsterImg = imread('images/monster7','jpg');
                monsterTex = Screen('MakeTexture', theScreen, monsterImg);
                Screen('DrawTexture', theScreen, monsterTex);
                DrawFormattedText(theScreen, blockText1, 'center', resY-(29/30)*resY, grey, 150)
                Screen('Flip',theScreen,[],1);
                pause(5)
                DrawFormattedText(theScreen, '(Press any button on the controller to continue.)', 'center', (19/20)*resY, grey, 150)
                Screen('Flip',theScreen);
                getGamePadAll;
                Screen('Close',monsterTex)
                Screen('Flip',theScreen)
                
            elseif (blockAcc >= 0.9)
                blockText1 = ['Your accuracy is about ' blockAccText '\n\nThere you go, your skills with the code have tamed that monster, keep it up!'];
                monsterImg = imread('images/final','jpg');
                monsterTex = Screen('MakeTexture', theScreen, monsterImg);
                Screen('DrawTexture', theScreen, monsterTex);
                DrawFormattedText(theScreen, blockText1, 'center', resY-(29/30)*resY, grey, 150)
                Screen('Flip',theScreen,[],1);
                pause(5)
                DrawFormattedText(theScreen, '(Press any button on the controller to continue.)', 'center', (19/20)*resY, grey, 150)
                Screen('Flip',theScreen);
                getGamePadAll;
                Screen('Close',monsterTex)
                Screen('Flip',theScreen)
                
            end
            if eyetracking
                if stimuliNum == stimuliNum*numTrialsPerBlock
                    Screen('Close',theScreen)
                    [theScreen theScreenArea] = Screen('OpenWindow', 0, backgroundColour, screenDim); % % open a screen
                    Screen('TextFont', theScreen, 'Arial');
                    Screen('TextSize', theScreen, 24);
                    Screen('TextStyle', theScreen, 1);
                end
                TrackStatusScreen(theScreen,screenDim,eyetrackerType, InputDevice)
            end
            
        end
        
    end
    
    %fixationOnset should be the same as timeStampAll(1,1)
    %stimulusOnset should be the same as timeStampAll(length(phase1check),1)
    %I don't know what colourOnset does?
    TrialLvl = [subjectNumber trialNum Feature1Value Feature2Value Feature3Value CorrectResponse Response TrialAccuracy phase2RT/1000 phase4RT/1000 timeStampAll(1,1)/1000 fixationOnset/1000 stimulusOnset/1000 stimulusOnset/1000 fixationXY(1) fixationXY(2) feedbackOnset/1000 str2num(fixNum)];
    dlmwrite([subjectCondition expName '-' num2str(subjectNumber) '.txt'],TrialLvl,'delimiter', '\t', 'newline','pc', 'precision','%.0f', '-append')
    
    if eyetracking
        GazeLvl = [repmat(subjectNumber,length(timeStampAll),1) repmat(1,length(timeStampAll),1) [1:length(timeStampAll)]' double(timeStampAll)/1000 leftEyeAll(:,7)*resX leftEyeAll(:,8)*resY leftEyeAll(:,12) leftEyeAll(:,13) rightEyeAll(:,7)*resX rightEyeAll(:,8)*resY rightEyeAll(:,12) rightEyeAll(:,13) repmat(trialNum,length(timeStampAll),1) [phase1Vec;phase2Vec;phase4Vec] repmat(-1,length(timeStampAll),1)  repmat(-1,length(timeStampAll),1)  ((leftEyeAll(:,7)*resX)+(rightEyeAll(:,7)*resX))/2 ((leftEyeAll(:,8)*resY)+(rightEyeAll(:,8)*resY))/2];
        %GazeLvl = [repmat(subjectNumber,length(timeStampAll),1) repmat(1,length(timeStampAll),1) [1:length(timeStampAll)]' double(timeStampAll) leftEyeAll(:,7) leftEyeAll(:,8) leftEyeAll(:,12) leftEyeAll(:,13) rightEyeAll(:,7) rightEyeAll(:,8) rightEyeAll(:,12) rightEyeAll(:,13) repmat(trialNum,length(timeStampAll),1) [phase1Vec;phase2Vec;phase4Vec]];
        dlmwrite([subjectCondition expName '-' num2str(subjectNumber) '-1.gazedata'],GazeLvl,'delimiter', '\t', 'precision','%.3f', '-append')
    end
    
end


Screen('Flip',theScreen);
Screen('TextSize', theScreen, 24);


endText = {'That''s it! You''re all done.\n\nIf you finished with a rabbit, you got away.\n\n Otherwise...'};

subfunctionTextScreen(theScreen, endText,2);

if eyetracking
    
    if eyetrackerType==1
        tetio_disconnectTracker;
        tetio_cleanUp;
        tetio_stopTracking
    elseif eyetrackerType==2
        
        success = eyetribe_stop_recording(connection);
        % close connection
        success = eyetribe_close(connection);
        fclose(connection)
        
    end
    
    
end



pause(10);
Screen('CloseAll');
quit;




%% SUBFUNCTIONS For instructions section

%caution: if you put these in the main function they have access to all the
%variables, otherwise you'll have to pass them in.

    function subfunctionTextScreen(screenName,instructions,inputType)
        % Display text only, then wait to continue
        
        for l=1:length(instructions)
            [nx ny] = DrawFormattedText(screenName, instructions{l}, 'center',(1/3)*resY,black);
            Screen('Flip',screenName, [], 1);
            pause(0.1);
        end
        
        pause(3)
        
        if inputType == 1
            DrawFormattedText(screenName, '(Click the mouse to continue.)', 'center',(2/3)*resY,black);
            Screen('Flip',screenName, [], 1);
            GetClicks;
        elseif inputType == 2
            DrawFormattedText(screenName, '(Press any button on the controller to continue.)', 'center',(19/20)*resY,black);
            Screen('Flip',screenName, [], 1);
            getGamePadAll;
        end
        
        Screen('Flip',screenName);
        
    end % end subfunctionTextScreen

    function feedbackScreen(screenName,TrialAccuracy,Response,correctResponse)
        
        if TrialAccuracy
            Screen('FrameRect', screenName, green,[0 0 200 200],3);
            if conditionCode == 1  || conditionCode == 3
                Screen(theScreen,'TextSize',90)
                DrawFormattedText(screenName, categoryAlignment(Response), 50, 10, green, 200)
            else
                Screen(theScreen,'TextSize',70)
                DrawFormattedText(screenName, categoryAlignment{Response}, 55, 20, green, 200)
            end
            
            Screen(theScreen,'TextSize',30)
            yourAnswer = '  Your\nAnswer';
            %width=Screen(screenName,'TextBounds',yourAnswer);
            DrawFormattedText(screenName, yourAnswer, 35, 120, green, 100)
            Screen('FrameRect', screenName, green, [resX-200 0 resX 200],3);
            if conditionCode == 1  || conditionCode == 3
                Screen(theScreen,'TextSize',90)
                DrawFormattedText(screenName, categoryAlignment(correctResponse), resX-150, 10, green, 200)
            else
                Screen(theScreen,'TextSize',70)
                DrawFormattedText(screenName, categoryAlignment{correctResponse}, resX-150, 20, green, 200)
            end
            
            Screen(theScreen,'TextSize',30)
            correctAnswer = 'Correct\nAnswer';
            width=Screen(screenName,'TextBounds',correctAnswer);
            DrawFormattedText(screenName, correctAnswer, (resX-170), 120, green, 100)
        else
            Screen('FrameRect', screenName, red,[0 0 200 200],3);
            if conditionCode == 1  || conditionCode == 3
                Screen(theScreen,'TextSize',90)
                DrawFormattedText(screenName, categoryAlignment(Response), 50, 10, red, 200)
            else
                Screen(theScreen,'TextSize',70)
                DrawFormattedText(screenName, categoryAlignment{Response}, 55, 20, red, 200)
            end
            
            Screen(theScreen,'TextSize',30)
            yourAnswer = '  Your\nAnswer';
            %width=Screen(screenName,'TextBounds',yourAnswer);
            DrawFormattedText(screenName, yourAnswer, 35, 120, red, 100)
            Screen('FrameRect', screenName, green, [resX-200 0 resX 200],3);
            if conditionCode == 1 || conditionCode == 3
                Screen(theScreen,'TextSize',90)
                DrawFormattedText(screenName, categoryAlignment(correctResponse), resX-150, 10, green, 200)
            else
                Screen(theScreen,'TextSize',70)
                DrawFormattedText(screenName, categoryAlignment{correctResponse}, resX-150, 20, green, 200)
            end
            
            Screen(theScreen,'TextSize',30)
            correctAnswer = 'Correct\nAnswer';
            %width=Screen(screenName,'TextBounds',correctAnswer);
            DrawFormattedText(screenName, correctAnswer, (resX-170), 120, green, 100)
        end
        
    end

    function feedbackScreenInstructions(screenName,Response,correctResponse)
        
        
        Screen('FrameRect', screenName, red,[0 0 200 200],3);
        
        if conditionCode == 1  || conditionCode == 3
            Screen(theScreen,'TextSize',90)
            DrawFormattedText(screenName, categoryAlignment(Response), 50, 10, red, 200)
        else
            Screen(theScreen,'TextSize',70)
            DrawFormattedText(screenName, categoryAlignment{Response}, 55, 20, red, 200)
        end
        
        Screen(theScreen,'TextSize',30)
        yourAnswer = '  Your\nAnswer';
        
        DrawFormattedText(screenName, yourAnswer, 35, 120, red, 100)
        
        Screen('FrameRect', screenName, green, [resX-200 0 resX 200],3);
        
        Screen(theScreen,'TextSize',90)
        DrawFormattedText(screenName, correctResponse, resX-150, 10, green, 200)
        Screen(theScreen,'TextSize',30)
        correctAnswer = 'Correct\nAnswer';
        width=Screen(screenName,'TextBounds',correctAnswer);
        DrawFormattedText(screenName, correctAnswer, (resX-170), 120, green, 100)
        
        
        
        
    end %end feedback display


end