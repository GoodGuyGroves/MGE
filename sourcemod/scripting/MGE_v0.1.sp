#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <smlib>

public Plugin:myinfo =
{
	name = "MGE",
	author = "Russell Groves",
	description = "A plugin to practice many (eventually) aspects of competitive CS:GO.",
	version = "0.1",
	url = "none"
};

#define ARENAS 5

enum enumPlayerInfo
{
	clientIndex,																										// Done in OnClientConnect
	String:steamID[30],																									// Done in OnClientConnect
	String:playerName[30],																								// Done in OnClientConnect
	currArena,
	bool:isAlive,
	bool:active,
	String:primWep[10],
	String:secWep[10],
	String:team[2],																										// Done in Event_PlayerTeam hook
};

enum enumArenaInfo
{
	arenaNum,
	ctPlayer,
	tPlayer,
	Float:ctPosition[3],
	Float:ctAngle[3],
	Float:tPosition[3],
	Float:tAngle[3],
	bool:ctOccupied,
	bool:tOccupied
};

new const String:arenaArray[ARENAS][] = { "long", "a-site", "middle", "cat-lower", "b-site" };
new arenaInfo[ARENAS][enumArenaInfo];
new playerData[MAXPLAYERS+1][enumPlayerInfo];
new const String:trigger[] = "!join";

public OnPluginStart()
{
	LoadTranslations("common.phrases");
	//RegConsoleCmd("sm_rdmjoin", Command_RDMJoin);
	RegConsoleCmd("say", Command_Say);
	RegConsoleCmd("say_team", Command_Say);
	//AddCommandListener(CS_OnBuyCommand, "buy");
	HookEvent("player_team", Event_PlayerTeam, EventHookMode_Post);
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Post);
	HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Post);
}

public OnMapStart()
{

	arenaInfo[0][arenaNum] = 0; // long
	arenaInfo[0][ctPosition] = Float:{ 1425.299316, 1554.034546, 65.482758 }
	arenaInfo[0][ctAngle] = Float:{ 1.337632, -96.538467, 0.000000 }
	arenaInfo[0][tPosition] = Float:{ 555.922546,  138.107529, 66.537231 };
	arenaInfo[0][tAngle] = Float:{ 2.956831, 63.717297, 0.000000 };
	arenaInfo[0][ctOccupied] = false;
	arenaInfo[0][tOccupied] = false;

	arenaInfo[0][arenaNum] = 1; // a-site
	arenaInfo[1][ctPosition] = Float:{ 1274.116577, 2663.002197, 192.093811 };
	arenaInfo[1][ctAngle] = Float:{ 1.126423, -143.495361, 0.000000 };
	arenaInfo[1][tPosition] = Float:{ 318.183472, 1476.959473, 64.093811 };
	arenaInfo[1][tAngle] = Float:{ -4.716795, 75.605049, 0.000000 };
	arenaInfo[1][ctOccupied] = false;
	arenaInfo[1][tOccupied] = false;

	arenaInfo[0][arenaNum] = 2; // middle
	arenaInfo[2][ctPosition] = Float:{ -146.875443, 2162.865234, -61.070915 };
	arenaInfo[2][ctAngle] = Float:{ -1.161573, -131.617020, 0.000000 };
	arenaInfo[2][tPosition] = Float:{ -378.031311, 592.052307, 68.941483 };
	arenaInfo[2][tAngle] = Float:{ 5.350435, 91.726868, 0.000000 };
	arenaInfo[2][ctOccupied] = false;
	arenaInfo[2][tOccupied] = false;

	arenaInfo[0][arenaNum] = 3; // cat-lower
	arenaInfo[3][ctPosition] = Float:{ 469.207703, 1694.784424, 64.093811 };
	arenaInfo[3][ctAngle] = Float:{ 1.971195, -138.285965, 0.000000 };
	arenaInfo[3][tPosition] = Float:{ -1119.132690, 1248.484985, -32.154953 };
	arenaInfo[3][tAngle] = Float:{ 2.569617, 47.374950, 0.000000 };
	arenaInfo[3][ctOccupied] = false;
	arenaInfo[3][tOccupied] = false;

	arenaInfo[0][arenaNum] = 4; // b-site
	arenaInfo[4][ctPosition] = Float:{ -1615.403564, 2472.006836, 68.597305 };
	arenaInfo[4][ctAngle] = Float:{ 0.035231, -117.447578, 0.000000 };
	arenaInfo[4][tPosition] = Float:{ -1795.663574, 1146.142944, 96.093811 };
	arenaInfo[4][tAngle] = Float:{ 2.288012, 120.943108, 0.000000 };
	arenaInfo[4][ctOccupied] = false;
	arenaInfo[4][tOccupied] = false;
}

