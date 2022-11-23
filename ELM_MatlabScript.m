% Embryonic Lineaging in Matlab (ELM)
% by Kira L. Heikes
% Goldstein Lab at UNC-Chapel Hill
% published in: 
% code deposited in Github at: https://github.com/kiraheikes/ELM

% originally made to plot embryonic lineage of the tardigrade Hypsibius
% exemplaris

% can apply to other animal embryos using lineage data that names cells by
% division orientation (anterior, posterior, dorsal, ventral, left, right,
% or a,p,d,v,l,r for short)

% this program relies on data stored in an excel spreadsheet with the
% following organization of three columns:
% rows of cells, each with their cell ID, branch length (mean time point
% from multiple replicates), and error bar values (standard deviation from
% the mean) organized into columns - and number of replicates in a fourth
% column if you choose to have this printed on the lineage

% IMPORTANT: the first row of data must be the cell initializing the
% lineage. I used 'O' as the CellID string to identify this initial cell
% but you can use any string you would like and the script will still work
% all subsequent cell data must be in relative cell stage order but does
% not need to be in temporal order (reach out to me if this is confusing)


% pull data from excel spreadsheet
[~,CellID] = xlsread('filename.xlsx',sheetNumber,'range:range'); % all cell IDs - the first column in your excel spreadsheet
BranchLength = xlsread('filename.xlsx',sheetNumber,'range:range'); % all mean cell division times (or internalization/node termination times) - the second column in your excel spreadsheet
ErrorBars = xlsread('filename.xlsx',sheetNumber,'range:range'); % all error bars (standard deviation from mean) - the third column in your excel spreadsheet
% NumReps = xlsread('filename.xlsx',sheetNumber,'range:range'); % optional replicate data for each mean division - if using, un-comment code related to printing replicate data below; this will be the fourth column in your excel spreadsheet


% specify special cell-types - change the strings in these arrays to specify cells of interest to you
redCells = {'A','AV','AVP','AVPp','AVPpp','AVPppp','AVPppa'}; % array of cell IDs that should be labelled with a red circle - you can edit this color in the DrawCircle function at the bottom of the script
orangeCells = {'P','PV','PVA','PVAa','PVAaa','PVAaaa','PVAaap'}; % array of cell IDs that should be labelled with an orange circle - you can edit this color in the DrawCircle function at the bottom of the script
internalizationCells = {'AVPppp','AVPppa','PVAaaa','PVAaap'}; % array of cell IDs that internalize and are no longer traced after this time

% pull data from above-defined arrays to populate more useful arrays
ParentID = cellfun(@(S) S(1:end-1), CellID, 'Uniform', 0); % all parent cell IDs
for H = 1:length(CellID)
    if strcmp(CellID(H),{'A'})==1 || strcmp(CellID(H),{'P'})==1
        ParentID(H) = CellID(1);
    end
end

DivisionLabel = cellfun(@(x) x(end:end),CellID,'un',0); % all Division Labels

DivisionSide = zeros(1,length(DivisionLabel)); % initialize array of DivisionSide data
for M = 1:length(DivisionLabel)
    if ismember(DivisionLabel(M),CellID(1))==1
        DivisionSide(1,M) = 0; % initiates the lineage
    elseif ismember(DivisionLabel(M),{'a','l','d','A','L','D'})==1
        DivisionSide(1,M) = 1; % left-side daughter of division
    elseif ismember(DivisionLabel(M),{'p','r','v','P','R','V'})==1
        DivisionSide(1,M) = 2; % right-side daughter of division
    else
        DivisionSide(1,M) = 3; % division orientation unknown
    end
end
DivisionSide = DivisionSide'; % transpose DivisionSide array

EventType = zeros(1,length(CellID)); % initialize array of EventType data
for L = 1:length(CellID)
    if ismember(CellID(L),internalizationCells)==1
        EventType(L) = 3; % terminate node with grey dotted line because cells internalize and are no longer traced
    elseif strcmp(CellID(L),CellID(1))==1
        EventType(L) = 1; % lineage initialization
    elseif ismember(CellID(L),ParentID)==1
        EventType(L) = 2; % division
    else
        EventType(L) = 4; % terminate with grey dotted line because no more data
    end
    
end
EventType = EventType'; % transpose EventType array

CellStage = zeros(1,length(CellID)); % initialize array of CellStage data
for K = 1:length(CellID)
    if strcmp(CellID(K),CellID(1))==1
        CellStage(K) = 1; % 1-cell stage
    else
        CellStage(K) = 2^strlength(CellID(K)); % keeps track of which round of division (even if divisions are not in unison, this value works)
    end
end
CellStage = CellStage'; % transpose CellStage array

