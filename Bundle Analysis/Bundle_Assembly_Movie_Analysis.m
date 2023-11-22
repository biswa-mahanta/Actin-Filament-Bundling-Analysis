close all; %closes all figures 
clear;  %clears variables in workspace memory
clc; % clears command window

%Defining Parameters 
%using inputs from dialog box to set noise filter base and background base.
%standard deviations are automatically set at the base divided by 7.
prompt = {'Time Interval Between Snapshots:', 'Micron/Pixel Ratio:','Noise Filter Base:','Background Base:',... 
           'Photobleaching Correction Factor (Per Frame)','Adj. Factor for Setting Initial Bundle Threshold',... 
           'Exponential or Linear Photobleaching Correction Factor?','Split Number','Adaptive or Global Thresholding?'}; 
box_title = 'Set Parameters'; %prompts and title for dialog box
dims = [1 35];definput = {'10','0.267','7','63','0.0063','1.8','Exponential','3','Adaptive'}; %sets dimensions of dialog box and default values 
parameters = inputdlg(prompt,box_title,dims,definput); parameters=char(parameters); %opens dialog box, asking for parameters to be set
noise_filter_base = str2double(parameters(3,:)); noise_filter_stdev = noise_filter_base/7;
background_base = str2double(parameters(4,:));background_stdev = background_base/7;  
time_interval = str2double(parameters(1,:));  
micron_pixel_conversion = str2double(parameters(2,:));
photobleaching_correction = str2double(parameters(5,:)); 
start_corr = str2double(parameters(6,:)); 
exp_or_line = parameters(7,:);

%Read in Movies of Interest   
[movie_name] = uigetfile('*.avi', 'Select Images'); %select file or files to analyze    
tic
movie = VideoReader(char(movie_name));  %read in movies  
split_number = str2double(parameters(8,:)); %the number of sections each axis will be split into to generate the image grid.
%split_number squared is the number of total rectangles in the grid.
image_width = movie.Width;  %in pixels
image_height = movie.Height; %in pixels
assert(mod(image_width,split_number)==0 & mod(image_height,split_number)==0,'Split number is not compatible with image.');  
%image width and height in pixels must be divisible by the split_number 
frame_count = movie.NumFrames; 

%initializing variables  
bundled_pix_ovr_total = zeros(frame_count-1,1); %subtract one because the first frame establishes the baseline, bundling is not quantified
snapshot_intensities = zeros(frame_count-1,1); %subtract one because the first frame establishes the baseline, bundling is not quantified
snapshot_intensities_bundled = zeros(frame_count-1,1);  %subtract one because the first frame establishes the baseline, bundling is not quantified
fraction_bundled = zeros(frame_count-1,1);  
all_intensities = zeros(frame_count-1, 10000);
scale_bar_x =[(image_width - 50),(image_width - 50 + 10/micron_pixel_conversion)];  
%scale bar will be located 50 pixels from edge of frame in the x direction, 37.5 pixels long 
%Scale bar will be 10 microns long. 0.2667 pixels per micron 10/0.266 = 37.5 pixels long = 10 um 
scale_bar_y = [image_height - 20,image_height - 20]; 
%scale bar will be 20 pixels from edge of frame in the y direction
pixel_lists = cell(frame_count - 1, 2); % where frame, x y coordinates of objects 
all_bundled_coords = cell(frame_count - 1, 2); %storescoordinates of detected bundles objects for analysis movie later 
time_snapshots = cell(frame_count - 1); %stores frame for analysis movie later  
skeletons = cell(frame_count - 1); %stores skeleton for analysis movie later

