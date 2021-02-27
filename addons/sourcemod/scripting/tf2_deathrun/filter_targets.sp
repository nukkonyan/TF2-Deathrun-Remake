void filter_targets()	{
	AddMultiTargetFilter("@runner",			FilterTarget, "runners", false);
	AddMultiTargetFilter("@runners",		FilterTarget, "runners", false);
	AddMultiTargetFilter("@aliverunners",	FilterTarget, "alive runners", false);
	AddMultiTargetFilter("@death",			FilterTarget, "death", false);
}

/* FilterTarget()
 **
 ** Filters the clients if they are runners, aliverunners or the death.
 ** -------------------------------------------------------------------------- */
bool FilterTarget(const char[] pattern, ArrayList clients)	{
	TFTeam		team = TFTeam_Red;
	bool	aliveOnly = false;
	if(StrContains(pattern, "death", false) != -1)
		team = TFTeam_Blue;
	if(StrContains(pattern, "alive", false) != -1)
		aliveOnly = true;

	for(int i = 1; i <= MaxClients; i ++)	{
		if(!IsValidClient(i))
			continue;

		if(aliveOnly && !IsValidClient(i, true))
			continue;

		if(TF2_GetClientTeam(i) != team)
			continue;

		clients.Push(i);
	}

	return	true;
}