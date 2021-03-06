%% input: two image
%% output: translational displacement [dx,dy] and correlation peaks

%% main phase correlation function
function [dx,dy,peak,Pt] = PhaseCorrelation(AI,BI,subpixel,window)

% check input numbers
if nargin < 2
    error('Input number should be more than 2!')
elseif nargin == 2
    subpixel='parabola';window = 'hanning'; 
elseif nargin == 3
    window = 'hanning';
end


% Get size
[height, width ] = size(AI);
 cy = height/2;
 cx = floor(width/2);

win = windowing(width,height,window);

% Apply Windowing 
IA = win .* double((AI));
IB = win .* double(BI);

% PhaseCorrelation
A=fft2(IA);
B=fft2(IB);

At = A./abs(A);
Bt = (conj(B))./abs(B);
Pt = fftshift(ifft2(At.*Bt));

[mm,y]=max(Pt);
[mx,x]=max(mm);
dx=x;
dy=y(x); 

[pxx,pyy,peak] = subpixfitting2(Pt,dx,dy,subpixel);

% get translation from center
dx = floor(width/2) - pxx + 1;
dy = floor(height/2 )- pyy + 1;


end

%% windowing function
function win = windowing(width,height,method)

%% Create window
 cy = height/2;
 cx = floor(width/2);

% hannig window and root of hanning window
han_win = zeros(width);
Rhan_win = zeros(width);
trapez_win = zeros(width);

% make window 
for i = 1 :height
    for j = 1:width
            han_win(i,j) = 0.25 * (1.0 + cos(pi*abs(cy- i) / height))*(1.0 + cos(pi*abs(cx - j) / width));
            % Root han_win
            Rhan_win(i,j)=abs(cos(pi*abs(cy - i) / height)*cos(pi*abs(cx - j) / width));
            if i >height/8  &&  i<height*7/8
                fi = 1;
            elseif i <= height/8
                fi = (i-1)/height * 8;
            elseif i >= height*7/8
                fi = (height - i)/height *8;
            end
            if j >width/8  &&  j<width*7/8
                fj = 1;
            elseif j <= width/8
                fj = (j-1)/width * 8;
            elseif j >= width*7/8
                fj = (width - j)/width *8;
            end
            trapez_win(i,j)=fi*fj;
    end
end

% 
if method == 'hanning'
    win = han_win;
elseif method == 'Rhanning'
    win = Rhan_win;
elseif method == 'trapez'
    win = trapez_win;
else
    win = han_win;
end

end

%% interpolation
function [sdx,sdy,peak] = subpixfitting(Pt,dx,dy,method)


% subpixel matching
box = Pt(dy-1:dy+1,dx-1:dx+1);

% making weight function
center_weight = 10;
wvec = ones(9,1);
wvec(5)=center_weight;
W = diag([wvec]);
W = diag([reshape(box,9,1)]);

% parabola for 3 
Tx = repmat([-1 0 1],3,1);
Ty = Tx.';
x = reshape(Tx,9,1);
y = reshape(Ty,9,1);
x2 = x.*x;
y2 = y.*y;
One = ones(9,1);

A = [x2,y2,x,y,One];
p = (A'*W*A)\A'*W*reshape(box,9,1);

sdy = dy -p(4) /2.0/p(2);
sdx = dx -p(3) /2.0/p(1);
peak = p(5) - p(3)*p(3)/4.0/p(1) - p(4)*p(4)/4.0/p(2);

z = p(1)*x.^2+p(2)*y.^2+p(3)*x+p(4)*y+p(5);

figure(111)
plot3(x,y,reshape(box,9,1),'*',x,y,z,'o')
legend('Raw data','Palabora fitted')
end

function [sdx,sdy,peak] = subpixfitting2(Pt,dx,dy,method)


% subpixel matching
box = Pt(dy-1:dy+1,dx-1:dx+1);

% making weight function
center_weight = 10;
wvec = ones(9,1);
wvec(5)=center_weight;
W = diag([wvec]);
W = diag([reshape(abs(box),9,1)]);

% parabola for 3 
Tx = repmat([-1 0 1],3,1);
Ty = Tx.';
x = reshape(Tx,9,1);
y = reshape(Ty,9,1);
x2 = x.*x;
y2 = y.*y;
One = ones(9,1);

A = [x2+y2,x,y,One];
p = (A'*W*A)\A'*W*reshape(box,9,1);

sdy = dy -p(3) /2.0/p(1);
sdx = dx -p(2) /2.0/p(1);
peak = p(4) - p(2)*p(2)/4.0/p(1) - p(3)*p(3)/4.0/p(1);

z = p(1)*x.^2+p(1)*y.^2+p(2)*x+p(3)*y+p(4);

figure(111)
plot3(x,y,reshape(box,9,1),'*',x,y,z,'o')
legend('Raw data','Palabora fitted')
grid on
end