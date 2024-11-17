
function taskTracker()
    delete(timerfindall()) % delete old timers
    period = 15*60; % 15 minute timer
    timerWithEditorActivity( period )
end

function timerWithEditorActivity( period )

    promptTimer = timer('ExecutionMode', 'fixedRate', 'Period', period, ...
               'TimerFcn', @(t,~)runScriptIfActive(t,period),'Name','focus_prompt');
    start(promptTimer);

    % Store the timer object in the base workspace
    assignin('base', 'promptTimer', promptTimer);
end

function runScriptIfActive(t,period)
    % Check if matlab editor is currently the selected window
    editorActive = com.mathworks.mde.desk.MLDesktop.getInstance.getMainFrame.isActive;
    if editorActive
        taskPrompt(t,period)
        %parfeval(taskPrompt(period), 0);
    else
        disp("Didn't run timer due to inactive editor")
    end
end

function taskPrompt(t,period)
    tic
    % first delete old pomo timers, in case they haven't stopped
    old = timerfindall('Name','pomodoro');
    stop(old)
    delete(old)

    % find last time's task
    taskTable = load('taskData.mat').taskTable;
    lastTask = taskTable.Task(end);

    % then prompt for user input
    Q1 = strcat("The most important thing was ", lastTask, '. Did you do it? Y/N');
    Q2 = 'What is the most important thing to do next?';

    response = inputdlg({Q1,Q2},'Focus Check',1,{'',''});
    
    if isempty(response)
        % cancel pressed- stop timer
        stop(t)
    else

        taskDone = strcmpi(response{1},'y');
        nextTask = response{2};

        taskTable.Complete(end) = taskDone;
        taskTable(end+1,:) = {datetime('now'), nextTask, false};
        save("taskData.mat","taskTable")
        
        timePrompt = toc;
        
        duration = period-timePrompt;
    
        if duration<0
            duration = period;
        end

        % then start new pomodoro
        pomoTimer = timer('ExecutionMode', 'fixedRate', 'Period', 1, ...
                   'TimerFcn', @(t,~)drawPomo(t,nextTask,duration),...
                   'TasksToExecute',duration,'StopFcn',@(t,~)delete(t),...
                   'Name','pomodoro');
        start(pomoTimer);
    
        %drawPomoBlocking(nextTask,duration)
    end

end

function drawPomo(timer, taskLabel, duration)

    fractionRemaining = 1 - timer.TasksExecuted/timer.tasksToExecute;

    hFig = findobj('Type', 'figure', 'Tag', 'pomodoro');
    if isempty(hFig) % only create new figure if earlier figure isn't there
        hFig = figure('WindowStyle', 'Docked','Tag','pomodoro');
    end

    clf(hFig)
    hAx = axes('Parent', hFig);

    angleResolution = 100; % number of xy points per arc on figure

    angle = 2*pi*linspace(0,fractionRemaining,angleResolution);
    x = [0 -sin(angle)];
    y = [0 cos(angle)];
    fill(hAx, x,y,'g');
    axis equal
    xlim([-1 1])
    ylim([-1 1])
    timeRemaining = datetime(0, 1, 1, 0, 0, duration*fractionRemaining);
    xlabel(hAx,['Time remaining: ' datestr(timeRemaining,'MM:SS')])
    title(taskLabel)
end
