local TUNING = GLOBAL.TUNING

-- 去死吧草蜥蜴
if GetModConfigData("no_gekko") then TUNING.GRASSGEKKO_MORPH_CHANCE = 0 end

-- 五格背包栏
if GetModConfigData("more_slots") then
    local require = GLOBAL.require
    local TheInput = GLOBAL.TheInput
    local ThePlayer = GLOBAL.ThePlayer
    local IsServer = GLOBAL.TheNet:GetIsServer()
    local Inv = require "widgets/inventorybar"

    Assets = {
        Asset("IMAGE", "images/back.tex"), Asset("ATLAS", "images/back.xml"),
        Asset("IMAGE", "images/neck.tex"), Asset("ATLAS", "images/neck.xml")
    }
    -- for key,value in pairs(GLOBAL.EQUIPSLOTS) do print('4r',key,value) end

    GLOBAL.EQUIPSLOTS = {
        HANDS = "hands",
        HEAD = "head",
        BODY = "body",
        BACK = "back",
        NECK = "neck"
    }
    GLOBAL.EQUIPSLOT_IDS = {}
    local slot = 0
    for k, v in pairs(GLOBAL.EQUIPSLOTS) do
        slot = slot + 1
        GLOBAL.EQUIPSLOT_IDS[v] = slot
    end
    slot = nil

    AddComponentPostInit("resurrectable", function(self, inst)
        local original_FindClosestResurrector = self.FindClosestResurrector
        local original_CanResurrect = self.CanResurrect
        local original_DoResurrect = self.DoResurrect

        self.FindClosestResurrector = function(self)
            if IsServer and self.inst.components.inventory then
                local item = self.inst.components.inventory:GetEquippedItem(
                                 GLOBAL.EQUIPSLOTS.NECK)
                if item and item.prefab == "amulet" then
                    return item
                end
            end
            original_FindClosestResurrector(self)
        end

        self.CanResurrect = function(self)
            if IsServer and self.inst.components.inventory then
                local item = self.inst.components.inventory:GetEquippedItem(
                                 GLOBAL.EQUIPSLOTS.NECK)
                if item and item.prefab == "amulet" then
                    return true
                end
            end
            original_CanResurrect(self)
        end

        self.DoResurrect = function(self)
            self.inst:PushEvent("resurrect")
            if IsServer and self.inst.components.inventory then
                local item = self.inst.components.inventory:GetEquippedItem(
                                 GLOBAL.EQUIPSLOTS.NECK)
                if item and item.prefab == "amulet" then
                    self.inst.sg:GoToState("amulet_rebirth")
                    return true
                end
            end
            original_DoResurrect(self)
        end
    end)

    AddComponentPostInit("inventory", function(self, inst)
        local original_Equip = self.Equip
        self.Equip = function(self, item, old_to_active)
            if original_Equip(self, item, old_to_active) and item and
                item.components and item.components.equippable then
                local eslot = item.components.equippable.equipslot
                if self.equipslots[eslot] ~= item then
                    if eslot == GLOBAL.EQUIPSLOTS.BACK and
                        item.components.container ~= nil then
                        self.inst:PushEvent("setoverflow", {overflow = item})
                    end
                end
                return true
            else
                return
            end
        end

        self.GetOverflowContainer = function()
            if self.ignoreoverflow then return end
            local item = self:GetEquippedItem(GLOBAL.EQUIPSLOTS.BACK)
            return item ~= nil and item.components.container or nil
        end
    end)

    AddGlobalClassPostConstruct("widgets/inventorybar", "Inv", function()
        local Inv_Refresh_base = Inv.Refresh or function() return "" end
        local Inv_Rebuild_base = Inv.Rebuild or function() return "" end

        function Inv:LoadExtraSlots(self)
            self.bg:SetScale(1.35, 1, 1.25)
            self.bgcover:SetScale(1.35, 1, 1.25)

            if self.addextraslots == nil then
                self.addextraslots = 1

                self:AddEquipSlot(GLOBAL.EQUIPSLOTS.BACK, "images/back.xml",
                                  "back.tex")
                self:AddEquipSlot(GLOBAL.EQUIPSLOTS.NECK, "images/neck.xml",
                                  "neck.tex")
                -- else
                -- GLOBAL.GetPlayer().HUD.controls.stickyrecipepopup:Refresh()

                if self.inspectcontrol then
                    local W = 68
                    local SEP = 12
                    local INTERSEP = 28
                    local inventory = self.owner.replica.inventory
                    local num_slots = inventory:GetNumSlots()
                    local num_equip = #self.equipslotinfo
                    local num_buttons = self.controller_build and 0 or 1
                    local num_slotintersep = math.ceil(num_slots / 5)
                    local num_equipintersep = num_buttons > 0 and 1 or 0
                    local total_w = (num_slots + num_equip + num_buttons) * W +
                                        (num_slots + num_equip + num_buttons -
                                            num_slotintersep - num_equipintersep -
                                            1) * SEP +
                                        (num_slotintersep + num_equipintersep) *
                                        INTERSEP
                    self.inspectcontrol.icon:SetPosition(-4, 6)
                    self.inspectcontrol:SetPosition((total_w - W) * .5 + 3, -6,
                                                    0)
                end
            end
        end

        function Inv:Refresh()
            Inv_Refresh_base(self)
            Inv:LoadExtraSlots(self)
        end

        function Inv:Rebuild()
            Inv_Rebuild_base(self)
            Inv:LoadExtraSlots(self)
        end
    end)

    AddPrefabPostInit("inventory_classified", function(inst)
        function GetOverflowContainer(inst)
            local item = inst.GetEquippedItem(inst, GLOBAL.EQUIPSLOTS.BACK)
            return item ~= nil and item.replica.container or nil
        end

        function Count(item)
            return item.replica.stackable ~= nil and
                       item.replica.stackable:StackSize() or 1
        end

        function Has(inst, prefab, amount)
            local count = inst._activeitem ~= nil and inst._activeitem.prefab ==
                              prefab and Count(inst._activeitem) or 0

            if inst._itemspreview ~= nil then
                for i, v in ipairs(inst._items) do
                    local item = inst._itemspreview[i]
                    if item ~= nil and item.prefab == prefab then
                        count = count + Count(item)
                    end
                end
            else
                for i, v in ipairs(inst._items) do
                    local item = v:value()
                    if item ~= nil and item ~= inst._activeitem and item.prefab ==
                        prefab then
                        count = count + Count(item)
                    end
                end
            end

            local overflow = GetOverflowContainer(inst)
            if overflow ~= nil then
                local overflowhas, overflowcount = overflow:Has(prefab, amount)
                count = count + overflowcount
            end

            return count >= amount, count
        end

        if not IsServer then
            inst.GetOverflowContainer = GetOverflowContainer
            inst.Has = Has
        end
    end)

    AddStategraphPostInit("wilson", function(self)
        for key, value in pairs(self.states) do
            if value.name == 'amulet_rebirth' then
                local original_amulet_rebirth_onexit = self.states[key].onexit

                self.states[key].onexit = function(inst)
                    local item = inst.components.inventory:GetEquippedItem(
                                     GLOBAL.EQUIPSLOTS.NECK)
                    if item and item.prefab == "amulet" then
                        item = inst.components.inventory:RemoveItem(item)
                        if item then
                            item:Remove()
                            item.persists = false
                        end
                    end
                    original_amulet_rebirth_onexit(inst)
                end
            end
        end
    end)

    function backpackpostinit(inst)
        if IsServer then
            inst.components.equippable.equipslot =
                GLOBAL.EQUIPSLOTS.BACK or GLOBAL.EQUIPSLOTS.BODY
        end
    end

    function amuletpostinit(inst)
        if IsServer then
            inst.components.equippable.equipslot =
                GLOBAL.EQUIPSLOTS.NECK or GLOBAL.EQUIPSLOTS.BODY
        end
    end

    AddPrefabPostInit("amulet", amuletpostinit)
    AddPrefabPostInit("blueamulet", amuletpostinit)
    AddPrefabPostInit("purpleamulet", amuletpostinit)
    AddPrefabPostInit("orangeamulet", amuletpostinit)
    AddPrefabPostInit("greenamulet", amuletpostinit)
    AddPrefabPostInit("yellowamulet", amuletpostinit)

    AddPrefabPostInit("backpack", backpackpostinit)
    AddPrefabPostInit("krampus_sack", backpackpostinit)
    AddPrefabPostInit("piggyback", backpackpostinit)
    AddPrefabPostInit("icepack", backpackpostinit)
    AddPrefabPostInit("backcub", backpackpostinit) -- 小熊背包
    AddPrefabPostInit("duckpack", backpackpostinit) -- 鸭鸭背包
    AddPrefabPostInit("beibao001", backpackpostinit) -- 翅膀
