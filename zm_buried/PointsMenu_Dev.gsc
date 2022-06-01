#include maps/mp/_utility;
#include common_scripts/utility;
#include maps/mp/gametypes_zm/_hud_util;
#include maps/mp/zombies/_zm_utility;
#include maps/mp/zombies/_zm_powerups;
#include maps/mp/zombies/_zm_laststand;
#include maps/mp/zombies/_zm_weapons;
#include maps/mp/zombies/_zm_laststand;
#include maps/mp/zombies/_zm_perks;

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
        self.MenuTextColor = 6;
        self thread BuildMenu();
        self.bAbilityJump = false;
        self.HealthUpgrade = 1;
        self ShowOpenHint();
        self thread TakeAbilitiesThread();
		self.oldMaxHealth = self.maxhealth + 150;
		self.bAbilitySpeed = false;
    }
}

ShowOpenHint()
{
    self iprintln("^2To open the menu Press Aim Button + Melee Button");
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
    self MenuOption("Main Menu", 5, "Misc Menu", ::SubMenu, "Misc Menu");

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
    self MenuOption("Powerup Menu", PowerupOptionsPos, "Buy Fire Sale", ::BuyPowerup, 6);
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
    self MenuOption("Abilities Menu", 2, "Upgrade Health", ::AbilitiesFunc, 3);

    self MainMenu("Troll Menu", "Main Menu");
    self MenuOption("Troll Menu", 0, "Decrease Players Speed", ::TrollFunc, 1);
    self MenuOption("Troll Menu", 1, "Low Gravity", ::SetDvarCustom, 1);

    self MainMenu("Misc Menu", "Main Menu");
    self MenuOption("Misc Menu", 0, "Change Menu Color", ::SubMenu, "Change Menu Color");
    self MenuOption("Misc Menu", 1, "End the game", ::EndGameFunc);

    self MainMenu("Change Menu Color", "Misc Menu");
    self MenuOption("Change Menu Color", 0, "Red", ::MenuColorFunc, 1);
    self MenuOption("Change Menu Color", 1, "Green", ::MenuColorFunc, 2);
    self MenuOption("Change Menu Color", 2, "Yellow", ::MenuColorFunc, 3);
    self MenuOption("Change Menu Color", 3, "Blue", ::MenuColorFunc, 4);
    self MenuOption("Change Menu Color", 4, "Cyan", ::MenuColorFunc, 5);
    self MenuOption("Change Menu Color", 5, "Pink", ::MenuColorFunc, 6);
    self MenuOption("Change Menu Color", 6, "White", ::MenuColorFunc, 7);

    self MainMenu("Buy Wonder Weapons", "Weapons Menu");
    self MenuOption("Buy Wonder Weapons", 0, "Buy Ray Gun", ::BuyWeapon, 0);
    self MenuOption("Buy Wonder Weapons", 1, "Buy Paralyzer", ::BuyWeapon, 3);
    if (is_weapon_included("raygun_mark2_zm"))
    {
        self MenuOption("Buy Wonder Weapons", 2, "Buy Ray Gun Mark 2", ::BuyWeapon, 2);
    }

    self MainMenu("Buy Equipments", "Weapons Menu");
    self MenuOption("Buy Equipments", 0, "Buy Cymbal Monkey", ::BuyWeapon, 6);
    self MenuOption("Buy Equipments", 1, "Buy Claymore", ::BuyWeapon, 8);
    self MenuOption("Buy Equipments", 1, "Buy Time Bomb", ::BuyWeapon, 12);

    self MainMenu("Buy Melee", "Weapons Menu");
    self MenuOption("Buy Melee", 0, "Buy Bowie Knife", ::BuyMelee, 0);
    self MenuOption("Buy Melee", 1, "Buy Tazer", ::BuyMelee, 1);
}

