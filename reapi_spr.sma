#include <amxmodx>
#include <hamsandwich> 
#include <reapi>
#include <cromchat>

#pragma compress 1

#define VERSION "2.8.1"

new cvar_prefix;
new prefix[64];

new bool:SPRActive[33]=false;
new bool:g_sprStarted = false;
new SprChoice;
new NoScope=false;
new gmsgSetFOV;

//#define REMOVE_WEAPONS
new g_iMaxPlayers 
#define IsPlayer(%1)    ( 1 <= %1 <= g_iMaxPlayers ) 

enum _:g_eWeaponData 
{ 
    _NameForChat[32], 
    _WeaponName[32], 
    _Ammo, 
    WeaponIdType:_CSW 
} 
enum _:g_eWeaponTypes 
{ 
    S 
} 
new const g_szSecondary[][g_eWeaponData]= 
{ 
    {"Glock18",     "weapon_glock18",     240,     WEAPON_GLOCK18}, 
    {"Usp",     "weapon_usp",        240,     WEAPON_USP}, 
    {"P228",     "weapon_p228",        240,     WEAPON_P228}, 
    {"Dual Elites", "weapon_elite",     240,     WEAPON_ELITE}, 
    {"Fiveseven",     "weapon_fiveseven",    240,     WEAPON_FIVESEVEN}, 
    {"Deagle",     "weapon_deagle",     240,     WEAPON_DEAGLE} 
} 
new g_WpnID[g_eWeaponTypes]

public plugin_init() 
{ 
	register_plugin("[ReAPI] Special Round Final", VERSION, "SkY#IN")
	register_cvar("[ReAPI] SpecialRound", VERSION, FCVAR_SERVER|FCVAR_SPONLY|FCVAR_UNLOGGED);

	register_clcmd("say /spr", "SPRMenu", ADMIN_KICK);
	register_clcmd("amx_spr", "SPRMenu", ADMIN_KICK);

	cvar_prefix = register_cvar("amx_spr_prefix", "[SPR]");

	register_event("SetFOV","zoom","b","1<90") //NoZoom Check
	register_clcmd("drop", "PlayerDropCheck");
	RegisterHam(Ham_Spawn, "player", "SpawnPlayer", 1)
	register_logevent("SPREndNow", 2, "1=Round_Start")
	register_logevent("SPREndNow", 2,"1=Round_End") 
	RegisterHam(Ham_Touch, "weaponbox", "BlockWeapons") 
	RegisterHam(Ham_Touch, "armoury_entity", "BlockWeapons") 
	RegisterHam(Ham_Touch, "weapon_shield", "BlockWeapons")
	g_iMaxPlayers = get_maxplayers()
	get_pcvar_string(cvar_prefix, prefix, charsmax(prefix))

	gmsgSetFOV = get_user_msgid( "SetFOV" );
}

public client_putinserver(id)
{
	if(g_sprStarted){
		SPRActive[id] = true;
	}
}

public SpawnPlayer(id)
{
	if(g_sprStarted && SPRActive[id]){
		CC_SendMessage(id, "&x03%s &x04SPR &x03is LIVE &x01So you have &x04received &x03SPR Weapons", prefix)
		set_task(1.0,"GivePlayerItem", id);
	}
}

