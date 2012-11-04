function m = logm_so3(M)

    cos_angle = (M(1,1)+M(2,2)+M(3,3) - 1)/2;
    m = [M(3,2)-M(2,3) M(1,3)-M(3,1) M(2,1)-M(1,2)]/2;
    
    sin_angle_abs = norm(m);
    if cos_angle > sqrt(1/2) % [0-pi/4[ use asin
        if (sin_angle_abs > 0)
            m = m * asin(sin_angle_abs) / sin_angle_abs;
        end
    elseif cos_angle > -sqrt(1/2) % [pi/4-3pi/4[ use acos, but antisymmetric part
        m = m * acos(cos_angle) / sin_angle_abs;
    else % rest use symmetric part
        % antisymmetric part vanishes, but still large rotation, need
        % information from symmetric part
        angle = pi - asin(sin_angle_abs);
        d = diag(M) - cos_angle;
        
        if d(1)*d(1) > d(2)*d(2) && d(1)*d(1) > d(3)*d(3) % first is largest fill with first column
            m2 = [d(1) (M(2,1)+M(1,2))/2 (M(1,3)+M(3,1))/2];
        elseif d(2)*d(2) > d(3)*d(3) % second is largest, fill with second column
            m2 = [(M(2,1)+M(1,2))/2 d(2) (M(3,2)+M(2,3))/2];
        else % third is largest, fill with third column
            m2 = [(M(1,3)+M(3,1))/2 (M(3,2)+M(2,3))/2 d(3)];
        end
        
        % flip, if we point in the wrong direction!
        if dot(m2, m) < 0
            m2 = m2 * -1;
        end
        m2 = m2/norm(m2);
        
        m = angle * m2;
    end
end

% this appears to implement http://en.wikipedia.org/wiki/Axis-angle_representation#Log_map_from_SO.283.29_to_so.283.29
            
% from http://www.edwardrosten.com/cvd/toon/html-user/so3_8h_source.html
%inline Vector<3, Precision> SO3<Precision>::ln() const{
%00291     using std::sqrt;
%00292     Vector<3, Precision> result;
%00293     
%00294     const Precision cos_angle = (my_matrix[0][0] + my_matrix[1][1] + my_matrix[2][2] - 1.0) * 0.5;
%00295     result[0] = (my_matrix[2][1]-my_matrix[1][2])/2;
%00296     result[1] = (my_matrix[0][2]-my_matrix[2][0])/2;
%00297     result[2] = (my_matrix[1][0]-my_matrix[0][1])/2;
%00298     
%00299     Precision sin_angle_abs = sqrt(result*result);
%00300     if (cos_angle > M_SQRT1_2) {            // [0 - Pi/4[ use asin
%00301         if(sin_angle_abs > 0){
%00302             result *= asin(sin_angle_abs) / sin_angle_abs;
%00303         }
%00304     } else if( cos_angle > -M_SQRT1_2) {    // [Pi/4 - 3Pi/4[ use acos, but antisymmetric part
%00305         const Precision angle = acos(cos_angle);
%00306         result *= angle / sin_angle_abs;        
%00307     } else {  // rest use symmetric part
%00308         // antisymmetric part vanishes, but still large rotation, need information from symmetric part
%00309         const Precision angle = M_PI - asin(sin_angle_abs);
%00310         const Precision d0 = my_matrix[0][0] - cos_angle,
%00311             d1 = my_matrix[1][1] - cos_angle,
%00312             d2 = my_matrix[2][2] - cos_angle;
%00313         TooN::Vector<3, Precision> r2;
%00314         if(d0*d0 > d1*d1 && d0*d0 > d2*d2){ // first is largest, fill with first column
%00315             r2[0] = d0;
%00316             r2[1] = (my_matrix[1][0]+my_matrix[0][1])/2;
%00317             r2[2] = (my_matrix[0][2]+my_matrix[2][0])/2;
%00318         } else if(d1*d1 > d2*d2) {              // second is largest, fill with second column
%00319             r2[0] = (my_matrix[1][0]+my_matrix[0][1])/2;
%00320             r2[1] = d1;
%00321             r2[2] = (my_matrix[2][1]+my_matrix[1][2])/2;
%00322         } else {                                // third is largest, fill with third column
%00323             r2[0] = (my_matrix[0][2]+my_matrix[2][0])/2;
%00324             r2[1] = (my_matrix[2][1]+my_matrix[1][2])/2;
%00325             r2[2] = d2;
%00326         }
%00327         // flip, if we point in the wrong direction!
%00328         if(r2 * result < 0)
%00329             r2 *= -1;
%00330         r2 = unit(r2);
%00331         result = TooN::operator*(angle,r2);
%00332     } 
%00333     return result;
%00334 }