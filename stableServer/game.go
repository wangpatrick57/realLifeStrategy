package main

import (
    "fmt"
    "sync"
)

type Game struct {
    GameID string
    Players map[string]*Player
    RespawnPoints []*RespawnPoint
    Mutex sync.Mutex //lock this for actions regarding these vars and arrays
}

func (game *Game) constructor() {
    game.mutexLock()
    game.Players = make(map[string]*Player)
}

func (game *Game) checkNameTaken(nameToCheck string) bool {
    game.mutexLock()

    for _, p := range game.Players {
        if p.getConnected() && p.getName() == nameToCheck {
            return true
        }
    }

    return false
}

func (game *Game) getGameID() string {
    game.mutexLock()
    return game.GameID
}

func (game *Game) setGameID(gameID string) {
    game.mutexLock()
    game.GameID = gameID
}

func (game *Game) getPlayer(name string) *Player {
    game.mutexLock()
    return game.Players[name]
}

func (game *Game) getPlayers() map[string]*Player {
    game.mutexLock()
    return game.Players
}

func (game *Game) addPlayer(player *Player) {
    game.mutexLock()

    if (player.getName() == "") {
        fmt.Printf("player has no name\n")
    } else {
        game.Players[player.getName()] = player
    }
}

func (game *Game) rpString() string {
    game.mutexLock()
    ret := ""

    for _, rp := range game.RespawnPoints {
        ret += fmt.Sprintf("rp:%f:%f:", rp.getLat(), rp.getLong())
    }

    return ret
}

func (game *Game) tryClean() {
    game.mutexLock()

    for _, p := range game.Players {
        if (p.getConnected()) {
            return
        }
    }

    //hardcoding special games
    if (game.GameID == "Home" || game.GameID == "DeAnza") {
        game.Players = make(map[string]*Player)
    } else {
        master.removeGame(game.GameID)
    }
}

func (game *Game) mutexLock() {
    game.Mutex.Lock()
    defer game.Mutex.Unlock()
}