public SPRMenu(id)
{
	if(!(get_user_flags(id) & ADMIN_KICK))
		return PLUGIN_HANDLED;

	if(g_sprStarted){
		CC_SendMessage(id, "&x04%s &x03SPR Already &x04Running!", prefix);
		return PLUGIN_HANDLED;
	}

	if(!is_user_alive(id)){
		CC_SendMessage(id, "&x04%s &x03You must be alive to use SPR command", prefix)
		return PLUGIN_HANDLED;
	}

	new szMenu[128];
	formatex(szMenu, charsmax(szMenu), "\d[\rAmS GAMiNG\d] \ySpecial Round v%s^n", VERSION);

	new menu = menu_create(szMenu, "SPRHandle")

	menu_additem(menu, "Knife round")  //0
	menu_additem(menu, "Grenade + Knife round")  //1
	menu_additem(menu, "Shotgun round")  //2
	menu_additem(menu, "Deagle round")  //3
	menu_additem(menu, "AWP round")  //4
	menu_additem(menu, "Random Pistol Round")  //5
	menu_additem(menu, "M4A1 round")  //6
	menu_additem(menu, "AK-47 round")  //7
	menu_additem(menu, "TMP round")  //8
	menu_additem(menu, "Unlimated Grenades round") //9 
	menu_additem(menu, "Scout round")// 10
	menu_additem(menu, "No Scope AWP"); // 11

	menu_setprop( menu, MPROP_NUMBER_COLOR, "\y" );
	menu_display( id, menu );

	return PLUGIN_HANDLED;
}

public SPRHandle(id, menu, iItem) 
{ 
	if(iItem == MENU_EXIT){ 
	    menu_destroy(menu); 
	    return PLUGIN_HANDLED; 
	} 

	new SPRName[64];

	switch(iItem)  
	{ 
	    case 0: 
	    {
			copy(SPRName, charsmax(SPRName), "Knife");
	    } 
	    case 1: 
	    { 
			copy(SPRName, charsmax(SPRName), "Grenades & Knife");
	    } 
	    case 2: 
	    { 
			copy(SPRName, charsmax(SPRName), "Shotgun");  
	    } 
	    case 3: 
	    { 
			copy(SPRName, charsmax(SPRName), "Deagle");
	    } 
	    case 4: 
	    { 
			copy(SPRName, charsmax(SPRName), "AWP"); 
	    } 
	    case 5: 
	    { 
			copy(SPRName, charsmax(SPRName), "Random Pistols"); 
	    } 
	    case 6: 
	    { 
			copy(SPRName, charsmax(SPRName), "M4A1");  
	    } 
	    case 7: 
	    { 
			copy(SPRName, charsmax(SPRName), "AK47"); 
	    } 
	    case 8: 
	    { 
			copy(SPRName, charsmax(SPRName), "TMP");           
	    } 
	    case 9: 
	    { 
			copy(SPRName, charsmax(SPRName), "Unlimited Grenades");             
	    }
		case 10:
		{ 
			copy(SPRName, charsmax(SPRName), "Scout");			 
		}
		case 11:
		{
			copy(SPRName, charsmax(SPRName), "No Scope AWP");
		}
	}

	SprChoice = iItem

	GiveWeaponToAll()
	g_sprStarted = true 
	hideBuyIcon()

	set_dhudmessage(random_num(0,255), random_num(0,255), random_num(0,255), -1.0, 0.0, 0, 6.0, 12.0, 0.1, 0.2)
	show_dhudmessage(0, "-=[ Special Round Started ]=-")

	set_dhudmessage(192, 192, 192, -1.0, 0.05, 0, 6.0, 12.0, 0.1, 0.2) 
	show_dhudmessage(0, "[ %s ] Round", SPRName)
	
	new Name[32];
	get_user_name(id, Name, 31);

	CC_SendMessage(0, "&x03%s &x03%s &x04Started &x03%s &x04Round!", prefix, Name, SPRName);
	CC_SendMessage(0, "&x03%s &x04You cannot pickup guns during Special Round!", prefix);

	menu_destroy(menu); 
	return PLUGIN_HANDLED; 
}  

public SPREndNow()
{
    if(g_sprStarted)
    {   
		g_sprStarted = false
		SprChoice = 0

		NoScope=false; 

		EndSpecialRound()
		CC_SendMessage(0, "&x04%s &x03Special Round &x04Ended ", prefix); 

		server_cmd("exec server.cfg")
    }
}

public EndSpecialRound()
{
    new players[32], number, Player//, id
    get_players(players, number,"a")
    
    for(new i=0; i < number; i++)
    {	
        Player = players[i]
        SPRActive[Player]=false;
    	rg_remove_all_items(Player)
    	rg_give_item(Player, "weapon_knife");
    }

}

