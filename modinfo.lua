-- 基本信息
name = "温蒂的礼物"
description = [[
让温蒂小姐姐生活愉快的mod！
]]
author = "3verness"
version = "1.2.1"

-- 这是一个DST mod
dst_compatible = true

-- 每个人都需要安装这个mod么？
all_clients_require_mod = true

-- 这个mod会改变服务器逻辑么？
clients_only_mod = false

-- 设置图标
icon_atlas = "icon.xml"
icon = "icon.tex"

configuration_options = {
    {
        name = "no_gekko",
        label = "去死吧草蜥蜴",
        options = {
            {description = "开", data = true},
            {description = "关", data = false}
        },
        default = true
    }, {
        name = "more_slots",
        label = "五格背包栏",
        options = {
            {description = "开", data = true},
            {description = "关", data = false}
        },
        default = true
    }, {
        name = "trash_bin",
        label = "二本垃圾桶",
        options = {
            {description = "开", data = true},
            {description = "关", data = false}
        },
        default = true
    }, {
        name = "no_rot",
        label = "永葆青春",
        options = {
            {description = "开", data = true},
            {description = "关", data = false}
        },
        default = true
    }, {
        name = "great_warm_stone",
        label = "永恒之石",
        options = {
            {description = "开", data = true},
            {description = "关", data = false}
        },
        default = true
    }, {
        name = "great_eye_turret",
        label = "移动炮塔",
        options = {
            {description = "开", data = true},
            {description = "关", data = false}
        },
        default = true
    }, {
        name = "more_treeguards",
        label = "树人军团",
        options = {
            {description = "开", data = true},
            {description = "关", data = false}
        },
        default = true
    }, {
        name = "no_wilt",
        label = "常青树",
        options = {
            {description = "开", data = true},
            {description = "关", data = false}
        },
        default = true
    }, {
        name = "strong_abigail",
        label = "战神！阿比盖尔",
        options = {
            {description = "开", data = true},
            {description = "关", data = false}
        },
        default = true
    }, {
        name = "great_rock_fruit",
        label = "石果炸药",
        options = {
            {description = "开", data = true},
            {description = "关", data = false}
        },
        default = true
    }, {
        name = "beefalos_friend",
        label = "牛牛的好朋友",
        options = {
            {description = "开", data = true},
            {description = "关", data = false}
        },
        default = true
    }, {
        name = "fuck_bat",
        label = "讨厌的蝙蝠",
        options = {
            {description = "开", data = true},
            {description = "关", data = false}
        },
        default = true
    }, {
        name = "rider_hunter",
        label = "牛骑士？战士",
        options = {
            {description = "开", data = true},
            {description = "关", data = false}
        },
        default = true
    }, {
        name = "no_poop",
        label = "忍住牛牛",
        options = {
            {description = "开", data = true},
            {description = "关", data = false}
        },
        default = true
    }
}

