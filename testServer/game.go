package main

import (
    "fmt"
    "sync"
)

type Game struct {
    GameID string
    Players map[string]*Player
    RespawnPoints []*RespawnPoint
    BorderPoints []*Coord //short for border coords
    Mutex sync.Mutex //lock this for actions regarding these vars and arrays
}

func (game *Game) constructor() {
    game.Mutex.Lock()
    defer game.Mutex.Unlock()
    game.Players = make(map[string]*Player)
    game.RespawnPoints = make([]*RespawnPoint, 0)
    game.BorderPoints = make([]*Coord, 0)
}

func (game *Game) checkNameTaken(nameToCheck string) bool {
    game.Mutex.Lock()
    defer game.Mutex.Unlock()

    for _, p := range game.Players {
        if p.getConnected() && p.getName() == nameToCheck {
            return true
        }
    }

    return false
}

func (game *Game) getGameID() string {
    game.Mutex.Lock()
    defer game.Mutex.Unlock()
    return game.GameID
}

func (game *Game) setGameID(gameID string) {
    game.Mutex.Lock()
    defer game.Mutex.Unlock()
    game.GameID = gameID
}

func (game *Game) getPlayer(name string) *Player {
    game.Mutex.Lock()
    defer game.Mutex.Unlock()
    return game.Players[name]
}

func (game *Game) getPlayers() map[string]*Player {
    game.Mutex.Lock()
    defer game.Mutex.Unlock()
    return game.Players
}

func (game *Game) getPlayerNames() []string {
    game.Mutex.Lock()
    defer game.Mutex.Unlock()
    names := make([]string, len(game.Players))
    index := 0

    for name, _ := range game.Players {
        names[index] = name
        index++
    }

    return names
}

func (game *Game) addPlayer(player *Player) {
    game.Mutex.Lock()
    defer game.Mutex.Unlock()

    if (player.getName() == "") {
        fmt.Printf("player has no name\n")
    } else {
        game.Players[player.getName()] = player
    }
}

func (game *Game) addBorderPoint(index int, lat float64, long float64) {
    game.Mutex.Lock()
    defer game.Mutex.Unlock()
    borderPoint := &Coord{Lat: lat, Long: long}

    for (len(game.BorderPoints) <= index) {
        game.BorderPoints = append(game.BorderPoints, borderPoint)
    }

    game.BorderPoints[index] = borderPoint
}

func (game *Game) getBorderPoints() []*Coord {
    game.Mutex.Lock()
    defer game.Mutex.Unlock()
    return game.BorderPoints
}

func (game *Game) addRespawnPoint(index int, lat float64, long float64) {
    game.Mutex.Lock()
    defer game.Mutex.Unlock()
    borderPoint := &RespawnPoint{Index: index, Lat: lat, Long: long}

    for (len(game.RespawnPoints) <= index) {
        game.RespawnPoints = append(game.RespawnPoints, borderPoint)
    }

    game.RespawnPoints[index] = borderPoint
}

func (game *Game) getRespawnPoints() []*RespawnPoint {
    game.Mutex.Lock()
    defer game.Mutex.Unlock()
    return game.RespawnPoints
}

func (game *Game) bpString(index int) string {
    game.Mutex.Lock()
    defer game.Mutex.Unlock()
    coord := game.BorderPoints[index]
    return fmt.Sprintf("bp:%d:%f:%f:", index, coord.getLat(), coord.getLong())
}

func (game *Game) rpString(index int) string {
    game.Mutex.Lock()
    defer game.Mutex.Unlock()
    respawnPoint := game.RespawnPoints[index]
    return fmt.Sprintf("rp:%d:%f:%f:", index, respawnPoint.getLat(), respawnPoint.getLong())
}

//cleans the players in a game but not the settings for hardcoded games
//for user created games it deletes the game when it is empty
func (game *Game) tryClean() {
    game.Mutex.Lock()
    defer game.Mutex.Unlock()

    for _, p := range game.Players {
        if (p.getConnected()) {
            return
        }
    }

    //hardcoded games
    if (game.GameID == "Home" || game.GameID == "DeAnza") {
        game.Players = make(map[string]*Player)
    } else {
        getMaster().removeGame(game.GameID)
    }
}

//resets the settings, but doesn't clean players or try to delete the game
func (game *Game) resetSettings() {
    game.Mutex.Lock()
    defer game.Mutex.Unlock()
    game.RespawnPoints = make([]*RespawnPoint, 0)
    game.BorderPoints = make([]*Coord, 0)
}
