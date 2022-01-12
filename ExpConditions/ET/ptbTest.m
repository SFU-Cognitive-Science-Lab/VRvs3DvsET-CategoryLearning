%% literally just trying to write to the screen lol

%% SOLVED KAT IS AN IDIOT LOL

% black = [0 0 0];
% white = [1 1 1];
% 
% 
% [window, windowRect] = Screen('OpenWindow', 0, black); % % open a screen
% 
% 
% DrawFormattedText(window, 'When correctly positioned press any key to start the calibration.', 'center', 'center', white);
%  
% Screen('Flip', window);
% 
% Screen('CloseAll');



screenDim = get(0,'screensize'); % note: 0,0 is the top left corner of the screen
resX = screenDim(3); resY = screenDim(4); % max screen size (should be resolution of your computer)
bgArea = screenDim;


white = [255 255 255];
black = [0 0 0];
red = [255 0 0];
green = [0 255 0];
blue = [0 0 255];
grey = [100 100 100]+50;
boxStartColour = blue;
backgroundColour = black;

[theScreen, WindowRect] = Screen('OpenWindow', 0, backgroundColour); % % open a screen

instructionsScreen = 'You will be presented with a series of images.\n\n Relax and observe--you will be asked simple questions about them throughout. \n\n Please remain as still as possible throughout the experiment.\n\n Prior to each image you will see a screen with a cross in the centre.\n\n Please, look at this cross until it disappears. \n\n Enjoy!';
DrawFormattedText(theScreen, instructionsScreen, 'center','center', white);
DrawFormattedText(theScreen, '(Press any button on the controller to continue.)', 'center',resY*0.8,white);
Screen('Flip', theScreen); 
