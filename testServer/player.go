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
    SendDCTo map[string]bool
    Mutex sync.Mutex //lock this for actions regarding any of these variables
}

func (player *Player) constructor(playerNames []string) {
    player.Mutex.Lock()
    player.Connected = true
    player.Dead = false //this is redundant cuz dead is false by default but it shows that it's supposed to have a default value
    player.SendWardTo = make(map[string]bool)
    player.SendTeamTo = make(map[string]bool)
    player.SendDeadTo = make(map[string]bool)
    player.SendDCTo = make(map[string]bool)
    player.Mutex.Unlock()

    //can't lock mutex here cuz i wanna use the makeSendTrue function
    player.makeSendTrue("ward", playerNames)
    player.makeSendTrue("team", playerNames)
    player.makeSendTrue("dead", playerNames)

    player.Mutex.Lock()
    defer player.Mutex.Unlock()
}

func (player *Player) getName() string {
    player.Mutex.Lock()
    defer player.Mutex.Unlock()
    return player.Name
}

func (player *Player) setName(name string) {
    player.Mutex.Lock()
    defer player.Mutex.Unlock()
    player.Name = name
}

func (player *Player) getLoc() (float64, float64) {
    player.Mutex.Lock()
    defer player.Mutex.Unlock()
    return player.Lat, player.Long
}

func (player *Player) setLoc(lat, long float64) {
    player.Mutex.Lock()
    defer player.Mutex.Unlock()
    player.Lat = lat
    player.Long = long
}

func (player *Player) getLat() float64 {
    player.Mutex.Lock()
    defer player.Mutex.Unlock()
    return player.Lat
}

func (player *Player) setLat(lat float64) {
    player.Mutex.Lock()
    defer player.Mutex.Unlock()
    player.Lat = lat
}

func (player *Player) getLong() float64 {
    player.Mutex.Lock()
    defer player.Mutex.Unlock()
    return player.Long
}

func (player *Player) setLong(long float64) {
    player.Mutex.Lock()
    defer player.Mutex.Unlock()
    player.Long = long
}

func (player *Player) getWardLoc() (float64, float64) {
    player.Mutex.Lock()
    defer player.Mutex.Unlock()
    return player.WardLat, player.WardLong
}

func (player *Player) setWardLoc(lat, long float64) {
    player.Mutex.Lock()
    defer player.Mutex.Unlock()
    player.WardLat = lat
    player.WardLong = long
}

func (player *Player) getWardLat() float64 {
    player.Mutex.Lock()
    defer player.Mutex.Unlock()
    return player.WardLat
}

func (player *Player) setWardLat(lat float64) {
    player.Mutex.Lock()
    defer player.Mutex.Unlock()
    player.WardLat = lat
}

func (player *Player) getWardLong() float64 {
    player.Mutex.Lock()
    defer player.Mutex.Unlock()
    return player.WardLong
}

func (player *Player) setWardLong(long float64) {
    player.Mutex.Lock()
    defer player.Mutex.Unlock()
    player.WardLong = long
}

func (player *Player) getTeam() string {
    player.Mutex.Lock()
    defer player.Mutex.Unlock()
    return player.Team
}

func (player *Player) setTeam(team string) {
    player.Mutex.Lock()
    defer player.Mutex.Unlock()
    player.Team = team
}

func (player *Player) getDead() bool {
    player.Mutex.Lock()
    defer player.Mutex.Unlock()
    return player.Dead
}

func (player *Player) setDead(dead bool) {
    player.Mutex.Lock()
    defer player.Mutex.Unlock()
    player.Dead = dead
}

func (player *Player) getConnected() bool {
    player.Mutex.Lock()
    defer player.Mutex.Unlock()
    return player.Connected
}

func (player *Player) setConnected(connected bool) {
    player.Mutex.Lock()
    defer player.Mutex.Unlock()
    player.Connected = connected
}

func (player *Player) getSendTo(sendMapString string, name string) (bool, bool) {
    player.Mutex.Lock()
    defer player.Mutex.Unlock()
    var sendMap map[string]bool

    if (sendMapString == "ward") {
        sendMap = player.SendWardTo
    } else if (sendMapString == "team") {
        sendMap = player.SendTeamTo
    } else if (sendMapString == "dead") {
        sendMap = player.SendDeadTo
    } else if (sendMapString == "dc") {
        sendMap = player.SendDCTo
    } else {
        fmt.Printf("%s is not a valid sendMap\n", sendMapString)
        return false, false
    }

    return sendMap[name], true
}

func (player *Player) setSendTo(sendMapString string, name string, sendTo bool) {
    player.Mutex.Lock()
    defer player.Mutex.Unlock()
    var sendMap map[string]bool

    if (sendMapString == "ward") {
        sendMap = player.SendWardTo
    } else if (sendMapString == "team") {
        sendMap = player.SendTeamTo
    } else if (sendMapString == "dead") {
        sendMap = player.SendDeadTo
    } else if (sendMapString == "dc") {
        sendMap = player.SendDCTo
    } else {
        fmt.Printf("%s is not a valid sendMap\n", sendMapString)
    }

    sendMap[name] = sendTo
}

func (player *Player) makeSendTrue(sendMapString string, playerNames []string) {
    player.Mutex.Lock()
    defer player.Mutex.Unlock()
    var sendMap map[string]bool

    if (sendMapString == "ward") {
        sendMap = player.SendWardTo
    } else if (sendMapString == "team") {
        sendMap = player.SendTeamTo
    } else if (sendMapString == "dead") {
        sendMap = player.SendDeadTo
    } else if (sendMapString == "dc") {
        sendMap = player.SendDCTo
    } else {
        fmt.Printf("%s is not a valid sendMap\n", sendMapString)
        return
    }

    for _, name := range playerNames {
        if name != player.Name { //checking p != player so that there's no mutex lock within a mutex lock
            sendMap[name] = true
        }
    }
}

func (player *Player) initialPlayerString() string {
    player.Mutex.Lock()
    defer player.Mutex.Unlock()
    //conn has to be before everything and team has to be before ward
    ret := fmt.Sprintf("%d:%s:%f:%f:%d:%s:%s:%d:%s:%t:", LOC, player.Name, player.Lat, player.Long,
        TEAM, player.Name, player.Team, DEAD, player.Name, player.Dead)

    if (player.WardLat != 0 || player.WardLong != 0) {
        ret += fmt.Sprintf("%d:%s:%f:%f:", WARD, player.Name, player.WardLat, player.WardLong)
    }

    return ret
}
