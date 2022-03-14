#include maps/mp/_utility;
#include common_scripts/utility;
#include maps/mp/gametypes_zm/_hud_util;
#include maps/mp/zombies/_zm_utility;
#include maps/mp/zombies/_zm_powerups;
#include maps/mp/zombies/_zm_laststand;
#include maps/mp/zombies/_zm_weapons;
#include maps/mp/zombies/_zm_laststand;
//Enable this only in zm_tomb
//#include maps/mp/zombies/_zm_weap_one_inch_punch;

init()
{
    level.bDoubleSpeed = false;
    level.bDoubleJumpHeight = false;
    level.bLowGravity = false;
    level.bSlowSpeedTroll = false;
    level.bGodMode = false;
    level.bPerksLimitRemoved = false;
    level thread onplayerconnect();
}

onplayerconnect()
{
    for (;;)
    {
        level waittill("connecting", player);
        player thread onplayerspawned();
        flag_wait("initial_blackscreen_passed");
        player thread HealthCounter();
        player thread ZombieCounter();
        player thread PointsCounter();
    }
}

onplayerspawned()
{
    self endon("disconnect");
    level endon("game_ended");
    for(;;)
    {
        self waittill("spawned_player");
        self thread BuildMenu();
        self.bAbilityJump = false;
    }
}

BuildMenu()
{
    self endon("disconnect");
    self endon("death");
    self.MenuOpen = false;
    self.Menu = spawnstruct();
    self InitialisingMenu();
    self MenuStructure();
    self thread MenuDeath();
    self thread MenuLaststand();
    while (1)
    {
        if (self.MenuOpen == false)
        {
            if(self AdsButtonPressed() && self MeleeButtonPressed() && self.MenuOpen == false && self player_is_in_laststand() == false)
            {
                self MenuOpening();
                self LoadMenu("Main Menu");
                wait 0.5;
            }
        }
        if (self.MenuOpen == true)
        {
            if (self MeleeButtonPressed())
            {
                if (isDefined(self.Menu.System["MenuPrevious"][self.Menu.System["MenuRoot"]]))
                {
                    self.Menu.System["MenuCurser"] = 0;
                    self SubMenu(self.Menu.System["MenuPrevious"][self.Menu.System["MenuRoot"]]);
                    wait 0.5;
                }
                else
                {
                    self MenuClosing();
                    wait 1;
                }
            }
            else if (self actionslotonebuttonpressed())
            {
                self.Menu.System["MenuCurser"] -= 1;
                if (self.Menu.System["MenuCurser"] < 0)
                {
                    self.Menu.System["MenuCurser"] = self.Menu.System["MenuTexte"][self.Menu.System["MenuRoot"]].size - 1;
                }
                self.Menu.Material["Scrollbar"] elemMoveY(.2, 60 + (self.Menu.System["MenuCurser"] * 15.6));
                wait.2;
            }
            else if (self actionslottwobuttonpressed())
            {
                self.Menu.System["MenuCurser"] += 1;
                if (self.Menu.System["MenuCurser"] >= self.Menu.System["MenuTexte"][self.Menu.System["MenuRoot"]].size)
                {
                    self.Menu.System["MenuCurser"] = 0;
                }
                self.Menu.Material["Scrollbar"] elemMoveY(.2, 60 + (self.Menu.System["MenuCurser"] * 15.6));
                wait.2;
            }
            else if (self usebuttonpressed())
            {
                wait 0.2;
                self thread [[self.Menu.System["MenuFunction"][self.Menu.System["MenuRoot"]][self.Menu.System["MenuCurser"]]]](self.Menu.System["MenuInput"][self.Menu.System["MenuRoot"]][self.Menu.System["MenuCurser"]]);
                wait 0.5;
            }
        }
        wait 0.05;
    }
}

