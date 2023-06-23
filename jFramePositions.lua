local _, Addon = ...;

Addon.FRAMES = CreateFrame( 'Frame' );
Addon.FRAMES:RegisterEvent( 'ADDON_LOADED' );
Addon.FRAMES:SetScript( 'OnEvent',function( self,Event,AddonName )
    if( AddonName == 'jFramePositions' ) then

        Addon.FRAMES.Hooked = {};

        --
        --  Get module defaults
        --
        --  @return table
        Addon.FRAMES.GetDefaults = function( self )
            return {
            };
        end

        Addon.FRAMES.SetValue = function( self,Index,Value )
            if( Addon.FRAMES.persistence[ Index ] ~= nil ) then
                Addon.FRAMES.persistence[ Index ] = Value;
            end
        end

        Addon.FRAMES.GetValue = function( self,Index )
            if( Addon.FRAMES.persistence[ Index ] ~= nil ) then
                return Addon.FRAMES.persistence[ Index ];
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
                        Movable = false,
                        RelativeFrame = UIParent,
                        AnchorPoint = 'right',
                        RelativePoint = 'center',
                        x = -600,
                        y = -212,
                    },
                    width = 474,
                    height = 350,
                    hooks = {
                        'FCF_ResetAllWindows',
                        'FloatingChatFrame_Update',
                    },
                },
            };
        end

        --
        --  Create module config frames
        --
        --  @return void
        Addon.FRAMES.CreateFrames = function( self )
        end

        -- Update Window
        --
        -- @param   string  Window
        -- return void
        Addon.FRAMES.ApplySettings = function( self,Window )
            local s = Addon.FRAMES:GetSettings()[ Window:GetName() ];
            if( s.width ~= nil ) then
                Window:SetWidth( s.width )
            end
            if( s.height ~= nil ) then
                Window:SetHeight( s.height )
            end
            if( s.scale ~= nil ) then
                Window:SetScale( s.scale )
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

            local _ap, _, _relp, _x = Window:GetPoint()
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
            if( s.hooks ) then
                for i,Hook in ipairs( s.hooks ) do
                    if( not Addon.FRAMES.Hooked[ Hook ] ) then
                        hooksecurefunc( Hook, function()
                            Addon.FRAMES:ApplySettings( _G[Window:GetName()] );
                        end );
                        Addon.FRAMES.Hooked[ Hook ] = true;
                    end
                end
            end
        end

        --
        --  Module refresh
        --
        --  @return void
        Addon.FRAMES.Refresh = function( self )
            if( not Addon.FRAMES.persistence ) then
                return;
            end
            C_Timer.After( 1, function()
                for Window,i in pairs( Addon.FRAMES:GetSettings() ) do
                    Window = _G[ Window ] or false;
                    if( Window ) then
                        Addon.FRAMES:ApplySettings( Window );
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
            Addon.FRAMES.db = LibStub( 'AceDB-3.0' ):New( AddonName,{ char = Addon.FRAMES:GetDefaults() },true );
            if( not Addon.FRAMES.db ) then
                return;
            end
            Addon.FRAMES.persistence = Addon.FRAMES.db.char;
            if( not Addon.FRAMES.persistence ) then
                return;
            end
        end

        --
        --  Module run
        --
        --  @return void
        Addon.FRAMES.Run = function( self )
            -- Events frame
            Addon.FRAMES.Events = CreateFrame( 'Frame' );
            -- Reset edits
            if( EditModeManagerFrame ) then
                EventRegistry:RegisterCallback( 'EditMode.Enter', function()
                end );
                EventRegistry:RegisterCallback( 'EditMode.Exit', function()
                    Addon.FRAMES:Refresh();
                end );
            end
            -- Reset events
            if( not Addon:IsClassic() ) then
                Addon.FRAMES.Events:RegisterEvent( 'CINEMATIC_STOP' );
                Addon.FRAMES.Events:RegisterEvent( 'PLAYER_ENTERING_WORLD' );
                Addon.FRAMES.Events:RegisterEvent( 'PLAYER_LEVEL_UP' );
            end
            Addon.FRAMES.Events:SetScript( 'OnEvent', function( self,Event )
                Addon.FRAMES:Refresh();
            end );
            -- /wow-retail-source/Interface/FrameXML/EditModePresetLayouts.lua
        end

        Addon.FRAMES:Init();
        Addon.FRAMES:Refresh();
        Addon.FRAMES:Run();
        Addon.FRAMES:UnregisterEvent( 'ADDON_LOADED' );
    end
end );