public GiveWeaponToAll()
{
	new players[32], number, Player//, id
	get_players(players, number,"a")

	for(new i=0; i < number; i++)
	{	
	    Player = players[i]	    
	    SPRActive[Player]=true;
	    GivePlayerItem(Player);
	}
}

public GivePlayerItem(id)
{	
	rg_remove_all_items(id)
	rg_give_item(id, "weapon_knife")

	switch(SprChoice)
    {
        case 0: 
        {  
	        rg_give_item(id, "weapon_knife")       
        } 
        case 1: 
        {
	        rg_give_item(id, "weapon_hegrenade") 
	        rg_give_item(id, "weapon_flashbang") 
	        rg_give_item(id, "weapon_flashbang") 
        }
        case 2: 
        {           
	        rg_give_item(id, "weapon_m3") 
	        rg_give_item(id, "weapon_xm1014") 
	        rg_set_user_bpammo(id,WEAPON_M3,240)   
	        rg_set_user_bpammo(id,WEAPON_XM1014,240)  
        } 
        case 3: 
        {  
	        rg_give_item(id, "weapon_deagle") 
	        rg_set_user_bpammo(id,WEAPON_DEAGLE,240)   
        } 
        case 4: 
        { 
	        rg_give_item(id, "weapon_awp") 
	        rg_set_user_bpammo(id,WEAPON_AWP,240)              
        } 
        case 5: 
        {   
			g_WpnID[S] = random_num(1, charsmax(g_szSecondary))
			rg_give_item(id, g_szSecondary[g_WpnID[S]][_WeaponName]) 
			rg_set_user_bpammo(id, g_szSecondary[g_WpnID[S]][_CSW], g_szSecondary[g_WpnID[S]][_Ammo])
        } 
        case 6: 
        {    
	        rg_give_item(id, "weapon_m4a1") 
	        rg_set_user_bpammo(id,WEAPON_M4A1,240)
        } 
        case 7: 
        { 
	        rg_give_item(id, "weapon_ak47") 
	        rg_set_user_bpammo(id,WEAPON_AK47,240)
        } 
        case 8: 
        { 
			rg_give_item(id, "weapon_tmp") 
			rg_set_user_bpammo(id,WEAPON_TMP,240)  
        } 
        case 9: 
        { 
			rg_give_item(id, "weapon_hegrenade") 
			rg_give_item(id, "weapon_flashbang") 
			rg_give_item(id, "weapon_flashbang") 

			rg_set_user_bpammo(id,WEAPON_HEGRENADE,240)      
        }
        case 10:
        { 
			rg_give_item(id, "weapon_scout") 
			rg_set_user_bpammo(id,WEAPON_SCOUT,240)
        }
        case 11:
        {
        	NoScope=true;
        	rg_give_item(id, "weapon_awp") 
	        rg_set_user_bpammo(id,WEAPON_AWP,240)
        }
    }
}

// NoZoom
public zoom(id) {
	if(NoScope && g_sprStarted)
	{
		message_begin(MSG_ONE, gmsgSetFOV, {0,0,0}, id)
		write_byte(90) //NO Zooming
		message_end()
	}
	return PLUGIN_CONTINUE;
}

// Remove Buy Zone
public hideBuyIcon() 
{ 
	server_cmd("mp_buytime 0.0")
}

public PlayerDropCheck(id)
{
	if(g_sprStarted)
	{
		CC_SendMessage(id, "&x03%s &x04You cannot drop gun during Special Round!", prefix);
		return PLUGIN_HANDLED;
	}
	return PLUGIN_CONTINUE;
}

public BlockWeapons(iEnt, id) 
{ 
	if(g_sprStarted && IsPlayer(id)) 
	{ 
		#if defined REMOVE_WEAPONS 
		set_pev(iEnt, pev_flags, FL_KILLME) 
		dllfunc(DLLFunc_Think, iEnt) 
		#endif 
		return HAM_SUPERCEDE 
	} 
	return HAM_IGNORED 
}