MainMenu(Menu, Return)
{
    self.Menu.System["GetMenu"] = Menu;
    self.Menu.System["MenuCount"] = 0;
    self.Menu.System["MenuPrevious"][Menu] = Return;
}
MenuOption(Menu, Index, Texte, Function, Input)
{
    self.Menu.System["MenuTexte"][Menu][Index] = "^" + self.MenuTextColor + Texte;
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
    self.Menu.System["Title"] setText("^" + self.MenuTextColor + menu);
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
            self iprintln("^1You dont have enough points!");
            self iprintln("^1Require 50 points!");
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
            self iprintln("^1You dont have enough points!");
            self iprintln("^1Require 50 points!");
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
            self iprintln("^1You dont have enough points!");
            self iprintln("^1Require 50 points!");
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
            self iprintln("^1You dont have enough points!");
            self iprintln("^1Require 50 points!");
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
            self iprintln("^1You dont have enough points!");
            self iprintln("^1Require 100 points!");
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
            self iprintln("^1You dont have enough points!");
            self iprintln("^1Require 100 points!");
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
    else if (weaponType == 12)
    {
        weaponSZ = "time_bomb_zm";
        weaponPrice = 80;
        weaponColor = 1;
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
        self iprintln("^1You dont have enough points!");
        self iprintln("^1Require " + weaponPrice + " points!");
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
        self iprintln("^1You dont have enough points!");
        self iprintln("^1Require " + meleePrice + " points!");
    }
}

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
            self iprintln("^1Low Gravity Is Already Activiate Wait Until The Effect Finish!");
        else
        {
            self iprintln("^1You dont have enough points!");
            self iprintln("^1Require 100 points!");
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
            self iprintln("^1Double Speed Is Already Activiate Wait Until The Effect Finish!");
        else
        {
            self iprintln("^1You dont have enough points!");
            self iprintln("^1Require 100 points!");
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
            self iprintln("^1Double Jump Height Is Already Activiate Wait Until The Effect Finish!");
        else
        {
            self iprintln("^1You dont have enough points!");
            self iprintln("^1Require 100 points!");
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
                self iprintln("^1Someone have already activated god mode wait until it finish!");
            }
        }
        else
        {
            self iprintln("^1You dont have enough points!");
            self iprintln("^1Require 150 points!");
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
                self iprintln("^1Someone have already removed the perks limit!");
            }
        }
        else
        {
            self iprintln("^1You dont have enough points!");
            self iprintln("^1Require " + Price + " points!");
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
                self iprintln("^1You already have perma double speed!");
            }
        }
        else
        {
            self iprintln("^1You dont have enough points!");
            self iprintln("^1Require 100 points!");
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
                self iprintln("^1You already have perma double jump!");
            }
        }
        else
        {
            self iprintln("^1You dont have enough points!");
            self iprintln("^1Require 100 points!");
        }
    }
    if (abilityType == 3)
    {
        if (self.points >= 40 * self.HealthUpgrade)
        {
            if (self hasperk("specialty_armorvest"))
            {
                if (self.HealthUpgrade == 6)
                {
                    self iprintln("^1You reached the maximum health upgrade!");
                }
                else
                {
				    self.points -= 40 * self.HealthUpgrade;
                    self setmaxhealth(self.oldMaxHealth + (50 * self.HealthUpgrade));
					self.health = self.oldMaxHealth + (50 * self.HealthUpgrade);
                    foreach (player in level.players)
                        player iprintln("^4" + self.name + " have upgraded the health to: " + self.oldMaxHealth + (50 * self.HealthUpgrade));
					self.HealthUpgrade += 1;
                }
            }
            else
            {
                self iprintln("^1You should buy juggernog first before using this upgrade!");
            }
        }
        else
        {
            self iprintln("^1You dont have enough points!");
            self iprintln("^1Require " + (40 * self.HealthUpgrade) + " points!");
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
                self iprintln("^1Someone have already activated this troll!");
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
	    if (self.bAbilityJump == true)
		{
		    if(self GetVelocity()[2]>150 && !self isOnGround())
            {
                wait 0.2;
                self setvelocity((self getVelocity()[0],self getVelocity()[1],self getVelocity()[2])+(0,0,250));
                wait 0.8;
            }
		}
		wait 0.01;
    }
}

