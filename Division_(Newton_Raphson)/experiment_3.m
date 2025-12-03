N = [15, 23, 11, 13, 7, 19];
D = [23, 15, 19, 29, 3, 17];
error_tol = 1e-6;
max_repetition = 50;
for k = 1:length(N)
Q = round(D(k)/5)*5;
x = 1/Q;
for i = 1:max_repetition
    y = x * (2 - (D(k)*x));
    if abs(y-x)<error_tol
        fprintf('%2d/%2d = %.20f\n',N(k), D(k), N(k)*y);
        break;
    end
    x = y;
end
end
