function   [xc,yc,R] = circfitrobust(x,y)


a = robustfit([x y], -(x.^2 + y.^2));
xc = a(2)/-2;
yc = a(3)/-2;
R = sqrt(-a(1) + xc^2 + yc^2);

end