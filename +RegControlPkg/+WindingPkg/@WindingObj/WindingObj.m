classdef WindingObj < Simulink.Parameter
    %WINDINGOBJ Contained by a transformer
    %   Multiple of these inside a vector in the Transformer class
    
    properties (PropertyType = 'int32 scalar')
        Connection
        NumTaps
    end
    
    properties (PropertyType = 'double scalar')  
        kvll
        Vbase
        kva
        puTap
        Rpu
        Rneut
        Xneut
        TapIncrement
        MinTap
        MaxTap
    end
    
    methods
        function obj = WindingObj(varargin)
            %WINDINGOBJ Construct an instance of Winding using specified
            %parameters (defaults for unspecified)
            
            p = inputParser;
            numchk = {'numeric'};
            nempty = {'nonempty'};
            
            addOptional(p,'Connection',0,@(x)validateattributes(x,numchk,nempty));
            addOptional(p,'kvll',12.47,@(x)validateattributes(x,numchk,nempty));
            addOptional(p,'Vbase',0,@(x)validateattributes(x,numchk,nempty));
            
            addOptional(p,'kva',1000.0,@(x)validateattributes(x,numchk,nempty));
            addOptional(p,'puTap',1.0,@(x)validateattributes(x,numchk,nempty));
            addOptional(p,'Rpu',0.002,@(x)validateattributes(x,numchk,nempty));
            
            addOptional(p,'Rneut',-1.0,@(x)validateattributes(x,numchk,nempty)); % default to open - make user specify connection
            addOptional(p,'Xneut',0.0,@(x)validateattributes(x,numchk,nempty));
            addOptional(p,'TapIncrement',0.00625,@(x)validateattributes(x,numchk,nempty));
            
            addOptional(p,'NumTaps',32,@(x)validateattributes(x,numchk,nempty));
            addOptional(p,'MaxTap',1.10,@(x)validateattributes(x,numchk,nempty));
            addOptional(p,'MinTap',0.90,@(x)validateattributes(x,numchk,nempty));
            
            parse(p,varargin{:});
            
            obj.Connection = p.Results.Connection;
            obj.kvll       = p.Results.kvll;
            
            if p.Results.Vbase == 0 % no VBase specified
                obj.Vbase = (( obj.kvll/sqrt(3) )*1000.0);
            else
                obj.Vbase = p.Results.Vbase;
            end
            
            
            obj.kva        = p.Results.kva;
            obj.puTap      = p.Results.puTap;
            obj.Rpu        = p.Results.Rpu;
            
            obj.Rneut      = p.Results.Rneut;
            obj.Xneut      = p.Results.Xneut;
            % ComputeAntiFloatAdder(1.0e-6, kva/3.0/1000.0);     %  1 PPM
            
            obj.TapIncrement = p.Results.TapIncrement;
            obj.NumTaps      = p.Results.NumTaps;
            obj.MaxTap       = p.Results.MaxTap;
            obj.MinTap       = p.Results.MinTap;
        end
        
%         function obj = MakeLike(AnotherWinding)
%             %MAKELIKE Construct an instance of Winding by copying the
%             %parameters of another winding
%             
%             p = inputParser;
%             nempty = {'nonempty'};
%             wdgchk = {'Winding'};
%             
%             addRequired(p,'AnotherWinding',@(x)validateattributes(x,wdgchk,nempty));
%             parse(p,AnotherWinding);
%             
%             obj.Connection = p.Results.AnotherWinding.Connection;
%             obj.kvll       = p.Results.AnotherWinding.kvll;
%             obj.VBase      = p.Results.AnotherWinding.VBase;
%             
%             obj.kva        = p.Results.AnotherWinding.kva;
%             obj.puTap      = p.Results.AnotherWinding.puTap;
%             obj.Rpu        = p.Results.AnotherWinding.Rpu;
%             
%             obj.Rneut      = p.Results.AnotherWinding.Rneut;
%             obj.Xneut      = p.Results.AnotherWinding.Xneut;
%             % ComputeAntiFloatAdder(1.0e-6, kva/3.0/1000.0);     %  1 PPM
%             
%             obj.TapIncrement = p.Results.AnotherWinding.TapIncrement;
%             obj.NumTaps      = p.Results.AnotherWinding.NumTaps;
%             obj.MaxTap       = p.Results.AnotherWinding.MaxTap;
%             obj.MinTap       = p.Results.AnotherWinding.MinTap;
%         end
    end
    
    methods(Static)
        function obj = MakeLike(AnotherWinding)
            %MAKELIKE Construct an instance of WindingObj by copying the
            %parameters of another winding
            
            p = inputParser;
            nempty = {'nonempty'};
            wdgchk = {'WindingObj'};
            
            addRequired(p,'AnotherWinding',@(x)validateattributes(x,wdgchk,nempty));
            parse(p,AnotherWinding);
            
            args{1} = p.Results.AnotherWinding.Connection;
            args{2} = p.Results.AnotherWinding.kvll;
            args{3} = p.Results.AnotherWinding.VBase;
            
            args{4} = p.Results.AnotherWinding.kva;
            args{5} = p.Results.AnotherWinding.puTap;
            args{6} = p.Results.AnotherWinding.Rpu;
            
            args{7} = p.Results.AnotherWinding.Rneut;
            args{8} = p.Results.AnotherWinding.Xneut;
            % ComputeAntiFloatAdder(1.0e-6, kva/3.0/1000.0);     %  1 PPM
            
            args{9} = p.Results.AnotherWinding.TapIncrement;
            args{10} = p.Results.AnotherWinding.NumTaps;
            args{11} = p.Results.AnotherWinding.MaxTap;
            args{12} = p.Results.AnotherWinding.MinTap;
            
            obj = WindingObj(args{:});
        end
    end
end

