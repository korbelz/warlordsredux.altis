//db EH
"fundsDatabaseClients" addPublicVariableEventHandler {
	[] spawn BIS_fnc_WL2_refreshOSD;
};

//Voice system EH
player addEventHandler ["GetInMan", {
	params ["_unit", "_role", "_vehicle", "_turret"];
	VIC_ENTERED = true;
	if ((typeOf _vehicle == "B_Plane_Fighter_01_F") || {(typeOf _vehicle == "B_Plane_CAS_01_dynamicLoadout_F") || {(typeOf _vehicle == "B_Heli_Attack_01_dynamicLoadout_F") || {(typeOf _vehicle == "B_T_VTOL_01_armed_F") || {(typeOf _vehicle == "B_T_VTOL_01_vehicle_F") || {(typeOf _vehicle == "B_T_VTOL_01_infantry_F")}}}}}) then  {
		[["voiceWarningSystem", "betty"], 0, "", 25, "", false, true, false, true] call BIS_fnc_advHint;
		0 spawn BIS_fnc_WL2_betty;
	};
	if ((typeOf _vehicle == "O_Plane_Fighter_02_F") || {(typeOf _vehicle == "O_Plane_CAS_02_dynamicLoadout_F") || {(typeOf _vehicle == "O_Heli_Attack_02_dynamicLoadout_F") || {(typeOf _vehicle == "O_T_VTOL_02_vehicle_dynamicLoadout_F")}}}) then {
		[["voiceWarningSystem", "rita"], 0, "", 25, "", false, true, false, true] call BIS_fnc_advHint;
		0 spawn BIS_fnc_WL2_rita;
	};
}];

//Inv block EH
player addEventHandler ["InventoryOpened",{
	params ["_unit","_container"];
	_override = false;
	_allUnitBackpackContainers = (player nearEntities ["Man", 50]) select {isPlayer _x} apply {backpackContainer _x};

	if (_container in _allUnitBackpackContainers) then {
		systemchat "Access denied!";
		_override = true;
	};
	_override;
}];

