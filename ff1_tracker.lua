-- Final Fantasy Auto Tracker
-- Author: Michael Watters <wattersm@watters.ws>
-- GNU GENERAL PUBLIC LICENSE Version 3

-- This script is heavily inspired by the Final Fantasy Randomizer project and the Final Fantasy dissassembly created
-- by Disch.

-- For an explanation of bitwise operations see https://en.wikipedia.org/wiki/Bitwise_operation#AND

--Okay rom.readbyte(4) should return 32 if it's FFR.
--And something else if it's vanilla.
--And also rom.readbyte(6) should be 0x43

-- Create socket object for message passing
socket = require("socket.core");

udp = assert(socket.udp());

randomized = rom.readbyte(0x04) == 0x20 and true or false; 

if randomized then
	emu.message("Randomized ROM detected.");
end

if (rom.readbyte(0x7CDC0) == 0x08 and rom.readbyte(0x7CDC1) == 0xCE) then
	shard_hunt_enabled = true
	shard_limit = rom.readbyte(0x39516)
else
	shard_hunt_enabled = false
end

function math.sign(v)
	return (v >= 0 and 1) or -1
end

function math.round(v, bracket)
	bracket = bracket or 1
	return math.floor(v/bracket + math.sign(v) * 0.5) * bracket
end

function BitAND(a,b) --Bitwise and
    local p,c = 1,0
    while a>0 and b>0 do
        local ra,rb=a%2,b%2
        if ra+rb>1 then c=c+p end
        a,b,p=(a-ra)/2,(b-rb)/2,p*2
    end
    return c
end

function BitOR(a,b)--Bitwise or
    local p,c=1,0
    while a+b>0 do
        local ra,rb=a%2,b%2
        if ra+rb>0 then c=c+p end
        a,b,p=(a-ra)/2,(b-rb)/2,p*2
    end
    return c
end

function lshift(x, by)
  return x * 2 ^ by
end

function rshift(x, by)
  return math.round(x / 2 ^ by)
end

function draw_message(x, y, m)
    gui.text(x, y,  m, 'red', 'black');
end

function CheckGameEventFlag(objid)
	return rshift(memory.readbyte(map_objects[objid]['offset']), 2);
end

function send_udp_message(message)
	assert(udp:sendto(message, "127.0.0.1", 11000));
end

function update_portal_status()
	if inventory['Portal'] ~= 1 then
		inventory['Portal'] = 1
		emu.message("Portal status changed.");
		send_udp_message("OBJID_PORTAL:1");
	end
end


-- OBJVISIBLE is determined by a bitwise AND operation - see bank_0E.asm for details
-- Citizens only appear after the pirates are dead

-- map objects start at 0x6200
map_objects = {
OBJID_GARLAND      = {offset = 0x6202, status = 0, limit = 1, t = 'alive', f = 'dead'},
OBJID_PRINCESS_1   = {offset = 0x6203, status = 0, limit = 1, t = 'kidnapped', f = 'rescued'},
OBJID_PRINCESS_2   = {offset = 0x6212, status = 0, limit = 1, t = 'alive', f = 'dead'},
OBJID_BIKKE        = {offset = 0x6204, status = 0, limit = 1, t = 'alive', f = 'dead'},
OBJID_ELFPRINCE    = {offset = 0x6206, status = 0, limit = 3, t = 'awake', f = 'sleeping'},
OBJID_ASTOS        = {offset = 0x6207, status = 0, limit = 4, t = 'dead', f = 'alive'},
OBJID_NERRICK      = {offset = 0x6208, status = 0, limit = 1, t = 'alive', f = 'dead'},
OBJID_SMITH        = {offset = 0x6209, status = 0, limit = 1, t = 'alive', f = 'dead'},
OBJID_MATOYA       = {offset = 0x620A, status = 0, limit = 1, t = 'alive', f = 'dead'},
OBJID_UNNE         = {offset = 0x620B, status = 0, limit = 3, t = 'translated', f = 'untranslated'},
OBJID_VAMPIRE      = {offset = 0x620C, status = 0, limit = 1, t = 'alive', f = 'dead'},
OBJID_SARDA        = {offset = 0x620D, status = 0, limit = 1, t = 'alive', f = 'dead'},
OBJID_BAHAMUT      = {offset = 0x620E, status = 0, limit = 1, t = 'alive', f = 'dead'},
OBJID_SUBENGINEER  = {offset = 0x6210, status = 0, limit = 5, t = 'blocking', f = 'gone'},
OBJID_FAIRY        = {offset = 0x6213, status = 0, limit = 1, t = 'free', f = 'bottled'},
OBJID_TITAN        = {offset = 0x6214, status = 0, limit = 1, t = 'hungry', f = 'sated'},
OBJID_RODPLATE     = {offset = 0x6216, status = 0, limit = 1, t = 'closed', f = 'open'},
OBJID_LUTEPLATE    = {offset = 0x6217, status = 0, limit = 1, t = 'alive', f = 'dead'},
OBJID_SKYWAR_FIRST = {offset = 0x623A, status = 0, limit = 1, t = 'alive', f = 'dead'},
OBJID_SKYWAR_LAST  = {offset = 0x623E, status = 0, limit = 1, t = 'alive', f = 'dead'},
OBJID_PIRATETERR_1 = {offset = 0x623F, status = 0, limit = 1, t = 'free', f = 'hiding'},  -- ; townspeople that were terrorized by the
OBJID_PIRATETERR_2 = {offset = 0x6240, status = 0, limit = 1, t = 'free', f = 'hiding'},  -- ; pirates... they don't become visible until after
OBJID_PIRATETERR_3 = {offset = 0x6241, status = 0, limit = 1, t = 'free', f = 'hiding'},  -- ; you beat Bikke and claim the ship
OBJID_BAT          = {offset = 0x6257, status = 0, limit = 1, t = 'alive', f = 'dead'},
OBJID_SHIP         = {offset = 0x6000, status = 0, limit = 1, t = 'unavailable', f = 'available'},
OBJID_BRIDGE       = {offset = 0x6008, status = 0, limit = 1, t = 'open', f = 'closed'},
OBJID_CANAL        = {offset = 0x600C, status = 0, limit = 1, t = 'closed', f = 'open'},
OBJID_CANOE        = {offset = 0x6012, status = 0, limit = 1, t = 'closed', f = 'open'},
OBJID_AIRSHIP      = {offset = 0x6004, status = 0, limit = 1, t = 'closed', f = 'open'},
OBJID_BLACKORB     = {offset = 0x62CA, status = 0, limit = 1, t = 'closed', f = 'open'},
}

