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

% Last Modified by GUIDE v2.5 25-Oct-2012 22:10:42

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
             [colors(j) '.-']);
        quiver([X(f,S(j).a, 1,3), X(f,S(j).b, 1,3)], ...
               [X(f,S(j).a, 2,3), X(f,S(j).b, 2,3)], ...
               [X(f,S(j).a, 1,1), X(f,S(j).b, 1,1)], ...
               [X(f,S(j).a, 2,1), X(f,S(j).b, 2,1)], ...
               0.2, colors(j));
    else
        % 3D
        plot3([X(f,S(j).a, 1,4), X(f,S(j).b, 1,4)], ...
              [X(f,S(j).a, 2,4), X(f,S(j).b, 2,4)], ...
              [X(f,S(j).a, 3,4), X(f,S(j).b, 3,4)], ...
              [colors(j) '.-']);
        quiver3([X(f,S(j).a, 1,4), X(f,S(j).b, 1,4)], ...
                [X(f,S(j).a, 2,4), X(f,S(j).b, 2,4)], ...
                [X(f,S(j).a, 3,4), X(f,S(j).b, 3,4)], ...
                [X(f,S(j).a, 1,1), X(f,S(j).b, 1,1)], ...
                [X(f,S(j).a, 2,1), X(f,S(j).b, 2,1)], ...
                [X(f,S(j).a, 3,1), X(f,S(j).b, 3,1)], ...
                0.2, colors(j));
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

function reset_tree(handles)

setappdata(handles.stuff, 'TREE', struct('a', {1}, 'b', {2}, 'joint', {'rigid'}, 'params', {{T(1:getappdata(handles.stuff, 'dims'))}}, 'state', {0}, 'bounds', {[0;0]}));
draw_tree(handles.tree_in, getappdata(handles.stuff, 'TREE'), getappdata(handles.stuff, 'joint'));

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
setappdata(handles.stuff, 'frames', 50);
setappdata(handles.stuff, 'curframe', 1);
setappdata(handles.stuff, 'animdir', 1);
setappdata(handles.stuff, 'drawing', false);
reset_tree(handles);

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


% --- Executes on selection change in dims.
function dims_Callback(hObject, eventdata, handles)
% hObject    handle to dims (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

setappdata(handles.stuff, 'dims', str2num(subsref(get(hObject, 'String'), substruct('{}', {get(hObject, 'Value')}))));
reset_tree(handles);


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

X = manip_simulate(dims, max([S.a S.b]), frames, S);
setappdata(handles.stuff, 'DATA', X);
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

msgbox('Not even close to implemented.', 'Nope', 'error');


% --- Executes on button press in animate.
function animate_Callback(hObject, eventdata, handles)
% hObject    handle to animate (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

ding = getappdata(handles.stuff, 'animating');
if isempty(ding)
    ding = timer('ExecutionMode', 'fixedRate', ...
                 'Period', 0.1, ...
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
setappdata(handles.stuff, 'TREE', S);
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

    setappdata(handles.stuff, 'TREE', S);
    select_joint(handles, 1);
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
setappdata(handles.stuff, 'TREE', S);


function select_joint(handles, i)

S = getappdata(handles.stuff, 'TREE');
setappdata(handles.stuff, 'joint', i);
set(handles.jointsel, 'String', sprintf('Joint %d-%d', S(i).a, S(i).b));
draw_tree(handles.tree_in, S, getappdata(handles.stuff, 'joint'));


% --- Executes on mouse press over axes background.
function tree_in_ButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to tree_in (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% find nearest node or joint (if within a radius) and set selected
if (gco == gca)
    point = get(gco, 'CurrentPoint');
else
    point = get(get(gco, 'Parent'), 'CurrentPoint');
end
p = subsref(point, substruct('()', {1, 1:2}));
S = getappdata(handles.stuff, 'TREE');
[x,y] = draw_tree(handles.tree_in, S, 0);
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
    select_joint(handles, min_i);
end
