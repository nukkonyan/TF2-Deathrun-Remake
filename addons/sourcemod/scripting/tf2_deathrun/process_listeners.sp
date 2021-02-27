/* ProcessListeners()
 **
 ** Here we add the listeners to block the commands defined on the config file.
 ** -------------------------------------------------------------------------- */
void ProcessListeners(bool removeListerners=false)	{
	int trieSize = g_CmdList.Size;
	char command[PLATFORM_MAX_PATH], key[4];
	for(int i = 1; i <= trieSize; i++)	{
		IntToString(i, key, sizeof(key));
		if(g_CmdList.GetString(key, command, sizeof(command)))	{
			if(StrEqual(command, ""))
				break;

			if(removeListerners)
				RemoveCommandListener(Command_Block, command);
			else
				AddCommandListener(Command_Block, command);
		}
	}
}

/* Command_Block()
 **
 ** Blocks a command, check teams and if it's on preparation.
 ** -------------------------------------------------------------------------- */
Action Command_Block(int client, char[] command, int args)	{
	if(g_isDRmap)	{
		int PreparationOnly, blockteam;
		g_CmdBlockOnlyOnPrep.GetValue(command, PreparationOnly);
		//If the command must be blocked only on preparation
		//and we aren't on preparation time, we let the client run the command.
		if(!g_onPreparation && PreparationOnly == 0)
			return	Plugin_Continue;

		g_CmdTeamToBlock.GetValue(command, blockteam);
		//If the client has the same team as "g_CmdTeamToBlock"
		//or it's for both teams, we block the command.
		if(GetClientTeam(client) == blockteam || blockteam == 1)
			return	Plugin_Stop;

	}
	return	Plugin_Continue;
}