multitext = iup.text{
  multiline = "YES",
  expand = "YES",
}

vbox = iup.vbox{
  multitext,
}

dlg = iup.dialog{
  vbox,
  title = "Inventory",
  size = "QUARTERx450",
}

--dlg:showxy(50, 180)

--items starts at 0x6020
KeyItems = {
    Lute = 1,
    Crown = 2,
    Crystal = 3,
    Herb = 4,
    Key = 5,
    Tnt = 6,
    Adamant = 7,
    Slab = 8,
    Ruby = 9,
    Rod = 0x0a,
    Floater = 0x0b,
    Chime = 0x0c,
    Tail = 0x0D,
    Cube = 0x0e,
    Bottle = 0x0f,
    Oxyale = 0x10,
    EarthOrb = 0x11,
    FireOrb = 0x12,
    WaterOrb = 0x13,
    AirOrb = 0x14,
    Shard = 0x15,
    --Ship = 224,
    --Airship = 228,
    --Bridge = 232,
    --Canoe = 242,
}

-- These inventory items start at 0x6036
Items2 = {
    Tent = 22,
    Cabin = 23,
    House = 24,
    Heal = 0x6039,
    Pure = 26,
    Soft = 27,
    WoodenNunchucks = 28,
    SmallKnife = 29,
    WoodenRod = 30,
    Rapier = 31,
    IronHammer = 32,
    ShortSword = 33,
    HandAxe = 34,
    Scimitar = 35,
    IronNunchucks = 36,
    LargeKnife = 37,
    IronStaff = 38,
    Sabre = 39,
    LongSword = 40,
    GreatAxe = 41,
    Falchon = 42,
    SilverKnife = 43,
    SilverSword = 44,
    SilverHammer = 45,
    SilverAxe = 46,
    FlameSword = 47,
    IceSword = 48,
    DragonSword = 49,
    GiantSword = 50,
    SunSword = 51,
    CoralSword = 52,
    WereSword = 53,
    RuneSword = 54,
    PowerRod = 55,
    LightAxe = 56,
    HealRod = 57,
    MageRod = 58,
    Defense = 59,
    WizardRod = 60,
    Vorpal = 61,
    CatClaw = 62,
    ThorHammer = 63,
    BaneSword = 64,
    Katana = 65,
    Xcalber = 66,
    Masamune = 67,
    Cloth = 68,
    WoodenArmor = 69,
    ChainArmor = 70,
    IronArmor = 71,
    SteelArmor = 72,
    SilverArmor = 73,
    FlameArmor = 74,
    IceArmor = 75,
    OpalArmor = 76,
    DragonArmor = 77,
    Copper = 78,
    Silver = 79,
    Gold = 80,
    Opal = 81,
    WhiteShirt = 82,
    BlackShirt = 83,
    WoodenShield = 84,
    IronShield = 85,
    SilverShield = 86,
    FlameShield = 87,
    IceShield = 88,
    OpalShield = 89,
    AegisShield = 90,
    Buckler = 91,
    ProCape = 92,
    Cap = 93,
    WoodenHelm = 94,
    IronHelm = 95,
    SilverHelm = 96,
    OpalHelm = 97,
    HealHelm = 98,
    Ribbon = 99,
    Gloves = 100,
    CopperGauntlets = 101,
    IronGauntlets = 102,
    SilverGauntlets = 103,
    ZeusGauntlets = 104,
    PowerGauntlets = 105,
    OpalGauntlets = 106,
    ProRing = 107,
    Gold10 = 108,
    Gold20 = 109,
    Gold25 = 110,
    Gold30 = 111,
    Gold55 = 112,
    Gold70 = 113,
    Gold85 = 114,
    Gold110 = 115,
    Gold135 = 116,
    Gold155 = 117,
    Gold160 = 118,
    Gold180 = 119,
    Gold240 = 120,
    Gold255 = 121,
    Gold260 = 122,
    Gold295 = 123,
    Gold300 = 124,
    Gold315 = 125,
    Gold330 = 126,
    Gold350 = 127,
    Gold385 = 128,
    Gold400 = 129,
    Gold450 = 130,
    Gold500 = 131,
    Gold530 = 132,
    Gold575 = 133,
    Gold620 = 134,
    Gold680 = 135,
    Gold750 = 136,
    Gold795 = 137,
    Gold880 = 138,
    Gold1020 = 139,
    Gold1250 = 140,
    Gold1455 = 141,
    Gold1520 = 142,
    Gold1760 = 143,
    Gold1975 = 144,
    Gold2000 = 145,
    Gold2750 = 146,
    Gold3400 = 147,
    Gold4150 = 148,
    Gold5000 = 149,
    Gold5450 = 150,
    Gold6400 = 151,
    Gold6720 = 152,
    Gold7340 = 153,
    Gold7690 = 154,
    Gold7900 = 155,
    Gold8135 = 156,
    Gold9000 = 157,
    Gold9300 = 158,
    Gold9500 = 159,
    Gold9900 = 160,
    Gold10000 = 161,
    Gold12350 = 162,
    Gold13000 = 163,
    Gold13450 = 164,
    Gold14050 = 165,
    Gold14720 = 166,
    Gold15000 = 167,
    Gold17490 = 168,
    Gold18010 = 169,
    Gold19990 = 170,
    Gold20000 = 171,
    Gold20010 = 172,
    Gold26000 = 173,
    Gold45000 = 174,
    Gold65000 = 175,
    Ship = 224,
    Airship = 228,
    Bridge = 232,
    Canoe = 242,
}

