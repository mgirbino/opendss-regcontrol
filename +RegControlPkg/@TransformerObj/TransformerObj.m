classdef TransformerObj < Simulink.Parameter
    %TRANSFORMEROBJ Object defining multi-phase transformer
    %   Data from OpenDSS Transformer class that's relevant to simulation
    
    properties (PropertyType = 'logical scalar')
        HVLeadsLV
        IsSubstation
        XRConst % whether X/R is assumed constant for harmonic studies
        
        XHLChanged
    end
    
    properties (PropertyType = 'char')
        bank % name
    end
    
    properties (PropertyType = 'int32 scalar')
        NumWindings
        fNterms
        fNconds
        fNphases % number, 3 by default
        
        ActiveWinding
        DeltaDirection
        Yorder
    end
    
    properties % (PropertyType = 'WindingObj vector')
        Winding
    end
    
    properties (PropertyType = 'double scalar')      
        
        % Reg1 Transformer:
        % phases=1 
        % bank=reg1 
        % XHL=0.01 
        % kVAs=[1666 1666]
        % Buses=[650.1 RG60.1] 
        % kVs=[2.4  2.4] 
        % LoadLoss=0.01
        
        % Reg1 RegControl:  
        % transformer=Reg1 
        % winding=2  
        % vreg=122  
        % band=2  
        % ptratio=20 
        % ctprim=700  
        % R=3   
        % X=9

        
        pctImag % percent magnetizing current. Magnetizing branch is
            % in parallel with windings in each phase
        pctLoadLoss % percent load loss at full load
            % side effect: %R of High and Low windings (1 and 2)
        pctNoLoadLoss % at rated excitation voltage
            % converts to a resistance in parallel with the magnetizing
            % impedance in each winding
        %   %R
        %   %Rs
        
        %   basefreq
        %   bus
        %   buses
        %   conn % connection of this winding
        %   conns
        %   emergamps
        EmergMaxHkVA % emergency/contingency rating for H winding
            % usually 140-150% of maximum nameplate rating, depending
            % on load shape
        %   enabled
        FaultRate % failure rate per year
        FLrise % full load temperature rise, deg C
        HSrise % hot spot temperature rise, deg C
        %   kV
        %   kVA
        kVAs % kVA ratings of all windings in an array
        %   kVs
        %   like
        %   m
        %   MaxTap % 1.10 by default
        %   MinTap % 0.90 by default
        %   n
        %   normamps
        NormMaxHkVA % of H winding (winding 1) -- usually 100% - 110%
            % of maximum nameplate rating, depending on load shape
        %   NumTaps
        %   pctperm
        
        %   ppm_antifloat
        %   repair
        %   Rneut
        %   subname
        %   tap % p.u. tap that this winding is on
        %   taps % p.u. tap of all windings in an array
        %   thermal
        %   wdg
        %   windings % number of windings, default is 2.
        %   X12
        %   X13
        %   X23
        %   XfmrCode
        XHL % percent reactance, H-L (winding 1 to winding 2)
            % for 2- and 3-winding transformers
            % on the kva base of winding 1
        XHT
        XLT
        %   Xneut
        ThermalTimeconst
        n_thermal
        m_thermal     
        ppm_FloatFactor % ppm of xsformer VA rating connected to groud
            % to protect against accidentally floating a winding without
            % a reference. Positive --> adding very large reactance to gnd
            % Negative --> a capacitor
        Y_Terminal_FreqMult
    end
    
    properties % (PropertyType = 'double vector')
        XSC@double % the percent reactance between all paris of windings
    end
    
    methods
        function obj = SetNumWindings(obj, N)
            if N <= 1
                msg = 'Error: Number of Windings must be > 1';
                error(msg)
            end
            
            OldWdgSize  = (obj.NumWindings-1) * fix(obj.NumWindings/2); % fix: ML equivalent to Pascal div (division, discarding fractional part)
            obj.NumWindings = N;
            MaxWindings = N;
            NewWdgSize  = (obj.NumWindings-1) * fix(obj.NumWindings/2);
            obj.fNconds = obj.fNphases + 1;
            obj.fNterms = obj.NumWindings;
            
            obj.Winding = RegControlPkg.WindingObj.empty;
            for i = 1:MaxWindings
                obj.Winding(i) = RegControlPkg.WindingObj;
            end

            % array of short circuit measurements between pairs of windings
            obj.XSC = [];
            for i = (OldWdgSize+1):NewWdgSize
                obj.XSC(i) = 0.30;
            end
            % Reallocmem(TermRef, SizeOf(TermRef^[1]) * 2 * NumWindings*fNphases);

