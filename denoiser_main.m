function denoiser_main
% load image %
I = double(imread('test_images/lena512.bmp'));
I = I./255;
%v = var(I(:));
v = 20/512;
%disp(v);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Add gaussian noise %
u0 = imnoise(I, 'gaussian', 0, v);
% u = I + randn(size(I)) .* (v);
% u(u < 0) = 0;
% u(u > 1) = 1;

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% % Apply Soft Wavelet Thresholding on the noised image %
x = u0;
[thr,sorh,keepapp] = ddencmp('den','wv',x);
wv = 'sym4';
level = 3;
sorh = 's';
b = wdencmp('gbl',x,wv,level,thr,sorh,keepapp);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% subplot(2,2,1), imshow(I);
% subplot(2,2,2), imshow(u0);
% subplot(2,2,3), imshow(b);
mkdir('Projects/Image_Processing_Denoising/noised_images');
mkdir('Projects/Image_Processing_Denoising/denoised_soft');
imwrite(u0, 'Projects/Image_Processing_Denoising/noised_images/lena512_noised.bmp');
imwrite(b, 'Projects/Image_Processing_Denoising/denoised_soft/lena512_soft.bmp');
disp('Noised Image rmse: ');
disp( rms_error(I, u0));
disp('Noised Image psnr: ');
disp(psnr_fn(I, u0));
disp('Wavelet Threshold Image rmse: ');
disp( rms_error(I, b));
disp('Wavelet Threshold Image psnr: ');
disp(psnr_fn(I, b));
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Set Parameters for diffusion %
sigma = v;
k = 60;
lambda1 = 80;
lambda2 = 1;
tau = 0.0001;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Apply Gaussian Filtering and Parona-Malik(PM) Anisotropic Diffusion %
bsigma = imgaussfilt(b,sigma);
pmb = PMdiffuse(bsigma,k, lambda2);
u = u0;
for iter = 1:500
    usigma = imgaussfilt(u,sigma);
    pmu = PMdiffuse(usigma,k, lambda1);
    f_term = immultiply(b,pmu);
    s_term = immultiply(u,pmb);
    add_term = imadd(f_term, s_term).*tau;
    u = imadd(u,add_term);
end

%subplot(2,2,4), imshow(u);
mkdir('Projects/Image_Processing_Denoising/denoised_diffused');
imwrite(u, 'Projects/Image_Processing_Denoising/denoised_diffused/lena512_diffused.bmp');
disp('Anisotropic_final Image rmse:');
disp( rms_error(I, u));
disp('Anisotropic_final Image psnr:');
disp(psnr_fn(I, u));
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
end

function res = PMdiffuse(j,k, lambda)
    % North Gradient %
    north = zeros(size(j,1), size(j,2)); 
    north(2:end, 1:end) =  j(1:end-1, 1:end) ;
    north(1, :) = j(1, :);
    
    del_j_north = north - j;
    
    % South Gradient.
    south = zeros(size(j,1), size(j,2)); 
    south(1:end-1, 1:end) =  j(2:end, 1:end) ;
    south(end, :) = j(end, :); 

    del_j_south = south - j;

    % West Gradient.
    west = zeros(size(j,1), size(j,2)); 
    west(:, 2:end) =  j(:, 1:end-1) ;
    west(:, 1) = j(:, 1); 

    del_j_west = west - j;

    % East Gradient.
    east = zeros(size(j,1), size(j,2));
    east(:, 1:end-1) =  j(:, 2:end);
    east(:, end) = j(:, end); 

    del_j_east = east - j;

    %%% Calculate Diffusion Coefficients.
    cn = exp(-(del_j_north./k).^2);
    cs = exp(-(del_j_south./k).^2);
    ce = exp(-(del_j_east./k).^2);
    cw = exp(-(del_j_west./k).^2);
    
    % Update the image on this iteration. 
    res = lambda.*(cn.*del_j_north + cs.*del_j_south + ce.*del_j_east + cw.*del_j_west);
end

function rmse = rms_error(Input, Output)
    sq_error = (double(Input) - double(Output)).^2;
    mse = sum(sum(sq_error)) / (512*512);
    rmse = sqrt(mse);
end

function psnr = psnr_fn(Input, Output)
    sq_error = (double(Input) - double(Output)).^2;
    mse = sum(sum(sq_error)) / (512*512);
    psnr = 10 * log10( 256^2 / mse);
end