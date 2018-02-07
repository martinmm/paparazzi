function [s, varargout] = read_paparazzi_data_log(varargin)
% function [s, u, vnf] = read_paparazzi_data_log(filepath, settingspath, gps_check)
% function to read the data from a paparazzi data file applying unit conversions found in the
% corresponding log file (has to have the same base name and the same directory location as the data
% file)
%
% Input: 
% - filepath (optional): full file path
% - settingspath (optional): path to .m script or .mat file that produces/contains the variabelse 
%       ingl={...} (keywords for lines that shall be ignored), ingv={...} (variable names that shall 
%       be ignored), cname_in={...} (variable names or expressions that shall be replaced with 
%       custom names), cname_out={...} (custom variable names), cunit_in={...} (units that shall be
%       replaced or converted) , cunit_out={...} (custom units after replacement or conversion), 
%       cunit_coef=[...] (multiplication factors for unit conversion, set to 1 if only the unit name 
%       shall be written differently
%       these variables can also be provided as global variables in a main script which is calling
%       the function read_paparazzi_data_log.m
% - gps_chk (otional): true or 1 to exclude all data beforetthe gps signal
%       reached acceptable quality (gps_mode == 3); false to read all data.
%       Only implemented for Bebop2 and SUMO 
% 
% Output:
% - s: structure containing data read from data file
% - u (optional): units to the data in s
% - vnf (optional): variables for which the log file contains information but which are not found in 
%       the data file. this output can be helpful to speed up the reading process by creating the  
%       variable "ignl", a cell containing keywords the script shall not search for.
%
% Calling this function from a loop might cause problems when you want to
% concatenate the output structures 's' into an array structure 'S(i)' in
% cases when the read data file contains a variable not present in the
% previous file(s). This can be avoided by using a loop like this: 
% 
%     for df = 1:length(dfiles)
%         [s.data, s.units, s.vnf] = ...
%             read_paparazzi_data_log([dpath,dfiles{df}],sfile,1);
%         if df > 1
%             efS = setdiff(fieldnames(s.data),fieldnames(S(end).data));
%             for ee = 1:length(efS)
%                 S(end).data.(efS{ee}) = [];
%             end
%             efS = setdiff(fieldnames(s.units),fieldnames(S(end).units));
%             for ee = 1:length(efS)
%                 S(end).units.(efS{ee}) = [];
%             end
%             efs = setdiff(fieldnames(S(end).data),fieldnames(s.data));
%             for ee = 1:length(efs)
%                 s.data.(efs{ee}) = [];
%             end
%             efs = setdiff(fieldnames(S(end).units),fieldnames(s.units));
%             for ee = 1:length(efs)
%                 s.units.(efs{ee}) = [];
%             end
%         end
%         S(df) = s;
%         
%         if ~exist('vnf','var'), vnf = s.vnf;
%         else vnf = intersect(vnf, s.vnf); end
%     end
%
%
% -------------------------------------------------------------------------
%    Copyright 2017 Stephan Kral; Geopysical Institute, University of
%      Bergen, Norway; stephan.kral@uib.no
% 
%    This program is free software: you can redistribute it and/or modify
%     it under the terms of the GNU General Public License as published by
%     the Free Software Foundation, either version 3 of the License, or
%     (at your option) any later version.
% 
%     This program is distributed in the hope that it will be useful,
%     but WITHOUT ANY WARRANTY; without even the implied warranty of
%     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%     GNU General Public License for more details.
% 
%     You should have received a copy of the GNU General Public License
%     along with this program.  If not, see <http://www.gnu.org/licenses/>.
% ----------------------------------------------------------------------------
%
% Modified: 
% 17.11.2016, SK:   - removed settings and created external script "settings_for_read_paparazzi.m"
%                   - added input option for path to settings file or script 
% 18.11.2016, SK:   - fixed bug with passed filepaths
% 20.06.2017, SK:   - fixed bug with conversion from string to data array,
%                       avoidng reshape command. 
% 05.10.2017, SK:   - included routine to first check which messages are
%                       included in the data file before reading their
%                       relevant information from the log file (instead of
%                       reading all message information from the log file
%                       and then searching the data file for all messages,
%                       even though a high number of messages is not
%                       relevant, since they are not in the data file (e.g.
%                       outdated sensors...)). Significant speed-up! Output
%                       vnf becomes kind of obsolete.
% 05.10.2017, SK:   - included optional gps_chk to get rid of very bad gps
%                       data in the very beginning (before the start of the
%                       measurement flight). This is currently only working 
%                       for the Bebop2 and SUMO systems. 
%
% 
% Required scripts/functions: 
% - grep.m (http://se.mathworks.com/matlabcentral/fileexchange/9647-grep--a-pedestrian--very-fast-grep-utility)
%   much faster than any matlab reading routine I have tried and also very powerful, and very
%   similar to the unix function grep
% 
% Todo: 
% - test with more data sets
% - read other important parameters from log file
% - simplify bebop variable names
% 
%% 

% USE: RUN SETTINGS_PAPARAZZI_DATA_LOG AND CORRESPONDING DIRECTORY STRUCTURE
                          % bebop

% check number of arguments passed to the function and get file path and settings if passed
if nargin>=1
    dfilepath=varargin{1}; 
else
    dfilepath='';
end
if nargin>=2
    try run(varargin{2})                                                                            % try to run specific .m file (skripts)
    catch, try load(varargin{2}), catch, end                                                        % try to run specific .mat files
    end
else
    try load('settings_for_read_paparazzi.mat')                                                     % try to open default .mat file 
    catch, try run('settings_for_read_paparazzi.m'),                                                % try to run default .m file (script)
        catch, warning('no settings found under specified path'); end       
    end
end
if nargin==3
    gps_chk = logical(varargin{3});
    if ~islogical(gps_chk) 
        error('gps_chk (3rd input variable) has to be of type logical')
    end
else
    gps_chk = false;
end
    

% check if something is missing 
if ~exist('ignl','var'), ignl = {}; end
ignl=[ignl,{'SHAPE','BATTERY_MONITOR'}];
if ~exist('ignv','var'), ignv = {}; end
% ignv = [ignv,{'BATTERY_MONITOR_array'}]; 
if ~exist('cunit_in','var') && ~exist('cunit_out','var') && ~exist('cunit_coef','var')
    cunit_in =   {'cm', 'mm',      'rad', 'cm/s', 'mm/s',    'rad/s',  'Pa', 'cms', 'centideg', 'decideg', 'degs', 'ms', 'decivolt'};
    cunit_out =  { 'm',  'm',      'deg',  'm/s',  'm/s',    'deg/s', 'hPa', 'm/s',      'deg',     'deg','deg/s', 'm/s',       'V'};
    cunit_coef = [1e-2, 1e-3, rad2deg(1),   1e-2,   1e-3, rad2deg(1),  1e-2,  1e-2,       1e-2,      1e-1,      1,     1,      1e-1];   % multiplication factors
end
if ~exist('cname_in','var') && ~exist('cname_out','var')
    cname_in =  {};
    cname_out = {};
end

% get file path if it is not passed
if exist(dfilepath,'file')==7
    [dfile,dpath,~]=uigetfile([dfilepath,'*.data'],...                                              % open file selection window
        'multiselect','off');
    dfilepath=[dpath,dfile];                                                                        % path to .data file
elseif exist(dfilepath,'file')~=2
    [dfile,dpath,~]=uigetfile('/media/krals/DATA_380GB/Andenes_2016/*.data',...                     % open file selection window
        'multiselect','off');
    dfilepath=[dpath,dfile];                                                                        % path to .data file
else
    [dpath,dfile,ext] = fileparts(dfilepath);
    dpath = [dpath,filesep];
    dfile = [dfile,ext];
end

lfile=strrep(dfile,'.data','.log');                                                                 % .log file
lfilepath=[dpath,lfile];                                                                            % path to .log file

% write file names to structure s
s.data_file = dfile;
s.log_file = lfile;

% read time from file name
s.t_from_filename = datenum(['20',dfile(1:18)],'yyyy_mm_dd__HH_MM_SS');
u.t_from_filename = 'matlab_datenum';

%% check which parameters are in the data file
fid = fopen(dfilepath);
C = textscan(fid, '%*f %*f %s %*[^\n]');    % read only the third column
C = C{:};
fclose(fid);
C = unique(C);

%% read log file
tic
fprintf('reading log file: %s ',lfile)
% read log file
fid = fopen(lfilepath,'r');
lline = fread(fid,'*char')';                                                                        % read into (long string)
fclose(fid);
lline = strsplit(lline,'\n')';                                                                      % split string at newline -> cell
ll = 1;
for dd = 1:length(C)
    % get line numbers for messages
    [~,p] = grep('-s -i', ['<message NAME="',C{dd},'"'], lfilepath);                                % get lines with keywords 'message NAME="...' (donwload 'grep.m' from matlab file exchange)
    lls = p.line;
    lle = p.line((cellfun(@(x) ~isempty(x),regexp(p.match,'/>','once'))==1));                       % copy the lines including the end of the message
    clear p
    if isempty(lle)
        [~,p] = grep('-s -i', '/message', lfilepath);                                               % get lines with keywords '/message (end of message)
        lle = p.line(find(p.line>lls,1));
        clear p
    end
    
    namestr = C{dd};                                                                                % create base field names for variabels
    
    if ismember(namestr,ignl), continue
    else, lfields{ll,1} = namestr; end %#ok<*AGROW>
    
    msg.(lfields{ll}) = lline(lls:lle);                                                             % get all information string on variable name, units etc. 
    fstr.(lfields{ll}) = ['%f %*u ',lfields{ll}];                                                   % create base format string (edited further down)
%     rxp.(lfields{ll}) = 
    ii = find(cellfun(@isempty,regexp(msg.(lfields{ll}),'<field'))==0);                             % get line index containing info on sub-variables
    cls.(lfields{ll}) = 1;
    if isempty(ii), continue, end                                                                   % skip variable groups for which the required info is not available (irrelevant variables)
    kk = 1;
    for iii=1:length(ii)                                                                            % loop through sub variables
        fic = strsplit(msg.(lfields{ll}){ii(iii)},'>');
        fic = strsplit(strtrim(regexprep(fic{1},{'<field','"/','"'},'')));                          % split string and replace irrelevant strings
        clear fi
        for ff=1:length(fic)                                                                        % loop through these split information
            if ~ismember('=',fic{ff}), continue, end                                                % skip loop if there is additional info in fic{ff} not matching the pattern
            ficc = strsplit(fic{ff},'=');                                                           % split between name and value
            fi.(upper(ficc{1})) = ficc{2};                                                          % put info into structure
        end
        lfstr = regexprep([lfields{ll},'_',fi.NAME],cname_in,cname_out);                            % create field names for each variable applying custom names if set
        
        switch_array(ll) = 0;
        % edit formatstring according to data type
        if ismember(fi.TYPE,{'string','char'})
                fstr.(lfields{ll}) = [fstr.(lfields{ll}),' %*s'];
                continue
        elseif ismember(fi.TYPE,{'int8','uint8','int16','uint16','int32','uint32','float'})
            if ismember(lfstr,ignv)
                fstr.(lfields{ll}) = [fstr.(lfields{ll}),' %*f'];
                continue
            else
                fstr.(lfields{ll}) = [fstr.(lfields{ll}),' %f'];
                cls.(lfields{ll}) = cls.(lfields{ll})+1;
            end
        elseif ismember(fi.TYPE,{'int8[]','uint8[]','int16[]','uint16[]','int32[]','uint32[]','float[]'})
            % fprintf('variables for %s are not well defined: %s\n',lfields{ll}, fi.TYPE)
             if ismember(lfstr,ignv)
                fstr.(lfields{ll}) = [fstr.(lfields{ll}),' %*f'];
                continue
             else
                 [~,p] = grep('-s -i', [' ',lfields{ll},' '], dfilepath);
            if ~isempty(p.match)
                mstr = p.match{1}; clear p
                fstr.(lfields{ll}) = ['%f %*u ',lfields{ll},' %f',...
                    repmat(',%f',1,length(strsplit(mstr,','))-1)];
                cls.(lfields{ll}) = length(strsplit(mstr,','))+1;
            end
            fname.(lfields{ll}) = [lfields{ll},'_array'];
            switch_array(ll) = 1;
            continue
             end
        end
        
        % write unit information to structure
        if isfield(fi,'ALT_UNIT') && isfield(fi,'ALT_UNIT_COEF')
            unit.(lfstr) = fi.ALT_UNIT;                                                             % write ALT_UNIT to structure
            convf.(lfstr) = str2double(fi.ALT_UNIT_COEF);                                           % write ALT_UNIT_COEF to structure
        elseif isfield(fi,'UNIT')
            unit.(lfstr) = fi.UNIT;                                                                 % write UNIT to structure
            convf.(lfstr) = 1;                                                                      % set factor to 1
        else
            unit.(lfstr) = '';
            convf.(lfstr) = 1;
        end
        [~,cui] = ismember(unit.(lfstr),cunit_in);
        if cui > 0
            unit.(lfstr) = cunit_out{cui};                                                          % write custom units to structure
            convf.(lfstr) = cunit_coef(cui);                                                        % set factor to custom unit coefficient
        end
%         fprintf('%u %u\n',ll,kk)
%         if ll==200 && kk==7
%         end
        try 
            fname.(lfields{ll}){kk} = lfstr; 
        catch
            error('Error with %s, %s\n',lfields{ll},lfstr);
        end
        kk = kk+1;
    end
%     if ismember(lfields{ll},'ACTUATORS')
%         fstr.(lfields{ll}) = '%f %*u ACTUATORS %f %f %f %f %f %f';
%     end
    
    ll = ll+1;
end

fprintf('(%.2f seconds)\n', toc)

%% read data file

% read only data with good GPS signal
if gps_chk == true
    [~,q] = grep('-s -i', 'GPS 3',dfilepath);                                                       % for SUMO
    if isempty(q.line)
        [~,q] = grep('-s -i -R', ['GPS_INT [0-9.-]* [0-9.-]* [0-9.-]* [0-9.-]* ',...                % for Bebop2
            '[0-9.-]* [0-9.-]* [0-9.-]* [0-9.-]* [0-9.-]* [0-9.-]* [0-9.-]* [0-9.-]* ',...
            '[0-9.-]* [0-9.-]* [0-9.-]* 3'], dfilepath);
    end
    sline = q.line(1); clear q                                                                      % get start line (after this timestamp gps should be OK)
else
    sline = 0;
end
    
    
nf = 1;
vnf{nf} = '';
for ll = 1:length(lfields)
    tic
    [~,p] = grep('-s -i', [' ',lfields{ll},' '], dfilepath);                                        % find lines containing data matching variable type (keyword lfields)
%     [~,dsstr]=unix(sprintf('grep -s -i '' %s '' %s',lfields{ll}, dfilepath));                     % apply the unix comand grep to find lines matching variable group (keywork lfields)
%     if isempty(dsstr), continue, end
    p.match = p.match(p.line >= sline);                                                             % skip all lines before sline
    if isempty(p.match)
    %    fprintf('(%.2f seconds) - no data found!\n', toc)
        vnf{nf} = lfields{ll}; 
        nf = nf+1;
        continue, 
    end
    fprintf('read %s from data file: %s ', lfields{ll}, dfile)
    
    dc = cellfun(@(x) [x,' '],p.match,'UniformOutput',0); clear p                                   % add a whitespace at the end of each line
    dc = dc(cellfun(@isempty,regexp(dc,'replay')));                                                 % ignore all lines containing keyword 'replay' since they don't contain actual measurements if a reply has been written to the same data file
    if isempty(dc)
        vnf{nf} = lfields{ll}; 
        nf = nf+1;
        continue, 
    end
    dsstr = cell2mat(dc');                                                                          % create string that can be read with sscanf
    [data, count] = sscanf(dsstr, fstr.(lfields{ll}), [cls.(lfields{ll}),length(dc)]);                                                       % apply format string to read data into vector
    if numel(data) > count, data(count+1:end) = NaN; end
    data = data';
%     dl=ceil(length(data)/cls.(lfields{ll})); rdl=rem(length(data),cls.(lfields{ll}));               % determine number of lines
%     data = [data;NaN(rdl,1)];                                                                       % fill incomplete lines
%     data = reshape(data,cls.(lfields{ll}),dl)';                                                     % reshape data vector into table with lines for time and columns for parameters
    switch switch_array(ll)
        case 1
        s.([fname.(lfields{ll}),'_o']) = data;
        u.(fname.(lfields{ll})) = '';
        case 0
        % write data and units to output structures
        tstr = regexprep(['t_',lfields{ll}], cname_in, cname_out);
        s.(tstr) = data(:,1);
        for ff = 1:size(data,2)-1
            s.([fname.(lfields{ll}){ff},'_o']) = convf.(fname.(lfields{ll}){ff}) .* data(:,ff+1);       % convert to custom units/alt_units
            u.(fname.(lfields{ll}){ff}) = unit.(fname.(lfields{ll}){ff});
        end
    end
   fprintf('(%.2f seconds)\n', toc)
end

% write UAV id
s.UAV_id = sscanf(dsstr, '%*f %u %*s'); s.UAV_id=s.UAV_id(1);  

%% parse output varaibles
nargoutchk(0,3)
if nargout>1, varargout{1} = u; end
if nargout>2, varargout{2} = vnf; end