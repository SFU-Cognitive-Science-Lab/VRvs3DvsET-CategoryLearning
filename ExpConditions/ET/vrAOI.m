%% finding AOI dimensions for vrtest e/t version

f1 = verts(makeRec(0, 1920, 1080));
f2 = verts(makeRec(120, 1920, 1080));
f3 = verts(makeRec(240, 1920, 1080));

% I get edges from makeRec, need vertices.


function v = verts(bounds)
    left = bounds(1);
    top = bounds(2);
    right = bounds(3);
    bottom = bounds(4);
    
    lt = [left, top];
    rt = [right, top];
    rb = [right, bottom];
    lb = [left, bottom];
    
    v = [lt; rt; rb; lb];

end

function rectangle = makeRec(location, resX, resY)

    imgSize = [100 100];
    center = [resX/2, resY/2 + 50];
    distance = resY*0.42;
    shiftAngle = 50;
    
    [x, y] = getCoords(shiftAngle, distance, location);
        
    leftBound = center(1) + x - imgSize(1)/2;
    topBound = center(2) + y - imgSize(2)/2;
    rightBound = leftBound + imgSize(1);
    bottomBound = topBound + imgSize(2);
                
    rectangle = [leftBound topBound rightBound bottomBound];
    
end

function [x, y] = getCoords(angle, dist, loc)   % this will return the location of the centre of the feature

    if loc == 0   
        x = dist*sind(120 + angle); % I know it looks weird that this has the 120 in it, but I swear this works
        y = dist*cosd(120 + angle);
        
    elseif loc == 120
        x = dist*sind(angle);
        y = dist*cosd(angle);
        
    else       
        x = dist*sind(240 + angle);
        y = dist*cosd(240 + angle);
    end
        
end