%                 ZB.Free;
%                 Y_1Volt.Free;
%                 Y_1Volt_NL.Free;
%                 Y_Term.Free;
%                 Y_Term_NL.Free;
% 
%                 ZB         = TCMatrix.CreateMatrix(NumWindings - 1);
%                 Y_1Volt    = TCMatrix.CreateMatrix(NumWindings);
%                 Y_1Volt_NL = TCMatrix.CreateMatrix(NumWindings);
%                 Y_Term     = TCMatrix.CreateMatrix(2 * NumWindings);
%                 Y_Term_NL  = TCMatrix.CreateMatrix(2 * NumWindings);
        end
        
        function obj = TransformerObj(varargin)
            %TRANSFORMEROBJ Construct an instance of Transformer using specified
            %parameters (defaults for unspecified)
            
            p = inputParser;
            numchk = {'numeric'};
            boolchk = {'logical'};
            charchk = {'char'};
            
            nempty = {'nonempty'};
            posint = {'nonempty','integer','positive'};
            pospct = {'nonempty','positive'};
            
            
            addOptional(p,'HVLeadsLV',false,@(x)validateattributes(x,boolchk,nempty));            
            addOptional(p,'IsSubstation',false,@(x)validateattributes(x,boolchk,nempty));
            addOptional(p,'XRConst',false,@(x)validateattributes(x,boolchk,nempty));            
            
            addOptional(p,'bank','none',@(x)validateattributes(x,charchk,nempty));
            
            addOptional(p,'NumWindings',2,@(x)validateattributes(x,numchk,posint));
            % addOptional(p,'fNterms',0,@(x)validateattributes(x,numchk,posint));
            % addOptional(p,'fNconds',0,@(x)validateattributes(x,numchk,posint));
            addOptional(p,'fNphases',3,@(x)validateattributes(x,numchk,posint));

            addOptional(p,'pctImag',0,@(x)validateattributes(x,numchk,pospct));
            addOptional(p,'pctLoadLoss',0,@(x)validateattributes(x,numchk,pospct));
            addOptional(p,'pctNoLoadLoss',0,@(x)validateattributes(x,numchk,pospct));
            addOptional(p,'FaultRate',0.007,@(x)validateattributes(x,numchk,pospct));

            addOptional(p,'EmergMaxHkVA',0,@(x)validateattributes(x,numchk,nempty));
            addOptional(p,'FLrise',65.0,@(x)validateattributes(x,numchk,nempty));
            addOptional(p,'HSrise',15.0,@(x)validateattributes(x,numchk,nempty));
            
            addOptional(p,'NormMaxHkVA',0,@(x)validateattributes(x,numchk,nempty));
            addOptional(p,'XHL',0.07,@(x)validateattributes(x,numchk,nempty));
            addOptional(p,'XHT',0.35,@(x)validateattributes(x,numchk,nempty));
            addOptional(p,'XLT',0.30,@(x)validateattributes(x,numchk,nempty));         
 
            addOptional(p,'ThermalTimeconst',2.0,@(x)validateattributes(x,numchk,nempty));
            addOptional(p,'n_thermal',0.8,@(x)validateattributes(x,numchk,nempty));
            addOptional(p,'m_thermal',0.8,@(x)validateattributes(x,numchk,nempty));
            addOptional(p,'ppm_FloatFactor',0.000001,@(x)validateattributes(x,numchk,nempty));
            addOptional(p,'Y_Terminal_FreqMult',0,@(x)validateattributes(x,numchk,nempty));
            
            parse(p,varargin{:});
                        
            obj.fNphases = p.Results.fNphases;
            obj.fNconds = obj.fNphases+1;
            obj.NumWindings = p.Results.NumWindings;
            obj = obj.SetNumWindings(2); % must do this after setting number of phases
            obj.ActiveWinding = 1;
            
            obj.fNterms  = obj.NumWindings;  % Force allocation of terminals and conductors
            
            obj.XHL = p.Results.XHL;
            obj.XHT = p.Results.XHT;
            obj.XLT = p.Results.XLT;
            obj.XHLChanged = true; % Set flag to for calc of XSC array from XHL, etc.
            
            obj.DeltaDirection = 1;
            
            %VABase           = Winding^[1].kVA*1000.0;
            obj.ThermalTimeconst = p.Results.ThermalTimeconst;
            obj.n_thermal        = p.Results.n_thermal;
            obj.m_thermal        = p.Results.m_thermal;
            obj.FLrise           = p.Results.FLrise;
            obj.HSrise           = p.Results.HSrise;  % Hot spot rise
            
            obj.NormMaxHkVA = p.Results.NormMaxHkVA;
            obj.EmergMaxHkVA = p.Results.EmergMaxHkVA;
            obj.pctLoadLoss = p.Results.pctLoadLoss;
            
            if obj.NormMaxHkVA == 0 % unspecified
                obj.NormMaxHkVA = 1.1 * obj.Winding(1).kVA;
            end
            if obj.EmergMaxHkVA == 0
                obj.EmergMaxHkVA = 1.5 * obj.Winding(1).kVA; 
            end
            if obj.pctLoadLoss == 0
                obj.pctLoadLoss = 2.0 * obj.Winding(1).Rpu * 100.0; %  assume two windings for init'ing
            end
            
            obj.ppm_FloatFactor  = p.Results.ppm_FloatFactor;
            
