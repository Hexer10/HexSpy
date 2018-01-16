#include <sourcemod>
#include <sdktools>
#include <clientprefs>
#include <colorvariables>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_NAME           "HexSpy"
#define PLUGIN_VERSION        "1.0"

#define sPrefix  "{bluegrey}[Hex SPY]{default}"


Handle hSpyCookie;
 
ConVar cv_bImmunity;

bool bSpy[MAXPLAYERS+1];
bool bLate;

File CfgFile;

public Plugin myinfo =
{
	name = PLUGIN_NAME,
	author = "Hexah",
	description = "See other player commands!",
	version = PLUGIN_VERSION,
	url = "csitajb.it"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	bLate = late;
}


public void OnPluginStart()
{
	RegAdminCmd("sm_hexspy", Cmd_Spy, ADMFLAG_GENERIC);
	
	CreateConVar("sm_hexspy_version", PLUGIN_VERSION, "HexSpy plugin version", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	cv_bImmunity = CreateConVar("sm_hexspy_immunity", "1", "If true(1) who has an immunity lower can't see the cmd of one that has it higher", _, true, 0.0, true, 0.0);
	
	hSpyCookie = RegClientCookie("sm_hexspy_enabled", "If true client has enabled the hexspy", CookieAccess_Private); //Reg cookie
	
	if (bLate) for(int i = 1; i <= MaxClients; i++)if (IsClientInGame(i)) OnClientCookiesCached(i); //Late load, clientprefs

}

public void OnClientCookiesCached(int client)
{
	char sValue[4];
	GetClientCookie(client, hSpyCookie, sValue, sizeof(sValue));
	bSpy[client] = view_as<bool>(StringToInt(sValue));
}

public Action Cmd_Spy(int client, int args)
{
	if (!AreClientCookiesCached(client))
	{
		CReplyToCommand(client, "%s Your data hasn't been fetched yet", sPrefix);
		return Plugin_Handled;
	}
	
	bSpy[client] = !bSpy[client];
	
	char sValue[4];
	IntToString(bSpy[client], sValue, sizeof(sValue));
	SetClientCookie(client, hSpyCookie, sValue);
	
	CReplyToCommand(client, "%s You have %s the command spy!", sPrefix, bSpy[client]? "enabled" : "disabled");
	return Plugin_Handled;
}

void GetFile()
{
	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), "configs/hexspy.ini");
	
	//Maybe we can skip this using "a+" mode?
	if (!FileExists(sPath))
	{
		File file = OpenFile(sPath, "w");
		file.Close();
	}
	
	CfgFile = OpenFile(sPath, "r");
	
	if (CfgFile == null)
		SetFailState("Config file: %s couldn't be neither found or created", sPath);
}

public Action OnClientCommand(int client, int args)
{
	if (!IsClientInGame(client))
		return Plugin_Continue;
		
	char sCommand[64];
	char sArgs[128];
	GetCmdArg(0, sCommand, sizeof(sCommand));
	GetCmdArgString(sArgs, sizeof(sArgs));
	
	bool bAllow;
	
	if ((StrContains(sCommand, "sm_") == 0) && (GetCommandFlags(sCommand) != INVALID_FCVAR_FLAGS)) //Check if the command actually exixsts
		bAllow = true;

	GetFile();

	char sLine[64];
	while (CfgFile.ReadLine(sLine, sizeof(sLine))) //Parse the cfg file
	{
		TrimString(sLine);
		if (ReplaceStringEx(sLine, sizeof(sLine), "!", "") == 0)
		{
			if (StrEqual(sLine, sCommand))
			{
				bAllow = false;
				break;
			}
		}
		else
		{
			if (StrEqual(sLine, sCommand))
			{
				bAllow = true;
				break;
			}
		}
	}
	
	if (!bAllow)
		return Plugin_Continue;
		
	if (StrContains(sCommand, "sm_") == 0) 
		ReplaceStringEx(sCommand, sizeof(sCommand), "sm_", "/"); //This need to be done as last

	if (!bAllow)
		return Plugin_Continue;
	
	for (int i = 1; i <= MaxClients; i++)if (IsClientInGame(i) && bSpy[i] && client != i && CheckImmunity(client, i))
	{
		CPrintToChat(i, "%s {lime}%N: {blue}%s {darkblue}%s", sPrefix, client, sCommand, sArgs);
	}
	
	return Plugin_Continue;	
}

bool CheckImmunity(int client, int reciver)
{
	if (!cv_bImmunity.BoolValue)
		return true;
		
	int iImmunityS = GetAdminImmunityLevel(GetUserAdmin(client));
	int iImmunityR = GetAdminImmunityLevel(GetUserAdmin(reciver));
	
	if (iImmunityS > iImmunityR)
		return false;
		
	return true;
}
