local C = {}
C.Title = 'GHOSTLIGHT HOLLOW'
C.MaxPlayers = 8
C.Version = 1
C.SaveKey = 'GhostlightHollow_v1'
C.StudioPersistence = false
C.Rarities = {'Common', 'Uncommon', 'Rare', 'Epic', 'Legendary', 'Mythic', 'Secret'}
C.Colors = {{161,224,255},{141,247,166},{75,188,255},{186,105,255},{255,199,81},{255,100,157},{240,243,255}}
C.Slots = {5,8,12,16,20}
C.HauntCosts = {0,150000,1400000,10000000,75000000}
C.Capacity = {3,5,8,12,18,25}
C.Floors = {
    {Name='Abandoned Foyer', Cost=0, Min=1, Max=3},
    {Name='Whispering Bedrooms', Cost=350000, Min=2, Max=4},
    {Name='Cursed Library', Cost=3500000, Min=3, Max=5},
    {Name='Forgotten Basement', Cost=35000000, Min=4, Max=6},
    {Name='The Moonless Crypt', Cost=350000000, Min=5, Max=7},
    {Name='The Catacombs', Cost=2500000000, Min=6, Max=7},
}
C.UpgradeNames = {'Suction','Capture','Capacity','Movement','Flashlight'}
C.UpgradeBase = {Suction=15000,Capture=20000,Capacity=12000,Movement=10000,Flashlight=8000}
C.MaxUpgrade = 6
C.Capture = {Range=24, BreakRange=38, ClickInterval=0.09, IdleTimeout=2.5, Tick=0.1, AttackInterval=4.5, AttackRange=12, AttackDamage=0.7}
C.ChamberInterval = 35
C.Ghosts = {
    mothlight={Name='Mothlight',Rarity=1,Income=3,Shape='Moth',Weight=65},
    teacup_trembler={Name='Teacup Trembler',Rarity=1,Income=4,Shape='Cup',Weight=45},
    lantern_lurker={Name='Lantern Lurker',Rarity=2,Income=10,Shape='Lantern',Weight=28},
    button_boo={Name='Button Boo',Rarity=2,Income=13,Shape='Doll',Weight=22},
    clockwork_wail={Name='Clockwork Wail',Rarity=3,Income=32,Shape='Clock',Weight=12},
    ivy_specter={Name='Ivy Specter',Rarity=3,Income=42,Shape='Vine',Weight=10},
    velvet_veil={Name='Velvet Veil',Rarity=4,Income=135,Shape='Veil',Weight=5},
    quillgeist={Name='Quillgeist',Rarity=4,Income=175,Shape='Book',Weight=4},
    hollow_regent={Name='Hollow Regent',Rarity=5,Income=700,Shape='Crown',Weight=1.8},
    bellwarden={Name='Bellwarden',Rarity=5,Income=950,Shape='Knight',Weight=1.4},
    eclipse_mourner={Name='Eclipse Mourner',Rarity=6,Income=3750,Shape='Eclipse',Weight=0.5},
    starless_stag={Name='Starless Stag',Rarity=6,Income=5000,Shape='Stag',Weight=0.35},
    the_last_candle={Name='The Last Candle',Rarity=7,Income=21000,Shape='Candle',Weight=0.035},
    door_to_nowhere={Name='Door to Nowhere',Rarity=7,Income=32500,Shape='Door',Weight=0.02},
}
for id, g in C.Ghosts do
    g.Id = id
    g.Difficulty = 1 + (g.Rarity - 1) * 0.85
    g.Areas = {}
    for i, floor in C.Floors do
        if g.Rarity >= floor.Min and g.Rarity <= floor.Max then table.insert(g.Areas, i) end
    end
end
return C
