#define		PLAYERCOND_SPYCLOAK	(1<<4)
#define		MAXGENERIC	25	//Used as a limit in the config file

#define		DBD_UNDEF	-1 //DBD = Don't Be Death
#define		DBD_OFF		1
#define		DBD_ON		2
#define		DBD_THISMAP	3 // The cookie will never have this value
#define		TIME_TO_ASK	30.0 //Delay between asking the client its preferences and it's connection/join.

//Variables

int		g_lastdeath = -1,
		g_timesplayed_asdeath[MAXPLAYERS + 1],
		g_dontBeDeath[MAXPLAYERS+1] =	{	DBD_UNDEF,	...};
bool	g_isDRmap				= false,
		g_onPreparation			= false,
		g_canEmitSoundToDeath	= true,

//General
		g_diablefalldamage,
		g_finishoffrunners;
int		g_runner_outline,
		g_death_outline;
float	g_runner_speed,
		g_death_speed;

//Weapon
bool		g_MeleeOnly,
			g_MeleeRestricted,
			g_RestrictAll,
			g_UseDefault,
			g_UseAllClass;
StringMap	g_RestrictedWeps,
			g_AllClassWeps,

//Command
			g_CmdList,
			g_CmdTeamToBlock,
			g_CmdBlockOnlyOnPrep,

//Sound
			g_SndRoundStart,
			g_SndOnDeath,
			g_SndOnKill,
			g_SndLastAlive;
float		g_OnKillDelay;

//Cookies
Cookie		g_DRCookie;

//ConVars
ConVar	dr_queue,
		dr_unbalance,
		dr_autobalance,
		dr_firstblood,
		dr_scrambleauto,
		dr_airdash,
		dr_push,
		dr_plugin_advert,
		dr_plugin_timer;

int	dr_queue_def		= 0,
	dr_unbalance_def	= 0,
	dr_autobalance_def	= 0,
	dr_firstblood_def	= 0,
	dr_scrambleauto_def	= 0,
	dr_airdash_def		= 0,
	dr_push_def			= 0;

void ResetCvars()	{
	dr_queue		.SetInt(dr_queue_def);
	dr_unbalance	.SetInt(dr_unbalance_def);
	dr_autobalance	.SetInt(dr_autobalance_def);
	dr_firstblood	.SetInt(dr_firstblood_def);
	dr_scrambleauto	.SetInt(dr_scrambleauto_def);
	dr_airdash		.SetInt(dr_airdash_def);
	dr_push			.SetInt(dr_push_def);

	//We clear the stringmaps
	ProcessListeners(true);
	g_RestrictedWeps		.Clear();
	g_AllClassWeps			.Clear();
	g_CmdList				.Clear();
	g_CmdTeamToBlock		.Clear();
	g_CmdBlockOnlyOnPrep	.Clear();
	g_SndRoundStart			.Clear();
	g_SndOnDeath			.Clear();
	g_SndOnKill				.Clear();
	g_SndLastAlive			.Clear();
}

void stringmaps()	{
	g_RestrictedWeps		= new StringMap();
	g_AllClassWeps			= new StringMap();
	g_CmdList				= new StringMap();
	g_CmdTeamToBlock		= new StringMap();
	g_CmdBlockOnlyOnPrep	= new StringMap();
	g_SndRoundStart			= new StringMap();
	g_SndOnDeath			= new StringMap();
	g_SndOnKill				= new StringMap();
	g_SndLastAlive			= new StringMap();
}

void convars()	{
	dr_queue		= FindConVar("tf_arena_use_queue");
	dr_unbalance	= FindConVar("mp_teams_unbalance_limit");
	dr_autobalance	= FindConVar("mp_autoteambalance");
	dr_firstblood	= FindConVar("tf_arena_first_blood");
	dr_scrambleauto	= FindConVar("mp_scrambleteams_auto");
	dr_airdash		= FindConVar("tf_scout_air_dash_count");
	dr_push			= FindConVar("tf_avoidteammates_pushaway");
}

/**
 *	Lets block the death from changing team.
 */
