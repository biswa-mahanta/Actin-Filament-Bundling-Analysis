close all; %closes all figures 
clear;  %clears variables in workspace memory
clc; % clears command window

%Defining Parameters
prompt = {'Time Interval Between Snapshots:', 'Micron/Pixel Ratio:','Noise Filter Base:','Background Base:'};box_title = 'Set Parameters'; %prompts and title for dialog box
dims = [1 35];definput = {'10','0.267','7','63'}; %sets dimensions of dialog box and default values 
parameters = inputdlg(prompt,box_title,dims,definput); parameters=char(parameters); %opens dialog box, asking for parameters to be set
noise_filter_base = str2double(parameters(3,:)); noise_filter_stdev = noise_filter_base/7;
background_base = str2double(parameters(4,:));background_stdev = background_base/7;  
time_interval_between_snapshots = str2double(parameters(1,:));  %time between two frames
micron_pixel_conversion = str2double(parameters(2,:));
%using inputs from dialog box to set noise filter base and background base.
%standard deviations are automatically set at the base divided by 7.


%Read in Movies of Interest   
[movie_name] = uigetfile('*.avi', 'Select Images'); %select file or files to analyze    
tic
movie = VideoReader(char(movie_name));  %read in movies  
frame_count = movie.NumFrames;   
time_interval_per_frame = movie.Duration/frame_count;
frame_interval = 20;  %frame interval for photobleaching analysis
% the above line means single filament intensities will be  
%measured every blank frames
image_width = movie.Width;  %in pixels
image_height = movie.Height; %in pixels 


%initializing variables   
single_filament_averages = zeros(frame_count, 1);
bundled_pix_ovr_total = zeros(frame_count-1,1); %subtract one because the first frame establishes the baseline, bundling is not quantified
snapshot_intensities = zeros(frame_count-1,1); %subtract one because the first frame establishes the baseline, bundling is not quantified
snapshot_intensities_bundled = zeros(frame_count-1,1);  %subtract one because the first frame establishes the baseline, bundling is not quantified
fraction_bundled = zeros(frame_count-1,1);  
all_intensities = zeros(frame_count-1, 10000); 
thresholds = zeros(floor(frame_count/frame_interval),1);
scale_bar_x =[(image_width - 50),(image_width - 50 + 10/micron_pixel_conversion)];  
%scale bar will be located 50 pixels from edge of frame in the x direction, 37.5 pixels long 
%Scale bar will be 10 microns long. 0.2667 pixels per micron 10/0.266 = 37.5 pixels long = 10 um 
scale_bar_y = [image_height - 20,image_height - 20]; 
%scale bar will be 20 pixels from edge of frame in the y direction
pixel_lists = cell(frame_count - 1, 2); % where frame, x y coordinates of objects  
single_fil_intensities = zeros(image_height*image_width,(floor(frame_count/frame_interval) +1)); 
bundled_coords = cell(frame_count - 1, 2); %storescoordinates of detected bundles fiobjects for analysis movie later 
time_snapshots = cell(frame_count - 1); %stores frame for analysis movie later  
skeletons = cell(frame_count - 1); %stores skeleton for analysis movie later
analysis_fig = figure('Position', [0 0 1440 900]); 

