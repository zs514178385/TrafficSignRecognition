% Function to Segment blue coloured traffic signs
%% Read the Image and get the correct channel for blue
for i = 35412:35412
    image_name =strcat('image.0',num2str(i), '.jpg');
    filename = fullfile('bluesign', image_name);
    if exist(filename, 'file')
        im = imread(filename); %719 %686
    else
        continue;
    end
    im_d = im2double(im);
    im_c = imadjust(im_d, stretchlim(im_d));
    im_b = im_c(:,:,3);
    im_b = medfilt2(im_b, [3 3]); 
    im_b = (im_b - im_c(:,:,1)) ./ (im_c(:,:,1) + im_c(:,:,2) + im_c(:,:,3));
    im_b_usig = im2uint8(im_b);
    im_b = im_b_usig;
    %imtool(im_b)
    %% Crop only a specific region for finding the sign
    im_roi = im_b(1:500,:); 
    %% Apply MSER
    %On Original Image
    % [r,f] = vl_mser(im_roi,'MinDiversity',0.7,...
    %                 'MaxVariation',0.2,...
    %                 'Delta',8, 'DarkOnBright', 0, 'MaxArea', 0.005, 'MinArea', 0.0001 ) ;
    
    % On a extracted region of interest
    [r,f] = vl_mser(im_roi,'MinDiversity',0.7,...
                    'MaxVariation',0.2,...
                    'Delta',8, 'DarkOnBright', 0, 'MaxArea', 0.01, 'MinArea', 0.0001 ) ;
    f = vl_ertr(f) ;
    M = zeros(size(im_b)) ;
    count = 1;
    sAll = [];
    for x=r'
     s = vl_erfill(im_roi,x) ;
     sAll = [sAll;s];
    end
    % Obtain the output in the original size image
    M_roi = zeros(500, size(im_b,2));
    M_roi(sAll) = 1;
    M(1:500,:) = M(1:500,:) + M_roi;
    %imtool(M)
    %% Plot the MSER contours
    %figure(2) ;
    %clf ; imagesc(im_b) ; hold on ; axis equal off; colormap gray ;
    %[c,h]=contour(M,(0:max(M(:)))+.5) ;
    %et(h,'color','y','linewidth',3) ;
    %% Colour Thresholding and combine the these with MSER
    im_hsv = rgb2hsv(im);
    im_h = im_hsv(:,:,1);
    im_s = im_hsv(:,:,2);
    im_v = im_hsv(:,:,3);
    im_s_bw = im_s >= 0.35 & im_s <= 0.8; % decreased lower bound from 0.6 to 0.35
    im_v_bw = im_v >= 0.35 & im_v <= 1; % Could be done away with
    im_final = M & im_s_bw & im_v_bw;
    %imtool(im_final)
    %imtool(im_hsv(:,:,1));
    %imtool(im_hsv(:,:,2));
    %imtool(im_hsv(:,:,3));
    %% Morphological Cleaning
    % Approach 2 - Slightly Better, see debug branch for more
    struct_2 = strel('rectangle', [3 3]);
    im_dilate = imdilate(im_final, struct_2);
    im_filtered = medfilt2(im_dilate, [5 5]); %[2 2]
    struct = strel('rectangle', [5 5]);  %[2 2]
    im_erode = imerode(im_filtered, struct);
    im_erode = imfill(im_erode, 'holes');
    %imshow(im_erode)
   %% Get the Bounding Box from the Region 
   label = bwlabel(im_erode);
   S = regionprops(logical(im_erode), 'Area', 'BoundingBox');
   allArea = [S.Area];
   if isempty(allArea)
       continue;
   end
   [~,ind] = sort(allArea, 'descend'); % Picking the blob with the largest area
   bbox = S(ind(2)).BoundingBox;
   figure(2)
   imshow(im)
   hold on;
   rectangle('position',bbox,'Edgecolor','g', 'linewidth', 2)
   %% Save the File
   filename = sprintf('im_blue_1_ %d.jpg',i);
   output_folder = ('bluesignoutputs');
   hgexport(gcf, fullfile(output_folder, filename), hgexport('factorystyle'), 'Format', 'jpeg');
end