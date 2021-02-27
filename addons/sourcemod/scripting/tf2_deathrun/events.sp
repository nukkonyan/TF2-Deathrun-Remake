void events()	{
	HookEvent("teamplay_round_start",		OnPrepartionStart);
	HookEvent("arena_round_start",			OnRoundStart);
	HookEvent("post_inventory_application",	OnPlayerInventory);
	HookEvent("player_spawn",				OnPlayerSpawn);
	HookEvent("player_death",				OnPlayerDeath,	EventHookMode_Pre);
}

/* OnPrepartionStart()
 **
 ** We setup the cvars again, balance the teams and we freeze the players.
 ** -------------------------------------------------------------------------- */
public Action OnPrepartionStart(Handle event, const char[] name, bool dontBroadcast)
{
	if(g_isDRmap)
	{
		g_onPreparation = true;

		//We force the cvars values needed every round (to override if any cvar was changed).
		SetupCvars();

		//We move the players to the corresponding team.
		BalanceTeams();

		//Players shouldn't move until the round starts
		for(int i = 1; i <= MaxClients; i++)
		if(IsClientInGame(i) && IsPlayerAlive(i))
		{
			SetEntityMoveType(i, MOVETYPE_NONE);
		}

		EmitRandomSound(g_SndRoundStart);
	}
}

/* OnRoundStart()
 **
 ** We unfreeze every player.
 ** -------------------------------------------------------------------------- */
public Action OnRoundStart(Handle event, const char[] name, bool dontBroadcast)	{
	if(g_isDRmap)	{
		for(int i = 1; i <= MaxClients; i++)
		if(IsClientInGame(i) && IsPlayerAlive(i))	{
			SetEntityMoveType(i, MOVETYPE_WALK);
			if((TF2_GetClientTeam(i) == TFTeam_Red && g_runner_outline == 0)||(TF2_GetClientTeam(i) == TFTeam_Blue && g_death_outline == 0))	{
				TF2_SetClientGlow(i, 1);
			}
		}
		g_onPreparation = false;
	}
}

/* TF2Items_OnGiveNamedItem_Post()
 **
 ** Here we check for the demoshield and the sapper.
 ** -------------------------------------------------------------------------- */
public int TF2Items_OnGiveNamedItem_Post(int client, char[] classname,int index,int level, int quality, int ent)
{
	if(g_isDRmap && g_MeleeOnly)
	{
		if(StrEqual(classname,"tf_weapon_builder", false) || StrEqual(classname,"tf_wearable_demoshield", false))
		{
			CreateTimer(0.1, Timer_RemoveWep, EntIndexToEntRef(ent));
		}
	}
}

/* Timer_RemoveWep()
 **
 ** We kill the demoshield/sapper
 ** -------------------------------------------------------------------------- */
public Action Timer_RemoveWep(Handle timer, int ref)
{
	int ent = EntRefToEntIndex(ref);
	if( IsValidEntity(ent) && ent > MaxClients)
	{
		AcceptEntityInput(ent, "Kill");
	}
}

/* OnPlayerInventory()
 **
 ** Here we strip players weapons (if we have to).
 ** Also we give special melee weapons (again, if we have to).
 ** -------------------------------------------------------------------------- */
