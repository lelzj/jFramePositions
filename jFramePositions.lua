local _, Addon = ...;

Addon.FRAMES = CreateFrame( 'Frame' );
Addon.FRAMES:RegisterEvent( 'ADDON_LOADED' );
Addon.FRAMES:SetScript( 'OnEvent',function( self,Event,AddonName )
    if( AddonName == 'jFramePositions' ) then

        self.Hooked = {};

        --
        --  Get module defaults
        --
        --  @return table
        Addon.FRAMES.GetDefaults = function( self )
            return {
            };
        end

        Addon.FRAMES.SetValue = function( self,Index,Value )
            if( self.persistence[ Index ] ~= nil ) then
                self.persistence[ Index ] = Value;
            end
        end

        Addon.FRAMES.GetValue = function( self,Index )
            if( self.persistence[ Index ] ~= nil ) then
                return self.persistence[ Index ];
            end
        end

        --
        --  Get module settings
        --
        --  @return table
        Addon.FRAMES.GetSettings = function( self )
            return {
                PlayerFrame = {
                    Alpha = 0.9,
                    Moving = {
                        Movable = false,
                        RelativeFrame = UIParent,
                        AnchorPoint = 'right',
                        RelativePoint = 'center',
                        x = -130,
                        y = -150,
                    },
                },
                TargetFrame = {
                    Alpha = 0.9,
                    Moving = {
                        Movable = false,
                        RelativeFrame = UIParent,
                        AnchorPoint = 'right',
                        RelativePoint = 'center',
                        x = 340,
                        y = -150,
                    },
                },
                FocusFrame = {
                    Alpha = 0.9,
                    Moving = {
                        Movable = false,
                        RelativeFrame = UIParent,
                        AnchorPoint = 'right',
                        RelativePoint = 'center',
                        x = 370,
                        y = -50,
                    },
                },
                ChatFrame1 = {
                    Alpha = 1,
                    Moving = {
                        Movable = true,
                        RelativeFrame = UIParent,
                        AnchorPoint = 'right',
                        RelativePoint = 'center',
                        x = -600,
                        y = -212,
                    },
                    Width = 474,
                    Height = 350,
                    Hooks = {
                        'FCF_ResetAllWindows',
                        'FloatingChatFrame_Update',
                    },
                },
            };
        end

        -- Update Window
        --
        -- @param   string  Window
        -- return void
        Addon.FRAMES.ApplySettings = function( self,Window )
            local s = self:GetSettings()[ Window:GetName() ];
            if( s.Width ~= nil ) then
                Window:SetWidth( s.Width )
            end
            if( s.Height ~= nil ) then
                Window:SetHeight( s.Height )
            end
            if( s.Scale ~= nil ) then
                Window:SetScale( s.Scale )
            end
            if( s.Alpha ~= nil ) then
                Window:SetAlpha( s.Alpha )
            end
            if( not s.Moving ) then
                return;
            end
            if( InCombatLockdown() ) then
                return;
            end

            local _ap, _, _relp, _x = Window:GetPoint();
            if( _ap ~= s.Moving.AnchorPoint or _relp ~= s.Moving.RelativePoint or Round( tonumber( _x ) ) ~= s.Moving.x ) then
                Window:ClearAllPoints();
                Window:SetMovable( true );
                Window:SetPoint( 
                    s.Moving.AnchorPoint,
                    s.Moving.RelativeFrame or nil,
                    s.Moving.RelativePoint,
                    s.Moving.x,
                    s.Moving.y 
                );
                Window:StartMoving();
                Window:SetUserPlaced( true );
                Window:StopMovingOrSizing();
                Window:SetMovable( s.Moving.Movable );
                if not s.Moving.Movable then
                    Window:SetScript( 'OnDragStart', function( self )
                        return;
                    end );
                end
            end
            if( s.Hooks ) then
                for i,Hook in ipairs( s.Hooks ) do
                    if( not self.Hooked[ Hook ] ) then
                        hooksecurefunc( Hook, function()
                            self:ApplySettings( _G[Window:GetName()] );
                        end );
                        self.Hooked[ Hook ] = true;
                    end
                end
            end
        end

        --
        --  Module refresh
        --
        --  @return void
        Addon.FRAMES.Refresh = function( self )
            if( not self.persistence ) then
                return;
            end
            C_Timer.After( 1, function()
                for Window,i in pairs( self:GetSettings() ) do
                    Window = _G[ Window ] or false;
                    if( Window ) then
                        self:ApplySettings( Window );
                    end
                end
            end );
        end

        --
        --  Module init
        --
        --  @return void
        Addon.FRAMES.Init = function( self )
            -- Database
            self.db = LibStub( 'AceDB-3.0' ):New( AddonName,{ char = self:GetDefaults() },true );
            if( not self.db ) then
                return;
            end
            self.persistence = self.db.char;
            if( not self.persistence ) then
                return;
            end
        end

        --
        --  Module run
        --
        --  @return void
        Addon.FRAMES.Run = function( self )
            -- Events frame
            self.Events = CreateFrame( 'Frame' );
            -- Reset edits
            if( EditModeManagerFrame ) then
                EventRegistry:RegisterCallback( 'EditMode.Enter', function()
                end );
                EventRegistry:RegisterCallback( 'EditMode.Exit', function()
                    self:Refresh();
                end );
            end
            -- Reset events
            if( not Addon:IsClassic() ) then
                self.Events:RegisterEvent( 'CINEMATIC_STOP' );
                self.Events:RegisterEvent( 'PLAYER_ENTERING_WORLD' );
                self.Events:RegisterEvent( 'PLAYER_LEVEL_UP' );
            end
            -- /wow-retail-source/Interface/FrameXML/EditModePresetLayouts.lua
            self.Events:SetScript( 'OnEvent',function( self,Event )
                Addon.FRAMES:Refresh();
            end );
        end

        self:Init();
        self:Refresh();
        self:Run();
        self:UnregisterEvent( 'ADDON_LOADED' );
    end
end );