MenuStructure()
{
    self MainMenu("Main Menu", undefined);
    self MenuOption("Main Menu", 0, "Powerup Menu", ::SubMenu, "Powerup Menu");
    self MenuOption("Main Menu", 1, "Weapons Menu", ::SubMenu, "Weapons Menu");
    self MenuOption("Main Menu", 2, "Fun Menu", ::SubMenu, "Fun Menu");
    self MenuOption("Main Menu", 3, "Abilities Menu", ::SubMenu, "Abilities Menu");
    self MenuOption("Main Menu", 4, "Troll Menu", ::SubMenu, "Troll Menu");

    self MainMenu("Powerup Menu", "Main Menu");
    PowerupOptionsPos = 0;
    self MenuOption("Powerup Menu", PowerupOptionsPos, "Buy Nuke", ::BuyPowerup, 1);
    PowerupOptionsPos++;
    self MenuOption("Powerup Menu", PowerupOptionsPos, "Buy Instakill", ::BuyPowerup, 2);
    PowerupOptionsPos++;
    self MenuOption("Powerup Menu", PowerupOptionsPos, "Buy Double Points", ::BuyPowerup, 3);
    PowerupOptionsPos++;
    self MenuOption("Powerup Menu", PowerupOptionsPos, "Buy Carpenter", ::BuyPowerup, 4);
    PowerupOptionsPos++;
    self MenuOption("Powerup Menu", PowerupOptionsPos, "Buy Max Ammo", ::BuyPowerup, 5);
    PowerupOptionsPos++;
    self MainMenu("Weapons Menu", "Main Menu");
    self MenuOption("Weapons Menu", 0, "Buy Wonder Weapons", ::SubMenu, "Buy Wonder Weapons");
    self MenuOption("Weapons Menu", 1, "Buy Equipments", ::SubMenu, "Buy Equipments");
    if (level.script != "zm_tomb")
        self MenuOption("Weapons Menu", 2, "Buy Melee", ::SubMenu, "Buy Melee");

    self MainMenu("Fun Menu", "Main Menu");
    self MenuOption("Fun Menu", 0, "Double Speed", ::SetDvarCustom, 2);
    self MenuOption("Fun Menu", 1, "Double Jump Height", ::SetDvarCustom, 3);
    self MenuOption("Fun Menu", 2, "God Mode", ::FunFunc, 0);
    self MenuOption("Fun Menu", 3, "Remove Perks Limit", ::FunFunc, 1);
    self MenuOption("Fun Menu", 4, "Revive All Players", ::FunFunc, 2);
    
    self MainMenu("Abilities Menu", "Main Menu");
    self MenuOption("Abilities Menu", 0, "Perma Double Speed", ::AbilitiesFunc, 1);
    self MenuOption("Abilities Menu", 1, "Perma Double Jump", ::AbilitiesFunc, 2);

    self MainMenu("Troll Menu", "Main Menu");
    self MenuOption("Troll Menu", 0, "Decrease Players Speed", ::TrollFunc, 1);
    self MenuOption("Troll Menu", 1, "Low Gravity", ::SetDvarCustom, 1);

    self MainMenu("Buy Wonder Weapons", "Weapons Menu");
    OptionPos = 0;
    self MenuOption("Buy Wonder Weapons", OptionPos, "Buy Ray Gun", ::BuyWeapon, 0);
    if (is_weapon_included("minigun_alcatraz_zm"))
    {
        OptionPos++;
        self MenuOption("Buy Wonder Weapons", OptionPos, "Buy Minigun", ::BuyWeapon, 1);
    }
    if (is_weapon_included("raygun_mark2_zm"))
    {
        OptionPos++;
        self MenuOption("Buy Wonder Weapons", OptionPos, "Buy Ray Gun Mark 2", ::BuyWeapon, 2);
    }
    if (is_weapon_included("slowgun_zm"))
    {
        OptionPos++;
        self MenuOption("Buy Wonder Weapons", OptionPos, "Buy Paralyzer", ::BuyWeapon, 3);
    }
    if (is_weapon_included("blundergat_zm"))
    {
        OptionPos++;
        self MenuOption("Buy Wonder Weapons", OptionPos, "Buy Blundergat", ::BuyWeapon, 4);
    }
    if (is_weapon_included("blundersplat_zm"))
    {
        OptionPos++;
        self MenuOption("Buy Wonder Weapons", OptionPos, "Buy Vitriolic Withering", ::BuyWeapon, 5);
    }

    self MainMenu("Buy Equipments", "Weapons Menu");
    OptionPos1 = 0;
    bFirstEquipLoaded = false;
    if (is_weapon_included("cymbal_monkey_zm"))
    {
        bFirstEquipLoaded = true;
        self MenuOption("Buy Equipments", OptionPos1, "Buy Cymbal Monkey", ::BuyWeapon, 6);
    }
    if (is_weapon_included("emp_grenade_zm"))
    {
        if (bFirstEquipLoaded == true)
            OptionPos1++;
        else
            bFirstEquipLoaded = true;
        self MenuOption("Buy Equipments", OptionPos1, "Buy EMP Grenade", ::BuyWeapon, 7);
    }
    if (is_weapon_included("claymore_zm"))
    {
        if (bFirstEquipLoaded == true)
            OptionPos1++;
        else
            bFirstEquipLoaded = true;
        self MenuOption("Buy Equipments", OptionPos1, "Buy Claymore", ::BuyWeapon, 8);
    }
    if (is_weapon_included("beacon_zm"))
    {
        if (bFirstEquipLoaded == true)
            OptionPos1++;
        else
            bFirstEquipLoaded = true;
        self MenuOption("Buy Equipments", OptionPos1, "Buy Beacon", ::BuyWeapon, 9);
    }
    if (is_weapon_included("bouncing_tomahawk_zm"))
    {
        if (bFirstEquipLoaded == true)
            OptionPos1++;
        else
            bFirstEquipLoaded = true;
        self MenuOption("Buy Equipments", OptionPos1, "Buy Tomahawk", ::BuyWeapon, 10);
    }
    if (is_weapon_included("upgraded_tomahawk_zm"))
    {
        if (bFirstEquipLoaded == true)
            OptionPos1++;
        else
            bFirstEquipLoaded = true;
        self MenuOption("Buy Equipments", OptionPos1, "Buy Upgraded Tomahawk", ::BuyWeapon, 11);
    }

    self MainMenu("Buy Melee", "Weapons Menu");
    OptionPos2 = 0;
    bFirstMeleeLoaded = false;
    if (is_weapon_included("bowie_knife_zm"))
    {
        bFirstMeleeLoaded = true;
        self MenuOption("Buy Melee", OptionPos2, "Buy Bowie Knife", ::BuyMelee, 0);
    }
    if (is_weapon_included("tazer_knuckles_zm"))
    {
        if (bFirstMeleeLoaded == true)
            OptionPos2++;
        else
            bFirstMeleeLoaded = true;
        self MenuOption("Buy Melee", OptionPos2, "Buy Tazer", ::BuyMelee, 1);
    }
    if (level.script == "zm_prison")
    {
        if (bFirstMeleeLoaded == true)
            OptionPos2++;
        else
            bFirstMeleeLoaded = true;
        self MenuOption("Buy Melee", OptionPos2, "Buy Spoon", ::BuyMelee, 2);
        OptionPos2++;
        self MenuOption("Buy Melee", OptionPos2, "Buy Spork", ::BuyMelee, 3);
    }
    //Enable this only in zm_tomb
    /*if (level.script == "zm_tomb")
    {
        OptionPos2++;
        self MenuOption("Buy Melee", 0, "Buy Iron Fist", ::BuyFist, 0);
        OptionPos2++;
        self MenuOption("Buy Melee", 1, "Buy Upgraded Iron Fist", ::BuyFist, 1);
        OptionPos2++;
        self MenuOption("Buy Melee", 2, "Buy Upgraded Air Iron Fist", ::BuyFist, 2);
        OptionPos2++;
        self MenuOption("Buy Melee", 3, "Buy Upgraded Fire Iron Fist", ::BuyFist, 3);
        OptionPos2++;
        self MenuOption("Buy Melee", 4, "Buy Upgraded Ice Iron Fist", ::BuyFist, 4);
        OptionPos2++;
        self MenuOption("Buy Melee", 5, "Buy Upgraded Lightning Iron Fist", ::BuyFist, 5);
    }*/
}