Action Callback_PreventTeamChange(int client, const char[] command, int args)	{
	char arg1[96];
	GetCmdArg(1, arg1, sizeof(arg1));
	switch(TF2_GetClientTeam(client))	{
		case	TFTeam_Blue:	{
			if(StrEqual(command, "jointeam", false) && StrEqual(arg1, "red", false))	{
				CPrintToChat(client, "%s %t", DRTag, "you may not change team as death");
				return	Plugin_Handled;
			}
			
			if(StrEqual(command, "jointeam", false) && StrEqual(arg1, "spectate", false))	{
				CPrintToChat(client, "%s %t", DRTag, "you may not change team as death");
				return	Plugin_Handled;
			}

			if(StrEqual(command, "jointeam", false) && StrEqual(arg1, "auto", false))	{
				CPrintToChat(client, "%s %t", DRTag, "you may not change team as death");
				return	Plugin_Handled;
			}
			
			if(StrEqual(command, "spectate", false))	{
				CPrintToChat(client, "%s %t", DRTag, "you may not change team as death");
				return	Plugin_Handled;
			}
		}
		case	TFTeam_Red:	{
			if(StrEqual(command, "jointeam", false) && StrEqual(arg1, "blue", false))	{
				CPrintToChat(client, "%s %t", DRTag, "you may not change team as red");
				return	Plugin_Handled;
			}
			
			if(StrEqual(command, "jointeam", false) && StrEqual(arg1, "auto", false))	{
				CPrintToChat(client, "%s %t", DRTag, "you may not change team as red");
				return	Plugin_Handled;
			}
		}

	}
	if(StrEqual(command, "jointeam", false) && StrEqual(arg1, "auto", false))	{
		CPrintToChat(client, "%s %t", DRTag, "you may not change autoassign team");
		return	Plugin_Handled;
	}
	return	Plugin_Continue;
}

int GetAlivePlayersCount(TFTeam team, int ignore)	{
	int count = 0, i;

	for(i = 1; i <= MaxClients; i++)	{
		if(IsValidClient(i) && IsPlayerAlive(i) && TF2_GetClientTeam(i) == team && i != ignore)
			count++;
	}

	return	count;
}

/* TF2_SwitchtoSlot()
 **
 ** Changes the client's slot to the desired one.
 ** -------------------------------------------------------------------------- */
stock void TF2_SwitchtoSlot(int client, int slot)	{
	if(slot >= 0 && slot <= 5 && IsValidClient(client) && IsPlayerAlive(client))	{
		char classname[64];
		int wep = GetPlayerWeaponSlot(client, slot);
		if(wep > MaxClients && IsValidEdict(wep) && GetEdictClassname(wep, classname, sizeof(classname)))	{
			FakeClientCommandEx(client, "use %s", classname);
			SetClientActiveWeapon(client, wep);
		}
	}
}

/* BalanceTeams()
 **
 ** Moves players to their int team in this round.
 ** -------------------------------------------------------------------------- */
stock void BalanceTeams()	{
	if(GetClientCount(true) > 1)	{
		int new_death = GetRandomValid();
		if(new_death == -1)	{
			CPrintToChatAll("%s %t", DRTag, "could not find valid death");
			return;
		}
		g_lastdeath = new_death;
		int i;
		for(i = 1; i < MaxClients; i++)	{
			if(!IsValidClient(i, _, true))
				continue;
			
			TFTeam team = TF2_GetClientTeam(i);
			if(team != TFTeam_Blue && team != TFTeam_Red)
				continue;

			if(i == new_death)	{
				if(team != TFTeam_Blue)
					ChangeAliveClientTeam(i, TFTeam_Blue);

				TFClassType class = TF2_GetPlayerClass(i);
				if(class == TFClass_Unknown)
					TF2_SetPlayerClass(i, TFClass_Scout, false, true);
			}
			else if(team != TFTeam_Red)
				ChangeAliveClientTeam(i, TFTeam_Red);
			
			CreateTimer(0.2, RespawnRebalanced, GetClientUserId(i));
		}
		if(!IsValidClient(new_death))	{
			CPrintToChatAll("%s %s", DRTag, "Death not ingame");
			return;
		}
		CPrintToChatAll("%s %t", DRTag, "client is the death", new_death);
		g_timesplayed_asdeath[g_lastdeath]++;

	}
	else	{
		CPrintToChatAll("%s %s", DRTag, "gamemode need players");
	}
}

/* GetRandomValid()
 **
 ** Gets a random player that didn't play as death recently.
 ** -------------------------------------------------------------------------- */
int GetRandomValid()	{
	int	possiblePlayers[MAXPLAYERS+1],
		possibleNumber = 0,
		min = GetMinTimesPlayed(false);
	for(int i = 1; i <= MaxClients; i++)	{
		if(!IsValidClient(i, _, true) || i == g_lastdeath)
			continue;
		
		TFTeam team = TF2_GetClientTeam(i);
		if(team != TFTeam_Blue && team != TFTeam_Red)
			continue;
		
		if(g_timesplayed_asdeath[i] != min)
			continue;
		
		if(g_dontBeDeath[i] == DBD_ON || g_dontBeDeath[i] == DBD_THISMAP)
			continue;

		possiblePlayers[possibleNumber] = i;
		possibleNumber++;
	}

	//If there are zero people available we ignore the preferences.
	if(possibleNumber == 0)	{
		min = GetMinTimesPlayed(true);
		for(int i = 1; i <= MaxClients; i++)	{
			if(!IsValidClient(i, _, true) || i == g_lastdeath)
				continue;
			
			TFTeam team = TF2_GetClientTeam(i);
			if(team != TFTeam_Blue && team != TFTeam_Red)
				continue;
			
			if(g_timesplayed_asdeath[i] != min)
				continue;
			
			possiblePlayers[possibleNumber] = i;
			possibleNumber++;
		}
		if(possibleNumber == 0)
			return -1;
	}

	return	possiblePlayers[GetRandomInt(0,possibleNumber-1)];
}