%specifiy intervals for spliting up image 
%need to split up image because of uneven illumination. Each section will have its own bundle intensity threshold.   
%image_width/split_number is width of one section in pixels
xstarts = repmat([1:image_width/split_number:image_width]',split_number,1);   %#ok<*NBRAK>
xends =repmat([image_width/split_number:image_width/split_number:image_width]',split_number,1); 
ystarts = repmat([1:image_height/split_number:image_height],split_number,1); ystarts = ystarts(:); 
yends =repmat([image_height/split_number:image_height/split_number:image_height],split_number,1); yends =yends(:);
interval_values = [xstarts,xends,ystarts,yends];   

%Set Bundle Threshold Intensity Based off the First Frame   

%Image Processing of First Frame 
before_fascin_image = readFrame(movie); %reads first frame
before_fascin_image = rgb2gray(before_fascin_image);
%figure; imshow(before_fascin_image);
doubled_image = double(before_fascin_image); %allows you to do floating point operations on image    
my_noise_filter = fspecial('gaussian',noise_filter_base,noise_filter_stdev);  %make the noise filter
noise_filtered_image = imfilter(doubled_image,my_noise_filter, 'symmetric');  %apply the noise filter to the image
%figure; imshow(noise_filtered_image);
my_background_filter = fspecial('gaussian',background_base,background_stdev); %make the background filter
background_image = imfilter(doubled_image,my_background_filter,'symmetric'); %make the background image
processed_image = noise_filtered_image - background_image;   %subtract the background from the noise filtered image
%figure; imshow(processed_image);
max_sub = max(processed_image(:)); min_sub = min(processed_image(:));  
norm_image = (processed_image - min_sub)./(max_sub-min_sub);  %normalizes the image so all intensity values are between 0 and 1 
%figure; imshow(norm_image);
threshold_mask = graythresh(norm_image);  %threshold the image
BW_image = imbinarize(norm_image,threshold_mask); %convert to black and white
%figure; imshow(BW_image);
skeleton = bwskel(BW_image); %skeletonization of the black and white image
%figure; imshow(skeleton);
inverted_BW_image = ones(size(BW_image)); %initalizes inverted BW_image
inverted_BW_image(BW_image == 1) = 0; %inverted_BW_image needed to find background 


%Establish Bundle Intensity Thresholds from First Frame 
thresh_intensity_ROI =zeros(1,split_number^2);   
%move through image grid, down columns, setting intensity
for row_idx = 1: split_number^2    %for each section of the image grid;
       section_stats = regionprops(skeleton(ystarts(row_idx):yends(row_idx),xstarts(row_idx):xends(row_idx)),... 
                       noise_filtered_image(ystarts(row_idx):yends(row_idx),xstarts(row_idx):xends(row_idx)),'PixelValues');  
       %finds the intensity values of pixels of the section 
       pixel_intensities = cat(1, section_stats.PixelValues);  %concatenates pixel intensity values into a single list. 
       background_stats = regionprops(inverted_BW_image(ystarts(row_idx):yends(row_idx),xstarts(row_idx):xends(row_idx)),... 
                          doubled_image(ystarts(row_idx):yends(row_idx),xstarts(row_idx):xends(row_idx)),'PixelValues'); 
       %fluorescence intensity readout will be signal - background.  
       %This step gives you the background intensity values for the section of interest.
       background_intensities = cat(1, background_stats.PixelValues); %concatenates background intensity values into a single list. 
       background_intensities = rmoutliers(background_intensities, 'percentiles',[8 92]); 
       %some undetected objects show up in the  inverted BW_image so this step removes these anomalies from the background calculation
       background = mean(background_intensities);
       pixel_intensities = pixel_intensities - background; % all pixel_intensities - mean background intensity
       thresh_intensity_ROI(row_idx) = mean(pixel_intensities) + start_corr * std(pixel_intensities); %sets thresh_intensity_ROI for that section   
end    

% if a section doesn't have any objects in the first frame, this function will help set 
%the threshold for the empty sections by taking the average of the surrounding sections.  
%This happens most often with the short filament samples. 
thresh_intensity_ROI = fill_empties_by_avg(thresh_intensity_ROI, split_number); 
orig_thresh_intensity_ROI = thresh_intensity_ROI;
%Analyze bundling after fascin has been added   

for frame = 1:(frame_count - 1)       
    %photobleaching correction is in the units: change in fluorescence per frame
    if isequal('Exponential',exp_or_line) 
        thresh_intensity_ROI = orig_thresh_intensity_ROI * exp(-photobleaching_correction * frame); 
    else 
        thresh_intensity_ROI = thresh_intensity_ROI - photobleaching_correction; 
    end
    time_snapshot = readFrame(movie); %reads in next frame 
    time_snapshots{frame} = time_snapshot; %stores frame for the analysis movie  
    %image processing and object detection 
    time_snapshot = rgb2gray(time_snapshot); 
    doubled_image = double(time_snapshot);   %allows you to do floating point operations on image    
    my_noise_filter = fspecial('gaussian',noise_filter_base,noise_filter_stdev);  %make the noise filter
    noise_filtered_image = imfilter(doubled_image,my_noise_filter, 'symmetric');  %apply the noise filter to the image
    my_background_filter = fspecial('gaussian',background_base,background_stdev); %make the background filter
    background_image = imfilter(doubled_image,my_background_filter,'symmetric'); %make the background image
    processed_image = noise_filtered_image - background_image; %subtract the background from the noise filtered image  
    max_sub = max(processed_image(:)); min_sub = min(processed_image(:));
    norm_image = (processed_image - min_sub)./(max_sub-min_sub);  %normalizes the image so all intensity values are between 0 and 1     
    threshold_mask = graythresh(norm_image);  %threshold the image  
    if strcmp(deblank(parameters(9,:)), 'Adaptive')||strcmp(deblank(parameters(9,:)), 'adaptive')
        BW_image = imbinarize(norm_image,'adaptive','ForegroundPolarity','dark','Sensitivity',1); %convert to black and white 
    else 
        BW_image =imbinarize(norm_image, threshold_mask);
    end  
    inverted_BW_image = ones(size(BW_image)); %initializes inverted_BW_image as all ones
    inverted_BW_image(BW_image == 1) = 0; %gets inverted BW_image for background calculations later
    skeleton = bwskel(BW_image);   %skeletonizes BW_image, reduces objects to their centerline.
    skeletons{frame} = skeleton; %for  analysis movie. saves skeleton into cell array for movie 
    bw_props = regionprops(skeleton,'PixelList'); %gets pixel coordinates for skeleton
    pixel_list = cat(1,bw_props.PixelList); %concatenates pixel coordinates into one list  
 
    %stores pixels for analysis movie
    if isempty(pixel_list); 
        pixel_lists{frame,1} = 0; 
        pixel_lists{frame,2} = 0;  
    else;
        pixel_lists{frame, 1} = pixel_list(:,1); 
        pixel_lists{frame, 2} = pixel_list(:,2);  
    end  
    
    %initializes variables for bundle analysis 
    num_total_pixels = size(pixel_list,1);   
    big_pic_bundled_coord = zeros(num_total_pixels,2);  
    %initializes matrix to store the bundled pixel coordinates from total image (not just a small section of the grid)
    bundled_pixels_coord = zeros((image_width/split_number)^2, 2);  
    %initializes matrix to store a grid section's bundled pixel coordinates
    next_start = 1; 
    all_sec_intensities = zeros(split_number^2,1); %where pixel intensities from all grid sections will be stored
    all_sec_num_bundled = zeros(split_number^2,1); % where bundled intensities from all grid sections will be stored
    all_sec_bundled_intensities = zeros(split_number^2,1);   
    list_ind_sec_intensities = zeros(split_number^2,num_total_pixels); 

for section = 1:(split_number^2)    
    ROI = skeleton(interval_values(section,3):interval_values(section,4),interval_values(section,1):interval_values(section,2));
    ROI_grayscale = noise_filtered_image(interval_values(section,3):interval_values(section,4),interval_values(section,1):interval_values(section,2));
    bw_props = regionprops(ROI,'PixelList');   
    pixel_list = cat(1,bw_props.PixelList);  
    intensity_props = regionprops(ROI, ROI_grayscale, 'PixelValues'); 
    section_intensities = cat(1,intensity_props.PixelValues); 
    background_stats = regionprops(inverted_BW_image(xstarts(section):xends(section),ystarts(section):yends(section)),... 
                       doubled_image(xstarts(section):xends(section),ystarts(section):yends(section)),'PixelValues');  
    background_intensities = cat(1, background_stats.PixelValues);  
    background_intensities = rmoutliers(background_intensities, 'percentiles',[8 92]); 
    background = mean(background_intensities); 
    section_intensities = section_intensities - background;   %subtract background 
    if isempty(pixel_list) == 0 %if there are objects in this section
       bundled_pixels_intensities = section_intensities(section_intensities >(thresh_intensity_ROI(section))); 
       bundled_pixels_coord = pixel_list(section_intensities >thresh_intensity_ROI(section),1:2); 
       num_bundled_pixels = size(bundled_pixels_intensities,1);                                               
    else %if there are no objects in this section
        bundled_pixels_intensities = 0; 
        num_bundled_pixels = 0;
    end    
     big_pic_bundled_coord(next_start:(next_start+num_bundled_pixels-1), 1:2)= [interval_values(section, 1) + (bundled_pixels_coord(1:num_bundled_pixels,1)-1),... 
                                                                                  interval_values(section, 3) + (bundled_pixels_coord(1:num_bundled_pixels,2)-1)];               
    next_start = next_start + num_bundled_pixels;  
    all_sec_intensities(section) = sum(section_intensities);  %all intensities even those of single filaments 
    all_sec_num_bundled(section) = num_bundled_pixels;%number of pixels bundled
    all_sec_bundled_intensities(section) = sum(bundled_pixels_intensities);  %section intensites above a certain threshold  
    list_ind_sec_intensities(section,1:length(section_intensities)) = section_intensities; 
end  

all_bundled_coords{frame, 1} = nonzeros(big_pic_bundled_coord(:,1));
all_bundled_coords{frame, 2} = nonzeros(big_pic_bundled_coord(:,2));
  
all_intensities(frame,1:length(nonzeros(list_ind_sec_intensities))) = nonzeros(list_ind_sec_intensities);
snapshot_intensities(frame) = sum(all_sec_intensities)/num_total_pixels;  %total snapshot intensities/ number of pixels 
bundled_pix_ovr_total(frame) = sum(all_sec_num_bundled)/num_total_pixels;  %number of bundled pixels over total
snapshot_intensities_bundled(frame) =  sum(all_sec_bundled_intensities)/num_total_pixels; %bundled_intensities divided by total number of pixels 
fraction_bundled(frame) = (sum(all_sec_bundled_intensities)/num_total_pixels)/(sum(all_sec_intensities)/num_total_pixels);  

end  


figure;plot(0:time_interval:(frame_count-2)*time_interval, fraction_bundled(1:frame_count-1,:),'LineWidth',5);  
% plot(subset_x', subset_fraction_bundled, 'LineStyle','none','Marker','.','MarkerSize',15); 
axes=gca; 
axes.LineWidth = 2; 
axes.FontSize = 18; 
axes.FontWeight ='bold';
xlim([0 (frame_count*time_interval)]); ylim([0 max(fraction_bundled)+0.1]);
xlabel('Time(s)','FontSize',20,'FontWeight','bold');
ylabel('Fraction Crosslinked','FontSize',20,'FontWeight','bold'); 
saveas(gcf,replace(movie.Name,'.avi','_crosslinked_fraction.pdf'));  


% Writing the analysis video
write_videos(frame_count,movie,time_snapshots,scale_bar_x,scale_bar_y,skeletons,pixel_lists,all_bundled_coords); 
fraction_bundled_ovr_time = fraction_bundled(1:frame_count-1,:); 
save(replace(movie.Name,'.avi','_BA_variables.mat'),'fraction_bundled_ovr_time','noise_filter_base','background_base',... 
    'time_interval','photobleaching_correction','start_corr','split_number','exp_or_line');
toc