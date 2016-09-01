classdef VersionObject
    
    properties (Access = public)
        release;
        revision;
        name;
    end
    
    methods
        
        function obj = VersionObject(varargin)
            
            params = struct(...
                'release', [], ...
                'revision', [] ...
            );
            
            params = structInpParse(params,varargin);
            
            obj.release = params.release;
            obj.revision = params.revision;
            obj.name = sprintf('%d.%d',obj.release,obj.revision);
            
        end
        
        function bool = eq(obj,testwith)
            bool = version_check(obj,testwith,'==');
        end
        
        function bool = lt(obj,testwith)
            bool = version_check(obj,testwith,'<');
        end
        
        function bool = le(obj,testwith)
            bool = version_check(obj,testwith,'<=');
        end
        
        function bool = gt(obj,testwith)
            bool = version_check(obj,testwith,'>');
        end
        
        function bool = ge(obj,testwith)
            bool = version_check(obj,testwith,'>=');
        end
        
        function bool = version_check(obj,testwith,type)
            bool = false;
            
            switch type
                
                case '=='
                    if obj.release == testwith.release && ...
                            obj.revision == testwith.revision
                        bool = true; return;
                    end
                
                case '<'
                    if obj.release < testwith.release
                        bool = true; return;
                    end
                    
                    if obj.release == testwith.release && ...
                            obj.revision < testwith.revision
                        bool = true; return;
                    end
                case '<='
                    if obj.release < testwith.release
                        bool = true; return;
                    end
                    
                    if obj.release == testwith.release && ...
                            obj.revision <= testwith.revision
                        bool = true; return;
                    end
                    
                case '>'
                    
                    if obj.release > testwith.release
                        bool = true; return;
                    end
                    
                    if obj.release == testwith.release && ...
                            obj.revision > testwith.revision
                        bool = true; return;
                    end
                    
                case '>='
                    
                    if obj.release > testwith.release
                        bool = true; return;
                    end
                    
                    if obj.release == testwith.release && ...
                            obj.revision >= testwith.revision
                        bool = true; return;
                    end
            end
                
        end    
            
    end
    
end