MainMenu(Menu, Return)
{
    self.Menu.System["GetMenu"] = Menu;
    self.Menu.System["MenuCount"] = 0;
    self.Menu.System["MenuPrevious"][Menu] = Return;
}
MenuOption(Menu, Index, Texte, Function, Input)
{
    self.Menu.System["MenuTexte"][Menu][Index] = "^6" + Texte;
    self.Menu.System["MenuFunction"][Menu][Index] = Function;
    self.Menu.System["MenuInput"][Menu][Index] = Input;
}
SubMenu(input)
{
    self.Menu.System["MenuCurser"] = 0;
    self.Menu.System["Texte"] fadeovertime(0.05);
    self.Menu.System["Texte"].alpha = 0;
    self.Menu.System["Texte"] destroy();
    self.Menu.System["Title"] destroy();
    self thread LoadMenu(input);
}
LoadMenu(menu)
{
    self.Menu.System["MenuCurser"] = 0;
    self.Menu.System["MenuRoot"] = menu;
    self.Menu.System["Title"] = self createFontString("default", 2.0);
    self.Menu.System["Title"] setPoint("CENTER", "TOP", 5, 30);
    self.Menu.System["Title"] setText("^6" + menu);
    self.Menu.System["Title"].sort = 3;
    self.Menu.System["Title"].alpha = 1;
    string = "";
    for(i=0;i<self.Menu.System["MenuTexte"][Menu].size;i++) string += self.Menu.System["MenuTexte"][Menu][i] + "\n";
    self.Menu.System["Texte"] = self createFontString("default", 1.3);
    self.Menu.System["Texte"] setPoint("CENTER", "TOP", 5, 60);
    self.Menu.System["Texte"] setText(string);
    self.Menu.System["Texte"].sort = 3;
    self.Menu.System["Texte"].alpha = 1;
    self.Menu.Material["Scrollbar"] elemMoveY(.2, 60 + (self.Menu.System["MenuCurser"] * 15.6));
}
SetMaterial(align, relative, x, y, width, height, RGBValue, shader, sort, alpha)
{
    hud = newClientHudElem(self);
    hud.elemtype = "icon";
    hud.color = RGBValue;
    hud.alpha = alpha;
    hud.sort = sort;
    hud.children = [];
    hud setParent(level.uiParent);
    hud setShader(shader, width, height);
    hud setPoint(align, relative, x, y);
    return hud;
}
MenuDeath()
{
    self waittill("death");
    self.Menu.Material["Background"] destroy();
    self.Menu.Material["Scrollbar"] destroy();
    self.Menu.Material["BorderMiddle"] destroy();
    self.Menu.Material["BorderLeft"] destroy();
    self.Menu.Material["BorderRight"] destroy();
    self MenuClosing();
}
MenuLaststand()
{
    for (;;)
    {
        if (player_is_in_laststand() && self.MenuOpen == true)
        {
            self MenuClosing();
        }
        wait 0.01;
    }
}
InitialisingMenu()
{
    self.Menu.Material["Background"] = self SetMaterial("CENTER", "TOP", 0, 0, 240, 1000, (1,1,1), "black", 0, 0);
    self.Menu.Material["Scrollbar"] = self SetMaterial("CENTER", "TOP", 0, 60, 240, 15, (1, 0, 1), "white", 1, 0);
    self.Menu.Material["BorderMiddle"] = self SetMaterial("CENTER", "TOP", 0, 50, 240, 1, (1, 0, 1), "white", 1, 0);
    self.Menu.Material["BorderLeft"] = self SetMaterial("CENTER", "TOP", -120, 0, 1, 1000, (1, 0, 1), "white", 1, 0);
    self.Menu.Material["BorderRight"] = self SetMaterial("CENTER", "TOP", 121, 0, 1, 1000, (1, 0, 1), "white", 1, 0);
}

