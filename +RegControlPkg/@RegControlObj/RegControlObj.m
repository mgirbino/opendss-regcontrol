classdef RegControlObj < Simulink.Parameter
    %REGCONTROLOBJ Is a RegControl, contains regulator parameters
    %   Is used in conjunction with a transformer, but does not directly
    %   interface with or contain one
    
    properties (Constant)
        EPSILON = 1.0e-12;
    end
    
    properties (PropertyType = 'double scalar')
        % specified:
        Bandwidth % in volts for the controlled bus
        BaseVoltage
        CTRating
        RevBandwidth % BW for operating in the reverse direction
        RevPowerThreshold
        RevVreg % voltage setting for operaiton in the reverse direction 
        Vreg % voltage regulator setting      
        LDC_Z % Z value for Beckwith LDC_Z control option
        R
        X 
        revLDC_Z % reverse Z value for Beckwith LDC_Z control option
        revR % LDC setting for reverse direction
        revX 
        revBandwidth
        revDelay
        revPowerThreshold % 100 kW
        PTRatio % ratio of the PT that converts the controlled winding
            % voltage to the regulator control voltage;
            % if winding is WYE, L-N voltage is used, else L-L used
            % SIDE EFFECT: sets RemotePTRatio property
        TapDelay
        
        TimeDelay
        Vlimit % for bus to which regulated winding is connected
        
        
        % private to control logic:       
        % ControlledElement
        


%         FwdPower    
%         NodeV
%         VLDC
%         Vterminal
%         BandTest
%         BoostNeeded
%         ControlledTransformer
%         ILDC
%         Increment
%         PendingTapChange
%         Vcontrol
%         Vactual
%         Vboost
%         Vlocalbus
%         VregTest        
    end  
    
    properties (PropertyType = 'uint8 scalar')
        % specified:
        ControlledPhase
        TapLimitPerChange % max allowable tap change per control
            % iteration in STATIC control mode
        xsfWinding % number of transformer winding being monitored,
            % formerly known as "Winding" -- changed to fix ambiguity
        % private to control object:
        TapNum % indicates tap position that the controlled transformer
            % winding tap position is currently at, or is being set to.
            % if being set --> value is outside the range of min/max tap,
            % then set to min/max tap position as appropriate
%         TapWinding
        fNphases 
        fNconds
        fNterms
        fPTphase
        ElementTerminal
    end
    
    properties (PropertyType = 'logical scalar')
        % specified:
        CogenEnabled
        InCogenMode
        
        IsReversible% typ applies to line regulators, not LTC
        InReverseMode
        ReverseNeutral% true --> reg goes to neutral in reverse
            % direction or in cogen operation
        ReversePending
        fInverseTime
            
        % private to control logic:
