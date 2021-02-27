/* OnPluginEnd()
 **
 ** When the plugin is unloaded. Here we reset all the cvars to their normal value.
 ** -------------------------------------------------------------------------- */

/**
 *	Fired just before the plugin actually is ended/disabled.
 */
public void OnPluginEnd()	{
	//Targets
	RemoveMultiTargetFilter("@runner",			FilterTarget);
	RemoveMultiTargetFilter("@runners",			FilterTarget);
	RemoveMultiTargetFilter("@aliverunners",	FilterTarget);
	RemoveMultiTargetFilter("@death",			FilterTarget);
	ResetCvars();
}

/* OnClientCookiesCached()
 **
 ** We look if the client have a saved value
 ** -------------------------------------------------------------------------- */
 
/**
 *	Loaded when the clients preference settings are loaded & cached from the database.
 */
public void OnClientCookiesCached(int client)	{
	char sValue[8];
	g_DRCookie.Get(client, sValue, sizeof(sValue));
	int nValue = StringToInt(sValue);

	if(nValue != DBD_OFF && nValue != DBD_ON)	//If cookie is not valid we ask for a preference.
		CreateTimer(TIME_TO_ASK, AskMenuTimer, client);
	else //client has a valid cookie
		g_dontBeDeath[client] = nValue;
}

Action AskMenuTimer(Handle timer, int client)	{
	BeDeathMenu(client, 0);
}

/* OnGameFrame()
 **
 ** We set the player max speed on every frame, and also we set the spy's cloak on empty.
 ** -------------------------------------------------------------------------- */
 
/**
 *	Fired before every server frames.
 */
public void OnGameFrame()	{
	if(g_isDRmap)	{
		for(int i = 1; i <= MaxClients; i++)	{
			if(IsValidClient(i) && IsPlayerAlive(i))	{
				if(TF2_GetClientTeam(i) == TFTeam_Red)
					SetClientMaxSpeed(i, g_runner_speed);
				else if(TF2_GetClientTeam(i) == TFTeam_Blue)
					SetClientMaxSpeed(i, g_death_speed);

				if(g_MeleeOnly)	{
					if(TF2_GetPlayerClass(i) == TFClass_Spy)
						TF2_SetClientCloakMeter(i, 1.0);
				}
			}
		}
	}
}

/* OnConfigsExecuted()
 **
 ** Here we get the default values of the CVars that the plugin is going to modify.
 ** -------------------------------------------------------------------------- */
 
/**
 *	Fired when all configs has been loaded.
 */
public void OnConfigsExecuted()	{
	dr_queue_def		= dr_queue.IntValue;
	dr_unbalance_def	= dr_unbalance.IntValue;
	dr_autobalance_def	= dr_autobalance.IntValue;
	dr_firstblood_def	= dr_firstblood.IntValue;
	dr_scrambleauto_def	= dr_scrambleauto.IntValue;
	dr_airdash_def		= dr_airdash.IntValue;
	dr_push_def			= dr_push.IntValue;
}

/**
 *	Fired once the map round begins.
 */
public void OnMapStart()	{
	g_lastdeath = -1;
	for(int i = 1; i <= MaxClients; i++)
	g_timesplayed_asdeath[i]=-1;

	char mapname[128];
	GetCurrentMap(mapname, sizeof(mapname));
	if(strncmp(mapname, "dr_", 3, false) == 0 || strncmp(mapname, "deathrun_", 9, false) == 0 || strncmp(mapname, "vsh_dr_", 6, false) == 0 || strncmp(mapname, "vsh_deathrun_", 6, false) == 0)	{	
		LogMessage("Deathrun map detected. Enabling Deathrun Gamemode.");
		g_isDRmap = true;
		char GameDescription[128];
		FormatEx(GameDescription, sizeof(GameDescription), "Deathrun Remake Version %s", PLUGIN_VERSION);
		SteamWorks_SetGameDescription(GameDescription);
		AddServerTag("deathrun");
		for (int i = 1; i <= MaxClients; i++)	{	
			if (!AreClientCookiesCached(i))
				continue;
			
			OnClientCookiesCached(i);
		}
		LoadDRConfig();
		PrecacheFiles();
		ProcessListeners();
	}
	else
	{	
		LogMessage("Current map is not a deathrun map. Disabling Deathrun Gamemode.");
		g_isDRmap = false;
		SteamWorks_SetGameDescription("Team Fortress");
		RemoveServerTag("deathrun");
	}
	
	AddCommandListener(Callback_PreventTeamChange, "jointeam");
	AddCommandListener(Callback_PreventTeamChange, "spectate");
	
	if(dr_plugin_advert.BoolValue)
		CreateTimer(dr_plugin_timer.FloatValue, DR_AdvertTimer);
}

/* PrecacheFiles()
 **
 ** We precache and add to the download table, reading every value of a Trie.
 ** -------------------------------------------------------------------------- */
void PrecacheSoundFromStringMap(StringMap sndTrie)	{
	int trieSize = sndTrie.Size;
	char soundString[PLATFORM_MAX_PATH], downloadString[PLATFORM_MAX_PATH], key[4];
	for(int i = 1; i <= trieSize; i++)	{
		IntToString(i, key, sizeof(key));
		if(sndTrie.GetString(key, soundString, sizeof(soundString)))	{
			if(PrecacheSound(soundString))	{
				Format(downloadString, sizeof(downloadString), "sound/%s", soundString);
				AddFileToDownloadsTable(downloadString);
			}
		}
	}
}

/* PrecacheFiles()
 **
 ** We precache and add to the download table every sound file found on the config file.
 ** -------------------------------------------------------------------------- */
void PrecacheFiles()	{
	PrecacheSoundFromStringMap(g_SndRoundStart);
	PrecacheSoundFromStringMap(g_SndOnDeath);
	PrecacheSoundFromStringMap(g_SndOnKill);
	PrecacheSoundFromStringMap(g_SndLastAlive);
}

/**
 *	Fired just before the round ends.
 */
public void OnMapEnd()	{
	ResetCvars();
	for(int i = 1; i <= MaxClients; i++)	{	
		g_dontBeDeath[i] = DBD_UNDEF;
	}
	
	RemoveCommandListener(Callback_PreventTeamChange, "jointeam");
	RemoveCommandListener(Callback_PreventTeamChange, "spectate");
}

/**
 *	Plugin Advertisement Timer.
 */
Action DR_AdvertTimer(Handle timer)	{
	if(dr_plugin_advert.BoolValue)
		CPrintToChatAll("{olive}This server is using TF2 Deathrun Remake Version %s made by /id/Teamkiller324", PLUGIN_VERSION);
}