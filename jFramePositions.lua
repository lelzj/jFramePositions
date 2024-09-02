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
                    FadeAble = true,
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
                    FadeAble = true,
                    Moving = {
                        Movable = false,
                        RelativeFrame = UIParent,
                        AnchorPoint = 'right',
                        RelativePoint = 'center',
                        x = 365,
                        y = -150,
                    },
                },
                FocusFrame = {
                    Alpha = 0.9,
                    FadeAble = true,
                    Moving = {
                        Movable = false,
                        RelativeFrame = UIParent,
                        AnchorPoint = 'right',
                        RelativePoint = 'center',
                        x = 600,
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
        Addon.FRAMES.ApplyClassicSettings = function( self,Window )
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
                if( s.FadeAble ) then
                    --Window:SetAlpha( 0 );
                else
                    Window:SetAlpha( s.Alpha );
                end
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
                            self:ApplyClassicSettings( _G[Window:GetName()] );
                        end );
                        self.Hooked[ Hook ] = true;
                    end
                end
            end
        end

        Addon.FRAMES.ApplyRetailSettings = function( self,Window )
            if( EditModeManagerFrame ) then
                Addon:Dump( EDIT_MODE_MODERN_SYSTEM_MAP ) -- < what is here? anything? what about EDIT_MODE_MODERN_SYSTEM_MAP.Enum if yes?
                print( AddonName..' just dumped data' );
                Enum.EditModeSystem.ChatFrame = {
                    anchorInfo = {
                        point = self:GetSettings().ChatFrame1.Moving.AnchorPoint,
                        relativeTo = self:GetSettings().ChatFrame1.Moving.RelativeFrame,
                        relativePoint = self:GetSettings().ChatFrame1.Moving.RelativePoint,
                        offsetX = self:GetSettings().ChatFrame1.Moving.x,
                        offsetY = self:GetSettings().ChatFrame1.Moving.y,
                    },
                };
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
                        if( Addon:IsClassic() or Addon:IsWrath() ) then
                            self:ApplyClassicSettings( Window );
                            --self:ApplyRetailSettings();
                        else
                            self:ApplyClassicSettings( Window );
                            --self:ApplyRetailSettings();
                        end
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
                self.Events:RegisterEvent( 'SPELLS_CHANGED' );
            end
            -- /wow-retail-source/Interface/FrameXML/EditModePresetLayouts.lua
            -- https://wowpedia.fandom.com/wiki/Category:API_namespaces/C_EditMode
            --[[if( EditModeManagerFrame ) then
                print( 'jFramePositions printing useCompactPartyFrames value' );
                print( Enum.EditModeUnitFrameSetting.UseRaidStylePartyFrames );
            end]]

            --[[
            local FaderFrame = CreateFrame( 'Frame' );
            FaderFrame:RegisterEvent( 'PLAYER_TARGET_CHANGED' );
            FaderFrame:RegisterEvent( 'PLAYER_REGEN_DISABLED' );
            FaderFrame:RegisterEvent( 'UNIT_HEALTH' );
            FaderFrame:RegisterEvent( 'UNIT_AURA' );
            FaderFrame:SetScript( 'OnEvent',function( self,Event,... )
                if( InCombatLockdown() ) then
                    return;
                end
                local a = UnitAffectingCombat( 'player' ) and 1 or 0;
                for Window,WindowData in pairs( Addon.FRAMES:GetSettings() ) do
                    Window = _G[ Window ] or false;
                    if( Window and WindowData.FadeAble ) then
                        if( Event == 'PLAYER_REGEN_DISABLED' ) then
                            a = WindowData.Alpha;
                        elseif( Event == 'PLAYER_TARGET_CHANGED' ) then
                            if( UnitExists( 'target' ) ) then
                                a = WindowData.Alpha;
                            end
                        elseif( Event == 'UNIT_AURA' ) then
                            local AuraData = select( 2,... );
                            if( AuraData.addedAuras ) then
                                for i,Aura in pairs( AuraData.addedAuras ) do
                                    if( Aura.sourceUnit and Addon:Minify( Aura.sourceUnit ):find( 'player' ) ) then
                                        if( Aura.name and Addon:Minify( Aura.name ):find( 'food' ) ) then
                                            a = WindowData.Alpha;
                                        end
                                        if( Aura.name and Addon:Minify( Aura.name ):find( 'drink' ) ) then
                                            a = WindowData.Alpha;
                                        end
                                    end
                                end
                            end
                        elseif( Event == 'UNIT_HEALTH' ) then
                            local Unit = select( 1,... );
                            if( Addon:Minify( Unit ):find( 'player' ) ) then
                                if( UnitHealth( 'player' ) >= UnitHealthMax( 'player' ) ) then
                                    a = 0;
                                else
                                    a = WindowData.Alpha;
                                end
                            end
                        else
                            if( a > 0 ) then
                                a = WindowData.Alpha;
                            end
                        end
                        Window:SetAlpha( a );
                    end
                end
            end );
            ]]

            self.Events:SetScript( 'OnEvent',function( self,Event,... )
                if( Event == 'PLAYER_LEVEL_UP' ) then
                    C_Timer.After( 2, function()
                        Addon.FRAMES:Refresh();
                    end );
                else
                    Addon.FRAMES:Refresh();
                end
            end );
        end

        local EventFrame = CreateFrame( 'Frame' );
        EventFrame:RegisterEvent( 'COMPACT_UNIT_FRAME_PROFILES_LOADED' );
        EventFrame:SetScript( 'OnEvent',function()
            self:Init();
            self:Refresh();
            C_Timer.After( 2,function()
                self:Run();
            end );
        end );
        self:UnregisterEvent( 'ADDON_LOADED' );
    end
end );