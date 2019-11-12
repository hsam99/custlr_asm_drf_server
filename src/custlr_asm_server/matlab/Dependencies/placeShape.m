function [x_aligned] = placeShape(im,x,layout)
% PLACESHAPE 
%
%	INPUT
%
%       x: mean shape coordinates
%       layout: 'muct' or 'standard'
%
%	OUTPUT
%
%
% John W. Miller
% 21-Apr-2017

if nargin < 3
    layout = 'standard';
end

% View the image
% f = figure('units','normalized','outerposition',[.25 0.4 .3 .55]);
% hold on, imshow(im,[],'InitialMagnification','fit')
% text(0.07,0.95,'Click on center of nose. Or close by. Test your luck.','fontsize',FS,'units','normalized','color','r')

% Get input from user
% [I,J] = ginput(1);
% TEMP hardcode left shoulder position
I = 48.5;
J = 10.5;

%debugg
% disp(I);
% disp(J);

% Center shape on user's point
x_aligned = x;

switch lower(layout)
    case 'standard'
        x_aligned(1:2:end) = x_aligned(1:2:end)-x(27); % Center on middle of nose
        x_aligned(2:2:end) = x_aligned(2:2:end)-x(28);
    case 'muct'
        
        %for custlr this correspond to left shoulder
        x_aligned(1:2:end) = x_aligned(1:2:end)-x(13); %take every other val from first val
        x_aligned(2:2:end) = x_aligned(2:2:end)-x(14); %take every other val from second val
        
        %original
        % Center on middle of nose
        %x_aligned(1:2:end) = x_aligned(1:2:end)-x(135); %take every other val from first val
        %x_aligned(2:2:end) = x_aligned(2:2:end)-x(136); %take every other val from second val
end
x_aligned(1:2:end) = x_aligned(1:2:end)+I;
x_aligned(2:2:end) = x_aligned(2:2:end)+J;

% Display centered shape
%plotLandmarks(x_aligned,'show_lines',1,'hold',1,'layout',layout)

end % End of main