MenuOpening()
{
    self setclientuivisibilityflag( "hud_visible", 0 );
    self.MenuOpen = true;
    self.Menu.Material["Background"] elemFade(.5, 0.76);
    self.Menu.Material["Scrollbar"] elemFade(.5, 0.6);
    self.Menu.Material["BorderMiddle"] elemFade(.5, 0.6);
    self.Menu.Material["BorderLeft"] elemFade(.5, 0.6);
    self.Menu.Material["BorderRight"] elemFade(.5, 0.6);
}

MenuClosing()
{
    self setclientuivisibilityflag( "hud_visible", 1 );
    self.Menu.Material["Background"] elemFade(.5, 0);
    self.Menu.Material["Scrollbar"] elemFade(.5, 0);
    self.Menu.Material["BorderMiddle"] elemFade(.5, 0);
    self.Menu.Material["BorderLeft"] elemFade(.5, 0);
    self.Menu.Material["BorderRight"] elemFade(.5, 0);
    self.Menu.System["Title"] destroy();
    self.Menu.System["Texte"] destroy();
    wait 0.05;
    self.MenuOpen = false;
}

elemMoveY(time, input)
{
    self moveOverTime(time);
    self.y = input;
}

elemMoveX(time, input)
{
    self moveOverTime(time);
    self.x = input;
}

elemFade(time, alpha)
{
    self fadeOverTime(time);
    self.alpha = alpha;
}

HealthCounter()
{
    self endon("disconnect");
    level endon("end_game");
    self.healthText = createFontString("hudsmall", 1.5);
    self.healthText setPoint("CENTER", "CENTER", 150, 180);
    self.healthText.label = &"^2Health: ^1";

	while (true)
	{
		self.healthText setValue(self.health);
		wait 0.25;
	}
}

ZombieCounter()
{
    self.zombieTotalText = createFontString("hudsmall", 1.5);
    self.zombieTotalText setPoint("CENTER", "CENTER", -150, 180);
    self.zombieTotalText.label = &"^1Zombies: ";

    while (true)
    {
    	enemies = get_round_enemy_array().size + level.zombie_total;
        self.zombieTotalText setValue(enemies);
        wait 0.05;
    }
}

PointsCounter()
{
    self.pointsText = createFontString("hudsmall", 1.5);
    self.pointsText setPoint("CENTER", "CENTER", 0, 180);
    self.pointsText.label = &"^3Points: ";
    self.points = 0;
    self.pointsTotal = self.kills;
    self.pointsText setValue(self.points);

    while (true)
    {
    	if (self.pointsTotal < self.kills)
        {
            if (self player_is_in_laststand())
            {
                self.pointsTotal = self.kills;
            }
            else
            {
                if (level.zombie_vars[self.team]["zombie_powerup_point_doubler_on"] == 1)
                    self.points = self.points + 2;
                else
                    self.points++;
                self.pointsText setValue(self.points);
                self.pointsTotal = self.kills;
            }
        }
        else
        {
            self.pointsText setValue(self.points);
        }
        wait 0.05;
    }
}