Action OnPlayerInventory(Event event, const char[] name, bool dontBroadcast)	{
	if(g_isDRmap)	{
		if(g_MeleeOnly)	{
			int client = GetClientOfUserId(event.GetInt("userid"));

			TF2_RemoveWeaponSlot(client, TFWeaponSlot_Primary);
			TF2_RemoveWeaponSlot(client, TFWeaponSlot_Secondary);
			TF2_RemoveWeaponSlot(client, TFWeaponSlot_Grenade);
			TF2_RemoveWeaponSlot(client, TFWeaponSlot_Building);
			TF2_RemoveWeaponSlot(client, TFWeaponSlot_PDA);

			if(g_MeleeRestricted)	{
				bool replacewep = false;
				switch(g_RestrictAll)	{
					case	true:	replacewep=true;
					case	false:	{
						int wepEnt		= GetPlayerWeaponSlot(client, TFWeaponSlot_Melee),
							wepIndex	= GetWeaponDefinitionIndex(wepEnt),
							rwSize		= g_RestrictedWeps.Size;
						char key[4], auxIndex;
						for(int i = 1; i <= rwSize; i++)
						{
							IntToString(i, key, sizeof(key));
							if(g_RestrictedWeps.GetValue(key, auxIndex))	{
								if(wepIndex == auxIndex)
									replacewep=true;
							}
						}
	
					}
				}
				if(replacewep)	{
					TF2_RemoveWeaponSlot(client, TFWeaponSlot_Melee);
					int weaponToUse = -1;
					if(g_UseAllClass)	{
						int acwSize = g_AllClassWeps.Size, rndNum;
						if(g_UseDefault)
							rndNum = GetRandomInt(1, acwSize+1);
						else
							rndNum = GetRandomInt(1, acwSize);

						if(rndNum <= acwSize)	{
							char key[4];
							IntToString(rndNum,key, sizeof(key));
							g_AllClassWeps.GetValue(key, weaponToUse);
						}

					}
					Handle hItem = TF2Items_CreateItem(FORCE_GENERATION | OVERRIDE_CLASSNAME | OVERRIDE_ITEM_DEF | OVERRIDE_ITEM_LEVEL | OVERRIDE_ITEM_QUALITY | OVERRIDE_ATTRIBUTES);

					//Here we give a melee to every class
					switch(TF2_GetPlayerClass(client))	{
						case	TFClass_Scout:	{
							TF2Items_SetClassname(hItem, "tf_weapon_bat");
							if(weaponToUse == -1)
								weaponToUse = 190;
							
							TF2Items_SetItemIndex(hItem, weaponToUse);
						}
						case	TFClass_Sniper:	{
							TF2Items_SetClassname(hItem, "tf_weapon_club");
							if(weaponToUse == -1)
								weaponToUse = 193;
							
							TF2Items_SetItemIndex(hItem, weaponToUse);
						}
						case	TFClass_Soldier:	{
							TF2Items_SetClassname(hItem, "tf_weapon_shovel");
							if(weaponToUse == -1)
								weaponToUse = 196;
							
							TF2Items_SetItemIndex(hItem, weaponToUse);
						}
						case	TFClass_DemoMan:	{
							TF2Items_SetClassname(hItem, "tf_weapon_bottle");
							if(weaponToUse == -1)
								weaponToUse = 191;
							
							TF2Items_SetItemIndex(hItem, weaponToUse);
						}
						case	TFClass_Medic:	{
							TF2Items_SetClassname(hItem, "tf_weapon_bonesaw");
							if(weaponToUse == -1)
								weaponToUse = 198;
							
							TF2Items_SetItemIndex(hItem, weaponToUse);
						}
						case	TFClass_Heavy:	{
							TF2Items_SetClassname(hItem, "tf_weapon_fists");
							if(weaponToUse == -1)
								weaponToUse = 195;
							
							TF2Items_SetItemIndex(hItem, weaponToUse);
						}
						case	TFClass_Pyro:	{
							TF2Items_SetClassname(hItem, "tf_weapon_fireaxe");
							if(!IsValidEdict(weaponToUse))
								weaponToUse = 192;
							
							TF2Items_SetItemIndex(hItem, weaponToUse);
						}
						case	TFClass_Spy:	{
							TF2Items_SetClassname(hItem, "tf_weapon_knife");
							if(weaponToUse == -1)
								weaponToUse = 194;
							
							TF2Items_SetItemIndex(hItem, weaponToUse);
						}
						case	TFClass_Engineer:	{
							TF2Items_SetClassname(hItem, "tf_weapon_wrench");
							if(weaponToUse == -1)
								weaponToUse = 197;
							
							TF2Items_SetItemIndex(hItem, weaponToUse);
						}
					}

					TF2Items_SetLevel(hItem, 69);
					TF2Items_SetQuality(hItem, 6);
					TF2Items_SetAttribute(hItem, 0, 150, 1.0); //Turn to gold on kill
					TF2Items_SetNumAttributes(hItem, 1);
					int weapon = TF2Items_GiveNamedItem(client, hItem);
					delete hItem;

					EquipPlayerWeapon(client, weapon);
				}
			}
			TF2_SwitchtoSlot(client, TFWeaponSlot_Melee);
		}
	}
}

