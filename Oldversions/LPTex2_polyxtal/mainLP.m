tic
clear

%%

% load('SlipSystem24.mat','SlipSystem'); 


prompt = 'The euler angle file name with .txt extension \n';
g_file = input(prompt);                      
g = fopen(g_file);   
g_matrix = textscan(g, '%f %f %f'); 
fclose(g);
% gmatrix = euler2quat(g_matrix{1,1}*degree,g_matrix{1,2}*degree,g_matrix{1,3}*degree,'Bunge'); 
gmatrix0 = rotation('Euler',[g_matrix{1,1},g_matrix{1,2},g_matrix{1,3}]*degree);
gmatrix = gmatrix0;
lg =  length(gmatrix);
e_ext= [1,0,0;0,0,0;0,0,-1];
b = zeros(5,lg);
max_strain = 1;
incr_e = 0.05; % incremental strain per step
n_steps = max_strain/incr_e;
new_gmatrix = gmatrix;
for j=1:1:n_steps+1
    if j==1, new_gmatrix(:,j) = gmatrix; continue; end
for i=1:1:lg, 
    DCMtrx = (matrix(gmatrix(i)))'; % Checked it. MTex returns axis transformation dcm not the component, that is why transpose 
    e_grain=DCMtrx*e_ext*DCMtrx';
    b = [e_grain(1,1);e_grain(2,2);2*e_grain(2,3);2*e_grain(1,3);2*e_grain(1,2)]; 
    spin = calcPlasticSpin(b);
    spin.min = incr_e*spin.min; %There is no need to put - spin as it already calculates -ve spin. it does n*diad*b so SS.q is -ve of anti(bdiadn)
    rotmin = rotation('matrix',spin.min);
    gmatrix(i) = rotmin*gmatrix(i);
%     gmatrix(i) = gmatrix(i)*rotmin;
% %     For max spin
%     rotmax = rotation('matrix',spin.max);
%     gmatrix(i) = rotmax*gmatrix(i);

    new_gmatrix(i,j) = gmatrix(i);
    
end
end
toc
        