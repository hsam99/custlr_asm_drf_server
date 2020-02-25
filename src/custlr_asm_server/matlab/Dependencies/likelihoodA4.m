function p = likelihoodA4(rect,bw,weightA4Prior,neighborhood)
% rect contains the coordinates of the four corners of a rectangle, it is
% expected to be of size 4x2, i.e., rect(1,:) contains the x and y
% coordinates of the first corner.
%
% bw is the binary image that contains edges;
%
% weightA4Prior is the weightage of the A4 prior probability (A4 shape in terms of ratio between its
% long edge and short edge). It is a number between 0 and 1. The higher the
% weightage, the more importance being placed on the shape than appearance
% that fits with the observed image. 
%
% neighborhood specifies the radius of the neighborhood of a corner point
% that the algorithm should check; If 0, it means only check the corner
% point and no surrounding point should be checked; if 1, it checks the
% 4-neighborhood, if 2, it checks the 8-neighborhood;
%
% p outputs the probability of the rect being an A4 in the image bw.

% obtain a small narrow strip for each edge of the potential A4 and compare
% it with the bw image
    p = 0;
    for i=1:size(rect,1)
        pt1 = rect(mod(i-1,4)+1,:);
        pt2 = rect(mod(i,4)+1,:);
        
        % check if either x or y coordinates of the two points are the same
        % create a strip from pt1 to pt2
        if (pt1(1) == pt2(1)) && (pt1(2) == pt2(2))
            p = 0;
            return;
        elseif pt1(1) == pt2(1)
            ys = pt1(2):(pt2(2)-pt1(2))/(2*max(size(bw))):pt2(2);
            xs = pt1(1)*ones(1,length(ys));
        elseif pt1(2) == pt2(2)
            xs = pt1(1):(pt2(1)-pt1(1))/(2*max(size(bw))):pt2(1);
            ys = pt1(2)*ones(1,length(xs));
        else
            xs = pt1(1):(pt2(1)-pt1(1))/(2*max(size(bw))):pt2(1);
            ys = pt1(2):(pt2(2)-pt1(2))/(2*max(size(bw))):pt2(2);            
        end
            
        ind = [ys' xs']; % note that xs correponds to columns and ys to rows
        ind = round(ind);
        ind = unique(ind,'rows');
        if neighborhood == 0 % a single line strip
            ind = sub2ind(size(bw),ind(:,1),ind(:,2));
        elseif neighborhood == 1 % 4-neighborhood strip, i.e., (i+1,j), (i-1,j), (i,j+1), (i,j-1)
            % assuming that ind is not on the boundary of the image
            ind = [ind; ind(:,1)+1, ind(:,2); ind(:,1)-1, ind(:,2); ind(:,1), ind(:,2)+1; ind(:,1), ind(:,2)-1];
            ind = unique(ind,'rows');
        elseif neighborhood == 2 % 8-neighborhood strip i.e., (i+1,j), (i-1,j), (i,j+1), (i,j-1),
            % (i+1,j+1), (i+1,j-1),(i-1,j+1),(i-1,j-1)
            % assuming that ind is not on the boundary of the image
            ind = [ind; ind(:,1)+1, ind(:,2); ind(:,1)-1, ind(:,2); ind(:,1), ind(:,2)+1; ind(:,1), ind(:,2)-1;...
                ind(:,1)+1, ind(:,2)+1; ind(:,1)-1, ind(:,2)+1; ind(:,1)+1, ind(:,2)-1; ind(:,1)-1, ind(:,2)-1];
            ind = unique(ind,'rows');
        end
        strip = bw(ind);
        p = p + sum(strip)/length(strip);
    end
    p = p/4;
    
    % estimate the ratio of the potential A4 (i.e., long edge against
    % short edge), and obtain its prior probability based on the Gaussian
    % distribution with mean as the true A4 ratio (1.4143), and standard deviation
    % as a small number (compared with the true A4 ratio), e.g., 0.5. 
    normv1 = norm(rect(1,:) - rect(2,:));
    normv2 = norm(rect(2,:) - rect(3,:));
    normv3 = norm(rect(3,:) - rect(4,:));
    normv4 = norm(rect(4,:) - rect(1,:));

    if(normv1 >normv2)
        %C1,C2 and C3,C4 are long edges
        ratio1 = normv1/normv2;
        ratio2 = normv3/normv4;
%         ratio1 = norm(v1) / a4_cm_height;
%         ratio2 = norm(v3) / a4_cm_height;
%         ratio3 = norm(v2) / a4_cm_width;
%         ratio4 = norm(v4) / a4_cm_width;
    else
        %C1,C2 and C3,C4 are short edges
        ratio1 = normv2/normv1;
        ratio2 = normv4/normv3;
%         ratio1 = norm(v2) / a4_cm_height;
%         ratio2 = norm(v4) / a4_cm_height;
%         ratio3 = norm(v1) / a4_cm_width;
%         ratio4 = norm(v3) / a4_cm_width;
    end
    ratio = (ratio1+ratio2)/2;
    
    % set the mean and variance of the Gaussian distribution of A4
    mu = 297/210;
    sigma = 0.5;
    q = exp(-(ratio-mu)^2/(2*sigma^2))/(sqrt(2*pi)*sigma);
    
    % Combine p and q with certain weightage defined by weightA4Prior
    p = (1-weightA4Prior)*p + weightA4Prior*q;
end