inventory = {
	Portal = 0,
	Shard = 0,
}

--0x355C = Starting gold?

--0x601C = Low byte of gold
--0x601d = middle byte
--0x601E = high byte

-- Give me everything
--for k, v in pairs(Items) do
--	memory.writebyte(0x6020 + v, 0x01);
--end

time_elapsed = 0

-- Enter main loop
while true do
    --if not emu.paused() then
        --gui.text(5, 225, "Frames: " .. emu.framecount(), "red", "black");
        --if emu.framecount() % 60 == 0 then
        --	time_elapsed = time_elapsed + 1;
        --	gui.text(10, 10, "Time: " .. time_elapsed .. "(s)", "red", "black");
        --end
    --end

    -- Update tracker data every 60 frames (1 second)
    if emu.framecount() % 60 == 0 then
        msgtable = {key_items = {}, map_objects={}}

        for k, v in pairs(KeyItems) do
			if k == 'Shard' and shard_hunt_enabled == false then
				status = 0;
			else
				status = memory.readbyte(0x6020 + v) ;
			end
 
			if inventory[k] ~= status then
                inventory[k] = status;
                m = k .. ":" .. status;
                send_udp_message(m); 
                -- send status message to player
                emu.message(k .. " status changed.");
            end
            table.insert(msgtable['key_items'], k .. ": " ..  status .. "\n");
        end

        for k, v in pairs(map_objects) do
			-- Canal status is located at 0x620C.  When this memory address is set to 0 the canal appears.
			if k == 'OBJID_CANAL' then
				cur_status = 1 - BitAND(memory.readbyte(v['offset']), 0x01);
			-- Dr. Unne uses the SetGameEventFlag function to check if you need to learn Leifenish.  
			-- The flag value is stored in RAM at 0x620B.  A return value of 0 means he has already taught you.
			elseif k == 'OBJID_ELFPRINCE' or k == 'OBJID_UNNE' or k == 'OBJID_MATOYA' then
				cur_status = CheckGameEventFlag(k);
			elseif k == 'OBJID_BIKKE' then
				cur_status = 1 - CheckGameEventFlag(k);
			else
				cur_status = BitAND(memory.readbyte(v['offset']), 0x01);
			end

            if cur_status ~= v['status'] then
                v['status'] = cur_status;
                m = k .. ":" .. cur_status .. "\n";

                -- send message to udp port
				send_udp_message(m); 
                -- Alert player
                emu.message(k .. " status changed.");
            end
            table.insert(msgtable['map_objects'], k .. ":" .. cur_status .. "\n");
        end

		-- Portal opens when the player collects all shards
		if (shard_hunt_enabled == true and inventory['Shard'] == shard_limit) then
			update_portal_status();
		else
			-- Check if all four orbs are lit.  When all are lit the path to Chaos is open.
			if (inventory['EarthOrb'] == 1 and inventory['FireOrb'] == 1 and inventory['WaterOrb'] == 1 and inventory['AirOrb'] == 1) then
				update_portal_status();
			end
		end

        -- Update the inventory window contents
        -- multitext.value = table.concat(msgtable['key_items'], "") .. "\n" .. table.concat(msgtable['map_objects'], "") ;
    end

    emu.frameadvance();
end