/* GetMinTimesPlayed()
 **
 ** Get the minimum "times played", if ignorePref is true, we ignore the don't be death preference
 ** -------------------------------------------------------------------------- */
stock int GetMinTimesPlayed(bool ignorePref)	{
	int min = -1;
	for(int i = 1; i <= MaxClients; i++)	{
		if(!IsValidClient(i, _, true) || g_timesplayed_asdeath[i] == -1)
			continue;
		
		if(i == g_lastdeath)
			continue;
		
		TFTeam team = TF2_GetClientTeam(i);
		if(team != TFTeam_Blue && team != TFTeam_Red)
			continue;
		
		if(!ignorePref)	{
			if(g_dontBeDeath[i] == DBD_ON || g_dontBeDeath[i] == DBD_THISMAP)
				continue;
		}
		
		if(min == -1)
			min = g_timesplayed_asdeath[i];
		else if(min > g_timesplayed_asdeath[i])
			min = g_timesplayed_asdeath[i];
	}
	return	min;

}

/* SetupCvars()
 **
 ** Modify several values of the CVars that the plugin needs to work properly.
 ** -------------------------------------------------------------------------- */
public void SetupCvars()	{
	dr_queue		.SetInt(0);
	dr_unbalance	.SetInt(0);
	dr_autobalance	.SetInt(0);
	dr_firstblood	.SetInt(0);
	dr_scrambleauto	.SetInt(0);
	dr_airdash		.SetInt(0);
	dr_push			.SetInt(0);
}

/* EmitRandomSound()
 **
 ** Emits a random sound from a trie, it will be emitted for everyone is a client isn't passed.
 ** -------------------------------------------------------------------------- */
void EmitRandomSound(StringMap sndTrie, int client = -1)	{
	int trieSize = sndTrie.Size;

	char key[4], sndFile[PLATFORM_MAX_PATH];
	IntToString(GetRandomInt(1, trieSize), key, sizeof(key));

	if(sndTrie.GetString(key, sndFile, sizeof(sndFile)))	{
		if(StrEqual(sndFile, ""))
			return;

		if(client != -1)	{
			if(client > 0 && client <= MaxClients && IsClientInGame(client) && !IsFakeClient(client))
				EmitSoundToClient(client, sndFile, _, _, SNDLEVEL_TRAIN);
			else
				return;
		}
		else
			EmitSoundToAll(sndFile, _, _, SNDLEVEL_TRAIN);
	}
}

int GetLastPlayer(TFTeam team, int ignore=-1)	{
	for(int i = 1; i <= MaxClients; i++)	{
		if(IsValidClient(i) && IsPlayerAlive(i) && TF2_GetClientTeam(i) == team && i != ignore)
			return i;
	}
	return	-1;
}

void ChangeAliveClientTeam(int client, TFTeam newTeam)	{
	if(TF2_GetClientTeam(client) != newTeam)	{
		SetClientLifestate(client, 2);
		TF2_ChangeClientTeam(client, newTeam);
		SetClientLifestate(client, 0);
		TF2_RespawnPlayer(client);
	}
}

/* RespawnRebalanced()
 **
 ** Timer used to spawn a client if he/she is in game and if it isn't alive.
 ** -------------------------------------------------------------------------- */
Action RespawnRebalanced(Handle timer, int data)	{
	int client = GetClientOfUserId(data);
	if(IsClientInGame(client))	{
		if(!IsPlayerAlive(client))
			TF2_RespawnPlayer(client);
	}
}

/**
 *	Returns if the client is valid.
 *
 *	@param client		Client index.
 *	@param checkalive	if true, alive players are invalid. Default off.
 *	@param checkbot		if true, bots are invalid. Default off.
 */
stock bool IsValidClient(int client, bool CheckAlive=false, bool CheckBot=false)	{
	if(!IsClientInGame(client))
		return	false;
	if(!IsClientConnected(client))
		return	false;
	if(client < 1 || client > MaxClients)
		return	false;
	if(CheckAlive)	{
		if(IsPlayerAlive(client))
			return	false;
	}
	if(CheckBot)	{
		if(IsFakeClient(client))
			return	false;
	}
	if(IsClientReplay(client))
		return	false;
	if(IsClientSourceTV(client))
		return	false;
	return	true;
}