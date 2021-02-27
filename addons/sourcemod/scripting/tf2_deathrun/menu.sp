void menucmd()	{
	RegConsoleCmd("drtoggle", BeDeathMenu);
}

Action BeDeathMenu(int client, int args)	{
	if(IsClientConsole(client) || !IsClientInGame(client))
		return	Plugin_Handled;
	
	if(DEBUG)
		PrintToServer("[TF2] Deathrun Remake Debug : Client %N opened DR Menu");
	
	Menu menu = new Menu(BeDeathMenuHandler);
	menu.SetTitle("Be the Death toggle");
	menu.AddItem("0", "Select me as Death");
	menu.AddItem("1", "Don't select me as Death");
	menu.AddItem("2", "Don't be Death in this map");
	//menu.ExitButton = true; Not needed, this is already on by default.
	menu.Display(client, 30);

	return	Plugin_Handled;
}

int BeDeathMenuHandler(Menu menu, MenuAction action, int client, int selection)	{
	switch(action)	{
		case	MenuAction_Select:	{
			switch(selection)	{
				case	0:	{
					g_dontBeDeath[client] = DBD_OFF;
					char sPref[2];
					IntToString(DBD_OFF, sPref, sizeof(sPref));
					g_DRCookie.Set(client, sPref);
					CPrintToChat(client, "%s %t", DRTag, "you selected to be chosen as death");
				}
				case	1:	{
					g_dontBeDeath[client] = DBD_ON;
					char sPref[2];
					IntToString(DBD_ON, sPref, sizeof(sPref));
					g_DRCookie.Set(client, sPref);
					CPrintToChat(client, "%s %t", DRTag, "you selected to no longer be chosen as death");
				}
				case	2:	{
					g_dontBeDeath[client] = DBD_THISMAP;
					CPrintToChat(client, "%s %t", DRTag, "you cannot be chosen as death on this map");
				}
			}
		}
		case	MenuAction_End:	delete menu;
	}
}