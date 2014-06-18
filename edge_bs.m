function B = edge_bs(A)
% edge detection for segmentation images.
%
% Usage:
%
%   B = edge_bs(A)
%
% by Berend Snijder
    if max(A(:))==0
        B=A;
        return
    end
    
    h = fspecial('laplacian',1);
    matColormap = colormap('Jet');
    B = rgb2gray(label2rgb(A,smoothcolormap(matColormap,max(A(:))),'k','shuffle'));
    B = imfilter(B,h);
    B = B>0;

end