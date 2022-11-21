#pragma newdecls required
#pragma semicolon 1
#include <sdkhooks>
#include <dhooks>
#undef REQUIRE_EXTENSIONS
#include <cstrike>
#include <vip_core>

public Plugin myinfo = {
	name = "[VIP] AWP Manager",
	author = "Delfram",
	version = "v1.0.1",
	url = "github.com/Delfram99/Awp-Manager"
}

bool hookHook = false;
bool IsCSGO = false;

Handle hookGetClipAmmoMax;
Handle hookGetReserveAmmoMax;

int gEntityHookID[2049][2];

bool g_iCvar_EnableAwpManagerForAll;
int g_iCvar_AwpClipAmmoForAll;
int g_iCvar_AwpReserveAmmoForAll;

static const char g_sFeature[][] = {"AwpManagerClip", "AwpManagerReserve"};

public void OnPluginStart() {
	int offset;
	IsCSGO = (GetEngineVersion() == Engine_CSGO);
	Handle config = LoadGameConfigFile("ammomanager.gamedata");
	
	if((offset = GameConfGetOffset(config, "Clip")) != -1) {
		hookGetClipAmmoMax = DHookCreate(offset, HookType_Entity, ReturnType_Int, ThisPointer_CBaseEntity, HookCallBack_GetClipAmmoMax);
	}

	if((offset = GameConfGetOffset(config, "Reserve")) != -1) {
		hookGetReserveAmmoMax = DHookCreate(offset, HookType_Entity, ReturnType_Int, ThisPointer_CBaseEntity, HookCallBack_GetReserveAmmoMax);
		DHookAddParam(hookGetReserveAmmoMax, HookParamType_Unknown);
	}

	if(!hookGetClipAmmoMax && !hookGetReserveAmmoMax) {
		CloseHandle(config);
		SetFailState("No offsets");
		return;
	}

	int bits = GameConfGetOffset(config, "CSendProp::m_nBits");
	
	if(bits != -1) {
		Address addr = GameConfGetAddress(config, "g_SendTableCRC");
		
		if(addr) {
			StoreToAddress(addr, 1337, NumberType_Int32);
			
			addr = GameConfGetAddress(config, "m_iClip1");
			if(addr) {
				StoreToAddress(addr + view_as<Address>(bits), 32, NumberType_Int32);
			}
			
			ConVar cvar = FindConVar("sv_sendtables");
			cvar.BoolValue = true;
			HookConVarChange(cvar, ConVarChange);
		}
	}
	CloseHandle(config);
	
	LoadTranslations("vip_modules.phrases");

	if(VIP_IsVIPLoaded()) {
		VIP_OnVIPLoaded();
	}
}

public void VIP_OnVIPLoaded() {
	VIP_RegisterFeature(g_sFeature[0], INT, _, _, OnItemDisplay);
	VIP_RegisterFeature(g_sFeature[1], INT, _, _, OnItemDisplay);
}

public bool OnItemDisplay(int iClient, const char[] sFeatureName, char[] sDisplay, int iMaxLen) {
	if(VIP_IsClientFeatureUse(iClient, sFeatureName)) {
		FormatEx(sDisplay, iMaxLen, "%t [%i] [+]", sFeatureName, VIP_GetClientFeatureInt(iClient, sFeatureName));
		return true;
	} else {
		FormatEx(sDisplay, iMaxLen, "%t [%i] [-]", sFeatureName, VIP_GetClientFeatureInt(iClient, sFeatureName));
		return true;
	}
}

public void ConVarChange(ConVar convar, const char[] oldValue, const char[] newValue) {
	if(hookHook) {
		return;	
	}
	hookHook = true;
	convar.BoolValue = true;
	hookHook = false;
}

public void OnMapStart() {
	char sBuffer[256];
	Handle hKeyValues;

	hKeyValues = CreateKeyValues("AwpManager");
	BuildPath(Path_SM, sBuffer, sizeof(sBuffer), "data/vip/modules/awp_manager.ini");
	if (FileToKeyValues(hKeyValues, sBuffer) == false) {
		SetFailState("Failed to open file \"%s\"", sBuffer);
	}
	KvRewind(hKeyValues);

	g_iCvar_EnableAwpManagerForAll = view_as<bool>(KvGetNum(hKeyValues, "enable_awp_manager_forall"));
	g_iCvar_AwpClipAmmoForAll = KvGetNum(hKeyValues, "awp_clip_ammo_forall");
	g_iCvar_AwpReserveAmmoForAll = KvGetNum(hKeyValues, "awp_reserve_ammo_forall");
	
	CloseHandle(hKeyValues);
}

public void OnEntityCreated(int entity, const char[] classname) {
	if(0 < entity < 2049 && !strncmp(classname, "weapon_", 7)) {
		SDKHook(entity, SDKHook_SpawnPost, WeaponCreatedPost);
		gEntityHookID[entity][0] = gEntityHookID[entity][1] = -1;
	}
}

public void WeaponCreatedPost(int entity) {
	SDKUnhook(entity, SDKHook_SpawnPost, WeaponCreatedPost);
	char weapon[64] = "weapon_";

	if(IsCSGO) {
		CS_WeaponIDToAlias(CS_ItemDefIndexToID(GetEntProp(entity, Prop_Send, "m_iItemDefinitionIndex")), weapon[7], sizeof(weapon) - 7);
	}
	else {
		GetEntityClassname(entity, weapon, sizeof(weapon));
	}

	if(hookGetClipAmmoMax && StrEqual(weapon, "weapon_awp", true)) {
		gEntityHookID[entity][0] = DHookEntity(hookGetClipAmmoMax, false, entity);
	}
	if(hookGetReserveAmmoMax && StrEqual(weapon, "weapon_awp", true)) {
		gEntityHookID[entity][1] = DHookEntity(hookGetReserveAmmoMax, false, entity);
	}
}


public MRESReturn HookCallBack_GetClipAmmoMax(int entity, Handle hReturn) {
	int iClient = GetEntPropEnt(entity, Prop_Data, "m_hOwner");

	if(iClient != -1 && VIP_IsClientVIP(iClient) && VIP_IsClientFeatureUse(iClient, g_sFeature[0])) {
		DHookSetReturn(hReturn, VIP_GetClientFeatureInt(iClient, g_sFeature[0]));
		return MRES_Supercede;
	} else if(iClient != -1 && g_iCvar_EnableAwpManagerForAll) {
		DHookSetReturn(hReturn, g_iCvar_AwpClipAmmoForAll);
		return MRES_Supercede;
	}
	return MRES_Ignored;
}

public MRESReturn HookCallBack_GetReserveAmmoMax(int entity, Handle hReturn, Handle hParams) {
	int iClient = GetEntPropEnt(entity, Prop_Data, "m_hOwner");
	
	if(iClient != -1 && VIP_IsClientVIP(iClient) && VIP_IsClientFeatureUse(iClient, g_sFeature[1])) {
		DHookSetReturn(hReturn, VIP_GetClientFeatureInt(iClient, g_sFeature[1]));
		return MRES_Supercede;
	} else if(iClient != -1 && g_iCvar_EnableAwpManagerForAll) {
		DHookSetReturn(hReturn, g_iCvar_AwpReserveAmmoForAll);
		return MRES_Supercede;
	}
	return MRES_Ignored;
}

public void OnPluginEnd() {
	if (CanTestFeatures() && GetFeatureStatus(FeatureType_Native, "VIP_UnregisterFeature") == FeatureStatus_Available) {
		VIP_UnregisterFeature(g_sFeature[0]);
		VIP_UnregisterFeature(g_sFeature[1]);
	}
}