public OnMapEnd()
{
	// Close relevant stuff to prevent memleaks.
}

public bool:OnClientConnect(client, String:rejectmsg[], maxlen)
{
	new String:target[30];
	new String:SID[30];
	GetClientAuthString(client, SID, 30);
	GetClientName(client, target, sizeof(target));
	playerData[client][clientIndex] = client;																			// Stores the clients index
	strcopy(playerData[client][playerName], 30, target);																// Stores the players name
	strcopy(playerData[client][steamID], 30, SID);																		// Stores the players SteamID
	playerData[client][active] = false;
	return true;
}

public OnClientDisconnect(client)
{
	// Remove playerData enumPlayerInfo data from playerData array at position 'client'
}

public Action:Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	PrintToConsole(client, "Event_PlayerSpawn successfully hooked!");

	if (playerData[client][active] == true)
	{
		if (strcmp(playerData[client][team], "3", false) == 0)
		{
			playerData[client][isAlive] = true;
			new arena = playerData[client][currArena];
			new Float:fPos[3];
			new Float:fAng[3];
			for (new i = 0; i < 3; i++)
			{
				fPos[i] = arenaInfo[arena][ctPosition][i];
				fAng[i] = arenaInfo[arena][ctAngle][i];
			}
			TeleportEntity(client, fPos, fAng, NULL_VECTOR);
			CreateTimer(0.5, Timer_GivePlayerWeapon, GetClientSerial(client));
			return Plugin_Handled;
		}
		else if (strcmp(playerData[client][team], "2", false) == 0)
		{
			playerData[client][isAlive] = true;
			new arena = playerData[client][currArena];
			new Float:fPos[3];
			new Float:fAng[3];
			for (new i = 0; i < 3; i++)
			{
				fPos[i] = arenaInfo[arena][tPosition][i];
				fAng[i] = arenaInfo[arena][tAngle][i];
			}
			TeleportEntity(client, fPos, fAng, NULL_VECTOR);
			CreateTimer(0.5, Timer_GivePlayerWeapon, GetClientSerial(client));
			return Plugin_Handled;
		}
		else if (strcmp(playerData[client][team], "1", false) == 0)
		{
			return Plugin_Continue;
		}
	}
	else if (playerData[client][active] == false)
	{
		return Plugin_Continue;
	}
	return Plugin_Handled;
}

public Action:Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	PrintToConsole(victim, "Event_PlayerDeath successfully hooked!");

	if (playerData[victim][active] == true)
	{
		CreateTimer(1.0, Timer_RespawnPlayer, GetClientSerial(victim));
		CreateTimer(1.0, Timer_RespawnPlayer, GetClientSerial(attacker));

		return Plugin_Handled;
	}
	else if (playerData[victim][active] == false)
	{
		return Plugin_Continue;
	}
	return Plugin_Handled;
}

public Action:Timer_RespawnPlayer(Handle:timer, any:serial)
{
	new client = GetClientFromSerial(serial);
	CS_RespawnPlayer(client);
}

public Action:Timer_GivePlayerWeapon(Handle:timer, any:serial)
{
	new client = GetClientFromSerial(serial);
	if (strcmp(playerData[client][team], "3", false) == 0)
	{
		Client_RemoveAllWeapons(client);
		//Client_GiveWeaponAndAmmo(client, "weapon_m4a1");
		//Client_GiveWeaponAndAmmo(client, "weapon_hkp2000");
		GivePlayerItem(client, "weapon_m4a1");
		GivePlayerItem(client, "weapon_hkp2000");
		GivePlayerItem(client, "weapon_knife");
	}
	else if (strcmp(playerData[client][team], "2", false) == 0)
	{
		Client_RemoveAllWeapons(client);
		//Client_GiveWeaponAndAmmo(client, "weapon_ak47");
		//Client_GiveWeaponAndAmmo(client, "weapon_deagle");
		GivePlayerItem(client, "weapon_ak47");
		GivePlayerItem(client, "weapon_deagle");
		GivePlayerItem(client, "weapon_knife");
	}
}


