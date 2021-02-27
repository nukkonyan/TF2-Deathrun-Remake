void cookies()	{
	g_DRCookie = new Cookie("DR_dontBeDeath", "Does the client want to be the Death?", CookieAccess_Private);
	for (int i = 1; i <= MaxClients; i++)
	{	
		if (!AreClientCookiesCached(i))
		{	
			continue;
		}
		OnClientCookiesCached(i);
	}
}