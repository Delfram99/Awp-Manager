# AWP Manager
This is a module for CS:GO [VIP Core](https://github.com/R1KO/VIP-Core/tree/v3.0.3R) that allows you to change the number of ammo in the clip and reserve, both for VIP and for ordinary players.
## Requirements
* Sourcemod 1.10+ and Metamod
* [Dhooks2](https://github.com/peace-maker/DHooks2/releases)
* [[VIP] Core 3.0+](https://github.com/R1KO/VIP-Core/tree/v3.0.3R)

## Installation
1. Unzip the latest [release](https://github.com/Delfram99/Awp-Manager/releases) to your sourcemod folder
2. Write the keys for your VIP groups in `groups.ini` 
```
"AwpManagerClip"    "7"     // how many ammo per AWP clip for VIP players
"AwpManagerReserve" "30"    // how many ammo per AWP reserve for VIP players
```
3. Add translations to `vip_modules.phrases.txt`
```
"AwpManagerClip"
{
    "en"    "[AWP] Ammo in clip"
    "ru"    "[AWP] Патроны в Обойме"
}
"AwpManagerReserve"
{
    "en"    "[AWP] Ammo in reserve"
    "ru"    "[AWP] Патроны в Запасе"
}
```
4. Customize `awp_manager.ini` for yourself
```
"AwpManager"
{
    "enable_awp_manager_forall" "0"     // enable ammo replacement for ordinary players, 1 - Yes, 0 - No
    "awp_clip_ammo_forall"      "5"     // how many ammo per AWP clip for ordinary players, 5 default
    "awp_reserve_ammo_forall"   "30"    // how many ammo per AWP reserve for ordinary players, 30 default
}
```
5. Done, restart your server OR load manualy `sm plugins load vip_awp_manager` and update VIP cfg settings `sm_reload_vip_cfg`