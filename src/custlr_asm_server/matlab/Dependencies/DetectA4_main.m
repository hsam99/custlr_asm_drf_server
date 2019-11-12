function [found, bestA4, bestScore, average_ratio] = DetectA4_main(filepath, debugg)
% Function DetectA4_main finds the A4 rectangle in an image by assuming
% relatively strong edge responses based on Hough Transform.
% Input: 
%   filepath: file name including path
%   debug: BOOL debug whether to show figures or not
% Output:
%   found: boolean, rectangle found
%   bestA4: the rectangle (4 points) representing A4
%   bestScore: the probability of best rectangle found being A4
%   average_ratio: image to life size ratio in terms of pixels/cm

%% Set global parameters

%%%%% time start%%%%
tic

thresholdOfBeingA4 = 0.8; % cut off threshold for searching, i.e., pruning parameter.
                            % Default value: 0.99
weightA4Prior = 0.3; % A4 shape prior weightage. Default value: 0.3
neighborhood = 0; % thickness of A4 edges to consider for likelihood estimation,
                    % 0: single line
                    % 1: 4-neighborhood
                    % 2: 8-neighborhood
                    % Default value: 0 (seems to be the best option)
thresholdHarrisMedian = 0.5; % Threshold the Harris scores on all the intersection points
                             % Default value: 1
nHoughPeaks = 40; % Threshold the number of peaks to be picked up in the Hough Transform space
                          % Default value: 40


%% Preprocessing and Hough Transform

% Load original file and convert to grey scale image
originalImage = imread(filepath);
greyImage = rgb2gray(originalImage);

%There is a bug exist in MATLAB R2017b that some images that are loaded in
%will be rotated, the following code is to solve this
[h,w] = size(greyImage);
if (h<w)
    greyImage = imrotate(greyImage, -90);
end

%Resize image to 2800 x 2100 pixels
greyImage = imresize(greyImage , [2800 2100]);

%2 different Gaussian filters for DoG
gaussian1 = fspecial('Gaussian', 21, 20); %21, 20
gaussian2 = fspecial('Gaussian', 21, 35); %21, 35
dog = gaussian1 - gaussian2;
dogFilterImage = conv2(double(greyImage), dog, 'same');

%Change to binary image
binaryImage = imbinarize(dogFilterImage);
% Shrink the lines slightly
binaryImage = imerode(binaryImage,ones(3));

% figure, imshow(binaryImage,[]); hold on%%%%%%xxx

%Find all the small line segments in the image
[H,T,R] = hough(binaryImage,'RhoResolution',4, 'Theta',-90:.5:89);

%Find n most probable lines in the Hough space
P  = houghpeaks(H,nHoughPeaks,'threshold',ceil(0.10*max(H(:)))); 

%Connect all the short line segments together
lines = houghlines(binaryImage,T,R,P,'FillGap',70,'MinLength',20);
%%%%%%%%%%%%%%%%
% % plot lines for debugging
% for i=1:length(lines)
%     plot([lines(i).point1(1), lines(i).point2(1)], [lines(i).point1(2), lines(i).point2(2)], 'b-', 'LineWidth', 2); hold on
% end
% %%%%%%%%%%%%%%%%


%Get peaks in rho and theta array
peak_rho = R(P(:,1));
peak_theta = T(P(:,2));

angle_h = 75;
angle_l = 15;
% %Remove lines with angle between 15 to 75
peak_rho = peak_rho( ~(peak_theta>= -angle_h & peak_theta<=-angle_l) & ...
    ~(peak_theta>= angle_l & peak_theta<= angle_h));

peak_theta = peak_theta( ~(peak_theta>= -angle_h & peak_theta<=-angle_l) & ...
    ~(peak_theta>= angle_l & peak_theta<= angle_h));

% time for Hough Transform related computation
timeElaspedForHoughTransformRelated = toc

%% Finding Intersection Points

[image_height, image_width] = size(greyImage);
   
x_value = [];
y_value = [];
ini_x = [];
ini_y = [];
coordinates = [];
loop = 1;
intersection = struct;

%Solve line equations to get intersection points
for i = 1:length(peak_rho)
    for j = i:length(peak_rho)
        %if both the same no need compare
        if(isequal(i,j))
            continue
        end
        
        %Both lines with same theta value will not intersect
        if (isequal(peak_theta(1,i) , peak_theta(1,j)))
            continue;
        end
        
        % solve the two equations as in the above commented code
        A = [cosd(peak_theta(1,i)), sind(peak_theta(1,i)); cosd(peak_theta(1,j)), sind(peak_theta(1,j))];
        b = [peak_rho(1,i); peak_rho(1,j)];
        solution = A\b;
        xSol = solution(1);
        ySol = solution(2);
        
        %Filter out x coordinates that are shorter than 15% of the width
        %and longer than 85% of the width
        if(double(xSol) > image_width*0.85 | double(xSol) < round(image_width*0.15))
            continue
        end

        %Filter out y coordinates that are shorter than 5% of the height
        %and longer than 80% of the height
        if(double(ySol) > image_height*0.80 | double(ySol) < image_height*0.05)
            continue
        end

        intersection(loop).rho1 = peak_rho(1,i);
        intersection(loop).rho2 = peak_rho(1,j);
        intersection(loop).theta1 = peak_theta(1,i);
        intersection(loop).theta2 = peak_theta(1,j);
        intersection(loop).x = double(round(xSol));
        intersection(loop).y = double(round(ySol));

        x_value = [x_value double(round(xSol))];
        y_value = [y_value double(round(ySol))];

        loop=loop+1;
    end
