/**
 *	Include files. (.inc). can also include sourcepawn files (.sp) via "example/example.sp"
 *	Load include files, usually adds functionality to the plugin.
 */
#include	<tk>
#include	<multicolors>
#include	<clientprefs>
#include	<tf2items>
#include	<tf2attributes>
//#include	"tf2_deathrun/tf2_deathrun"	//Natives coming soon.

#define		AUTOLOAD_EXTENSIONS
#define		REQUIRE_EXTENSIONS
#include	<steamworks>

//Plugin tag string is stored here
char	DRTag[256];

/**
 *	Including the required include files.
 */
#include	"tf2_deathrun/main.sp"				//Load the functions requried for stuff to work.
#include	"tf2_deathrun/events.sp"			//Hook events
#include	"tf2_deathrun/filter_targets.sp"	//Filter targets.
#include	"tf2_deathrun/config.sp"			//Load the configs, for things to start working.
#include	"tf2_deathrun/process_listeners.sp"	//Process listeners
#include	"tf2_deathrun/cookies.sp"			//Cookie stuff

/**
	This is a plugin made from scratch ground up. Including code from the deathrun redux.
	With added descriptions on what certain things do. (For educating newbies looking into the code)
	
	Credits:
	
	Teamkiller324
	+ Making the remake.
	
	ClassicGuzzi
	+ Making the redux.
	+ Using code from his redux.
**/

#pragma		semicolon	1
#pragma		newdecls	required

#define		PLUGIN_VERSION	"1.0.0"

//Here you can select if you wanna see debug messages for testing purposes. <:
bool	DEBUG=false;

/**
 *	Plugin information.
 *
 *	@param name			Plugin name.
 *	@param author		Who made the plugin?.
 *	@param description	Describe the plugins functions.
 *	@param version		Plugin version.
 *	@param url			Optional url to the author or project.
 */
public	Plugin	myinfo	=	{
	name		=	"[TF2] Deathrun Remake",
	author		=	"Tk /id/Teamkiller324",
	description	=	"Deathrun remake",
	version		=	PLUGIN_VERSION,
	url			=	"https://steamcommunity.com/id/Teamkiller324"
}

/**
 *	Fired once the plugin is initialized.
 */
public void OnPluginStart()	{	
	/**
	 *	Switch.
	 *
	 *	an if-checker, basically checks if the correct game is loaded or not, depending your configuration.
	 */
	switch(GetEngineVersion())	{
		case	Engine_TF2:	PrintToServer("[TF2] Deathrun Remake Version %s has been loaded", PLUGIN_VERSION);
		default:	SetFailState("[TF2] Deathrun Remake may only be running on Team Fortress 2");
	}
	
	/**
	 *	Translations.
	 *
	 *	Adds a functionality, depending on the clients game language/country they come from,
	 *	you can translate a string of words if they maybe don't understand for example english.
	 */
	LoadTranslations("tf2_deathrun.phrases");
	
	/**
	 *	Format.
	 *
	 *	You can store a string and aswell merge strings into one string with Format or FormatEx.
	 *	FormatEx takes less memory than Format.
	 *	We put %t for translation and {default} afterwards to default the color. So it doesn't end weird.
	 */
	FormatEx(DRTag, sizeof(DRTag), "%t{default}", "deathrun tag");
	
	/**
	 *	Load Functions.
	 */
	 
	//Cvar
	CreateConVar("tf_dr_remake_version", PLUGIN_VERSION, "TF2 Deathrun Remake Version.", FCVAR_REPLICATED|FCVAR_SPONLY|FCVAR_DONTRECORD|FCVAR_NOTIFY);
	
	//Plugin Advert
	dr_plugin_advert	= CreateConVar("tf_dr_remake_advert",		"1",	"Determine if an advert should play. \n0 = Disabled. \n1 = Enabled.", _, true, 0.0, true, 1.0);
	dr_plugin_timer		= CreateConVar("tf_dr_remake_advert_timer",	"180",	"Timer interval for the advert to play.", _, true, 60.0);
	
	events();			//Hooks
	stringmaps();		//Creation of StringMaps
	convars();			//Server ConVars
	filter_targets();	//Targets
	cookies();			//Preferences
	menucmd();			//Registers menu command
	
	AutoExecConfig(true, "tf2_deathrun");
}

#include	"tf2_deathrun/functions.sp"	//Load the functions

#include	"tf2_deathrun/menu.sp"	//Load the menu