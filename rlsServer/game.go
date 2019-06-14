package main

import (
    "fmt"
    "sync"
)

type Game struct {
    GameID string
    Players []*Player
    RespawnPoints []*RespawnPoint
    Mutex sync.Mutex //lock this for actions regarding these vars and arrays
}

func (game *Game) checkNameTaken(nameToCheck string) bool {
    game.mutexLock()

    for _, p := range game.Players {
        if p.getName() == nameToCheck {
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

    for i := 0; i < len(game.Players); i++ {
        player := game.Players[i]

        if (player.getName() == name) {
            return player
        }
    }

    fmt.Printf("player %s in game %s doesn't exist\n", name, game.GameID)
    tmp := Player{}
    return &tmp
}

func (game *Game) getPlayers() []*Player {
    game.mutexLock()
    return game.Players
}

func (game *Game) addPlayer(player *Player) {
    game.mutexLock()
    game.Players = append(game.Players, player)
}

func (game *Game) rpString() string {
    game.mutexLock()
    ret := ""

    for _, rp := range game.RespawnPoints {
        ret += fmt.Sprintf("rp:%f:%f:", rp.getLat(), rp.getLong())
    }

    return ret
}

func (game *Game) mutexLock() {
    game.Mutex.Lock()
    defer game.Mutex.Unlock()
}