//Last loadout EH
player addEventHandler ["Killed", {
	BIS_WL_loadoutApplied = FALSE;
	["RequestMenu_close"] call BIS_fnc_WL2_setupUI;
	
	BIS_WL_lastLoadout = +getUnitLoadout player;
	private _varName = format ["BIS_WL_purchasable_%1", BIS_WL_playerSide];
	private _gearArr = (missionNamespace getVariable _varName) # 5;
	private _lastLoadoutArr = _gearArr # 0;
	private _text = _savedLoadoutArr # 5;
	private _text = localize "STR_A3_WL_last_loadout_info";
	_text = _text + "<br/><br/>";
	{
		switch (_forEachIndex) do {
			case 0;
			case 1;
			case 2;
			case 3;
			case 4: {
				if (count _x > 0) then {
					_text = _text + (getText (configFile >> "CfgWeapons" >> _x # 0 >> "displayName")) + "<br/>";
				};
			};
			case 5: {
				if (count _x > 0) then {
					_text = _text + (getText (configFile >> "CfgVehicles" >> _x # 0 >> "displayName")) + "<br/>";
				};
			};
		};
	} forEach BIS_WL_lastLoadout;
	_lastLoadoutArr set [5, _text];
	_gearArr set [0, _lastLoadoutArr];
	(missionNamespace getVariable _varName) set [5, _gearArr];

	_connectedUAV = getConnectedUAV player;
	if (_connectedUAV != objNull) exitWith {
		player connectTerminalToUAV objNull;
	};
}];

//Safezone EH
player addEventHandler ["HandleDamage", {
	params ["_unit", "_selection", "_damage", "_source", "_projectile", "_hitIndex", "_instigator", "_hitPoint", "_directHit"];
	_base = (([BIS_WL_base1, BIS_WL_base2] select {(_x getVariable "BIS_WL_owner") == (side group _unit)}) # 0);
	if ((_unit inArea (_base getVariable "objectAreaComplete")) && {((_base getVariable ["BIS_WL_baseUnderAttack", false]) == false)}) then {
		0;
	} else {
		_damage;
	};
}];

addMissionEventHandler ["HandleChatMessage", {
	params ["_channel", "_owner", "_from", "_text"];
	_text = toLower _text;
	_list = getArray (missionConfigFile >> "adminFilter");
	((_list findIf {[_x, _text] call BIS_fnc_inString}) != -1);
}];

//Key press EH
0 spawn {
	waituntil {sleep 0.1; !isnull (findDisplay 46)};
	(findDisplay 46) displayAddEventHandler ["KeyDown", {
		params ["_displayorcontrol", "_key", "_shift", "_ctrl", "_alt"];
		private _e = false;
		private _settingsKey = actionKeys "user2";
		private _groupKey = actionKeys "user3";
		private _emotesKey = actionKeys "user4";
		private _zeusKey = actionKeys "curatorInterface";
		private _viewKey = actionKeys "tacticalView";
		_e = ((_key in _viewKey || {_key in _zeusKey}) && {!((getPlayerUID player) in (getArray (missionConfigFile >> "adminIDs")))});

		if (inputAction "cycleThrownItems" > 0.01) exitWith {
			[vehicle player, 0, false] spawn DAPS_fnc_Report;
		};

		if (_key in actionKeys "Gear" && {!(missionNamespace getVariable ["BIS_WL_gearKeyPressed", false]) && {alive player && {lifeState player != "INCAPACITATED" && {!BIS_WL_penalized}}}}) then {
			if !(isNull (uiNamespace getVariable ["BIS_WL_purchaseMenuDisplay", displayNull])) then {
				["RequestMenu_close"] call BIS_fnc_WL2_setupUI;
			} else {
				BIS_WL_gearKeyPressed = TRUE;
				0 spawn {
					_t = time + 0.5;
					waitUntil {!BIS_WL_gearKeyPressed || {time >= _t}};
					if (time < _t) then {
						if (isNull findDisplay 602) then {
							if (vehicle player == player) then {
								if (cursorTarget distanceSqr player <= 25 && {!(cursorTarget isKindOf "House") && {(!alive cursorTarget || {!(cursorTarget isKindOf "Man")})}}) then {
									player action ["Gear", cursorTarget];
								} else {
									player action ["Gear", objNull];
								};
							} else {
								vehicle player action ["Gear", vehicle player];
							};
						} else {
							closeDialog 602;
						};
					} else {
						if (BIS_WL_gearKeyPressed && {!(player getVariable ["BIS_WL_menuLocked", false])}) then {
							if (BIS_WL_currentSelection in [0, 2]) then {
								["RequestMenu_open"] call BIS_fnc_WL2_setupUI;
							} else {
								playSound "AddItemFailed";
								_action = switch (BIS_WL_currentSelection) do {
									case 1: {localize "STR_A3_WL_popup_voting"};
									case 3;
									case 8: {localize "STR_A3_WL_action_destination_select"};
									case 4;
									case 5;
									case 7: {localize "STR_A3_WL_action_scan_select"};
									default {""};
								};
								[toUpper format [(localize "STR_A3_WL_another_action") + (if (_action == "") then {"."} else {" (%1)."}), _action]] spawn BIS_fnc_WL2_smoothText;
							};
						};
					};
				};
			};
			_e = true;
		};
		
		if (_key in _settingsKey) exitWith {
			private _d = [4000, 5000, 6000, 7000, 8000];
			{
				if !(isNull (findDisplay _x)) then {
					(findDisplay _x) closeDisplay 1;
				};
			} forEach _d;
			0 spawn MRTM_fnc_openMenu;
		};
		if (_key in _groupKey) exitWith {
			private _d = [4000, 5000, 6000, 7000, 8000];
			{
				if !(isNull (findDisplay _x)) then {
					(findDisplay _x) closeDisplay 1;
				};
			} forEach _d;
			true spawn MRTM_fnc_openGroupMenu;
		};
		if (_key in _emotesKey) exitWith {
			private _d = [4000, 5000, 6000, 7000, 8000];
			{
				if !(isNull (findDisplay _x)) then {
					(findDisplay _x) closeDisplay 1;
				};
			} forEach _d;
			0 spawn MRTM_fnc_openEmoteMenu;
		};
		_e;
	}];
};

missionNamespace setVariable ["BIS_WL2_rearmTimers", 
	createHashMapFromArray [
		//Artillary
		["B_Mortar_01_F", 900], ["O_Mortar_01_F", 900], ["B_MBT_01_arty_F", 1800], 
		["O_MBT_02_arty_F", 1800], ["B_MBT_01_mlrs_F", 1800], ["I_Truck_02_MRL_F", 1800], 
		["B_Ship_Gun_01_F", 2700], ["B_Ship_MRLS_01_F", 2700],
		//AAA & SAM
		["B_AAA_System_01_F", 300], ["B_SAM_System_03_F", 450], ["O_SAM_System_04_F", 450], 
		["B_SAM_System_01_F", 600], ["B_SAM_System_02_F", 900],
		//Armed Vehicles
		["B_LSV_01_armed_F", 120], ["B_G_Offroad_01_armed_F", 120], ["B_LSV_01_AT_F", 200], ["B_G_Offroad_01_AT_F", 180],
		["B_MRAP_01_hmg_F", 300], ["B_MRAP_01_gmg_F", 300], ["B_APC_Wheeled_03_cannon_F", 500], ["B_APC_Wheeled_01_cannon_F", 600], ["B_APC_Tracked_01_rcws_F", 400], ["B_APC_Tracked_01_AA_F", 500],
		["B_AFV_Wheeled_01_cannon_F", 550], ["B_AFV_Wheeled_01_up_cannon_F", 600], ["B_MBT_01_cannon_F", 600], ["B_MBT_01_TUSK_F", 650],
		["O_LSV_02_armed_F", 120], ["O_G_Offroad_01_armed_F", 120], ["O_LSV_02_AT_F", 200], ["O_G_Offroad_01_AT_F", 180],
		["O_MRAP_02_hmg_F", 300], ["O_MRAP_02_gmg_F", 300], ["O_APC_Wheeled_02_rcws_v2_F", 400], ["O_APC_Tracked_02_cannon_F", 500], ["O_APC_Tracked_02_AA_F", 500], ["O_MBT_02_cannon_F", 600],
		["O_MBT_04_cannon_F", 650], ["O_MBT_04_command_F", 700], ["O_MBT_02_railgun_F", 700],
		//Aircraft	
		["B_Heli_Light_01_dynamicLoadout_F", 300], ["B_UAV_02_dynamicLoadout_F", 500], ["B_Heli_Attack_01_dynamicLoadout_F", 700], ["B_T_UAV_03_dynamicLoadout_F", 600], ["B_UAV_05_F", 500],
		["B_T_VTOL_01_armed_F", 600], ["B_Plane_CAS_01_dynamicLoadout_F", 900], ["B_Plane_Fighter_01_F", 900], ["B_Plane_Fighter_01_Stealth_F", 900],
		["O_Heli_Light_02_dynamicLoadout_F", 300], ["O_T_UAV_04_CAS_F", 500], ["O_Heli_Attack_02_dynamicLoadout_F", 700], ["O_UAV_02_dynamicLoadout_F", 330], ["O_T_VTOL_02_vehicle_dynamicLoadout_F", 700],
		["O_Plane_CAS_02_dynamicLoadout_F", 900], ["O_Plane_Fighter_02_F", 900], ["O_Plane_Fighter_02_Stealth_F", 900]
	]
];