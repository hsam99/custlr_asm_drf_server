function [key_measurements] = Custlr_ASM_Server_Front_v2(img_path)

% Function that accepts an image of a frontal person and performs ASM on it to identify the 5 key points
% 
% Doesn't write to an external TXT file, but returns a string
%
% INPUT
% img_path
% -STRING
% -Path to image in STRING
% -Image of the person in potrait orientation
% -person should be roughly centered with the A4 paper in the right hand
% -E.g 'D:\...\image.jpg''
% 
% OUTPUT
% key_measurements
% -STRING
% -measurements of the key body parts, scaled to real life size in CM

%debugg flag
debug = true;

%directory of where this m file is at
current_filename = mfilename();
current_dir = mfilename('fullpath');
current_dir = current_dir(1:end - (length(current_filename)));

%add paths to project dependencies
project_dir = current_dir; 
addpath(project_dir, fullfile(project_dir,'Dependencies'), fullfile(project_dir,'Models'));

%load pre-built shape and texture models
grayModel_99 = load('grayModel_99.mat');
shapeModel_99 = load('shapeModel_99.mat');

shapeModel_99 = shapeModel_99.shapemodel_99;
grayModel_99 = grayModel_99.graymodel_99;

%load image
img = imread(img_path);
img = imCorrectOrientation(img, img_path); %correct for orientation formatting problems
img = rgb2gray(img); %convert image to grayscale
img = imresize(img, [504 378]); %resize image to 504x378 to work with algorithm

%apply ASM algorithm to the image
%takes about 5 seconds.
landmarks_predicted = findShape(img, shapeModel_99, grayModel_99, debug);

%obtain 5 key landmarks pixel distance
[chest_pixels, shoulder_pixels, arm_size_pixels, waist_pixels, arm_length_pixels] = getPixelDistance(landmarks_predicted);
%debugg
disp(chest_pixels), disp(shoulder_pixels), disp(arm_size_pixels), disp(waist_pixels), disp(arm_length_pixels);

%get ratio of image to A4 paper4
% ratio is in pixels per cm
[A4_detected, ~, ~, A4_ratio] = DetectA4_main(img_path, debug);

%debugg
disp(A4_detected), disp(A4_ratio);

%apply ratio to pixels to obtain actual measurements
if(A4_detected == true)
    
    %A4 algo and ASM use different image scales so need get rescale factor
    rescale_factor = 2800 / 504;
    
    chest_measurement = chest_pixels * rescale_factor / A4_ratio;
    shoulder_measurement = shoulder_pixels * rescale_factor / A4_ratio;
    arm_size_measurement = arm_size_pixels * rescale_factor / A4_ratio;
    waist_measurement = waist_pixels * rescale_factor / A4_ratio;
    arm_length_measurement = arm_length_pixels * rescale_factor / A4_ratio;
    
    %print results to a txt file in directory of this function
    %reference https://vteams.com/blog/php-and-matlab-interfacing/
    
    key_measurements = sprintf('CM \nCHEST: %f\nSHOULDER: %f\nARM_SIZE: %f\nWAIST: %f\nARM_LENGTH: %f\n', chest_measurement, shoulder_measurement, arm_size_measurement, waist_measurement, arm_length_measurement);
    
else
    
    %No ratio, so just give back the pixels
    %print results to a txt file in directory of this function
    %reference https://vteams.com/blog/php-and-matlab-interfacing/
    
    key_measurements = sprintf('PIXEL(504x378) \nCHEST: %f\nSHOULDER: %f\nARM_SIZE: %f\nWAIST: %f\nARM_LENGTH: %f\n', chest_pixels, shoulder_pixels, arm_size_pixels, waist_pixels, arm_length_pixels);
end

%========= INTERNAL FUNCTIONS ============
    function [img_corrected] = imCorrectOrientation(img, img_path)
%        Corrects for the ORIENTATION EXIF TAG error
        
        %default is img_corrected to equal img
        img_corrected = img;

        info = imfinfo(img_path);
        
        if isfield(info, 'Orientation')
            orientation = info.Orientation;
            
            %debugg
            %fprintf('orientation here: %d\n', orientation);
            
            switch orientation
                case 1
                    %normal, leave the data alone
                case 2
                    img_corrected = img(:,end:-1:1,:);         %right to left
                case 3
                    img_corrected = img(end:-1:1,end:-1:1,:);  %180 degree rotation
                case 4
                    img_corrected = img(end:-1:1,:,:);         %bottom to top
                case 5
                    img_corrected = permute(img, [2 1 3]);     %counterclockwise and upside down
                case 6
                    img_corrected = rot90(img,3);            %undo 90 degree by rotating 270
                case 7
                    img_corrected = rot90(img(end:-1:1,:,:));  %undo counterclockwise and left/right
                case 8
                    img_corrected = rot90(img);                %undo 270 rotation by rotating 90
                otherwise
                    %debugg
                    %fprintf('unknown orientation %d \n', orientation);
            end
           
        else
            %debugg
            %fprintf('Error, no Orientation tag in image\n'); 
        end

    end
    
    function [chest_pixels, shoulder_pixels, arm_size_pixels, waist_pixels, arm_length_pixels] = getPixelDistance(landmarks)
       
%       Hard coded to find the number of pixels for each of the 5 key points in the frontl image
        
        chest_pixels = 0;
        shoulder_pixels = 0;
        arm_size_pixels = 0;
        waist_pixels = 0;
        arm_length_pixels = 0;

        %chest
        chest_pixels = chest_pixels + sqrt(((landmarks(1) - landmarks(3)) ^ 2 ) + ((landmarks(2) - landmarks(4)) ^ 2));
        
        %shoulder
        shoulder_pixels = shoulder_pixels + sqrt(((landmarks(5) - landmarks(7)) ^ 2 ) + ((landmarks(6) - landmarks(8)) ^ 2));
        shoulder_pixels = shoulder_pixels + sqrt(((landmarks(7) - landmarks(9)) ^ 2 ) + ((landmarks(8) - landmarks(10)) ^ 2));
        shoulder_pixels = shoulder_pixels + sqrt(((landmarks(9) - landmarks(11)) ^ 2 ) + ((landmarks(10) - landmarks(12)) ^ 2));
        shoulder_pixels = shoulder_pixels + sqrt(((landmarks(11) - landmarks(13)) ^ 2 ) + ((landmarks(12) - landmarks(14)) ^ 2));
        
        %arm_size
        arm_size_pixels = arm_size_pixels + sqrt(((landmarks(15) - landmarks(17)) ^ 2 ) + ((landmarks(16) - landmarks(18)) ^ 2));
        
        %waist
        waist_pixels = waist_pixels + sqrt(((landmarks(19) - landmarks(21)) ^ 2 ) + ((landmarks(20) - landmarks(22)) ^ 2));
        
        %arm_length
        arm_length_pixels = arm_length_pixels + sqrt(((landmarks(23) - landmarks(25)) ^ 2 ) + ((landmarks(24) - landmarks(26)) ^ 2));
        
    end
end