public Action:Event_PlayerTeam(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	PrintToConsole(client, "Event_PlayerTeam successfully hooked!");
	new String:playerTeam[2];
	GetEventString(event, "team", playerTeam, sizeof(playerTeam));
	strcopy(playerData[client][team], 2, playerTeam);
	PrintToConsole(client, "1) The team you joined is %s", playerData[client][team]);
	PrintToConsole(client, "2) The team you joined is %s", playerTeam);
	return Plugin_Handled;
}

public Action:Command_Say(client, args)
{
	new String:arg0[32];
	new String:arg1[32];
	new String:arg2[32];
	new String:arg3[32];
	GetCmdArg(0, arg0, sizeof(arg0));
	GetCmdArg(1, arg1, sizeof(arg1));
	GetCmdArg(2, arg2, sizeof(arg2));
	GetCmdArg(3, arg3, sizeof(arg3));
	new String:targName[30];
	GetClientName(client, targName, sizeof(targName));

	if (strcmp(arg1, trigger, false) != 0)
	{
		return Plugin_Continue;
	}

	if (strcmp(arg1, trigger, false) == 0)
	{

		if (args == 2)
		{

			new bool:validLocale = false;
			new localeIndex = 0;

			for (new i = 0; i < ARENAS; i++)
			{
				if (strcmp(arg2, arenaArray[i], false) == 0)
				{
					validLocale = true;
					localeIndex = i;
					break;
				}
				localeIndex++;
			}

			if (validLocale == true)
			{
				// 1 = Spectate
				// 2 = T
				// 3 = CT
				if (strcmp(playerData[client][team], "3", false) == 0)
				{
					if (arenaInfo[localeIndex][ctOccupied] == true)
					{
						ReplyToCommand(client, "[SM] Location occupied for CT's.");
						return Plugin_Handled;
					}

					if (arenaInfo[localeIndex][ctOccupied] == false)
					{
						new Float:fPos[3];
						new Float:fAng[3];
						for (new i = 0; i < 3; i++)
						{
							fPos[i] = arenaInfo[localeIndex][ctPosition][i];
							fAng[i] = arenaInfo[localeIndex][ctAngle][i];
						}
						TeleportEntity(client, fPos, fAng, NULL_VECTOR);
						ReplyToCommand(client, "[SM] You have been moved to %s.", arg2);
						arenaInfo[localeIndex][ctPlayer] = client;
						playerData[client][currArena] = localeIndex;
						playerData[client][active] = true;
						return Plugin_Handled;
					}
				}

				else if (strcmp(playerData[client][team], "2", false) == 0)
				{
					if (arenaInfo[localeIndex][tOccupied] == true)
					{
						ReplyToCommand(client, "[SM] Location occupied for T's.");
						return Plugin_Handled;
					}

					if (arenaInfo[localeIndex][tOccupied] == false)
					{
						new Float:fPos[3];
						new Float:fAng[3];
						for (new i = 0; i < 3; i++)
						{
							fPos[i] = arenaInfo[localeIndex][tPosition][i];
							fAng[i] = arenaInfo[localeIndex][tAngle][i];
						}
						TeleportEntity(client, fPos, fAng, NULL_VECTOR);
						ReplyToCommand(client, "[SM] You have been moved to %s.", arg2);
						arenaInfo[localeIndex][tPlayer] = client;
						playerData[client][currArena] = localeIndex;
						playerData[client][active] = true;
						return Plugin_Handled;
					}
				}
				else if (strcmp(playerData[client][team], "1", false) == 0)
				{
					ReplyToCommand(client, "[SM] Join a team first!");
				}
				else
				{
					ReplyToCommand(client, "[SM] Team not found.");
					return Plugin_Handled;
				}
			}
			else
			{
				ReplyToCommand(client, "[SM] Arena not found.");
				return Plugin_Handled;
			}

		}
		else
		{
			ReplyToCommand(client, "[SM] Usage: %t <arena>", trigger);
			return Plugin_Handled;
		}

		return Plugin_Handled;
	}
	else
	{
		ReplyToCommand(client, "[SM] Usage: %t <arena>", trigger);
		return Plugin_Handled;
	}
	
}