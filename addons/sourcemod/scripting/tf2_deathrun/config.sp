/**
 *	Load the required stuff to make the plugin work properly. (Duh)
 */
void LoadDRConfig()	{
	//--DEFAULT VALUES--
	//GenerealConfig
	g_diablefalldamage	= false;
	g_finishoffrunners	= true;
	g_runner_speed		= 300.0;
	g_death_speed		= 400.0;
	g_runner_outline	= 0;
	g_death_outline		= -1;

	//Weapon-config
	g_MeleeOnly			= true;
	g_MeleeRestricted	= true;
	g_RestrictAll		= true;
	g_UseDefault		= true;
	g_UseAllClass		= false;
	g_RestrictedWeps	.Clear();
	g_AllClassWeps		.Clear();

	//Command-config
	g_CmdList			.Clear();
	g_CmdTeamToBlock	.Clear();
	g_CmdBlockOnlyOnPrep.Clear();

	//Sound-config
	g_OnKillDelay	= 5.0;
	g_SndRoundStart	.Clear();
	g_SndOnDeath	.Clear();
	g_SndOnKill		.Clear();
	g_SndLastAlive	.Clear();

	char filepath[64];
	BuildPath(Path_SM, filepath, sizeof(filepath), "data/tf2_deathrun/tf2_deathrun.cfg");
	if(!FileExists(filepath))	{
		PrintToServer("[TF2] Deathrun Remake: An error has occured. (Did you install the config correctly?)");
		SetFailState("[TF2] Deathrun Remake Error 404: CONFIG_NOT_FOUND");
	}
	
	KeyValues kv = new KeyValues("deathrun");
	
	if(!kv.ImportFromFile(filepath))	{
		delete kv;
		SetFailState("[TF2] Deathrun Remake: Unable to load config file. (Is the config file configured correctly?)");
	}
	
	if(!kv.JumpToKey("default"))	{
		g_diablefalldamage = !!kv.GetNum("DisableFallDamage", g_diablefalldamage);
		g_finishoffrunners = !!kv.GetNum("FinishOffRunners", g_finishoffrunners);
		if(kv.JumpToKey("speed"))	{
			g_runner_speed = kv.GetFloat("runners", g_runner_speed);
			g_death_speed = kv.GetFloat("death", g_death_speed);
			kv.GoBack();
		}

		if(kv.JumpToKey("outline"))	{
			g_runner_outline = kv.GetNum("runners", g_runner_outline);
			g_death_outline = kv.GetNum("death", g_death_outline);
			kv.GoBack();
		}
		kv.GoBack();
	}

	kv.Rewind();
	if(kv.JumpToKey("weapons"))	{
		g_MeleeOnly = !!kv.GetNum("MeleeOnly", g_MeleeOnly);
		if(g_MeleeOnly)	{
			g_MeleeRestricted = !!kv.GetNum("RestrictedMelee", g_MeleeRestricted);
			if(g_MeleeRestricted)	{
				kv.JumpToKey("MeleeRestriction");
				g_RestrictAll = !!kv.GetNum("RestrictAll", g_RestrictAll);
				if(!g_RestrictAll)	{
					kv.JumpToKey("RestrictedWeapons");
					char key[4], auxInt;
					for(int i = 1; i < MAXGENERIC; i++)	{
						IntToString(i, key, sizeof(key));
						auxInt = kv.GetNum(key, -1);
						if(auxInt == -1)
							break;
						
						g_RestrictedWeps.SetValue(key, auxInt);
					}
					kv.GoBack();
				}
				g_UseDefault = !!kv.GetNum("UseDefault", g_UseDefault);
				g_UseAllClass = !!kv.GetNum("UseAllClass", g_UseAllClass);
				if(g_UseAllClass)	{
					kv.JumpToKey("AllClassWeapons");
					char key[4], auxInt;
					for(int i = 1; i < MAXGENERIC; i++)	{
						IntToString(i, key, sizeof(key));
						auxInt = kv.GetNum(key, -1);
						if(auxInt == -1)
							break;
						
						g_AllClassWeps.SetValue(key, auxInt);
					}
					kv.GoBack();
				}
				kv.GoBack();
			}
		}
	}

	kv.Rewind();
	kv.JumpToKey("blockcommands");
	do	{
		char	SectionName[128], CommandName[128];
		int		onprep;
		bool	onrunners, ondeath;

		kv.GotoFirstSubKey();
		kv.GetSectionName(SectionName, sizeof(SectionName));

		kv.GetString("command", CommandName, sizeof(CommandName));
		onprep = kv.GetNum("OnlyOnPreparation", 0);
		onrunners = !!kv.GetNum("runners", 1);
		ondeath = !!kv.GetNum("death", 1);

		TFTeam teamToBlock = TFTeam_Unassigned;
		if(onrunners && ondeath)
			teamToBlock = TFTeam_Spectator;
		else if(onrunners && !ondeath)
			teamToBlock = TFTeam_Red;
		else if(!onrunners && ondeath)
			teamToBlock = TFTeam_Blue;

		if(!StrEqual(CommandName, "") || teamToBlock == TFTeam_Unassigned)	{
			g_CmdList				.SetString(SectionName, CommandName);
			g_CmdBlockOnlyOnPrep	.SetValue(CommandName, onprep);
			g_CmdTeamToBlock		.SetValue(CommandName, teamToBlock);
		}
	}
	while(kv.GotoNextKey());

	kv.Rewind();
	if(kv.JumpToKey("sounds"))	{
		char key[4], sndFile[PLATFORM_MAX_PATH];
		if(kv.JumpToKey("RoundStart"))	{
			for(int i = 1; i < MAXGENERIC; i++)	{
				IntToString(i, key, sizeof(key));
				kv.GetString(key, sndFile, sizeof(sndFile), "");
				if(StrEqual(sndFile, ""))
					break;
				
				g_SndRoundStart.SetString(key, sndFile);
			}
			kv.GoBack();
		}

		if(kv.JumpToKey("OnDeath"))	{
			for(int i = 1; i < MAXGENERIC; i++)	{
				IntToString(i, key, sizeof(key));
				kv.GetString(key, sndFile, sizeof(sndFile), "");
				if(StrEqual(sndFile, ""))
					break;
				
				g_SndOnDeath.SetString(key, sndFile);
			}
			kv.GoBack();
		}

		if(kv.JumpToKey("OnKill"))	{
			g_OnKillDelay = kv.GetFloat("delay", g_OnKillDelay);
			for(int i = 1; i < MAXGENERIC; i++)	{
				IntToString(i, key, sizeof(key));
				kv.GetString(key, sndFile, sizeof(sndFile), "");
				if(StrEqual(sndFile, ""))
					break;
				
				g_SndOnKill.SetString(key, sndFile);
			}
			kv.GoBack();
		}

		if(kv.JumpToKey("LastAlive"))	{
			for(int i = 1; i < MAXGENERIC; i++)	{
				IntToString(i, key, sizeof(key));
				kv.GetString(key, sndFile, sizeof(sndFile), "");
				if(StrEqual(sndFile, ""))
					break;
				
				g_SndLastAlive.SetString(key, sndFile);
			}
			kv.GoBack();
		}
		kv.GoBack();
	}

	kv.Rewind();
	delete kv;

	char mapfile[PLATFORM_MAX_PATH], mapname[128];
	GetCurrentMap(mapname, sizeof(mapname));
	BuildPath(Path_SM, mapfile, sizeof(mapfile), "data/tf2_deathrun/maps/%s.cfg", mapname);
	if(FileExists(mapfile))	{
		kv = new KeyValues("drmap");
		if(!kv.ImportFromFile(mapfile))	{
			SetFailState("Improper structure for configuration file %s!", mapfile);
			return;
		}

		g_diablefalldamage = !!kv.GetNum("DisableFallDamage", g_diablefalldamage);
		g_finishoffrunners = !!kv.GetNum("FinishOffRunners", g_finishoffrunners);

		if(kv.JumpToKey("speed"))	{
			g_runner_speed = kv.GetFloat("runners", g_runner_speed);
			g_death_speed = kv.GetFloat("death", g_death_speed);
			kv.GoBack();
		}
		if(kv.JumpToKey("outline"))	{
			g_runner_outline = kv.GetNum("runners", g_runner_outline);
			g_death_outline = kv.GetNum("death", g_death_outline);
		}
		kv.Rewind();
		delete kv;
	}
}