end

-- 二本垃圾桶
if GetModConfigData("trash_bin") then
    local require = GLOBAL.require
    local Vector3 = GLOBAL.Vector3
    local containers = require("containers")

    local params = {}

    local containers_widgetsetup_base = containers.widgetsetup
    function containers.widgetsetup(container, prefab, data, ...)
        local t = params[prefab or container.inst.prefab]
        if t ~= nil then
            for k, v in pairs(t) do container[k] = v end
            container:SetNumSlots(container.widget.slotpos ~= nil and
                                      #container.widget.slotpos or 0)
        else
            containers_widgetsetup_base(container, prefab, data, ...)
        end
    end

    local function eliminatingBox()
        local container = {
            widget = {
                slotpos = {
                    Vector3(0, 64 + 32 + 8 + 4, 0), Vector3(0, 32 + 4, 0),
                    Vector3(0, -(32 + 4), 0), Vector3(0, -(64 + 32 + 8 + 4), 0)
                },
                animbank = "ui_cookpot_1x4",
                animbuild = "ui_cookpot_1x4",
                pos = Vector3(150, 0, 0),
                side_align_tip = 100,
                buttoninfo = {text = "Boom!", position = Vector3(0, -165, 0)}
            },
            type = "eliminate"
        }

        return container
    end

    params.eliminate = eliminatingBox()

    for k, v in pairs(params) do
        containers.MAXITEMSLOTS = math.max(containers.MAXITEMSLOTS, v.widget
                                               .slotpos ~= nil and
                                               #v.widget.slotpos or 0)
    end

    local function eliminatingFn(player, inst)
        local container = inst.components.container
        local eliminated = false
        for i = 1, container:GetNumSlots() do
            local item = container:GetItemInSlot(i)
            if item then
                if not item:HasTag("nonpotatable") and
                    not item:HasTag("irreplaceable") then
                    eliminated = true
                    container:RemoveItemBySlot(i)
                    item:Remove()
                end
            end
        end
    end

    function params.eliminate.widget.buttoninfo.fn(inst)
        if GLOBAL.TheWorld.ismastersim then
            eliminatingFn(inst.components.container.opener, inst)
        else
            SendModRPCToServer(GLOBAL.MOD_RPC["eliminate"]["eliminate"], inst)
        end
    end
    AddModRPCHandler("eliminate", "eliminate", eliminatingFn)

    local function trashWidget(inst)
        if not GLOBAL.TheWorld.ismastersim then
            inst:DoTaskInTime(0, function()
                if inst.replica then
                    if inst.replica.container then
                        inst.replica.container:WidgetSetup("eliminate")
                    end
                end
            end)
            return inst
        end
        if GLOBAL.TheWorld.ismastersim then
            if not inst.components.container then
                inst:AddComponent("container")
                inst.components.container:WidgetSetup("eliminate")
            end
        end
    end

    AddPrefabPostInit("researchlab2", trashWidget)
end

-- 永葆青春
if GetModConfigData("no_rot") then
    -- 冰箱
    TUNING.PERISH_FRIDGE_MULT = 0
    -- 盐盒
    TUNING.PERISH_SALTBOX_MULT = 0
    -- 蘑菇灯
    TUNING.PERISH_MUSHROOM_LIGHT_MULT = 0

    -- 骨灰罐
    AddPrefabPostInit("sisturn", function(inst)
        inst:AddComponent("preserver")
        inst.components.preserver:SetPerishRateMultiplier(0)
    end)

    -- 小偷包
    AddPrefabPostInit("krampus_sack", function(inst)
        inst:AddTag("fridge")
        inst:AddTag("nocool")
    end)
end

-- 永恒之石
if GetModConfigData("great_warm_stone") then
    AddPrefabPostInit("heatrock", function(inst)
        if not inst.components.fueled then return inst end
        inst.components.fueled:SetDepletedFn(function(inst)
            inst.components.fueled:SetPercent(1)
        end)
    end)
end

-- 移动炮塔
if GetModConfigData("great_eye_turret") then
    AddPrefabPostInit("eyeturret", function(inst)
        inst:AddComponent("portablestructure")
        inst.components.portablestructure:SetOnDismantleFn(function(inst)
            local item = GLOBAL.SpawnPrefab("eyeturret_item")
            item.Transform:SetPosition(inst.Transform:GetWorldPosition())
            inst:Remove()
        end)
    end)
end

-- 树人军团
if GetModConfigData("more_treeguards") then TUNING.LEIF_PERCENT_CHANCE = 1 / 25 end

-- 常青树
if GetModConfigData("no_wilt") then
    TUNING.EVERGREEN_GROW_TIME = {
        {base = 450, random = 150}, {base = 1500, random = 600},
        {base = 150000, random = 600}, {base = 300, random = 150}
    }
    TUNING.MARBLESHRUB_GROW_TIME = {
        {base = 2700, random = 300}, -- short
        {base = 2700, random = 300}, -- normal
        {base = 150000, random = 300} -- tall
    }
    ROCK_FRUIT_REGROW = {
        EMPTY = {BASE = 600, VAR = 60},
        PREPICK = {BASE = 180, VAR = 60},
        PICK = {BASE = 150000, VAR = 60},
        CRUMBLE = {BASE = 300, VAR = 60}
    }
end

-- 战神！阿比盖尔
if GetModConfigData("strong_abigail") then
    TUNING.ABIGAIL_LIGHTING = {
        {l = 0.0, r = 0.0}, {l = 0.5, r = 2.5, i = 0.75, f = 0.4},
        {l = 1, r = 2.5, i = 0.75, f = 0.4}
    }
    TUNING.ABIGAIL_SPEED = 8.0
    AddPrefabPostInit("abigail", function(inst)
        if not GLOBAL.TheWorld.ismastersim then return end
        inst:AddTag("crazy")
        inst.components.health:SetAbsorptionAmount(0.9)
    end)
end

-- 石果炸药
if GetModConfigData("great_rock_fruit") then
    local function newon_mine(inst, miner, workleft, workdone) -- 定义的新的掉落率函数。实际上是模仿"rock_avocado_fruit.lua"中的函数。
        local num_fruits_worked = GLOBAL.math.clamp(workdone /
                                                        TUNING.ROCK_FRUIT_MINES,
                                                    1, TUNING.ROCK_FRUIT_LOOT
                                                        .MAX_SPAWNS)
        num_fruits_worked = GLOBAL.math.min(num_fruits_worked, inst.components
                                                .stackable:StackSize())

        if inst.components.stackable:StackSize() > num_fruits_worked then
            inst.AnimState:PlayAnimation("mined")
            inst.AnimState:PushAnimation("idle", false)

            if num_fruits_worked == TUNING.ROCK_FRUIT_LOOT.MAX_SPAWNS then
                -- If we got hit hard, also launch the remaining fruit stack.
                GLOBAL.LaunchAt(inst, inst, miner, TUNING.ROCK_FRUIT_LOOT.SPEED,
                                TUNING.ROCK_FRUIT_LOOT.HEIGHT, nil,
                                TUNING.ROCK_FRUIT_LOOT.ANGLE)
            end
        end

        for _ = 1, num_fruits_worked do
            -- Choose a ripeness to spawn.
            local loot_roll = GLOBAL.math.random() -- 随机数决定掉落
            if loot_roll < TUNING.ROCK_FRUIT_LOOT.RIPE_CHANCE then
                local loot = GLOBAL.SpawnPrefab("rock_avocado_fruit_ripe") -- 掉落石果
                GLOBAL.LaunchAt(loot, inst, miner, TUNING.ROCK_FRUIT_LOOT.SPEED,
                                TUNING.ROCK_FRUIT_LOOT.HEIGHT, nil,
                                TUNING.ROCK_FRUIT_LOOT.ANGLE)
                if loot ~= nil then
                    loot.AnimState:PlayAnimation("split_open")
                    loot.AnimState:PushAnimation("idle_split_open")
                end
            elseif loot_roll <
                (TUNING.ROCK_FRUIT_LOOT.RIPE_CHANCE +
                    TUNING.ROCK_FRUIT_LOOT.SEED_CHANCE) then -- 掉落石果种子
                GLOBAL.LaunchAt(GLOBAL.SpawnPrefab("rock_avocado_fruit_sprout"),
                                inst, miner, TUNING.ROCK_FRUIT_LOOT.SPEED,
                                TUNING.ROCK_FRUIT_LOOT.HEIGHT, nil,
                                TUNING.ROCK_FRUIT_LOOT.ANGLE)
            end

            -- 这里把掉石头的步骤独立出来
            local AnchorPoint = TUNING.ROCK_FRUIT_LOOT.RIPE_CHANCE +
                                    TUNING.ROCK_FRUIT_LOOT.SEED_CHANCE
            local distance_AP = 1 - AnchorPoint
            if loot_roll > 1 - distance_AP then
                local loot_roll2 = GLOBAL.math.random() -- 来个随机数均分一下结果

                if loot_roll2 < 0.5 then -- 掉落石头
                    GLOBAL.LaunchAt(GLOBAL.SpawnPrefab("rocks"), inst, miner,
                                    TUNING.ROCK_FRUIT_LOOT.SPEED,
                                    TUNING.ROCK_FRUIT_LOOT.HEIGHT, nil,
                                    TUNING.ROCK_FRUIT_LOOT.ANGLE)
                    -- print("P1="..P1)
                else -- 掉落硝石
                    GLOBAL.LaunchAt(GLOBAL.SpawnPrefab("nitre"), inst, miner,
                                    TUNING.ROCK_FRUIT_LOOT.SPEED,
                                    TUNING.ROCK_FRUIT_LOOT.HEIGHT, nil,
                                    TUNING.ROCK_FRUIT_LOOT.ANGLE)
                    -- print("P2="..P2)
                end
                -- print("---------------------------")
            end
        end

        -- Finally, remove the actual stack items we just consumed
        local top_stack_item = inst.components.stackable:Get(num_fruits_worked)
        top_stack_item:Remove()
    end

    local function newfn(inst)

        if not GLOBAL.TheWorld.ismastersim then -- 如果是客户端就不执行代码
            return inst
        end

        if inst.components.workable ~= nil then -- 如果存在这个组件就运行
            -- for key,value in pairs(inst.components) do print(key,inst.components[key]) end--测试函数，查看是否有workable属性
            inst.components.workable:SetOnWorkCallback(newon_mine) -- 正常添加，方法1
            -- inst.components.workable.SetOnWorkCallback(inst.components.workable,newon_mine)--可替换方法1
            -- inst.components.workable.onwork=newon_mine--直接执行SetOnWorkCallback语句，可替换方法1
        end
    end

    AddPrefabPostInit("rock_avocado_fruit", newfn)
end

-- 牛牛的好朋友
if GetModConfigData("great_rock_fruit") then
    TUNING.BEEFALO_MIN_DOMESTICATED_OBEDIENCE = {
        DEFAULT = 0.8,
        ORNERY = 0.55,
        RIDER = 0.95,
        PUDGY = 0.6
    }
    TUNING.BEEFALO_DOMESTICATION_LOSE_DOMESTICATION = 0
    TUNING.BEEFALO_DOMESTICATION_GAIN_DOMESTICATION = 1 / 2400
end

-- 讨厌的蝙蝠
if GetModConfigData("fuck_bat") then
    AddPrefabPostInit("cave_entrance_open", function(inst)
        if inst.components.childspawner then
            inst.components.childspawner:SetMaxChildren(0)
        end
    end)
end

-- 牛骑士？猎人
if GetModConfigData("rider_hunter") then
    GLOBAL.ACTIONS.ACTIVATE.mount_valid = true
end

-- 忍住牛牛
if GetModConfigData("no_poop") then
    AddPrefabPostInit("beefalo", function(inst)
        if not GLOBAL.TheWorld.ismastersim then return end
        if inst.components.periodicspawner then
            inst.components.periodicspawner:Stop()
        end
    end)
end
