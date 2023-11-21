
function [num_bundles] = num_bundles_only(total_mat_pixels,noise_filtered_image,section_pixel_width,background_list)

%makes sure image dimensions are appropriate 
image_width = size(noise_filtered_image,1);  %in pixels
image_height = size(noise_filtered_image,2); %in pixels 
assert(image_width == image_height, 'Error. Image width and height must be the same.') 
split_number = image_width / section_pixel_width; % want sections as wide as th section_pixel_width 
assert(mod(image_width,section_pixel_width)== 0,'Image dimensions are not compatible with the section pixel width.');  

%initializes variables 
xstarts = repmat([1:section_pixel_width:image_width]',split_number,1); %image_width/split_number is width of one section and the interval val
xends =repmat([section_pixel_width:section_pixel_width:image_width]',split_number,1); 
ystarts = repmat([1:image_height/split_number:image_height],split_number,1); ystarts = ystarts(:);
yends =repmat([image_height/split_number:image_height/split_number:image_height],split_number,1); yends =yends(:);
interval_values = [xstarts,xends,ystarts,yends];   
bundle_codes_mat = zeros(size(total_mat_pixels));   
current_pix_intensities = zeros(size(total_mat_pixels,1), size(total_mat_pixels,2)); 
signal_background_sub = zeros(size(total_mat_pixels,1), size(total_mat_pixels,2));  
% signal_background_sub pixel intensities with signal background subtracted.
 

%this section subtracts the raw pixel intensity of the noise filtered image
%from the background signal of that particular section. Has to check to
%make sure it is in that section
for fil = 1: size(total_mat_pixels,1)  
    count = 0; 
    for coord = 1:2: size(total_mat_pixels,2)   
        count=count+1;
        current_pt = total_mat_pixels(fil,coord:coord+1); %x, y 
        if current_pt == [0 0] 
            break 
        end 
        current_pix_intensity = noise_filtered_image(current_pt(2),current_pt(1));    
        current_pix_intensities(fil,count) = current_pix_intensity;
         for section = 1: size(interval_values, 1) 
              if find(current_pt(2)>=interval_values(section,1) & current_pt(2)<=interval_values(section,2)... 
                             & current_pt(1)>=interval_values(section,3) & current_pt(1) <= interval_values(section,4)); 
                         %above line determines whether pt is in current section
                     current_pix_intensity = current_pix_intensity - background_list(section);  
                     signal_background_sub(fil,count) = current_pix_intensity;
                    
              end 
         end  
    end 
end 

intensity_vec = nonzeros(signal_background_sub); 
%background signal subtracted pixel intensities with zeros removed but it
%is a linear vector rather than an array 

%finds a good bundle intensity threshold based off of histogram of pixel
%intensities. Fit to a nonparametric curve.
func = fitdist(intensity_vec,'kernel'); %fits kernel distribution to the data
x = round(min(intensity_vec))-10:0.1:(round(max(intensity_vec))+10); %vector of the range of the intensity values, steps by 0.1
%these numbers will be plugged into the probability density function to get
%the y value
y = pdf(func,x); %plugs in intensity values to get their probable frequency (y), gives you a distribution of numbers
[~,peak_idxs] = findpeaks(y,'NPeaks',3);   %finds the peak values from the obtained distribution 

%first, obtain intensity value of first peak 
if length(peak_idxs) > 1 && peak_idxs(1) + 20 >= peak_idxs(2)  
%in other words, if there is more than one peak and if the second peak is
%less than 20 intensity units away from the first one:
    one_fil_intensity = (x(peak_idxs(1)) +  x(peak_idxs(2)))/2;   
    %sets the one fil intensity as the average between the first two close-together peaks 
else 
    one_fil_intensity = x(peak_idxs(1)); 
    %sets the one fil intensity as the first peak
end 

%now find separating line between first prominent peak and peaks afterward
inverted_y=max(y)-y; %inverts y values so you can find the valley by the find peaks function
[~,valley_idxs] = findpeaks(inverted_y,'MinPeakDistance',30,'NPeaks',1,'SortStr','descend');   
if isempty(valley_idxs) == 0 %if there is a valley;
    sep_line = x(valley_idxs(1));  %finds the separating line between peaks/ at the valley (local minima)
    one_fil_intensities = intensity_vec(intensity_vec <= (sep_line-30));   
    %takes all of the pixels that are less intense than the separating line
    %intensity - 30 (the values that make up the first peak)
    std_dev_one_fil = std(one_fil_intensities); %finds the standard deviation of the these one-fil intensities. 
    cutoff_thresh = one_fil_intensity + 1.9 * std_dev_one_fil; %makes the bundle cutoff rhe first peak value 
    %this way, 
else %if there is no valley (no separation between peaks 
    cutoff_thresh = mean(intensity_vec) + 1.9 *std(intensity_vec);
end  

%if you find this method of setting the cutoff threshold intensity was not effective, 
%use this code below to see a histogram of pixel intensities and use it manually to set the
%cutoff_thresh here. uncomment all three lines 
% analysis_fig = gcf;
% figure;histogram(intensity_vec,20);xlabel('Signal Intensity - Local Background');ylabel('Frequency'); title('Distribution of Signal Intensities');
% % histfit(intensity_vec,20,'kernel');
%cutoff_thresh =;
% figure(analysis_fig);  
%the above line makes sure you plot the yellow and green lines on the right figure later

 %makes a matrix of bundle codes 
bundle_codes_mat(signal_background_sub >= cutoff_thresh) = 2;  
bundle_codes_mat(signal_background_sub < cutoff_thresh & signal_background_sub ~=0) = 1;  

%plots bundle analysis results, green filaments are single, yellow
%filaments are bundled 

for fil = 1: size(total_mat_pixels,1)  
    count = 0;
    for coord = 1:2: size(total_mat_pixels,2)   
        count = count +1; 
        if bundle_codes_mat(fil, count) == 1 %registered as a single filament
           plot(total_mat_pixels(fil,coord),total_mat_pixels(fil,coord +1),'g.','MarkerSize',8);
        elseif bundle_codes_mat(fil, count) == 2 %registered as a bundled object.
            plot(total_mat_pixels(fil,coord),total_mat_pixels(fil,coord +1),'y.','MarkerSize',9); 
        elseif bundle_codes_mat(fil,count) == 0  %have reached the end of the filament
            break
        end 
    end 
end    

%counts bundles 
[row,~] =find(bundle_codes_mat==2); 
num_bundles = length(unique(row));  %finds number of objects with at least one bundled region

end % end of function