end
% All intersection points store here
xy_original = [];
xy_original = [x_value' y_value'];

%Remove duplicate index
[~,Index]=unique(xy_original,'rows');
duplicateIndex=setdiff(1:size(xy_original,1),Index);
if(~isempty(duplicateIndex))
    xy_original(duplicateIndex,:)=[];
end

x_value = xy_original(:,1);
y_value = xy_original(:,2);

timeEslapsedAfterFindingIntersectionPoints = toc % time for intersection points

% %%%%%%%%%%%%%%%%
% % plot intersection points for debugging
% plot(xy_original(:,1), xy_original(:,2), 'gs');
% %%%%%%%%%%%%%%%%

%% Search A4

%Boolean value to test whether a rectangle has found
found = false;
bestScore = 0; % initialise the likelihood score of the best A4
bestA4 = zeros(4,2); % to record the coordinates of 4 corners of the best A4
% set counter and other recording parameters for searching                           
countFound = 0; %%% for debugging only
pFound = []; %%% for debugging only

for i = 1:length(xy_original)
        x1 = xy_original(i,1);
        y1 = xy_original(i,2);
        index1 = find([intersection.x] == x1 & [intersection.y] == y1);
        rho1 = intersection(index1).rho1;
        theta1 = intersection(index1).theta1;
        %%%%% record the other set of rho and theta from the first point
        rho12 = intersection(index1).rho2;
        theta12 = intersection(index1).theta2;

        %2nd point
        for j =1:length(xy_original)
          x2 = xy_original(j,1);
          y2 = xy_original(j,2);

          if(isequal(x1,x2) && isequal(y1,y2))
              continue;
          end

          eqn1 = x2 * cosd(theta1) + y2 * sind(theta1) - rho1;
          eqn1 = abs(eqn1);
          
          % check if the point(x2,y2) satisfies line (rho1, theta1), if not check if it
          % satisfies line (rho12, theta12)
          if (eqn1 >= 1.0)
              eqn1 = x2 * cosd(theta12) + y2 * sind(theta12) - rho12;
              eqn1 = abs(eqn1);
              % swap rho1 and rho12
              temp = rho1;
              rho1 = rho12;
              rho12 = temp;
              % swap theta1 and theta12
              temp = theta1;
              theta1 = theta12;
              theta12 = temp;
          end

          if (eqn1 < 1.0)
              %Point satisfy eqn, on the same line
              index2 = find([intersection.x] == x2 & [intersection.y] == y2);
              if (isequal(intersection(index2).rho1,rho1) && isequal(intersection(index2).theta1,theta1))
                  rho2 = intersection(index2).rho2;
                  theta2 = intersection(index2).theta2;
              else
                  rho2 = intersection(index2).rho1;
                  theta2 = intersection(index2).theta1;
              end

              %3rd point
              for k =1:length(xy_original)
                  x3 = xy_original(k,1);
                  y3 = xy_original(k,2);

                  if((isequal(x1,x3) && isequal(y1,y3)) || (isequal(x2,x3) && isequal(y2,y3)))
                      continue;
                  end

                  %Check ratio of both line and angle
                  v1 = [x1,y1] - [x2,y2];
                  v2 = [x2,y2] - [x3,y3];
                  norm1 = norm(v1);
                  norm2 = norm(v2);
                  angle = acosd(sum(v1.*v2)/(norm(v1)*norm(v2)));
                  area_ratio = (norm1*norm2/(image_width*image_height));

                  %If area of rectangle bigger than 25% of image and smaller than 6%, continue
                  if (area_ratio >0.25 | area_ratio<0.06)
                      continue;
                  end

                  if(norm1>norm2)
                      ratio = norm1/norm2;
                  else
                      ratio = norm2/norm1;
                  end

                  %If ratio not in A4 ratio, continue
                  if (ratio > 1.52 | ratio < 1.31 | angle > 105 | angle < 75)
                    continue;
                  end

                  eqn2 = x3 * cosd(theta2) + y3 * sind(theta2) - rho2;
                  eqn2 = abs(eqn2);
                  if (eqn2 < 1.0)
                    %Point satisfy eqn, on the same line

                    index3 = find([intersection.x] == x3 & [intersection.y] == y3);
                    if (isequal(intersection(index3).rho1,rho2) && isequal(intersection(index3).theta1,theta2))
                      rho3 = intersection(index3).rho2;
                      theta3 = intersection(index3).theta2;
                    else
                      rho3 = intersection(index3).rho1;
                      theta3 = intersection(index3).theta1;
                    end


                    %4rd point
                    for m =1:length(xy_original)

                        x4 = xy_original(m,1);
                        y4 = xy_original(m,2);

                        if((isequal(x1,x4) && isequal(y1,y4)) || (isequal(x2,x4) && isequal(y2,y4))... 
                                || (isequal(x3,x4) && isequal(y3,y4)))
                            continue;
                        end

                        eqn3 = x4 * cosd(theta3) + y4 * sind(theta3) - rho3;
                        eqn3 = abs(eqn3);

                        if(eqn3 < 1.0)
                            %Find another rho n theta value;
                            index4 = find([intersection.x] == x4 & [intersection.y] == y4);
                            if (isequal(intersection(index4).rho1,rho3) && isequal(intersection(index4).theta1,theta3))
                                rho4 = intersection(index4).rho2;
                                theta4 = intersection(index4).theta2;
                            else
                                rho4 = intersection(index4).rho1;
                                theta4 = intersection(index4).theta1;
                            end

                            %If first point satisfy this rho4 and theta4, they
                            %are on the same line, and thus a rectangle is
                            %found
                            if ((x1 * cosd(theta4) + y1 * sind(theta4) - rho4) < 1.0)
                                
                                %Check if the the angle opposite is almost similar
                                %to avoid other polygon
                                v3 = [x4,y4] - [x3,y3];
                                v4 = [x4,y4] - [x1,y1];
                                angle1 = acosd(sum(v3.*v4)/(norm(v3)*norm(v4)));

                                if(abs(angle1-angle) > 5.0)
                                    continue;
                                end

                                %Compute diagonal, if point 2 and 4 shorter than
                                %any of the edge then continue
                                vd = [x4,y4] - [x2,y2];

                                if((norm(vd) < norm(v1)) && (norm(vd) < norm(v2)))
                                    continue;
                                end

                                %Check if the rectangle is vertical or
                                %horizontal
                                xx = abs(x4 - x1);
                                yy = abs(y4 - y1);
                                if (yy > xx)
                                    zz = abs(x4 - x3);
                                    if (zz > yy)
                                        %horizontal edge bigger than vertical
                                        continue; 
                                    end
                                else
                                    zz = abs(y4 - y3);
                                    if (zz < xx)
                                        %horizontal edge bigger than vertical
                                        continue; 
                                    end
                                end
                                
                                countFound = countFound + 1;
                                %%%%%
                                % check the likelihood of the rectangle being
                                % A4
                                p = likelihoodA4([x1,y1;x2,y2;x3,y3;x4,y4],binaryImage,weightA4Prior,neighborhood);
                                pFound = [pFound p];
                                % record the best potential A4 based on its
                                % likelihood score
                                if p > bestScore
                                    bestA4 = [x1 y1; x2 y2; x3 y3; x4 y4];
                                    bestScore = p;
                                end
    %                             % record all the potential A4
    %                             candidateA4(countFound,:) = [x1 y1 x2 y2 x3 y3 x4 y4];

                                if p < thresholdOfBeingA4
                                    continue;
                                end
                                %%%%%%%%%%%%%%%

                                found = true;
                                break;
                            else 
                                continue;
                            end
                        end

                    end

                  end

                  if (found == true)
                      break;
                  end

               end
          end

          if (found == true)
              break;
          end

        end

        if (found == true)
            break;
        end
    end

