package main

import (
    "fmt"
    "sync"
)

type Master struct {
    Games []*Game
    Mutex sync.Mutex //lock this for actions regarding the entire Games array
}

func (master *Master) getGames() []*Game {
    master.mutexLock()
    return master.Games
}

func (master *Master) getGame(gameID string) *Game {
    master.mutexLock()

    for _, g := range master.Games {
        if (g.getGameID() == gameID) {
            return g
        }
    }

    fmt.Printf("game %s doesn't exist\n", gameID)
    tmp := Game{}
    return &tmp
}

func (master *Master) addGame(game *Game) {
    master.mutexLock()
    master.Games = append(master.Games, game)
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
