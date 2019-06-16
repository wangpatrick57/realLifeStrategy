package main

import (
    "fmt"
    "sync"
)

type Master struct {
    Games map[string]*Game
    Mutex sync.Mutex //lock this for actions regarding the entire Games array
}

func (master *Master) constructor() {
    master.Games = make(map[string]*Game)
}

func (master *Master) getGames() map[string]*Game {
    master.mutexLock()
    return master.Games
}

func (master *Master) getGame(gameID string) *Game {
    master.mutexLock()
    return master.Games[gameID]
}

func (master *Master) addGame(game *Game) {
    master.mutexLock()

    if (game.getGameID() == "") {
        fmt.Printf("game has no gameID")
    } else {
        master.Games[game.getGameID()] = game
    }
}

func (master *Master) checkIDTaken(idToCheck string) bool {
    master.Mutex.Lock()
    defer master.Mutex.Unlock()

    for _, g := range master.Games {
        if g.getGameID() == idToCheck {
            return true
        }
    }

    return false
}

func (master *Master) mutexLock() {
    master.Mutex.Lock()
    defer master.Mutex.Unlock()
}