for frame = 1:(floor(frame_count/frame_interval) +1)   
    display(frame);
    time_snapshot = readFrame(movie); %reads in next frame    
    %movie current time is adjusted every iteration
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
    BW_image =imbinarize(norm_image, threshold_mask);
    %BW_image = imbinarize(norm_image,'adaptive','ForegroundPolarity','dark','Sensitivity',1); %convert to black and white 
    inverted_BW_image = ones(size(BW_image)); %initializes inverted_BW_image as all ones
    inverted_BW_image(BW_image == 1) = 0; %gets inverted BW_image for background calculations later
    skeleton = bwskel(BW_image);   %skeletonizes BW_image, reduces objects to their centerline.
    skeletons{frame} = skeleton; %for  analysis movie. saves skeleton into cell array for movie 
    bw_props = regionprops(skeleton,'PixelList'); %gets pixel coordinates for skeleton
    pixel_list = cat(1,bw_props.PixelList); %concatenates pixel coordinates into one list  
    intensity_stats = regionprops(skeleton,noise_filtered_image,'MeanIntensity','MaxIntensity','PixelValues');  
    max_intensities = cat(1, intensity_stats.MaxIntensity);  
    pixel_coord_mat = pixel_struct_to_mat(length(max_intensities),bw_props);
    background_stats = regionprops(inverted_BW_image,noise_filtered_image,'PixelValues'); 
       %fluorescence intensity readout will be signal - background.  
       %This step gives you the background intensity values for the section of interest.
    background_intensities = cat(1, background_stats.PixelValues); %concatenates background intensity values into a single list. 
    background_intensities = rmoutliers(background_intensities, 'percentiles',[8 92]); 
       %some undetected objects show up in the  inverted BW_image so this step removes these anomalies from the background calculation
    background = mean(background_intensities); 
    corrected_max_intensities = max_intensities - background;    
    original_fig = subplot(1,2,1); 
    set(gcf, 'Position', get(0, 'Screensize'));
    imshow(time_snapshot,[],'InitialMagnification','fit'); title('Original Image','FontSize',24); %shows original image
    image_analysis_figure=subplot(1,2,2);imshow(skeleton,[],'InitialMagnification','fit');hold on; %shows analysis image 
    plot(pixel_coord_mat(:,1:2:end), pixel_coord_mat(:,2:2:end),'m.','MarkerSize',8);   
    [bundle_idx, brightness_threshold] = set_bundle_threshold_photobleaching(corrected_max_intensities, pixel_coord_mat); 
    thresholds(frame) = brightness_threshold;  
    num_pixels = 0; 
    single_filament_sum = 0;  
    for i = 1:length(max_intensities)  
        if i ~= bundle_idx 
        single_fil_intensities(num_pixels + 1:num_pixels +length(intensity_stats(i).PixelValues),frame)... 
            = (intensity_stats(i).PixelValues - background);
        num_pixels = num_pixels + length(intensity_stats(i).PixelValues);
        end   
    end 
    if ((movie.CurrentTime - time_interval_per_frame) + time_interval_per_frame * frame_interval) <= movie.Duration;
    movie.CurrentTime = (movie.CurrentTime - time_interval_per_frame) + time_interval_per_frame * (frame_interval-1); 
    else  
        break; 
    end 
    
end 

means = zeros((floor(frame_count/frame_interval) +1),1);
medians = zeros((floor(frame_count/frame_interval) +1),1);

for each_frame = 1:(floor(frame_count/frame_interval) +1); 
    means(each_frame) = mean(nonzeros(single_fil_intensities(:,each_frame)));  
    medians(each_frame) = median(nonzeros(single_fil_intensities(:,each_frame)));
end 
 
frame_to_time = [0:frame_interval:frame_count].* time_interval_between_snapshots; %#ok<NBRAK>   %approximate

means = means(~isnan(means));  
frame_to_time = frame_to_time(~isnan(means)); 
linear_coeff_mean = polyfit(frame_to_time', means, 1);
line_fitted_mean_y = polyval(linear_coeff_mean,frame_to_time);   
corr_coef_mean = corr2(frame_to_time',means);
linear_rsquared_mean = power(corr_coef_mean,2);   
display(linear_coeff_mean,'linear_coeff_mean');
display(linear_rsquared_mean,'linear_rsquared_mean');
[exp_fit_mean,gof] = fit(frame_to_time', means, 'exp1');  
exp_fit_mean_y = feval(exp_fit_mean,frame_to_time);  
exp_rsquared_mean = gof.rsquare;   
display(exp_fit_mean,'exp_fit_mean');
display(exp_rsquared_mean,'exp_rsquared_mean'); 
disp('UNITS of correction factor: change in fluorescence per second');
 

% figure;
% plot(frame_to_time, nonzeros(thresholds),'LineWidth',3); xlabel('Time (s)'); 
% ylabel('Bundle Intensity Threshold'); 
% axes = gca; axes.FontSize = 14; axes.LineWidth = 2; 

figure;  
plot(frame_to_time,means,'LineWidth',3); hold on;
plot(frame_to_time,line_fitted_mean_y','--','LineWidth',2); hold on;
plot(frame_to_time',exp_fit_mean_y,'--','LineWidth',2);  
xlabel('Time (s)','FontSize',18); ylabel('Single Filament Mean Intensity','FontSize',18); 
axes = gca; axes.FontSize = 14; axes.LineWidth = 2;   
savefig(replace(movie_name,'.avi','_PBC_graph.fig')); 
save(replace(movie_name,'.avi','_PBC_variables.mat'),'frame_interval','exp_fit_mean','exp_rsquared_mean',... 
    'linear_coeff_mean','linear_rsquared_mean','time_interval_between_snapshots');

% figure;  
% plot(frame_to_time,medians,'LineWidth',3); xlabel('Time (s)','FontSize',18); hold on;
% plot(frame_to_time, line_fitted_med_y,'--','LineWidth',2);hold on; 
% plot(frame_to_time',exp_fit_med_y,'--','LineWidth',2); 
% ylabel('Single Filament Median Intensity','FontSize',18); 
% axes = gca; axes.FontSize = 14; axes.LineWidth = 2; 

