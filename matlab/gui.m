function varargout = gui(varargin)
% GUI MATLAB code for gui.fig
%      GUI, by itself, creates a new GUI or raises the existing
%      singleton*.
%
%      H = GUI returns the handle to a new GUI or the handle to
%      the existing singleton*.
%
%      GUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in GUI.M with the given input arguments.
%
%      GUI('Property','Value',...) creates a new GUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before gui_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to gui_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help gui

% Last Modified by GUIDE v2.5 08-Mar-2013 01:20:21

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @gui_OpeningFcn, ...
                   'gui_OutputFcn',  @gui_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT

function update_sim_plot(handles)

X = getappdata(handles.stuff, 'DATA');
if isempty(X); return; end;

setappdata(handles.stuff, 'drawing', true);

axes(handles.sim_out);
S = getappdata(handles.stuff, 'TREE');
f = getappdata(handles.stuff, 'curframe');
colors = 'bgrk';
cla;
hold on;
for j = 1:length(S)
    if size(X,3) == 3
        % 2D
        plot([X(f,S(j).a, 1,3), X(f,S(j).b, 1,3)], ...
             [X(f,S(j).a, 2,3), X(f,S(j).b, 2,3)], ...
             [colors(mod(j-1,4)+1) '.-']);
        quiver([X(f,S(j).a, 1,3), X(f,S(j).b, 1,3)], ...
               [X(f,S(j).a, 2,3), X(f,S(j).b, 2,3)], ...
               [X(f,S(j).a, 1,1), X(f,S(j).b, 1,1)], ...
               [X(f,S(j).a, 2,1), X(f,S(j).b, 2,1)], ...
               0.2, colors(mod(j-1,4)+1));
    else
        % 3D
        plot3([X(f,S(j).a, 1,4), X(f,S(j).b, 1,4)], ...
              [X(f,S(j).a, 2,4), X(f,S(j).b, 2,4)], ...
              [X(f,S(j).a, 3,4), X(f,S(j).b, 3,4)], ...
              [colors(mod(j-1,4)+1) '.-']);
        quiver3([X(f,S(j).a, 1,4), X(f,S(j).b, 1,4)], ...
                [X(f,S(j).a, 2,4), X(f,S(j).b, 2,4)], ...
                [X(f,S(j).a, 3,4), X(f,S(j).b, 3,4)], ...
                [X(f,S(j).a, 1,1), X(f,S(j).b, 1,1)], ...
                [X(f,S(j).a, 2,1), X(f,S(j).b, 2,1)], ...
                [X(f,S(j).a, 3,1), X(f,S(j).b, 3,1)], ...
                0.2, colors(mod(j-1,4)+1));
    end
end
hold off;
axis(repmat([-5 5], 1, size(X,3)-1));

setappdata(handles.stuff, 'drawing', false);

function advance_sim(handles)

f = getappdata(handles.stuff, 'curframe');
frames = getappdata(handles.stuff, 'frames');
animdir = getappdata(handles.stuff, 'animdir');
f = f + animdir;
if f > frames
    animdir = -1;
    f = frames - 1;
elseif f < 1
    animdir = 1;
    f = 2;
end
setappdata(handles.stuff, 'animdir', animdir);
setappdata(handles.stuff, 'curframe', f);
set(handles.curframe, 'Value', (f-1)/(frames-1));
update_sim_plot(handles);

function change_tree(handles, S)

past = getappdata(handles.stuff, 'TREE_past');
past{end+1} = getappdata(handles.stuff, 'TREE');
setappdata(handles.stuff, 'TREE_past', past);
setappdata(handles.stuff, 'TREE_future', {});
setappdata(handles.stuff, 'TREE', S);
if isappdata(handles.stuff, 'DATA')
    rmappdata(handles.stuff, 'DATA'); % hard to say whether the data was invalidated, so... assume it was
end
populate_joint_panel(handles, 'Design');

function reset_tree(handles)

change_tree(handles, struct('a', {1}, 'b', {2}, 'joint', {'rigid'}, 'params', {{T(1:getappdata(handles.stuff, 'dims'))}}, 'state', {0}, 'bounds', {[0;0]}));
select_joint(handles, 1, 'Design');

% --- Executes just before gui is made visible.
function gui_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to gui (see VARARGIN)