% initialize the plot for graphing the lineage data
figure % set-up plot
axis([-4.5 75.5 -40 660]) % set axis ranges
set(gca,'Ydir','reverse') % reverse y-axis so timeline of divisions goes from zero minutes down through time
set(gca,'YAxisLocation','right') % y-axis positioned on righthand side
ylabel('minutes after first division') % y-axis label
set(gca,'color','w','XTick',[]) % remove x-axis tick marks
yticks(-20:20:660) % set labelled y-axis (time) tick marks

hold on % plot all of the following on the same figure

% Initiate variables
numberDivisions = sum(EventType == 1 | EventType == 2); % calculate number of divisions
dendrogramWidth = 71; % establish dimensions of lineage (spacing to plot each division is set in the code below)
parentArray = cell(1,numberDivisions); % storing parent IDs of each cell
leftArray = zeros(1,numberDivisions); % storing x-position of left-hand daughter cell after each division
rightArray = zeros(1,numberDivisions); % storing x-position of right-hand daughter cell after each division
errorX = zeros(1,numberDivisions); % storing x-position of division events for plotting error bars in order
errorY = zeros(1,numberDivisions); % storing y-position of division events for plotting error bars in order
errorValues = zeros(1,numberDivisions); % storing standard deviation from mean for each division event in order
tick = 1; % keep track of order of cell division events (type 1 and 2)
xCellLabel = 1; % x-position of the division orientation label for each side of each division
yCellLabel = 1; % y-position of the division orientation label for each side of each division
xrep = 1; % x-position of the number of replicates of data for each mean division
yrep = 1; % y-position of the number of replicates of data for each mean division


% plot the division and internalization events
for S = 1:1:length(CellID) % for all cells in the CellID array
    if EventType(S) == 1 % initiation of lineage
        yLower = 0;
        yUpper = -10;
        xParent = round(dendrogramWidth/2,0);
        xLeft = 0.5*xParent;
        xRight = 1.5*xParent;
        parentArray(tick) = CellID(S);
        leftArray(tick) = xLeft;
        rightArray(tick) = xRight;
        errorX(tick) = xParent;
        errorY(tick) = yLower;
        errorValues(tick) = ErrorBars(S);
        tick = tick+1;
        drawVerticalLine(xParent,yUpper,yLower,1); % vertical solid black line
        drawHorizontalLine(xLeft,xRight,yLower,1); % horizontal solid black line
        
    elseif EventType(S) == 2 % cell division event
        index = find(strcmp(CellID, ParentID(S)));
        yUpper = BranchLength(index);
        yLower = BranchLength(S);
        parentIndex = find(strcmp(parentArray, ParentID(S)));
        if DivisionSide(S) == 1
            xParent = leftArray(parentIndex);
            xCellLabel = xParent-.25;
            yCellLabel = yUpper-15;
            xrep = xParent;
            yrep = yLower+15;
        elseif DivisionSide(S) == 2
            xParent = rightArray(parentIndex);
            xCellLabel = xParent-0.25;
            yCellLabel = yUpper-15;
            xrep = xParent-.025;
            yrep = yLower+15;
        elseif DivisionSide(S) == 3
            xParent = NaN;
        end
        
        xLeft = xParent-(dendrogramWidth/(4*CellStage(S)))+(0.03*(log(71)/log(CellStage(S))));
        xRight = xParent+(dendrogramWidth/(4*CellStage(S)))-(0.03*(log(71)/log(CellStage(S))));
        
        parentArray(tick) = CellID(S);
        leftArray(tick) = xLeft;
        rightArray(tick) = xRight;
        errorX(tick) = xParent;
        errorY(tick) = yLower;
        errorValues(tick) = ErrorBars(S);
        tick = tick+1;
        if isnan(xParent)
            drawVerticalLine(leftArray(parentIndex),yUpper,(yUpper+30),2); % vertical grey dotted line
            drawVerticalLine(rightArray(parentIndex),yUpper,(yUpper+30),2); % vertical grey dotted line
        else
            drawVerticalLine(xParent,yUpper,yLower,1); % vertical black line
            drawHorizontalLine(xLeft,xRight,yLower,1); % horizontal black line
            labelDivision(xCellLabel,yCellLabel,DivisionLabel(S)); % label the cell with division orientation
            % text(x_rep,y_rep,string(NumReps(S)),'FontSize', 6, 'Color', [0.4 0.4 0.4]) % label the cell with number replicates
        end
        
        if (ismember(CellID(S),redCells)==1)
            drawCircle(xParent,yUpper,1); % plot a red colored circle over this spot
        elseif (ismember(CellID(S),orangeCells)==1)
            drawCircle(xParent,yUpper,2); % plot an orange colored circle over this spot
        end
        
    elseif EventType(S) == 3 % cell internalization event
        index = find(strcmp(CellID, ParentID(S)));
        yUpper = BranchLength(index);
        yLower = BranchLength(S);
        parentIndex = find(strcmp(parentArray, ParentID(S)));
        if DivisionSide(S) == 1
            xParent = leftArray(parentIndex);
            xCellLabel = xParent;
            yCellLabel = yUpper-15;
        elseif DivisionSide(S) == 2
            xParent = rightArray(parentIndex);
            xCellLabel = xParent-0.25;
            yCellLabel = yUpper-15;
        elseif DivisionSide(S) == 3
            xParent = NaN;
        end
        drawVerticalLine(xParent,yUpper,(yUpper+60),2); % vertical grey dotted line
        
        if (ismember(CellID(S),redCells)==1)
            drawCircle(xParent,yUpper,1); % plot a red colored circle over this spot
        elseif (ismember(CellID(S),orangeCells)==1)
            drawCircle(xParent,yUpper,2); % plot an orange colored circle over this spot
        end
        labelDivision(xCellLabel,yCellLabel,DivisionLabel(S)); % label the cell with division orientation
        
    elseif EventType(S) == 4 % no more divisions/end of cell tracing
        index = find(strcmp(CellID, ParentID(S)));
        yUpper = BranchLength(index);
        parentIndex = find(strcmp(parentArray, ParentID(S)));
        if DivisionSide(S) == 1 % cell is anterior or dorsal
            xParent = leftArray(parentIndex);
            xCellLabel = xParent-0.2;
            yCellLabel = yUpper-13;
        elseif DivisionSide(S) == 2 % cell is posterior or ventral
            xParent = rightArray(parentIndex);
            xCellLabel = xParent-0.125;
            yCellLabel = yUpper-13;
        elseif DivisionSide(S) == 3 % no more divisions along this node
            xParent = NaN;
            yCellLabel = yUpper-13;
        end
        if isnan(yUpper)
            
        elseif isnan(xParent)
            drawVertialLine(leftArray(parentIndex),yUpper,(yUpper+20),2); % vertical dotted grey line
            drawVerticalLine(rightArray(parentIndex),yUpper,(yUpper+20),2); % vertical dotted grey line
            
            labelDivision(leftArray(parentIndex)-.25,yCellLabel,DivisionLabel(S)); % label the cell
            labelDivision(rightArray(parentIndex)-.125,yCellLabel,DivisionLabel(S)); % label the cell
        else
            drawVerticalLine(xParent,yUpper,(yUpper+20),2); % vertical dotted grey line
            
            labelDivision(xCellLabel,yCellLabel,DivisionLabel(S)); % label the cell with division orientation
        end
    end