%         UsingRegulatedBus
%         VlimitActive
%         Armed
%         TapChangeIsNeeded
%         LDCActive = false
%         LookingForward
    end
    
    properties (PropertyType = 'char scalar')
        ElementName
        RegulatedBus
    end
    
    % will probably make into its own bus:
    properties (PropertyType = 'Transformer scalar')
        ControlledElement = Transformer;
    end
    
    methods
        function obj = RegControlObj(varargin)
            p = inputParser;
            numchk = {'numeric'};
            boolchk = {'boolean'};
            charchk = {'char'};
            xsfrmrchk = {'Transformer'};
            
            nempty = {'nonempty'};
            posint = {'nonempty','integer','positive'};
            
            % doubles:
            addOptional(p,'Bandwidth',3.0,@(x)validateattributes(x,numchk,nempty));
            addOptional(p,'BaseVoltage',0,@(x)validateattributes(x,numchk,nempty));
            addOptional(p,'CTRating',300,@(x)validateattributes(x,numchk,nempty));
            
            addOptional(p,'RevBandwidth',3.0,@(x)validateattributes(x,numchk,nempty));
            addOptional(p,'RevDelay',60,@(x)validateattributes(x,numchk,nempty));
            addOptional(p,'RevPowerThreshold',100e3,@(x)validateattributes(x,numchk,nempty));
            addOptional(p,'RevVreg',120,@(x)validateattributes(x,numchk,nempty));
            addOptional(p,'Vreg',120,@(x)validateattributes(x,numchk,nempty));

            addOptional(p,'LDC_Z',0,@(x)validateattributes(x,numchk,nempty));
            addOptional(p,'R',0,@(x)validateattributes(x,numchk,nempty));
            addOptional(p,'X',0,@(x)validateattributes(x,numchk,nempty));
            
            addOptional(p,'revLDC_Z',0,@(x)validateattributes(x,numchk,nempty));
            addOptional(p,'revR',0,@(x)validateattributes(x,numchk,nempty));
            addOptional(p,'revX',0,@(x)validateattributes(x,numchk,nempty));
            
            addOptional(p,'PTRatio',60,@(x)validateattributes(x,numchk,nempty));
            addOptional(p,'TapDelay',2.0,@(x)validateattributes(x,numchk,nempty));
            addOptional(p,'TimeDelay',15,@(x)validateattributes(x,numchk,nempty));
            addOptional(p,'Vlimit',0,@(x)validateattributes(x,numchk,nempty));
            
            % integer indices:
            addOptional(p,'TapLimitPerChange',16,@(x)validateattributes(x,numchk,posint));
            addOptional(p,'xsfWinding',1,@(x)validateattributes(x,numchk,posint));
            addOptional(p,'TapNum',0,@(x)validateattributes(x,numchk,posint));
    
            addOptional(p,'fNphases',3,@(x)validateattributes(x,numchk,posint));
            addOptional(p,'fNconds',3,@(x)validateattributes(x,numchk,posint));
            addOptional(p,'fNterms',3,@(x)validateattributes(x,numchk,posint));
            addOptional(p,'fPTphase',1,@(x)validateattributes(x,numchk,posint));
            addOptional(p,'ElementTerminal',1,@(x)validateattributes(x,numchk,posint));
            
            % booleans:
            addOptional(p,'CogenEnabled',false,@(x)validateattributes(x,boolchk,nempty));
            addOptional(p,'InCogenMode',false,@(x)validateattributes(x,boolchk,nempty));

            addOptional(p,'IsReversible',false,@(x)validateattributes(x,boolchk,nempty));
            addOptional(p,'InReverseMode',false,@(x)validateattributes(x,boolchk,nempty));
            addOptional(p,'ReverseNeutral',false,@(x)validateattributes(x,boolchk,nempty));
                
            addOptional(p,'ReversePending',false,@(x)validateattributes(x,boolchk,nempty));
            addOptional(p,'fInverseTime',false,@(x)validateattributes(x,boolchk,nempty));
            
            % chars:
            addOptional(p,'ElementName','',@(x)validateattributes(x,charchk,nempty));
            addOptional(p,'RegulatedBus','',@(x)validateattributes(x,charchk,nempty));

            % transformer:
            addOptional(p,'Transformer',TransformerObj,@(x)validateattributes(x,xsfrmrchk,nempty));
            parse(p,varargin{:});
            
            obj.Bandwidth = p.Results.Bandwidth;
            obj.BaseVoltage = p.Results.BaseVoltage;
            obj.CTRating = p.Results.CTRating;
            
            obj.RevBandwidth = p.Results.RevBandwidth;
            obj.RevDelay = p.Results.RevDelay;
            obj.RevPowerThreshold = p.Results.RevPowerThreshold;
            obj.RevVreg = p.Results.RevVreg;
            obj.Vreg = p.Results.Vreg;
            
            obj.LDC_Z = p.Results.LDC_Z;
            obj.R = p.Results.R;
            obj.X = p.Results.X;
            
            obj.revLDC_Z = p.Results.revLDC_Z;
            obj.revR = p.Results.revR;
            obj.revX = p.Results.revX;
            
            obj.PTRatio = p.Results.PTRatio;
            obj.TapDelay = p.Results.TapDelay;
            obj.TimeDelay = p.Results.TimeDelay;
            obj.Vlimit = p.Results.Vlimit;
            
            obj.TapLimitPerChange = p.Results.TapLimitPerChange;
            obj.xsfWinding = p.Results.xsfWinding;
            obj.TapNum = p.Results.TapNum;
            
            obj.fNphases = p.Results.fNphases;
            obj.fNconds = p.Results.fNconds;
            obj.fNterms = p.Results.fNterms;
            obj.fPTphase = p.Results.fPTphase;
            obj.ElementTerminal = p.Results.ElementTerminal;
            
            obj.CogenEnabled = p.Results.CogenEnabled;
            obj.InCogenMode = p.Results.InCogenMode;
            
            obj.IsReversible = p.Results.IsReversible;
            obj.InReverseMode = p.Results.InReverseMode;
            obj.ReverseNeutral = p.Results.ReverseNeutral;
            
            obj.ReversePending = p.Results.ReversePending;
            obj.fInverseTime = p.Results.fInverseTime;
            
            obj.ElementName = p.Results.ElementName;
            obj.RegulatedBus = p.Results.RegulatedBus;
            
            obj.Transformer = p.Results.Transformer;
        end
    end
    
    methods(Static)
        function obj = MakeLike(AnotherRegControlObj)
            p = inputParser;
            nempty = {'nonempty'};
            regctrlchk = {'RegControlObj'};
            
            addRequired(p,'AnotherRegControlObj',@(x)validateattributes(x,regctrlchk,nempty));
            parse(p,AnotherRegControlObj);
            
            args{1} = p.Results.AnotherRegControlObj.Bandwidth;
            args{2} = p.Results.AnotherRegControlObj.BaseVoltage;
            args{3} = p.Results.AnotherRegControlObj.CTRating;
            
            args{3} = p.Results.AnotherRegControlObj.RevBandwidth;
            args{4} = p.Results.AnotherRegControlObj.RevDelay;
            args{5} = p.Results.AnotherRegControlObj.RevPowerThreshold;
            args{6} = p.Results.AnotherRegControlObj.RevVreg;
            args{7} = p.Results.AnotherRegControlObj.Vreg;
            
            args{8} = p.Results.AnotherRegControlObj.LDC_Z;
            args{9} = p.Results.AnotherRegControlObj.R;
            args{10} = p.Results.AnotherRegControlObj.X;
            
            args{11} = p.Results.AnotherRegControlObj.revLDC_Z;
            args{12} = p.Results.AnotherRegControlObj.revR;
            args{13} = p.Results.AnotherRegControlObj.revX;
            
            args{14} = p.Results.AnotherRegControlObj.PTRatio;
            args{15} = p.Results.AnotherRegControlObj.TapDelay;
            args{16} = p.Results.AnotherRegControlObj.TimeDelay;
            args{17} = p.Results.AnotherRegControlObj.Vlimit;
            
            args{18} = p.Results.AnotherRegControlObj.TapLimitPerChange;
            args{19} = p.Results.AnotherRegControlObj.xsfWinding;
            args{20} = p.Results.AnotherRegControlObj.TapNum;
            
            args{21} = p.Results.AnotherRegControlObj.fNphases;
            args{22} = p.Results.AnotherRegControlObj.fNconds;
            args{23} = p.Results.AnotherRegControlObj.fNterms;
            args{24} = p.Results.AnotherRegControlObj.fPTphase;
            args{25} = p.Results.AnotherRegControlObj.ElementTerminal;
            
            args{26} = p.Results.AnotherRegControlObj.CogenEnabled;
            args{27} = p.Results.AnotherRegControlObj.InCogenMode;
            
            args{28} = p.Results.AnotherRegControlObj.IsReversible;
            args{29} = p.Results.AnotherRegControlObj.InReverseMode;
            args{30} = p.Results.AnotherRegControlObj.ReverseNeutral;
            
            args{31} = p.Results.AnotherRegControlObj.ReversePending;
            args{32} = p.Results.AnotherRegControlObj.fInverseTime;
            
            args{33} = p.Results.AnotherRegControlObj.ElementName;
            args{34} = p.Results.AnotherRegControlObj.RegulatedBus;
            
            args{35} = p.Results.AnotherRegControlObj.Transformer;
            
            obj = RegControlObj(args{:});
        end
    end
end
