%% eye tracker calibration for psychtoolbox experiments

%% issues picking up gaze data (getting lots of NaNs)

%% first setup

sca;
addpath(genpath('C:\Users\cogni\TobiiProSDK'));

% get eyetracker
Tobii = EyeTrackingOperations();
eyetracker = Tobii.find_all_eyetrackers();

% set up screen (psyctoolbox--inspired by/copied from artview bc that is the exp kat is familiar with)

white = [255 255 255];
black = [0 0 0];
red = [255 0 0];
green = [0 255 0];
blue = [0 0 255];
grey = [100 100 100]+50;


[window, windowRect] = Screen('OpenWindow', 0, black); % % open a screen

% , [0 0 640 480]

[screenXpixels, screenYpixels] = Screen('WindowSize', window);
screen_pixels = [screenXpixels screenYpixels];

[xCenter, yCenter] = RectCenter(windowRect);
 
%% track status
% Dot size in pixels
dotSizePix = 30;

x = eyetracker.get_gaze_data();

Screen('TextSize', window, 20);

Screen('BlendFunction', window, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA'); % not really sure what this is but oh well

%% this is after setup and all that jazz

spaceKey = KbName('Space');     % probs can change this to use gamepad...but that's a problem for later

RKey = KbName('R');

dotSizePix = 30;

dotColor = [red;white]; % Red and white

leftColor = red; % Red
rightColor = blue; % Bluesss

% Calibration points
lb = 0.1;  % left bound
xc = 0.5;  % horizontal center
rb = 0.9;  % right bound
ub = 0.1;  % upper bound
yc = 0.5;  % vertical center
bb = 0.9;  % bottom bound

points_to_calibrate = [[lb,ub];[rb,ub];[xc,yc];[lb,bb];[rb,bb]];

calibInstructions = ('Please keep your head still and try to follow the dots around the screen with your eyes.\nPress space when you are ready to begin.');
DrawFormattedText(window, calibInstructions);
Screen('Flip', window);

[keyIsDown, seconds, keyCode ] = KbCheck;
keyCode = find(keyCode, 1);

while 1     % super ugly, I know...
   if keyCode == spaceKey
       break;
   end
end

HideCursor();


% Create calibration object
calib = ScreenBasedCalibration(eyetracker);

calibrating = 1;

while calibrating
    % Enter calibration mode
    calib.enter_calibration_mode();
    
    flagged = [];

    for i=1:length(points_to_calibrate)

        Screen('DrawDots', window, points_to_calibrate(i,:).*screen_pixels, dotSizePix, dotColor(1,:), [], 2);
        Screen('DrawDots', window, points_to_calibrate(i,:).*screen_pixels, dotSizePix*0.5, dotColor(2,:), [], 2);

        Screen('Flip', window);

        % Wait a moment to allow the user to focus on the point
        pause(1.5);

        test = calib.collect_data(points_to_calibrate(i,:));

    end

    DrawFormattedText(window, 'Calculating calibration result....', 'center', 'center', white);

    Screen('Flip', window);

    % Blocking call that returns the calibration result
    calibration_result = calib.compute_and_apply(); 
    

    calib.leave_calibration_mode();
  

    points = calibration_result.CalibrationPoints;
    
    if length(points) == 0
        continue;
    end    

    for i=1:length(points)
        Screen('DrawDots', window, points(i).PositionOnDisplayArea.*screen_pixels, dotSizePix*0.5, dotColor(2,:), [], 2);
        for j=1:length(points(i).RightEye)
            if points(i).LeftEye(j).Validity == CalibrationEyeValidity.ValidAndUsed
                Screen('DrawDots', window, points(i).LeftEye(j).PositionOnDisplayArea.*screen_pixels, dotSizePix*0.3, leftColor, [], 2);
                Screen('DrawLines', window, ([points(i).LeftEye(j).PositionOnDisplayArea; points(i).PositionOnDisplayArea].*screen_pixels)', 2, leftColor, [0 0], 2);
            end
            if points(i).RightEye(j).Validity == CalibrationEyeValidity.ValidAndUsed
                Screen('DrawDots', window, points(i).RightEye(j).PositionOnDisplayArea.*screen_pixels, dotSizePix*0.3, rightColor, [], 2);
                Screen('DrawLines', window, ([points(i).RightEye(j).PositionOnDisplayArea; points(i).PositionOnDisplayArea].*screen_pixels)', 2, rightColor, [0 0], 2);
            end
        end

    end

    DrawFormattedText(window, 'Press the ''R'' key to recalibrate or ''Space'' to continue....', 'center', screenYpixels * 0.95, white)

    Screen('Flip', window);

    while 1.
        [ keyIsDown, seconds, keyCode ] = KbCheck;
        keyCode = find(keyCode, 1);

        if keyIsDown
            if keyCode == spaceKey
                calibrating = false;
                break;
            elseif keyCode == RKey
                break;
            end
            KbReleaseWait;
        end
    end
end