%%%%%% time end%%%%%%%%%%%
timeElapsed = toc

rec_x = [bestA4(:,1); bestA4(1,1)];
rec_y = [bestA4(:,2); bestA4(1,2)];

%debugg
if debugg
    figure; imshow(greyImage);hold on
    plot(rec_x, rec_y,'r-', 'LineWidth', 2);hold on
end

if (bestScore >= 0.5)
    found = true; % failed if the best matching score of A4 is less than 50%
end

if(found == false)
    fprintf("Failed\n");
else
    fprintf("Rectangle is found\n");
end

if found % then calculate the ratio, otherwise skip
    v1 = bestA4(1,:) - bestA4(2,:);
    v2 = bestA4(2,:) - bestA4(3,:);
    v3 = bestA4(3,:) - bestA4(4,:);
    v4 = bestA4(4,:) - bestA4(1,:);
    a4_cm_height = 29.7;
    a4_cm_width = 21;

    if(norm(v1) >norm(v2))
        %C1,C2 and C3,C4 are long edges
        ratio1 = norm(v1) / a4_cm_height;
        ratio2 = norm(v3) / a4_cm_height;
        ratio3 = norm(v2) / a4_cm_width;
        ratio4 = norm(v4) / a4_cm_width;

    else
        %C1,C2 and C3,C4 are short edges
        ratio1 = norm(v2) / a4_cm_height;
        ratio2 = norm(v4) / a4_cm_height;
        ratio3 = norm(v1) / a4_cm_width;
        ratio4 = norm(v3) / a4_cm_width;
    end

    average_ratio = (ratio1+ratio2+ratio3+ratio4)/4;
    fprintf("The output ratio = %f\n",average_ratio);
end

if debugg
    countFound %%% for debugging only
    figure, histogram(pFound,'BinLimits',[0, 1]);
end

end % end of function