/* OnPlayerSpawn()
 **
 ** Here we enable the glow (if we need to), we set the spy cloak and we move the death player.
 ** -------------------------------------------------------------------------- */
Action OnPlayerSpawn(Event event, const char[] name, bool dontBroadcast)	{
	if(g_isDRmap)	{
		int client = GetClientOfUserId(event.GetInt("userid"));
		if(g_diablefalldamage)
			TF2Attrib_SetByName(client, "cancel falling damage", 1.0);
		
		if(g_MeleeOnly)	{
			int cond = GetEntProp(client, Prop_Send, "m_nPlayerCond");

			if(cond & PLAYERCOND_SPYCLOAK)
				SetEntProp(client, Prop_Send, "m_nPlayerCond", cond | ~PLAYERCOND_SPYCLOAK);
		}

		if(TF2_GetClientTeam(client) == TFTeam_Blue && client != g_lastdeath)	{
			ChangeAliveClientTeam(client, TFTeam_Red);
			CreateTimer(0.2, RespawnRebalanced, GetClientUserId(client));
		}

		if(g_onPreparation)
			SetEntityMoveType(client, MOVETYPE_NONE);
	}
}

/* OnPlayerDeath()
 **
 ** Here we reproduce sounds if needed and activate the glow effect if needed
 ** -------------------------------------------------------------------------- */
Action OnPlayerDeath(Event event, const char[] name, bool dontBroadcast)	{
	if(g_isDRmap)	{
		if(!g_onPreparation)	{
			int client = GetClientOfUserId(event.GetInt("userid")),
				aliveRunners = GetAlivePlayersCount(TFTeam_Red, client);

			if(TF2_GetClientTeam(client) == TFTeam_Red && aliveRunners > 0)
				EmitRandomSound(g_SndOnDeath,client);
			

			if(aliveRunners == 1)
				EmitRandomSound(g_SndLastAlive,GetLastPlayer(TFTeam_Red, client));
			

			int currentDeath = GetLastPlayer(TFTeam_Blue);
			if(currentDeath > 0 && currentDeath <= MaxClients && IsValidClient(currentDeath) && g_finishoffrunners)
				event.SetInt("attacker", GetClientUserId(currentDeath));
			
			if(g_canEmitSoundToDeath)	{
				if(currentDeath > 0 && currentDeath <= MaxClients)
				EmitRandomSound(g_SndOnKill,currentDeath);
				g_canEmitSoundToDeath = false;
				CreateTimer(g_OnKillDelay, ReenableDeathSound);
			}

			if(aliveRunners == g_runner_outline)	{
				for(int i=1; i<=MaxClients; i++)	{
					if(IsValidClient(i) && IsPlayerAlive(i) && TF2_GetClientTeam(client) == TFTeam_Red)
						TF2_SetClientGlow(i, 1);
				}
			}

			if(aliveRunners == g_death_outline)	{
				for(int i=1; i<=MaxClients; i++)	{
					if(IsValidClient(i) && IsPlayerAlive(i) && TF2_GetClientTeam(client) == TFTeam_Blue)
						TF2_SetClientGlow(i, 1);
				}
			}
		}

	}
	return Plugin_Continue;
}

Action ReenableDeathSound(Handle timer, int data)	{
	g_canEmitSoundToDeath = true;
}