BuyPowerup(powerupType)
{
    if (powerupType == 1)
    {
        if (self.points >= 50)
        {
            SpawnPowerUp("nuke");
            self.points -= 50;
        }
        else
        {
            iprintln("^1You dont have enough points!");
            iprintln("^1Require 50 points!");
        }
    }

    else if (powerupType == 2)
    {
        if (self.points >= 50)
        {
            SpawnPowerUp("insta_kill");
            self.points -= 50;
        }
        else
        {
            iprintln("^1You dont have enough points!");
            iprintln("^1Require 50 points!");
        }
    }

    else if (powerupType == 3)
    {
        if (self.points >= 50)
        {
            SpawnPowerUp("double_points");
            self.points -= 50;
        }
        else
        {
            iprintln("^1You dont have enough points!");
            iprintln("^1Require 50 points!");
        }
    }

    else if (powerupType == 4)
    {
        if (self.points >= 50)
        {
            SpawnPowerUp("carpenter");
            self.points -= 50;
        }
        else
        {
            iprintln("^1You dont have enough points!");
            iprintln("^1Require 50 points!");
        }
    }

    else if (powerupType == 5)
    {
        if (self.points >= 100)
        {
            SpawnPowerUp("full_ammo");
            self.points -= 100;
        }
        else
        {
            iprintln("^1You dont have enough points!");
            iprintln("^1Require 100 points!");
        }
    }

    else if (powerupType == 6)
    {
        if (self.points >= 100)
        {
            SpawnPowerUp("fire_sale");
            self.points -= 100;
        }
        else
        {
            iprintln("^1You dont have enough points!");
            iprintln("^1Require 100 points!");
        }
    }

    else if (powerupType == 7)
    {
        if (self.points >= 100)
        {
            SpawnPowerUp("minigun");
            self.points -= 100;
        }
        else
        {
            iprintln("^1You dont have enough points!");
            iprintln("^1Require 100 points!");
        }
    }
}

SpawnPowerUp(powerupSZ)
{
    level.powerup_drop_count = 0;
    powerup = level specific_powerup_drop(powerupSZ, self.origin);
    powerup thread powerup_timeout();
    foreach (player in level.players)
        player iprintln("^3" + powerupSZ + " ^2Spawned ^7By ^4" + self.name);
}

BuyWeapon(weaponType)
{
    weaponSZ = "";
    weaponPrice = 0;
    weaponColor = 0;

    if (weaponType == 0)
    {
        weaponSZ = "ray_gun_zm";
        weaponPrice = 150;
    }
    else if (weaponType == 1)
    {
        weaponSZ = "minigun_alcatraz_zm";
        weaponPrice = 150;
    }
    else if (weaponType == 2)
    {
        weaponSZ = "raygun_mark2_zm";
        weaponPrice = 200;
        weaponColor = 2;
    }
    else if (weaponType == 3)
    {
        weaponSZ = "slowgun_zm";
        weaponPrice = 200;
        weaponColor = 2;
    }
    else if (weaponType == 4)
    {
        weaponSZ = "blundergat_zm";
        weaponPrice = 200;
        weaponColor = 2;
    }
    else if (weaponType == 5)
    {
        weaponSZ = "blundersplat_zm";
        weaponPrice = 250;
        weaponColor = 2;
    }
    else if (weaponType == 6)
    {
        weaponSZ = "cymbal_monkey_zm";
        weaponPrice = 40;
        weaponColor = 1;
    }
    else if (weaponType == 7)
    {
        weaponSZ = "emp_grenade_zm";
        weaponPrice = 40;
        weaponColor = 1;
    }
    else if (weaponType == 8)
    {
        weaponSZ = "claymore_zm";
        weaponPrice = 20;
        weaponColor = 1;
    }
    else if (weaponType == 9)
    {
        weaponSZ = "beacon_zm";
        weaponPrice = 100;
        weaponColor = 0;
    }
    else if (weaponType == 10)
    {
        weaponSZ = "bouncing_tomahawk_zm";
        weaponPrice = 40;
        weaponColor = 1;
    }
    else if (weaponType == 11)
    {
        weaponSZ = "upgraded_tomahawk_zm";
        weaponPrice = 100;
        weaponColor = 0;
    }

    if (self.points >= weaponPrice)
    {
        self weapon_give(weaponSZ);
        self.points -= weaponPrice;

        foreach (player in level.players)
        {
            if (weaponColor == 0)
                player iprintln("^4" + self.name + " ^7Have Bought ^3" + weaponSZ);
            else if (weaponColor == 1)
                player iprintln("^4" + self.name + " ^7Have Bought ^5" + weaponSZ);
            else if (weaponColor == 2)
                player iprintln("^4" + self.name + " ^7Have Bought ^6" + weaponSZ);
        }
    }
    else
    {
        iprintln("^1You dont have enough points!");
        iprintln("^1Require " + weaponPrice + " points!");
    }
}

