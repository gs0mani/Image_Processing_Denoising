I = double(imread('test_images/lena512.bmp'));
I = I./ 255;
v = var(I(:));
%disp(v);

%u = imnoise(I, 'gaussian', sqrt(v));
u = I + randn(size(I)) .* 0.15;
u(u < 0) = 0;
u(u > 1) = 1;

x = u;
[thr,sorh,keepapp] = ddencmp('den','wv',x);
wv = 'sym4';
level = 3;
sorh = 's';
b = wdencmp('gbl',x,wv,level,thr,sorh,keepapp);

%subplot(2,2,1), imshow(I);
%subplot(2,2,2), imshow(u);
%subplot(2,2,3), imshow(b);
mkdir('Projects/Image_Processing_Denoising/noised_images');
mkdir('Projects/Image_Processing_Denoising/denoised_soft');
imwrite(u, 'Projects/Image_Processing_Denoising/noised_images/lena512_noised.bmp');
imwrite(b, 'Projects/Image_Processing_Denoising/denoised_soft/lena512_soft.bmp');

sigma = 0.0352;
k = 60;
lambda1 = 40;
lambda2 = 1;
tau = 0.0001;
bsigma = imgaussfilt(b,sigma);
pmb = PMdiffuse(bsigma,k, lambda2);

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