% Choose default command line output for gui
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% initialize internal state
% all of the gui's state is going to stored in the properties of this static text control
setappdata(handles.stuff, 'joint', 1);
setappdata(handles.stuff, 'dims', 3); % TODO: load these from the uicontrols
setappdata(handles.stuff, 'fudge', 1);
setappdata(handles.stuff, 'frames', 50);
setappdata(handles.stuff, 'curframe', 1);
setappdata(handles.stuff, 'animdir', 1);
setappdata(handles.stuff, 'drawing', false);
setappdata(handles.stuff, 'TREE_past', {});
reset_tree(handles);
setappdata(handles.stuff, 'TREE_past', {}); % clear undo state so the empty tree isn't an option
setappdata(handles.stuff, 'TREE_future', {});

% UIWAIT makes gui wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = gui_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on slider movement.
function curframe_Callback(hObject, eventdata, handles)
% hObject    handle to curframe (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider

pct = get(hObject, 'Value');
frames = getappdata(handles.stuff, 'frames');
setappdata(handles.stuff, 'curframe', round(pct*(frames-1)+1));
update_sim_plot(handles);

% --- Executes during object creation, after setting all properties.
function curframe_CreateFcn(hObject, eventdata, handles)
% hObject    handle to curframe (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


function change_dims(handles, D)

if exist('D', 'var')
    % caller wants to programmatically change the dropdown
    set(handles.dims, 'Value', find(strcmp(get(handles.dims, 'String'), num2str(D))));
else
    % caller is the callback; dropdown has been changed by user
    D = str2double(subsref(get(handles.dims, 'String'), substruct('{}', {get(handles.dims, 'Value')})));
end

setappdata(handles.stuff, 'dims', D);
reset_tree(handles);

% --- Executes on selection change in dims.
function dims_Callback(hObject, eventdata, handles)
% hObject    handle to dims (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

change_dims(handles);


% --- Executes during object creation, after setting all properties.
function dims_CreateFcn(hObject, eventdata, handles)
% hObject    handle to dims (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function nodes_Callback(hObject, eventdata, handles)
% hObject    handle to nodes (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of nodes as text
%        str2double(get(hObject,'String')) returns contents of nodes as a double


% --- Executes during object creation, after setting all properties.
function nodes_CreateFcn(hObject, eventdata, handles)
% hObject    handle to nodes (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function frames_Callback(hObject, eventdata, handles)
% hObject    handle to frames (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of frames as text
%        str2double(get(hObject,'String')) returns contents of frames as a double

setappdata(handles.stuff, 'frames', str2double(get(hObject, 'String')));
set(handles.maxframe, 'String', get(hObject, 'String'));

% --- Executes during object creation, after setting all properties.
function frames_CreateFcn(hObject, eventdata, handles)
% hObject    handle to frames (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in simulate.
function simulate_Callback(hObject, eventdata, handles)
% hObject    handle to simulate (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

S = getappdata(handles.stuff, 'TREE');
dims = getappdata(handles.stuff, 'dims');
frames = getappdata(handles.stuff, 'frames');

ding = getappdata(handles.stuff, 'animating');
if ~isempty(ding) && strcmp(ding.Running, 'on')
    was_running = true;
    stop(ding);
    while true
        if ~getappdata(handles.stuff, 'drawing')
            break;
        end
    end
else
    was_running = false;
end

try
    noise = eval(get(handles.noise, 'String'));
catch
    noise = [0.025 0.05];
end
if ~isreal(noise) || all(size(noise) ~= [1 2])
    noise = [0.025 0.05];
end

X = manip_simulate(dims, max([S.a S.b]), frames, S, noise, eye(dims+1), ~isfield(S, 'trajectory'));
setappdata(handles.stuff, 'DATA', X);
assignin('base', 'DATA', X);
setappdata(handles.stuff, 'simulating', false);
update_sim_plot(handles);

if was_running
    start(ding);
end

% --- Executes on button press in learn.
function learn_Callback(hObject, eventdata, handles)
% hObject    handle to learn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if getappdata(handles.stuff, 'simulating')
    fprintf('Waiting for simulation...\n');
    while true
        if ~getappdata(handles.stuff, 'simulating')
            break;
        end
    end
end

X = getappdata(handles.stuff, 'DATA');
if isempty(X)
    msgbox('Simulate first', 'Error');
    return;
end

learned = manip_learn(X, false);
assignin('base', 'SS', learned);
setappdata(handles.stuff, 'GUESS', learned);
draw_tree(handles.tree_out, learned, 0);

% --- Executes on button press in animate.
function animate_Callback(hObject, eventdata, handles)
% hObject    handle to animate (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

ding = getappdata(handles.stuff, 'animating');
if isempty(ding)
    ding = timer('ExecutionMode', 'fixedRate', ...
                 'Period', 0.2, ...
                 'TimerFcn', @(varargin) advance_sim(handles));
    start(ding);
else
    feval(subsref({@() start(ding), @() stop(ding)}, substruct('{}', {2 - strcmp(get(ding, 'Running'), 'off')})));
end
setappdata(handles.stuff, 'animating', ding);

% --- Executes during object creation, after setting all properties.
function sim_out_CreateFcn(hObject, eventdata, handles)
% hObject    handle to sim_out (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: place code in OpeningFcn to populate sim_out


% --- Executes during object creation, after setting all properties.
function stuff_CreateFcn(hObject, eventdata, handles)
% hObject    handle to stuff (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called


% --- Executes during object creation, after setting all properties.
function tree_in_CreateFcn(hObject, eventdata, handles)
% hObject    handle to tree_in (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: place code in OpeningFcn to populate tree_in

function [params, bounds, state, ok] = edit_joint(joint, dims)

ok = 1;
params = {};
bounds = [];
state = [];

if isa(joint, 'char')
    joint_type = joint;
    default = false;
else
    joint_type = joint.joint;
    default = true;
end

switch joint_type
    case 'rigid'
        answer = inputdlg({'Transform: SE(n)'}, ...
                          'Rigid joint parameters', ...
                          1, ...
                          {feval(subsref({@() format_SE(joint.params{1}), @() format_SE(eye(dims+1))}, substruct('{}', {2 - default})))});
        if isempty(answer); ok = 0; return; end;
        params = {eval(answer{1})};
        bounds = [0; 0];
        state = 0;
        % TODO check types
    case 'prismatic'
        answer = inputdlg({'Transform: SE(n)', ...
                           'Unit vector: R(n)', ...
                           'Bounds: R(2)', ...
                           'Initial state: R'}, ...
                          'Prismatic joint parameters', ...
                          1, ...
                          {feval(subsref({@() format_SE(joint.params{1}), @() format_SE(eye(dims+1))}, substruct('{}', {2 - default}))), ...
                           feval(subsref({@() mat2str(joint.params{2}),   @() mat2str(eye(1,dims))},   substruct('{}', {2 - default}))), ...
                           feval(subsref({@() mat2str(joint.bounds),      @() '[0;0]'},                substruct('{}', {2 - default}))), ...
                           feval(subsref({@() num2str(joint.state),       @() '0'},                    substruct('{}', {2 - default})))});
        if isempty(answer); ok = 0; return; end;
        params = {eval(answer{1}), eval(answer{2})};
        bounds = eval(answer{3});
        state = eval(answer{4});
        % TODO check types
    case 'revolute'
        answer = inputdlg({'Transform: SE(n)', ...
                           'Radius: SE(n)', ...
                           'Bounds: R(2)', ...
                           'Initial state: R'}, ...
                          'Revolute joint parameters', ...
                          1, ...
                          {feval(subsref({@() format_SE(joint.params{1}), @() format_SE(eye(dims+1))}, substruct('{}', {2 - default}))), ...
                           feval(subsref({@() format_SE(joint.params{2}), @() format_SE(eye(dims+1))}, substruct('{}', {2 - default}))), ...
                           feval(subsref({@() mat2str(joint.bounds),      @() '[0;0]'},                substruct('{}', {2 - default}))), ...
                           feval(subsref({@() num2str(joint.state),       @() '0'},                    substruct('{}', {2 - default})))});
        if isempty(answer); ok = 0; return; end;
        params = {eval(answer{1}), eval(answer{2})};
        bounds = eval(answer{3});
        state = eval(answer{4});
        % TODO check types
end


% --- Executes on button press in addjoint.
function addjoint_Callback(hObject, eventdata, handles)
% hObject    handle to addjoint (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


S = getappdata(handles.stuff, 'TREE');
n = max([S.a S.b]);
as = 1:n;
[a, ok] = listdlg('Name', 'Joint from...', ...
                  'PromptString', 'a = ', ...
                  'ListString', cellstr(num2str(as')), ...
                  'SelectionMode', 'single', ...
                  'ListSize', [80 15*(n+1)]);
if ~ok; return; end;
a = as(a);
b = n+1;
joints = {'rigid', 'prismatic', 'revolute'};
[joint, ok] = listdlg('Name', 'Joint type?', ...
                      'ListString', joints, ...
                      'SelectionMode', 'single', ...
                      'ListSize', [80 15*4]);
if ~ok; return; end;
joint = joints{joint};
[params, bounds, state, ok] = edit_joint(joint, getappdata(handles.stuff, 'dims'));
if ~ok; return; end;
S(end+1) = struct('a',{a}, 'b',{b}, 'joint',{joint}, 'params',{params}, 'state',{state}, 'bounds',{bounds});
change_tree(handles, S);
setappdata(handles.stuff, 'joint', length(S));
draw_tree(handles.tree_in, S, getappdata(handles.stuff, 'joint'));

% --- Executes on button press in deljoint.
function deljoint_Callback(hObject, eventdata, handles)
% hObject    handle to deljoint (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

joint = getappdata(handles.stuff, 'joint');
S = getappdata(handles.stuff, 'TREE');

if length(S) == 1
    msgbox('You would leave me without any joints, would you?');
else
    a = S(joint).a;
    b = S(joint).b;
    S = S([1:joint-1 joint+1:end]);
    for i=1:length(S)
        % promote grandchildren to children
        if S(i).a == b
            S(i).a = a;
        end
        
        % remove orphan node
        if S(i).a > b
            S(i).a = S(i).a - 1;
        end
        if S(i).b > b
            S(i).b = S(i).b - 1;
        end
    end

    change_tree(handles, S);
    select_joint(handles, 1, 'Design');
end


% --- Executes on button press in editjoint.
function editjoint_Callback(hObject, eventdata, handles)
% hObject    handle to editjoint (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

joint = getappdata(handles.stuff, 'joint');
S = getappdata(handles.stuff, 'TREE');

[params, bounds, state, ok] = edit_joint(S(joint), getappdata(handles.stuff, 'dims'));
if ~ok; return; end;
S(joint).params = params;
S(joint).bounds = bounds;
S(joint).state = state;
change_tree(handles, S);


function select_joint(handles, i, mode)

switch mode
    case 'Design'
        S = getappdata(handles.stuff, 'TREE');
        jointsel = handles.in_jointsel;
        tree = handles.tree_in;
        joint = 'joint';
    case 'Learned'
        S = getappdata(handles.stuff, 'GUESS');
        jointsel = handles.out_jointsel;
        tree = handles.tree_out;
        joint = 'ljoint';
end

setappdata(handles.stuff, joint, i);
set(jointsel, 'String', sprintf('%s joint %d-%d', mode, S(i).a, S(i).b));
draw_tree(tree, S, getappdata(handles.stuff, joint));
populate_joint_panel(handles, mode);


function cursor_to_joint(this, S, mode, handles)

% find nearest node or joint (if within a radius) and set selected
if (gco == gca)
    point = get(gco, 'CurrentPoint');
else
    point = get(get(gco, 'Parent'), 'CurrentPoint');
end
p = point(1, 1:2);
[x,y] = draw_tree(this, S, -1);
min_ratio = 1.1;
min_i = 0;
for i=1:length(S)
    da = norm([x(S(i).a) y(S(i).a)] - p);
    db = norm([x(S(i).b) y(S(i).b)] - p);
    d = norm([x(S(i).a) y(S(i).a)] - [x(S(i).b) y(S(i).b)]);
    % use the triangle inequality with a tolerance
    if da <= d && db <= d
        ratio = (da + db)/d;
        if ratio < min_ratio
            min_ratio = ratio;
            min_i = i;
        end
    end
end

if min_i ~= 0
    select_joint(handles, min_i, mode);
end


% --- Executes on mouse press over axes background.
function tree_in_ButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to tree_in (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

cursor_to_joint(handles.tree_in, getappdata(handles.stuff, 'TREE'), 'Design', handles);


% --- Executes on button press in changejoint.
function changejoint_Callback(hObject, eventdata, handles)
% hObject    handle to changejoint (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

S = getappdata(handles.stuff, 'TREE');
i = getappdata(handles.stuff, 'joint');
joints = {'rigid', 'prismatic', 'revolute'};
[joint, ok] = listdlg('Name', 'Joint type?', ...
                      'ListString', joints, ...
                      'SelectionMode', 'single', ...
                      'ListSize', [80 15*4], ...
                      'InitialValue', find(strcmp(joints, S(i).joint)));
if ~ok; return; end;
joint = joints{joint};
[params, bounds, state, ok] = edit_joint(joint, getappdata(handles.stuff, 'dims'));
if ~ok; return; end;
S(i).joint = joint;
S(i).params = params;
S(i).state = state;
S(i).bounds = bounds;
change_tree(handles, S);
draw_tree(handles.tree_in, S, getappdata(handles.stuff, 'joint'));


% --- Executes on button press in undo.
function undo_Callback(hObject, eventdata, handles)
% hObject    handle to undo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

past = getappdata(handles.stuff, 'TREE_past');
future = getappdata(handles.stuff, 'TREE_future');
S = getappdata(handles.stuff, 'TREE');
if ~isempty(past)
    future{end+1} = S;
    S = past{end};
    past = past(1:end-1);
    setappdata(handles.stuff, 'TREE_past', past);
    setappdata(handles.stuff, 'TREE_future', future);
    setappdata(handles.stuff, 'TREE', S);
end
select_joint(handles, 1, 'Design');


% --- Executes on button press in redo.
function redo_Callback(hObject, eventdata, handles)
% hObject    handle to redo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

past = getappdata(handles.stuff, 'TREE_past');
future = getappdata(handles.stuff, 'TREE_future');
S = getappdata(handles.stuff, 'TREE');
if ~isempty(future)
    past{end+1} = S;
    S = future{end};
    future = future(1:end-1);
    setappdata(handles.stuff, 'TREE_past', past);
    setappdata(handles.stuff, 'TREE_future', future);
    setappdata(handles.stuff, 'TREE', S);
end
select_joint(handles, 1, 'Design');


% --- Executes on button press in save.
function save_Callback(hObject, eventdata, handles)
% hObject    handle to save (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

[filename,path] = uiputfile('*.mat');
TREE = getappdata(handles.stuff, 'TREE');
DIMS = getappdata(handles.stuff, 'dims');
SELJ = getappdata(handles.stuff, 'joint');
save([path filename], 'TREE', 'DIMS', 'SELJ');

% --- Executes on button press in load.
function load_Callback(hObject, eventdata, handles)
% hObject    handle to load (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

[filename,path] = uigetfile('*.mat');
vars = load([path filename]);
change_dims(handles, vars.DIMS);
change_tree(handles, vars.TREE);
if isfield(vars, 'SELJ')
    select_joint(handles, vars.SELJ, 'Design');
end


% --- Executes on button press in debug.
function debug_Callback(hObject, eventdata, handles)
% hObject    handle to debug (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

keyboard



function fudge_factor_Callback(hObject, eventdata, handles)
% hObject    handle to fudge_factor (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of fudge_factor as text
%        str2double(get(hObject,'String')) returns contents of fudge_factor as a double
setappdata(handles.stuff, 'fudge', str2double(get(hObject, 'String')));


% --- Executes during object creation, after setting all properties.
function fudge_factor_CreateFcn(hObject, eventdata, handles)
% hObject    handle to fudge_factor (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in fudge.
function fudge_Callback(hObject, eventdata, handles)
% hObject    handle to fudge (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

S = getappdata(handles.stuff, 'TREE');
dims = getappdata(handles.stuff, 'dims');
fudge = getappdata(handles.stuff, 'fudge');

S = manip_fudge(S, dims, fudge);

change_tree(handles, S);
draw_tree(handles.tree_in, S, getappdata(handles.stuff, 'joint'));


% --- Executes on button press in unfudge.
function unfudge_Callback(hObject, eventdata, handles)
% hObject    handle to unfudge (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

S = getappdata(handles.stuff, 'TREE');

% deflate (delete any nodes created by fudging)
S([S.state] == -1) = [];

setappdata(handles.stuff, 'joint', 1);
change_tree(handles, S);
draw_tree(handles.tree_in, S, getappdata(handles.stuff, 'joint'));


function tag = decode_prop(tag)

tag = tag(7:end);
if strcmp(tag(1:5), 'param')
    tag = ['params{' tag(6:end) '}'];
end


function populate_joint_panel(handles, mode)

switch mode
    case 'Design'
        prefix = 'in_';
        S = getappdata(handles.stuff, 'TREE');
        jointdata = 'joint';
    case 'Learned'
        prefix = 'out_';
        S = getappdata(handles.stuff, 'GUESS');
        jointdata = 'ljoint';
end

contents = lower(get(handles.([prefix 'joint_type']), 'String'));

set(handles.([prefix 'rigid_panel']), 'Visible', 'off');
set(handles.([prefix 'prismatic_panel']), 'Visible', 'off');
set(handles.([prefix 'revolute_panel']), 'Visible', 'off');

i = getappdata(handles.stuff, jointdata);
if i > length(S)
    i = 1;
end
joint = S(i).joint;
set(handles.([prefix 'joint_type']), 'Value', find(strcmp(contents, joint)));
controls = get(handles.([prefix joint '_panel']), 'Children');
for c = controls(strcmp(get(controls, 'Style'), 'edit'))'
    try
        val = eval(['S(i).' decode_prop(get(c, 'Tag'))]);
    catch err
        if strcmp(err.identifier, 'MATLAB:badsubscript')
            val = verifier('', get(c, 'TooltipString'), getappdata(handles.stuff, 'dims'));
        else
            rethrow(err);
        end
    end
    set(c, 'String', verifier(val, get(c, 'TooltipString'), getappdata(handles.stuff, 'dims'), true));
    set(c, 'BackgroundColor', [1 1 1]);
end

set(handles.([prefix joint '_panel']), 'Visible', 'on');


% --- Executes on selection change in in_joint_type.
function in_joint_type_Callback(hObject, eventdata, handles)
% hObject    handle to in_joint_type (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns in_joint_type contents as cell array
%        contents{get(hObject,'Value')} returns selected item from in_joint_type

S = getappdata(handles.stuff, 'TREE');
dims = getappdata(handles.stuff, 'dims');
i = getappdata(handles.stuff, 'joint');
old_joint = S(i).joint;
new_joint = lower(subsref(get(hObject, 'String'), substruct('{}', {get(hObject, 'Value')})));
old_controls = get(handles.(['in_' old_joint '_panel']), 'Children');
new_controls = get(handles.(['in_' new_joint '_panel']), 'Children');
for c = new_controls(strcmp(get(new_controls, 'Style'), 'edit'))' % transfer over the parameters, if possible
    old_value = get(old_controls(strcmp(get(old_controls, 'Tag'), get(c, 'Tag'))), 'String');
    try
        verifier(old_value, get(c, 'TooltipString'), dims); % if the param verifies, we can keep it
    catch err
        if strcmp(err.identifier, 'KA:type') % otherwise, use the default value
            eval(['S(i).' decode_prop(get(c, 'Tag')) ' = verifier('''', get(c, ''TooltipString''), dims);']);
        else
            rethrow(err);
        end
    end
end

% now update the GUI
S(i).joint = new_joint;
change_tree(handles, S);


function joint_prop_callback(hObject, eventdata, handles)

string = get(hObject, 'String');
try
    value = verifier(string, get(hObject, 'TooltipString'), getappdata(handles.stuff, 'dims'));
    
    S = getappdata(handles.stuff, 'TREE');
    i = getappdata(handles.stuff, 'joint');
    eval(['S(i).' decode_prop(get(hObject, 'Tag')) ' = value;']);
    change_tree(handles, S);
    set(hObject, 'BackgroundColor', [0 1 0]); % happy green background == prop updated
catch err
    if strcmp(err.identifier, 'KA:type')
        set(hObject, 'BackgroundColor', [1 0 0]); % angry red background == prop not updated
    else
        rethrow(err);
    end
end


% --- Executes during object creation, after setting all properties.
function in_joint_type_CreateFcn(hObject, eventdata, handles)
% hObject    handle to in_joint_type (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function rigid_offset_Callback(hObject, eventdata, handles)
% hObject    handle to rigid_offset (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of rigid_offset as text
%        str2double(get(hObject,'String')) returns contents of rigid_offset as a double


% --- Executes during object creation, after setting all properties.
function rigid_offset_CreateFcn(hObject, eventdata, handles)
% hObject    handle to rigid_offset (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function joint_param1_Callback(hObject, eventdata, handles)
% hObject    handle to joint_param1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of joint_param1 as text
%        str2double(get(hObject,'String')) returns contents of joint_param1 as a double

joint_prop_callback(hObject, eventdata, handles);


% --- Executes during object creation, after setting all properties.
function joint_param1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to joint_param1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on key press with focus on joint_param1 and none of its controls.
function joint_param1_KeyPressFcn(hObject, eventdata, handles)
% hObject    handle to joint_param1 (see GCBO)
% eventdata  structure with the following fields (see UICONTROL)
%	Key: name of the key that was pressed, in lower case
%	Character: character interpretation of the key(s) that was pressed
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)



function joint_bounds_Callback(hObject, eventdata, handles)
% hObject    handle to joint_bounds (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of joint_bounds as text
%        str2double(get(hObject,'String')) returns contents of joint_bounds as a double
joint_prop_callback(hObject, eventdata, handles);

% --- Executes during object creation, after setting all properties.
function joint_bounds_CreateFcn(hObject, eventdata, handles)
% hObject    handle to joint_bounds (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function joint_state_Callback(hObject, eventdata, handles)
% hObject    handle to joint_state (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of joint_state as text
%        str2double(get(hObject,'String')) returns contents of joint_state as a double
joint_prop_callback(hObject, eventdata, handles);

% --- Executes during object creation, after setting all properties.
function joint_state_CreateFcn(hObject, eventdata, handles)
% hObject    handle to joint_state (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function joint_param2_Callback(hObject, eventdata, handles)
% hObject    handle to joint_param2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of joint_param2 as text
%        str2double(get(hObject,'String')) returns contents of joint_param2 as a double
joint_prop_callback(hObject, eventdata, handles);

% --- Executes during object creation, after setting all properties.
function joint_param2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to joint_param2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit18_Callback(hObject, eventdata, handles)
% hObject    handle to joint_param1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of joint_param1 as text
%        str2double(get(hObject,'String')) returns contents of joint_param1 as a double


% --- Executes during object creation, after setting all properties.
function edit18_CreateFcn(hObject, eventdata, handles)
% hObject    handle to joint_param1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function prismatic_vector_Callback(hObject, eventdata, handles)
% hObject    handle to joint_param2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of joint_param2 as text
%        str2double(get(hObject,'String')) returns contents of joint_param2 as a double


% --- Executes during object creation, after setting all properties.
function prismatic_vector_CreateFcn(hObject, eventdata, handles)
% hObject    handle to joint_param2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function prismatic_state_Callback(hObject, eventdata, handles)
% hObject    handle to joint_state (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of joint_state as text
%        str2double(get(hObject,'String')) returns contents of joint_state as a double


% --- Executes during object creation, after setting all properties.
function prismatic_state_CreateFcn(hObject, eventdata, handles)
% hObject    handle to joint_state (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function prismatic_bounds_Callback(hObject, eventdata, handles)
% hObject    handle to joint_bounds (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of joint_bounds as text
%        str2double(get(hObject,'String')) returns contents of joint_bounds as a double


% --- Executes during object creation, after setting all properties.
function prismatic_bounds_CreateFcn(hObject, eventdata, handles)
% hObject    handle to joint_bounds (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in out_joint_type.
function out_joint_type_Callback(hObject, eventdata, handles)
% hObject    handle to out_joint_type (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns out_joint_type contents as cell array
%        contents{get(hObject,'Value')} returns selected item from out_joint_type


% --- Executes during object creation, after setting all properties.
function out_joint_type_CreateFcn(hObject, eventdata, handles)
% hObject    handle to out_joint_type (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on mouse press over axes background.
function tree_out_ButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to tree_out (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

cursor_to_joint(handles.tree_out, getappdata(handles.stuff, 'GUESS'), 'Learned', handles);



function noise_Callback(hObject, eventdata, handles)
% hObject    handle to noise (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of noise as text
%        str2double(get(hObject,'String')) returns contents of noise as a double


% --- Executes during object creation, after setting all properties.
function noise_CreateFcn(hObject, eventdata, handles)
% hObject    handle to noise (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in export.
function export_Callback(hObject, eventdata, handles)
% hObject    handle to export (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

assignin('base', 'S', getappdata(handles.stuff, 'TREE'));
assignin('base', 'SS', getappdata(handles.stuff, 'GUESS'));
assignin('base', 'X', getappdata(handles.stuff, 'DATA'));
assignin('base', 'dims', getappdata(handles.stuff, 'dims'));