BuyMelee(meleeType)
{
    meleeSZ = "";
    meleeFlourishSZ = "";
    meleePrice = 0;
    meleeColor = 0;

    if (meleeType == 0)
    {
        meleeSZ = "bowie_knife_zm";
        meleeFlourishSZ = "zombie_bowie_flourish";
        meleePrice = 40;
    }
    else if (meleeType == 1)
    {
        meleeSZ = "tazer_knuckles_zm";
        meleeFlourishSZ = "zombie_tazer_flourish";
        meleePrice = 70;
        meleeColor = 1;
    }
    else if (meleeType == 2)
    {
        meleeSZ = "spoon_zm_alcatraz";
        meleeFlourishSZ = "";
        meleePrice = 60;
        meleeColor = 1;
    }
    else if (meleeType == 3)
    {
        meleeSZ = "spork_zm_alcatraz";
        meleeFlourishSZ = "";
        meleePrice = 150;
        meleeColor = 1;
    }
    
    if (self.points >= meleePrice)
    {
        self.points -= meleePrice;
        
        foreach (player in level.players)
        {
            if (meleeColor == 0)
                player iprintln("^4" + self.name + " ^7Have Bought ^3" + meleeSZ);
            else
                player iprintln("^4" + self.name + " ^7Have Bought ^6" + meleeSZ);
        }

        self takeweapon(self get_player_melee_weapon());
        if (meleeFlourishSZ != "")
        {
            currentWeaponSZ = self getcurrentweapon();
            self disable_player_move_states(1);
            self giveweapon(meleeFlourishSZ);
            self switchtoweapon(meleeFlourishSZ);
            self waittill_any("player_downed","weapon_change_complete");
            self switchtoweapon(currentWeaponSZ);
            self enable_player_move_states();
            self takeweapon(meleeFlourishSZ);
        }
        self giveweapon(meleeSZ);
        self set_player_melee_weapon(meleeSZ);
    }
    else
    {
        iprintln("^1You dont have enough points!");
        iprintln("^1Require " + meleePrice + " points!");
    }
}

//Enable this only in zm_tomb
/*BuyFist(fistType)
{
    FistSZ = "";
    FistPrice = 0;
    FistColor = 0;

    self ent_flag_init( "melee_punch_cooldown" );
    self.one_inch_punch_flag_has_been_init = 1;

    if (fistType == 1)
    {
        self.str_punch_element = "upgraded";
        self.b_punch_upgraded = 1;
        FistSZ = "one_inch_punch_upgraded_zm";
        FistPrice = 100;
        FistColor = 0;
    }
    else if (fistType == 2)
    {
        self.str_punch_element = "air";
        self.b_punch_upgraded = 1;
        FistSZ = "one_inch_punch_air_zm";
        FistPrice = 150;
        FistColor = 1;
    }
    else if (fistType == 3)
    {
        self.str_punch_element = "fire";
        self.b_punch_upgraded = 1;
        FistSZ = "one_inch_punch_fire_zm";
        FistPrice = 150;
        FistColor = 1;
    }
    else if (fistType == 4)
    {
        self.str_punch_element = "ice";
        self.b_punch_upgraded = 1;
        FistSZ = "one_inch_punch_ice_zm";
        FistPrice = 150;
        FistColor = 1;
    }
    else if (fistType == 5)
    {
        self.str_punch_element = "lightning";
        self.b_punch_upgraded = 1;
        FistSZ = "one_inch_punch_lightning_zm";
        FistPrice = 150;
        FistColor = 1;
    }
    else
    {
        self.str_punch_element = undefined;
        self.b_punch_upgraded = undefined;
        FistPrice = 60;
        FistColor = 0;
    }

    if (self.points >= FistPrice)
    {
        self.points -= FistPrice; 
        if (isDefined(self.b_punch_upgraded) && self.b_punch_upgraded)
        {
            current_melee_weapon = self get_player_melee_weapon();
            self takeweapon(current_melee_weapon);
            str_weapon = self getcurrentweapon();
            self disable_player_move_states(1);
            self giveweapon("zombie_one_inch_punch_upgrade_flourish");
            self switchtoweapon("zombie_one_inch_punch_upgrade_flourish");
            self waittill_any("player_downed", "weapon_change_complete");
            self switchtoweapon(str_weapon);
            self enable_player_move_states();
            self takeweapon("zombie_one_inch_punch_upgrade_flourish");
            self giveweapon( "one_inch_punch_upgraded_zm" );
            self set_player_melee_weapon( "one_inch_punch_upgraded_zm" );
        }
        else
        { 
            str_weapon = self getcurrentweapon();
            self disable_player_move_states(1);
            self giveweapon("zombie_one_inch_punch_flourish");
            self switchtoweapon("zombie_one_inch_punch_flourish");
            self waittill_any("player_downed", "weapon_change_complete");
            self switchtoweapon(str_weapon);
            self enable_player_move_states();
            self takeweapon("zombie_one_inch_punch_flourish");
            self giveweapon("one_inch_punch_zm");
            self set_player_melee_weapon("one_inch_punch_zm");
            self thread maps/mp/zombies/_zm_audio::create_and_play_dialog("perk", "one_inch");  
        }

        foreach (player in level.players)
        {
            if (FistColor == 0)
                player iprintln("^4" + self.name + " ^7Have Bought ^3" + FistSZ);
            else if (FistColor == 1)
                player iprintln("^4" + self.name + " ^7Have Bought ^6" + FistSZ);
        }
    }
    else
    {
        iprintln("^1You dont have enough points!");
        iprintln("^1Require " + FistPrice + " points!");
    }
    
    self thread maps/mp/zombies/_zm_weap_one_inch_punch::monitor_melee_swipe();
}*/

