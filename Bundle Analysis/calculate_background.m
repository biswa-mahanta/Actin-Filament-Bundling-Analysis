function [background_list] = calculate_background(section_pixel_width,skeleton, noise_filtered_image,BW_image,m,snapshots);

%the purpose of this function is to calculate background intensity for
%each section of the grid. (Needed for signal-background measurements.) To visualize the background image, uncomment all
%the lines of code in this function. m and snapshots are used in the commented code 

image_width = size(skeleton,1);  %in pixels
image_height = size(skeleton,2); %in pixels 
assert(image_width == image_height, 'Error. Image width and height must be the same.') 
split_number = image_width / section_pixel_width; % reccommend section size approximately 80 pixels wide and tall 
assert(mod(image_width,section_pixel_width)== 0,'Image dimensions are not compatible with the section pixel width (~line 32 in main code)');   
thick_BW_image = bwmorph(BW_image,'thicken', 8); %thicken makes sure halos aren't taken into account for background fluorescence
inverted_BW_image = ones(size(thick_BW_image)); 
inverted_BW_image(thick_BW_image == 1) = 0;  
% background = noise_filtered_image .* inverted_BW_image;  %HERE
% assembled_background = zeros(split_number*section_pixel_width,section_pixel_width*split_number); %HERE

xstarts = repmat([1:section_pixel_width:image_width]',split_number,1); 
xends =repmat([section_pixel_width:section_pixel_width:image_width]',split_number,1); 
ystarts = repmat([1:image_height/split_number:image_height],split_number,1); ystarts = ystarts(:);
yends =repmat([image_height/split_number:image_height/split_number:image_height],split_number,1); yends =yends(:);
%interval_values = [xstarts,xends,ystarts,yends];   %HERE

background_list = zeros(1,split_number^2);   
%overall_outlier_pixels = zeros(size(background,1)*size(background,2) ,2); %HERE
%start = 1; %HERE

for row_idx = 1: split_number^2;   
       background_stats = regionprops(inverted_BW_image(ystarts(row_idx):yends(row_idx),xstarts(row_idx):xends(row_idx)),... 
                          noise_filtered_image(ystarts(row_idx):yends(row_idx),xstarts(row_idx):xends(row_idx)),'PixelList','PixelValues');   
       background_intensities = cat(1, background_stats.PixelValues); 
       [~,section_outliers] = rmoutliers(background_intensities, 'percentiles',[8 92]);    
       %background_pixels = cat(1, background_stats.PixelList); %HERE
       %removes undetected filament sections by removing outliers 
       %outlier_pixels = background_pixels(section_outliers,1:2);   %HERE
       %Convert section outlier pixels coordinates to Overall Picture
       %Coordinates  
       %overall_outlier_pixels(start:start + length(outlier_pixels) - 1,1) = (interval_values(row_idx,1) + outlier_pixels(:,1) - 1); %HERE
       %overall_outlier_pixels(start:start + length(outlier_pixels) - 1,2) = (interval_values(row_idx,3) + outlier_pixels(:,2) - 1); %HERE
       %start = start + length(outlier_pixels); %HERE
       background_list(row_idx) = mean(background_intensities(~section_outliers));  
       %finds mean of background intensities of section without outliers     
end   
% overall_outlier_pixels = reshape(nonzeros(overall_outlier_pixels),(size(nonzeros(overall_outlier_pixels), 1)/2),2); 
% figure; imshow(background,[],'InitialMagnification','fit'); hold on;
% plot(overall_outlier_pixels(:,1),overall_outlier_pixels(:,2), '.k','MarkerSize',1); hold off;   
% background_file = replace(snapshots(m,:),'.tif','_background');
% saveas(gcf,background_file,'pdf');  
% close(gcf);
end 

 