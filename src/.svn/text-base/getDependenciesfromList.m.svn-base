function str=getDependenciesfromList(ROW)

d=size(ROW);



str='';

flag=0;

for i=1:d(2)
    if ROW(i)>-1000 && flag==1
        str=strcat(str,':',num2str(ROW(i)));
    elseif ROW(i)>-1000 && flag==0
        str=num2str(ROW(i));
        flag=1;
    elseif ROW(i)==-1000
        break;
    end
end
     