SetDvarCustom(dvarType)
{
    if (dvarType == 1)
    {
        if (self.points >= 50 && level.bLowGravity == false)
        {
            level.bLowGravity = true;
            level thread SetDvarCustomThread("bg_gravity", 100);
            self.points -= 50;
            foreach (player in level.players)
                player iprintln("^4" + self.name + " ^3Have Toggled ^3Low Gravity ^7 For ^11 Minute");
        }
        else if (level.bLowGravity == true)
            iprintln("^1Low Gravity Is Already Activiate Wait Until The Effect Finish!");
        else
        {
            iprintln("^1You dont have enough points!");
            iprintln("^1Require 100 points!");
        }
    }
    else if (dvarType == 2)
    {
        if (self.points >= 50 && level.bDoubleSpeed == false)
        {
            level.bDoubleSpeed = true;
            level thread SetDvarCustomThread("g_speed", 380);
            self.points -= 50;
            foreach (player in level.players)
                player iprintln("^4" + self.name + " ^3Have Toggled ^3Double Speed ^7 For ^11 Minute");
        }
        else if (level.bDoubleSpeed == true)
            iprintln("^1Double Speed Is Already Activiate Wait Until The Effect Finish!");
        else
        {
            iprintln("^1You dont have enough points!");
            iprintln("^1Require 100 points!");
        }
    }
    else if (dvarType == 3)
    {
        if (self.points >= 50 && level.bDoubleJumpHeight == false)
        {
            level.bDoubleJumpHeight = true;
            level thread SetDvarCustomThread("jump_height", 78);
            self.points -= 50;
            foreach (player in level.players)
                player iprintln("^4" + self.name + " ^3Have Toggled ^3Double Jump Height ^7 For ^11 Minute");
        }
        else if (level.bDoubleJumpHeight == true)
            iprintln("^1Double Jump Height Is Already Activiate Wait Until The Effect Finish!");
        else
        {
            iprintln("^1You dont have enough points!");
            iprintln("^1Require 100 points!");
        }
    } 
}

FunFunc(funType)
{
    if (funType == 0)
    {
        if (self.points >= 150)
        {
            if (level.bGodMode == false)
            {
                self.points -= 150;
                level thread GodMode(self);
            }
            else
            {
                iprintln("^1Someone have already activated god mode wait until it finish!");
            }
        }
        else
        {
            iprintln("^1You dont have enough points!");
            iprintln("^1Require 150 points!");
        }
    }
    if (funType == 1)
    {
        Price = 50*level.players.size; 
        if (self.points >= Price)
        {
            if (level.bPerksLimitRemoved == false)
            {
                self.points -= Price;
                level.perk_purchase_limit = 9;
                level.bPerksLimitRemoved = true;

                foreach (player in level.players)
                    player iprintln("^4" + self.name + " ^3Have Removed the ^6perks limit!");
            }
            else
            {
                iprintln("^1Someone have already removed the perks limit!");
            }
        }
        else
        {
            iprintln("^1You dont have enough points!");
            iprintln("^1Require " + Price + " points!");
        }
    }
    if (funType == 2)
    {
        Price = level.players.size*50;
        if (player_any_player_in_laststand())
        {
            foreach (player in level.players)
                if (player player_is_in_laststand())
                {
                    player reviveplayer();
                    player laststand_enable_player_weapons();
                    player maps/mp/zombies/_zm_perks::perk_set_max_health_if_jugg( "health_reboot", 1, 0 );
                    player thread maps/mp/zombies/_zm_pers_upgrades_functions::pers_upgrade_perk_lose_restore();
                    player.revivetrigger delete();
                    player.revivetrigger = undefined;
                    player cleanup_suicide_hud();
                    self.ignoreme = 0;
                }
        }
        else
            self iprintln("^1There is no any players need to be revived!");
    }
}

