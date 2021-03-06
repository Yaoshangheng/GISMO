function c=getstat(c)
   
   % c = GETSTAT(c)
   % This routine distills the results of a cross correlation into statistics
   % by trace. These statistics are stored in an Mx? matrix in the STAT field
   % of the correlation object, where M is the number of traces. See help
   % correlation for description of individual statisitics columns within the
   % STAT field. See Vandecar and Crosson (BSSA 1990) for details of how these
   % statistics are calculated.
   %
   % Note that statistics determined from the maximum cross correlation values
   % are transformed to z space to determine the mean and rms error and then
   % transformed back for presentation, where
   %
   %   z = 1/2 * log ( (1+r) / (1-r) ) r = (exp(2*Z)-1)./(exp(2*Z)+1)
   %
   % This is done because the cross correlation value is bounded by 1 on the
   % high side and not normally distributed. Fisher's transform (z) translates
   % the correlation values into a space where they have a roughly normal
   % distribution. The implimentation here is a slight approximation because
   % the matrix of maximum correlations contains the diagonal values of one
   % where each trace is compared against itself. GETSTAT makes an
   % approximation to remove this bias. For very small numbers of traces, this
   % approach may break down. But then, for small numbers of the traces, the
   % statistics aren't terribly valid anyway.
   %
   % The least squares inversion in this routine bogs down quickly when
   % operating on more than a few hundred traces.
   
   
   % Author: Michael West, Geophysical Institute, Univ. of Alaska Fairbanks
   % $Date$
   % $Revision$
   % TODO: needs better handling of xcorr=1 values (MEW - 11/20/06)
   
   if isempty(c.corrmatrix)
      error('CORR and LAG fields must be filled in input object.\nSee xcorr function');
   end
   
   
   % GET MEAN AND STD OF MAX. CROSS CORRELATION (EQ. 4)
   Ztmp = c.corrmatrix - 0.3*eye(size(c.corrmatrix));
   Z = 0.5 * log((1+Ztmp)./(1-Ztmp));
   Zmean = mean(Z);
   Zrmshi = mean(Z) + std(Z);
   Zrmslo = mean(Z) - std(Z);
   Rmean = (exp(2*Zmean)-1)./(exp(2*Zmean)+1);
   Rrmshi = (exp(2*Zrmshi)-1)./(exp(2*Zrmshi)+1);
   Rrmslo = (exp(2*Zrmslo)-1)./(exp(2*Zrmslo)+1);
   
   
   
   % BUILD A AND dT
   nTraces = size(c.corrmatrix,1);
   m = nTraces*(nTraces-1)/2+1;
   A = sparse(m,nTraces);
   A(m,:) = 1;
   dT = zeros(m,1);
   W = speye(m);
   I = zeros(m,1);
   J = zeros(m,1);
   count = 0;
   for p = 1:nTraces-1
      for q = (p+1):nTraces
         count = count + 1;
         A(count,p) = 1;
         A(count,q) = -1;
         dT(count) = c.lags(p,q);
         W(count,count) = c.corrmatrix(p,q);
      end;
   end;
   
   
   
   % INVERT FOR Test
   T = inv( A' * A ) * A' * dT;			% unweighted
   %Tw = inv( A' * W * A ) * A' * W * dT;		% weighted
   
   
   
   % ESTIMATE RESIDUALS, STD
   for p = 1:nTraces
      for q = 1:nTraces
         res(p,q) = c.lags(p,q) - ( T(p) - T(q) );	%eq. 7
      end;
   end;
   Trms = std(res)';		% ~eq. 8
   
   
   c.stat(:,1) = Rmean;
   c.stat(:,2) = Rrmshi;
   c.stat(:,3) = Rrmslo;
   c.stat(:,4) = -1*T;
   c.stat(:,5) = Trms;
end



