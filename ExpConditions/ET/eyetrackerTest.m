%% here's a real example you fucking idiottttt: http://developer.tobiipro.com/matlab/matlab-sdk-reference-guide.html\
% examples -> CalibrationSample


PsychDefaultSetup(2);

Tobii = EyeTrackingOperations();

%eyetracker_address = 'tet-tcp://172.28.195.1';

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


calib = ScreenBasedCalibration(eyetracker);

calib.enter_calibration_mode()

% check what these points should actually be
calibrationPoints = [[0.1,0.1];[0.1,0.9];[0.5,0.5];[0.9,0.1];[0.9,0.9]];

for i = 1:size(calibrationPoints,1)
   result = calib.collect_data(calibrationPoints(i, :)); 
end

calibration_result = calib.compute_and_apply();

if calibration_result.Status.Success
        points = calibration_result.CalibrationPoints;

        number_points = size(points,2);

        for i=1:number_points
            plot(points(i).PositionOnDisplayArea(1),points(i).PositionOnDisplayArea(2),'ok','LineWidth',10);
            mapping_size = size(points(i).RightEye,2);
            set(gca, 'YDir', 'reverse');
            axis([-0.2 1.2 -0.2 1.2])
            hold on;
            for j=1:mapping_size
                if points(i).LeftEye(j).Validity == CalibrationEyeValidity.ValidAndUsed
                    plot(points(i).LeftEye(j).PositionOnDisplayArea(1), points(i).LeftEye(j).PositionOnDisplayArea(2),'-xr','LineWidth',3);
                end
                if points(i).RightEye(j).Validity == CalibrationEyeValidity.ValidAndUsed
                    plot(points(i).RightEye(j).PositionOnDisplayArea(1),points(i).RightEye(j).PositionOnDisplayArea(2),'xb','LineWidth',3);
                end
            end

        end
        
else
    disp('u fucked up');
end


calib.leave_calibration_mode();