TakeAbilitiesThread()
{
    while (true)
    {
        self waittill("player_downed");
        if (self.HealthUpgrade > 1)
        {
            self.HealthUpgrade = 1;
            perk_set_max_health_if_jugg( "health_reboot", 1, 0 );
            foreach (player in level.players)
                player iprintln("^4" + self.name + " have lost the health upgrade");
        }
		if (self.bAbilitySpeed == true)
		{
		    self setmovespeedscale(1);
			foreach (player in level.players)
                player iprintln("^4" + self.name + " have lost the speed upgrade");
			self.bAbilitySpeed = false;
		}
		if (self.bAbilityJump == true)
		{
			foreach (player in level.players)
                player iprintln("^4" + self.name + " have lost the jump upgrade");
			self.bAbilityJump = false;
		}
    }
}

EndGameFunc()
{
    if (self.points >= 1200)
    {
	level.custom_game_over_hud_elem = ::GameOverHud;
        level notify("end_game");
        self freezeControls(1);
        self MenuClosing();
    }
    else
    {
        self iprintln("^1You dont have enough points!");
        self iprintln("^1Require 1200 points!");
    }
}

GameOverHud(player)
{
    game_over = newclienthudelem( player );
	game_over.alignX = "center";
	game_over.alignY = "middle";
	game_over.horzAlign = "center";
	game_over.vertAlign = "middle";
	game_over.y -= 130;
	game_over.foreground = true;
	game_over.fontScale = 3;
	game_over.alpha = 0;
	game_over.color = ( 1.0, 1.0, 1.0 );
	game_over.hidewheninmenu = true;
	game_over SetText("You Won!");
	game_over FadeOverTime( 1 );
	game_over.alpha = 1;
}

MenuColorFunc(color)
{
    self MenuClosing();
    self.MenuTextColor = color;

    if (self.MenuTextColor == 1)
    {
        self.Menu.Material["Scrollbar"].color = (1, 0, 0);
        self.Menu.Material["BorderMiddle"].color = (1, 0, 0);
        self.Menu.Material["BorderLeft"].color = (1, 0, 0);
        self.Menu.Material["BorderRight"].color = (1, 0, 0);
    }
    if (self.MenuTextColor == 2)
    {
        self.Menu.Material["Scrollbar"].color = (0, 1, 0);
        self.Menu.Material["BorderMiddle"].color = (0, 1, 0);
        self.Menu.Material["BorderLeft"].color = (0, 1, 0);
        self.Menu.Material["BorderRight"].color = (0, 1, 0);
    }
    if (self.MenuTextColor == 3)
    {
        self.Menu.Material["Scrollbar"].color = (1, 1, 0);
        self.Menu.Material["BorderMiddle"].color = (1, 1, 0);
        self.Menu.Material["BorderLeft"].color = (1, 1, 0);
        self.Menu.Material["BorderRight"].color = (1, 1, 0);
    }
    if (self.MenuTextColor == 4)
    {
        self.Menu.Material["Scrollbar"].color = (0, 0, 1);
        self.Menu.Material["BorderMiddle"].color = (0, 0, 1);
        self.Menu.Material["BorderLeft"].color = (0, 0, 1);
        self.Menu.Material["BorderRight"].color = (0, 0, 1);
    }
    if (self.MenuTextColor == 5)
    {
        self.Menu.Material["Scrollbar"].color = (0, 1, 1);
        self.Menu.Material["BorderMiddle"].color = (0, 1, 1);
        self.Menu.Material["BorderLeft"].color = (0, 1, 1);
        self.Menu.Material["BorderRight"].color = (0, 1, 1);
    }
    if (self.MenuTextColor == 6)
    {
        self.Menu.Material["Scrollbar"].color = (1, 0, 1);
        self.Menu.Material["BorderMiddle"].color = (1, 0, 1);
        self.Menu.Material["BorderLeft"].color = (1, 0, 1);
        self.Menu.Material["BorderRight"].color = (1, 0, 1);
    }
    if (self.MenuTextColor == 7)
    {
        self.Menu.Material["Scrollbar"].color = (1, 1, 1);
        self.Menu.Material["BorderMiddle"].color = (1, 1, 1);
        self.Menu.Material["BorderLeft"].color = (1, 1, 1);
        self.Menu.Material["BorderRight"].color = (1, 1, 1);
    }

    self MenuStructure();
    self iprintln("^" + self.MenuTextColor + "Menu color changed!");
}
