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
    master.Mutex.Lock()
    defer master.Mutex.Unlock()
    master.Games = make(map[string]*Game)
}

func (master *Master) getGames() map[string]*Game {
    master.Mutex.Lock()
    defer master.Mutex.Unlock()
    return master.Games
}

func (master *Master) getGame(gameID string) *Game {
    master.Mutex.Lock()
    defer master.Mutex.Unlock()
    return master.Games[gameID]
}

func (master *Master) addGame(game *Game) {
    master.Mutex.Lock()
    defer master.Mutex.Unlock()

    if game.getGameID() == "" {
        fmt.Printf("game has no gameID")
    } else {
        master.Games[game.getGameID()] = game
    }
}

func (master *Master) removeGame(gameID string) {
    master.Mutex.Lock()
    defer master.Mutex.Unlock()
    _, ok := master.Games[gameID]

    if ok {
        delete(master.Games, gameID)
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
