function [spin] = calcPlasticSpin(gmatrix,e_ext,A,c,tol,maxit)

%%

% While ~isempty(gmatrix)

DCMtrx = matrix(gmatrix);
% DCMtrx = DC_matrix_function(gvector(1),gvector(2),gvector(3));
[e_grain]= transform_e_function(e_ext,DCMtrx);
b = [e_grain(1,1);e_grain(2,2);2*e_grain(2,3);2*e_grain(1,3);2*e_grain(1,2)]; 



%%
[m,n]=size(A); b=b(:); c=c(:); it=0; 
if (length(c)~=n || length(b)~=m),error('wrong dimensions'); end
D=sign(sign(b)+.5); 
D = diag(D);                    % initial (inverse) basis matrix
A = [A D];                      % incorporate slack/artificial variables.Utilizing 2 phase method

%%
B = n+1:n+m;                    
N = 1:n;                        
phase=1; xb=abs(b); s=[zeros(n,1);ones(m,1)];   % supercost 

%%
while phase<3,
   df=-1; t=inf;
   yb= D'*s(B);  
   while (it < maxit)
      if isempty(N), break, end     % no freedom for minimization
      r = s(N) - [A(:,N)]'*yb;      % Transpose both sides to get the standard form of this equation
      [rmin,q] = min(r);            % determine minimum of reduced cost % if reduced cost is zero,
                                    %there is no improvement i.e. another optimal solution
      if rmin>=-tol*(norm(s(N),inf)+1), break, end % optimal!            
      it=it+1;
      if df>=0                      % apply Bland's rule to avoid cycling
         if maxit==inf,
            disp(['LINPROG(',int2str(it),'): warning! degenerate vertex']);
         end
         J=find(r<0); Nq=min(N(J)); q=find(N==Nq); % This line gets the first most column in NB which gives a -ve reduced cost. 
                                    % q is the location of that column in N                                                                                                     
      end 
      d = D*A(:,N(q)); % Descent Direction: d = -inv(B)*Nq.If dq >= 0, then the linear program is unbounded. Here d<=0 =>unbounded
      I=find(d>tol); %find out the entry no of those d values which are -ve
      if isempty(I), disp('Solution is unbounded'); it=-it; break; end
      xbd=xb(I)./d(I); [r,p]=min(xbd); p=I(p); % r is the step length alpha, p is position of that alpha, p will be going out
      if df>=0,                     % apply Bland's rule to avoid cycling
         J=find(xbd==r); Bp=min(B(I(J))); p=find(B==Bp); 
      end 
      xb= xb - r*d; xb(p)=r;        % update x, bsic var xb(p) is replaced with alpha 
      df=r*rmin;                    % change in f 
      v = D(p,:)/d(p);              % row vector
      yb= yb + v'*( s(N(q)) - d'*s(B) );
      d(p)=d(p)-1;
      D = D - d*v;                  % update inverse basis matrix
      t=B(p); B(p)=N(q); % pth column of B is replaced with qth column of N. q is the one with minimum reduced cost. it has come in. 
      if t>n+k, N(q)=[]; else N(q)=t; end %The pth column of B is brought into N.
                                          %If t was artificial var then one col of N is reduced:single phase
   end                             % end of phase
   xb=xb+D*(b-A(:,B)*xb);          % iterative refinement
   I=find(xb<0);                   % must be due to rounding error
   if I, xb(I)=xb(I)-xb(I); end    % so correct
   if phase==2 || it<0, break; end; % B, xb,n,m,res=A(:,B)*xb-b %| changed to ||
   if xb'*s(B)>tol,it=-it; disp('no feasible solution'); break;  end % if 
   phase=phase+1;                  % Go to Phase 2
   s=1e6*norm(c,'inf')*s; s(1:n)=c;% tol=tol*norm(s,inf);
end
x=sparse(n,1); x(B)=xb; x=x(1:n); if n<21, x=full(x); end
fval=c'*x;
if it>=maxit, disp('too many iterations'); it=-it; end

OP.B = B; OP.N = N; OP.D = D; OP.r = r;
        OP.xb = xb; OP.yb = yb; OP.M = sum(xb);OP.s=s;
        
%%

TaylorSolution = treeSol_function(OP,A,b);
minVar = find(min(var(TaylorSolution.xb));