end

hold on % plot error bars on same graph

% plot error bar data
er = errorbar(errorX(2:123),errorY(2:123),errorValues(2:123)); % plot standard deviation from each mean division or internalization event at the X and Y positions recorded for each
er.Color = [0.27 0.61 0.84 0.8]; % set the color and opacity for the error bars
% er.LineWidth = 0.5; % optional set the width of the error bars
er.LineStyle = 'none'; % set the linestyle of the error bars

saveas(gcf, 'test.png'); % save the plot with specified name in same folder as script

function drawHorizontalLine(xInput1,xInput2,yInput,style) % function to plot a horizontal line of specified style
if style==1 % solid black line
    plot([xInput1 xInput2],[yInput yInput],'k')
elseif style==2 % dotted grey line
    plot([xInput1 xInput2],[yInput yInput],'--','color',[0.6 0.6 0.6])
else % solid black line
    plot([xInput1 xInput2],[yInput yInput],'k')
end
end

function drawVerticalLine(xInput,yInput1,yInput2,style) % function to plot a vertical line of specified style
if style==1 % solid black line
    plot([xInput xInput],[yInput1 yInput2],'k')
elseif style==2 % dotted grey line
    plot([xInput xInput],[yInput1 yInput2],'--','color',[0.6 0.6 0.6])
else % solid black line
    plot([xInput xInput],[yInput1 yInput2],'k')
end
end

function labelDivision(xInput,yInput,DivisionLabel) % function to label a division event with text
text(xInput,yInput,DivisionLabel,'FontSize', 6, 'Color', [0.4 0.4 0.4])
end

function drawCircle(xInput,yInput,color) % function to label specific cells with a colored circle
if color==1 % red circle
    scatter(xInput,yInput,50,'MarkerFaceColor','#710e2d','MarkerEdgeColor','#710e2d','MarkerFaceAlpha',.28) % plot a red colored circle over this spot
elseif color==2 % orange circle
    scatter(xInput,yInput,50,'MarkerFaceColor','#db6551','MarkerEdgeColor','#db6551','MarkerFaceAlpha',.28) % plot an orange colored circle over this spot
end

end