%             for i = 1:obj.NumWindings 
%                 obj.Winding(1).ComputeAntiFloatAdder(ppm_FloatFactor, VABase/FNPhases);
%             end

            obj.pctNoLoadLoss = p.Results.pctNoLoadLoss;
            obj.pctImag = p.Results.pctImag;

            obj.FaultRate = p.Results.FaultRate;
            obj.IsSubstation = p.Results.IsSubstation;
            obj.XRConst = p.Results.XRConst;

            obj.HVLeadsLV = p.Results.HVLeadsLV;

            obj.Y_Terminal_FreqMult = p.Results.Y_Terminal_FreqMult;

            obj.Yorder = obj.fNterms * obj.fNconds;
            
            obj.bank = p.Results.bank;
        end
        
%         function obj = MakeLike(AnotherTransformer)
%             %MAKELIKE Construct an instance of Transformer by copying the
%             %parameters of another transformer
%             
%             p = inputParser;
%             nempty = {'nonempty'};
%             xsfrmrchk = {'Transformer'};
%             
%             addRequired(p,'AnotherTransforemr',@(x)validateattributes(x,xsfrmrchk,nempty));
%             parse(p,AnotherTransformer);
%             
%             obj.Connection = p.Results.AnotherTransformer.Connection;
%             
%             obj.fNphases = p.Results.AnotherTransformer.fNphases;
%             obj.fNConds = obj.fNphases+1;
%             obj.NumWindings = p.Results.AnotherTransformer.NumWindings;
%             obj = obj.SetNumWindings(obj, 2); % must do this after setting number of phases
%             obj.ActiveWinding = 1;
%             
%             obj.fNterms  = obj.AnotherTransformer.NumWindings;  % Force allocation of terminals and conductors
%             
%             obj.XHL = p.Results.AnotherTransformer.XHL;
%             obj.XHT = p.Results.AnotherTransformer.XHT;
%             obj.XLT = p.Results.AnotherTransformer.XLT;
%             obj.XHLChanged = AnotherTransformer.True; % Set flag to for calc of XSC array from XHL, etc.
%             
%             obj.DeltaDirection = 1;
%             
%             obj.ThermalTimeconst = p.Results.AnotherTransformer.ThermalTimeconst;
%             obj.n_thermal        = p.Results.AnotherTransformer.n_thermal;
%             obj.m_thermal        = p.Results.AnotherTransformer.m_thermal;
%             obj.FLrise           = p.Results.AnotherTransformer.FLrise;
%             obj.HSrise           = p.Results.AnotherTransformer.HSrise;  % Hot spot rise
%             
%             obj.NormMaxHkVA = p.Results.AnotherTransformer.NormMaxHkVA;
%             obj.EmergMaxHkVA = p.Results.AnotherTransformer.EmergMaxHkVA;
%             obj.pctLoadLoss = p.Results.AnotherTransformer.pctLoadLoss;
%             
%             obj.ppm_FloatFactor  = p.Results.AnotherTransformer.ppm_FloatFactor;
% 
%             obj.pctNoLoadLoss = p.Results.AnotherTransformer.pctNoLoadLoss;
%             obj.pctImag = p.Results.AnotherTransformer.pctImag;
% 
%             obj.FaultRate = p.Results.AnotherTransformer.FaultRate;
%             obj.IsSubstation = p.Results.AnotherTransformer.IsSubstation;
%             obj.XRConst = p.Results.AnotherTransformer.XRConst;
% 
%             obj.HVLeadsLV = p.Results.AnotherTransformer.HVLeadsLV;
% 
%             obj.Y_Terminal_FreqMult = p.Results.AnotherTransformer.Y_Terminal_FreqMult;
% 
%             obj.Yorder = obj.fNTerms * obj.fNconds;
%             
%             obj.bank = p.Results.AnotherTransformer.bank;
%         end
        
        function [obj, RotatedPhase] = RotatePhases(obj, IndicatedPhase)
            %ROTATEPHASES Cycles through transformer's phases and updates
            %the transformer's DeltaDirection
            
            p = inputParser;
            numchk = {'numeric'};
            xsfrmrchk = {'Transformer'};
            posint = {'nonempty','integer','positive'};
            nempty = {'nonempty'};
            
            addRequired(p,'IndicatedPhase',@(x)validateattributes(x,numchk,posint));
            addRequired(p,'obj',@(x)validateattributes(x,xsfrmrchk,nempty));
            parse(p,AnotherTransformer);
                        
            
            obj.HVLeadsLV = false;
            % FIRST NEED TO DETERMINE DELTADIRECTION:
            % If high voltage is delta, delta leads y (1)
            % If high voltage is wye, delta lags wye (2)
            if obj.Winding(1).Connection == obj.Winding(2).Connection
                obj.DeltaDirection = 1;
            else
                if obj.Winding(1).kvll >= obj.Winding(2).kvll
                    iHvolt = 1;
                else
                    iHVolt = 2;
                end
                switch obj.Winding(iHvolt).Connection
                    case 0
                        if obj.HVLeadsLV
                            obj.DeltaDirection = -1;
                        else
                            obj.DeltaDirection = 1;
                        end
                    case 1
                        if obj.HVLeadsLV
                            obj.DeltaDirection = 1;
                        else
                            obj.DeltaDirection = -1;
                        end
                end
            end

            % NOW, ACTUALLY DETERMINE PHASE ROTATION
            RotatedPhase = p.Results.IndicatedPhase + obj.DeltaDirection;

            % make sure RotatedPhase is within limits:
            if obj.fNphases > 2
                % Assumes 2 phase delta is open delta
                if RotatedPhase > obj.fNphases
                    RotatedPhase = 1;
                elseif RotatedPhase < 1
                    RotatedPhase = obj.fNphases;
                end
            elseif RotatedPhase < 1
                RotatedPhase = 3; % For 2-phase delta, next phase will be 3rd phase
            end
        end
        
        function pt = GetPresentTap(obj, TapIndex)
            %GETPRESENTTAP returns the puTap Winding value for a given
            %TapIndex
            
            if TapIndex > 0 && TapIndex <= obj.NumWindings
                pt = obj.Winding(TapIndex).puTap;
            else
                pt = 0;
            end
        end
        
        function obj = SetPresentTap(obj, TapIndex, Value)
            %SETPRESENTTAP modifies the puTap Winding value, selecting the
            %Winding using TapIndex
            
            % index bounds check:
            if TapIndex > 0 && TapIndex <= obj.NumWindings
                TempVal = Value;
                
                % tap saturation/bounds check:
                if TempVal < obj.Winding(TapIndex).MinTap
                    TempVal = obj.Winding(TapIndex).MinTap;
                elseif TempVal > obj.Winding(TapIndex).MaxTap
                    TempVal = obj.Winding(TapIndex).MaxTap;
                end
                
                % set to new value if it's different from original:
                if TempVal ~= obj.Winding(TapIndex).puTap
                    obj.Winding(TapIndex).puTap = TempVal;
                end
            end
        end
    end % of regular methods
    
    methods(Static)
        function obj = MakeLike(AnotherTransformer)
            %MAKELIKE Construct an instance of Transformer by copying the
            %parameters of another transformer
            
            p = inputParser;
            nempty = {'nonempty'};
            xsfrmrchk = {'TransformerObj'};
            
            addRequired(p,'AnotherTransforemr',@(x)validateattributes(x,xsfrmrchk,nempty));
            parse(p,AnotherTransformer);
            
            args{1} = p.Results.AnotherRegControlObj.Bandwidth;
            args{2} = p.Results.AnotherTransformer.Connection;
            
            args{3} = p.Results.AnotherTransformer.fNphases;
            % obj.fNConds = obj.fNphases+1;
            args{4} = p.Results.AnotherTransformer.NumWindings;
            % obj = obj.SetNumWindings(obj, 2); % must do this after setting number of phases
            args{5} = 1;
            
            args{6}  = obj.AnotherTransformer.NumWindings;  % Force allocation of terminals and conductors
            
            args{7} = p.Results.AnotherTransformer.XHL;
            args{8} = p.Results.AnotherTransformer.XHT;
            args{9} = p.Results.AnotherTransformer.XLT;
            % obj.XHLChanged = true; % Set flag to for calc of XSC array from XHL, etc.
            
            % obj.DeltaDirection = 1;
            
            args{10} = p.Results.AnotherTransformer.ThermalTimeconst;
            args{11}       = p.Results.AnotherTransformer.n_thermal;
            args{12}        = p.Results.AnotherTransformer.m_thermal;
            args{13}           = p.Results.AnotherTransformer.FLrise;
            args{14}           = p.Results.AnotherTransformer.HSrise;  % Hot spot rise
            
            args{15} = p.Results.AnotherTransformer.NormMaxHkVA;
            args{16} = p.Results.AnotherTransformer.EmergMaxHkVA;
            args{17} = p.Results.AnotherTransformer.pctLoadLoss;
            
            args{18}  = p.Results.AnotherTransformer.ppm_FloatFactor;

            args{19} = p.Results.AnotherTransformer.pctNoLoadLoss;
            args{20} = p.Results.AnotherTransformer.pctImag;

            args{21} = p.Results.AnotherTransformer.FaultRate;
            args{22} = p.Results.AnotherTransformer.IsSubstation;
            args{23} = p.Results.AnotherTransformer.XRConst;

            args{24} = p.Results.AnotherTransformer.HVLeadsLV;

            args{25} = p.Results.AnotherTransformer.Y_Terminal_FreqMult;

            % obj.Yorder = obj.fNTerms * obj.fNconds;
            
            args{26} = p.Results.AnotherTransformer.bank;
            
            obj = TransformerObj(args{:});
        end
    end
end

