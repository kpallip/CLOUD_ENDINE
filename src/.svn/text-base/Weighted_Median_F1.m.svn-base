function [ H, Weights, Perc, WM ] = Weighted_Median_F1( X, p )
%Written By: Vivek Pallipuram on October 9th, 2014
%   Builds a Histogram and returns the weighted median value of X
%   at the desired percentile value: p. Performs necessary interpolation
%   Formula p_i = (100/S_n)*(S_i - W_i/2) where S_N = sum(w)i=1:n and
%   S_i=sum(w)k=1:i. Interpolation formula: (k) + ((p - p(k))/( p(k+1) - p(k) )) * ( (k+1)-(k) );
%   where  p(k) < p < p(k+1)
%   ABOUT WEIGHTS: weight of an element is equal to element-magnitude times
%   frequency
%
%% Build the Histogram and get the weights

lenX = max(X);
H = zeros(lenX, 1);
Weights=zeros(lenX,1);

for i=1:length(X)

    H(X(i))=H(X(i))+1;
   
end

for i=1:lenX

    Weights(i)=H(i)*i;
end

%% Get the percentiles

Perc=zeros(lenX,1);
S_n=sum(Weights);

for i=1:lenX

    S_i=sum(Weights(1:i));
    Perc(i)= (100/S_n)*(S_i - Weights(i)/2);
    
end

%% Interpolate for p

for i=1:lenX

    if (p == Perc(i))
        WM=i;
        break;
    end

    if ( p < Perc(i))
        
        if((i-1)>0)
            
            WM=(i-1) + ((p - Perc(i-1))/(Perc(i) - Perc(i-1)))*((i) - (i-1));
            break;
        else
            WM=i;
            break;
        end
    end
    
end



end

