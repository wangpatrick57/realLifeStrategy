package main

import (
    "fmt"
    "sync"
)

type Player struct {
    Name string
    Lat float64
    Long float64
    WardLat float64
    WardLong float64
    Team string
    Dead bool
    Connected bool
    SendWardTo map[string]bool
    SendTeamTo map[string]bool
    SendDeadTo map[string]bool
    SendConnectedTo map[string]bool
    Mutex sync.Mutex //lock this for actions regarding any of these variables
}

func (player *Player) constructor(players map[string]*Player) {
    //can't use mutexLock() function because I need to unlock before doing makeSendTrue
    player.Mutex.Lock()
    player.Connected = true
    player.SendWardTo = make(map[string]bool)
    player.SendTeamTo = make(map[string]bool)
    player.SendDeadTo = make(map[string]bool)
    player.SendConnectedTo = make(map[string]bool)
    player.Mutex.Unlock()

    player.makeSendTrue("ward", players)
    player.makeSendTrue("team", players)
    player.makeSendTrue("dead", players)
    player.makeSendTrue("conn", players)
}

func (player *Player) getName() string {
    player.mutexLock()
    return player.Name
}

func (player *Player) setName(name string) {
    player.mutexLock()
    player.Name = name
}

func (player *Player) getLoc() (float64, float64) {
    player.mutexLock()
    return player.Lat, player.Long
}

func (player *Player) setLoc(lat, long float64) {
    player.mutexLock()
    player.Lat = lat
    player.Long = long
}

func (player *Player) getLat() float64 {
    player.mutexLock()
    return player.Lat
}

func (player *Player) setLat(lat float64) {
    player.mutexLock()
    player.Lat = lat
}

func (player *Player) getLong() float64 {
    player.mutexLock()
    return player.Long
}

func (player *Player) setLong(long float64) {
    player.mutexLock()
    player.Long = long
}

func (player *Player) getWardLoc() (float64, float64) {
    player.mutexLock()
    return player.WardLat, player.WardLong
}

func (player *Player) setWardLoc(lat, long float64) {
    player.mutexLock()
    player.WardLat = lat
    player.WardLong = long
}

func (player *Player) getWardLat() float64 {
    player.mutexLock()
    return player.WardLat
}

func (player *Player) setWardLat(lat float64) {
    player.mutexLock()
    player.WardLat = lat
}

func (player *Player) getWardLong() float64 {
    player.mutexLock()
    return player.WardLong
}

func (player *Player) setWardLong(long float64) {
    player.mutexLock()
    player.WardLong = long
}

func (player *Player) getTeam() string {
    player.mutexLock()
    return player.Team
}

func (player *Player) setTeam(team string) {
    player.mutexLock()
    player.Team = team
}

func (player *Player) getDead() bool {
    player.mutexLock()
    return player.Dead
}

func (player *Player) setDead(dead bool) {
    player.mutexLock()
    player.Dead = dead
}

func (player *Player) getConnected() bool {
    player.mutexLock()
    return player.Connected
}

func (player *Player) setConnected(connected bool) {
    player.mutexLock()
    player.Connected = connected
}

func (player *Player) getSendTo(sendMapString string, name string) (bool, bool) {
    player.mutexLock()
    var sendMap map[string]bool

    if (sendMapString == "ward") {
        sendMap = player.SendWardTo
    } else if (sendMapString == "team") {
        sendMap = player.SendTeamTo
    } else if (sendMapString == "dead") {
        sendMap = player.SendDeadTo
    } else if (sendMapString == "conn") {
        sendMap = player.SendConnectedTo
    } else {
        fmt.Printf("%s is not a valid sendMap\n", sendMapString)
        return false, false
    }

    return sendMap[name], true
}

func (player *Player) setSendTo(sendMapString string, name string, sendTo bool) {
    player.mutexLock()
    var sendMap map[string]bool

    if (sendMapString == "ward") {
        sendMap = player.SendWardTo
    } else if (sendMapString == "team") {
        sendMap = player.SendTeamTo
    } else if (sendMapString == "dead") {
        sendMap = player.SendDeadTo
    } else if (sendMapString == "conn") {
        sendMap = player.SendConnectedTo
    } else {
        fmt.Printf("%s is not a valid sendMap\n", sendMapString)
    }

    sendMap[name] = sendTo
}

func (player *Player) makeSendTrue(sendMapString string, players map[string]*Player) {
    player.mutexLock()
    var sendMap map[string]bool

    if (sendMapString == "ward") {
        sendMap = player.SendWardTo
    } else if (sendMapString == "team") {
        sendMap = player.SendTeamTo
    } else if (sendMapString == "dead") {
        sendMap = player.SendDeadTo
    } else if (sendMapString == "conn") {
        sendMap = player.SendConnectedTo
    } else {
        fmt.Printf("%s is not a valid sendMap\n", sendMapString)
        return
    }

    for _, p := range players {
        if p != player { //checking p != player so that there's no mutex lock within a mutex lock
            sendMap[p.getName()] = true
        }
    }
}

func (player *Player) initialPlayerString() string {
    player.mutexLock()
    //conn has to be before everything and team has to be before ward
    ret := fmt.Sprintf("loc:%s:%f:%f:conn:%s:%t:team:%s:%s:dead:%s:%t:", player.Name, player.Lat, player.Long,
        player.Name, player.Connected, player.Name, player.Team, player.Name, player.Dead)

    if (player.WardLat != 0 || player.WardLong != 0) {
        ret += fmt.Sprintf("ward:%s:%f:%f:", player.Name, player.WardLat, player.WardLong)
    }

    return ret
}

func (player *Player) mutexLock() {
    player.Mutex.Lock()
    defer player.Mutex.Unlock()
}
