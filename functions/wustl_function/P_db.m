function Pdb = P_db( dbname, params )



%Get pitch and yaw information
info = parse_WUSTL_cutoutname(dbname);
floorname = strsplit(dbname, '/');floorname = floorname{end-2};

%[R, t] for conversion of scan coordinate to panoramic coordinate
R_s2p = [0, 1, 0; 0, 0, -1; -1, 0, 0];
t_s2p = [0; 0; 0];

%[R, t] for conversion of panoramic coordinate to camera (DB perspective) coordinate
R_p2c = R_rpy(0, info.phi, info.theta);
t_p2c = [0; 0; 0];

%Obj: [R, t] for conversion of floor coordinate to camera coordinate
%conversion: floor -> scan -> panorama -> camera (DB perspective) 

%1. [R, t] for conversion of scan coordinate to camera coordinate
[R_s2c, t_s2c] = extrinsic_coordtrans(R_p2c, t_p2c, R_s2p', -R_s2p'*t_s2p, 1);

%2. [R, t] for conversion of floor coordinate to camera coordinate
[R_f2c, t_f2c] = extrinsic_coordtrans(R_s2c, t_s2c, R_s2f, t_s2f);

Pdb = [R_f2c, t_f2c];

end

