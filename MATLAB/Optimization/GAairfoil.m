function [AAoriginal,AAfittest,fittest,fitness]=GAairfoil(genNo,p0,range)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%this function runs a genetic algorithm on the 11 PARSEC parameters.
%The fitness is the cross-sectional AREA of the airfoil (airenaca), not an
%aerodynamic coefficient: the GA keeps the individuals with the smallest
%area, individuals larger than the original are clamped to the original
%area, and shapes with maximum thickness above 0.12 or below 0.01 are
%rejected. The result is therefore a thinner airfoil.
%genNo      number of generations to mate
%p0         Original airfoil to optimize
%range      Randomizer range to vary the PARSEC parameters
%
%Source: reference implementation used in El Houd & Hallou (2022),
%"Optimization study of NACA airfoil using nonlinear programming & genetic
%algorithms" (ref. [5] of the project report).
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%genetic parameters
[AAoriginal,~]=airenaca(p0);
popsize=40;  %population size
transprob=0.05;  %transcendence percentage 
crossprob=0.75;    %cross over percentage
mutprob=0.2;       %mutation percentage
newpop=[];
fitness=[];
for k=1:genNo
AA=[];
p=[];
%population evaluation (starting from the second generation)
for i=1:length(newpop)
    p1=newpop(i,:);
    [AAnew, ~]=airenaca(p1);  %fitness evaluation
    AA=[AA;AAnew];
    p=[p;p1];
end
%first population initialization
for i=1:popsize-length(newpop)
    p1=randp(p0,range);
    [AAnew, maxThickness]=airenaca(p1); %fitness evaluation
     %geometric constrain
    if maxThickness>0.12
        AAnew=AAoriginal;
    elseif maxThickness<0.01  
        AAnew=AAoriginal;
    end
    AA=[AA;AAnew];
    p=[p;p1];
end
pop=p;
%constraining the surface
for i=1:length(AA)
if AA(i)>=AAoriginal
        AA(i)=AAoriginal;
end
end
%sorting the individuals by the fittest
fitness=[fitness, max(AA./sum(AA))];

fi=AA./sum(AA);
[fittest,ind]=sort(fi,'ascend');
fittest=fittest(1:ceil(transprob*popsize));
ind=ind(1:ceil(transprob*popsize));
if k~=genNo
    newpop=pop(ind,:);
    %crossover
    for i=1:ceil(crossprob*popsize)
        indv1=randi([1,popsize],1);
        indv2=randi([1,popsize],1);
        crossindex=randi([1,11],1);
       newpop=[newpop;pop(indv1,1:crossindex) pop(indv2,crossindex+1:end)];
    end
    %mutation
    for i=1:ceil(mutprob*popsize)
        indv=pop(randi([1,popsize],1),:);
        mutindex=randi([1,11],1);
        pmut=randp(p0,range);
        indv(mutindex)=pmut(mutindex);
        newpop=[newpop;indv];
    end
end

end

%choosing the tournemnt winner or the most evolved individual
fittest=pop(ind(1),:);
AAfittest=AA(ind(1));
if AAfittest==AAoriginal
    fittest=p0;
end

x=[1:length(AA)];
%plotting the original airfoil vs. the optimized
plotairfoil(fittest,'k')
hold on
plotairfoil(p0,'r')
legend('Optimized','original')
xlabel('X/C')
ylabel('Y/C')
title('Airfoil shape')

end