SetDvarCustomThread(DvarSZ, dvarValue)
{
    oldDvarValue = getDvar(DvarSZ);
    setDvar(DvarSZ, dvarValue);
    wait 60;
    setDvar(DvarSZ, oldDvarValue);
    if (DvarSZ == "bg_gravity")
    {
        level.bLowGravity = false;
        foreach (player in level.players)
            player iprintln("^21 Minute Have Passed Setting The Gravity To Default!");
    }
    else if (DvarSZ == "g_speed")
    {
        level.bDoubleSpeed = false;
        foreach (player in level.players)
            player iprintln("^21 Minute Have Passed Setting The Speed To Default!");
    }
    else if (DvarSZ == "jump_height")
    {
        level.bDoubleJumpHeight = false;
        foreach (player in level.players)
            player iprintln("^21 Minute Have Passed Setting The Jump Height To Default!");
    }
}

AbilitiesFunc(abilityType)
{
    if (abilityType == 1)
    {
        if (self.points >= 100)
        {
            if (self.bAbilitySpeed == false)
            {
                self setmovespeedscale(2);
                self.points -= 100;
                self.bAbilitySpeed = true;
                foreach (player in level.players)
                    player iprintln("^4" + self.name + " have activate ^6perma double speed!");
            }
            else
            {
                iprintln("^1You already have perma double speed!");
            }
        }
        else
        {
            iprintln("^1You dont have enough points!");
            iprintln("^1Require 100 points!");
        }
    }
    if (abilityType == 2)
    {
        if (self.points >= 100)
        {
            if (self.bAbilityJump == false)
            {
                self thread DoubleJumpFunc();
                self.points -= 100;
                self.bAbilityJump = true;
                foreach (player in level.players)
                    player iprintln("^4" + self.name + " have activate ^6perma double jump!");
            }
            else
            {
                iprintln("^1You already have perma double jump!");
            }
        }
        else
        {
            iprintln("^1You dont have enough points!");
            iprintln("^1Require 100 points!");
        }
    }
}

TrollFunc(trollType)
{
    if (trollType == 1)
    {
        if (self.points >= 150)
        {
            if (level.bSlowSpeedTroll == false)
            {
                level.bSlowSpeedTroll = true;
                level thread SlowSpeedTroll(self);
            }
            else
            {
                iprintln("^1Someone have already activated this troll!");
            }
        }
    }
}

SlowSpeedTroll(playerActivated)
{
    foreach (player in level.players)
    {
        player iprintln("^4" + playerActivated.name + " ^7have activate ^1slow speed troll for 1 Min!");
        if (player != playerActivated)
        {
            Temp = player getmovespeedscale();
            player setmovespeedscale(Temp/2);
        }
    }
    wait 60;
    foreach (player in level.players)
    {
        player iprintln("^2Slow speed troll have expired resetting the speed for all players");
        if (player != playerActivated)
        {
            Temp = player getmovespeedscale();
            player setmovespeedscale(Temp*2);
        }
    }
    level.bSlowSpeedTroll = false;
}

GodMode(activatedPlayer)
{
    level.bGodMode = true;
    foreach (player in level.players)
    {
        player enableInvulnerability();
        player iprintln("^4" + activatedPlayer.name + " ^7have activate ^6God Mode for 1 Min!");
    }
    wait 60;
    foreach (player in level.players)
    {
        player DisableInvulnerability();
        player iprintln("^21 Min have passed disabling god mode!");
    }
    level.bGodMode = false;
}

DoubleJumpFunc()
{
    self endon("death");
    self endon("disconnect");
    for(;;)
    {
        if(self GetVelocity()[2]>150 && !self isOnGround())
        {
            wait 0.2;
            self setvelocity((self getVelocity()[0],self getVelocity()[1],self getVelocity()[2])+(0,0,250));
            wait 0.8;
        }
        wait 0.001;
    }
}
