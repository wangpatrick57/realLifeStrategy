package main

import (
    "sync"
)

type Client struct {
    Game *Game
    Player *Player
    Receiving bool
    ReceivingInitial bool
    Mutex sync.Mutex //lock this for actions regarding receiving, game, or player
}

func (client *Client) getGame() *Game {
    client.mutexLock()
    return client.Game
}

func (client *Client) setGame(game *Game) {
    client.mutexLock()
    client.Game = game
}

func (client *Client) getPlayer() *Player {
    client.mutexLock()
    return client.Player
}

func (client *Client) setPlayer(player *Player) {
    client.mutexLock()
    client.Player = player
}

func (client *Client) getReceiving() bool {
    client.mutexLock()
    return client.Receiving
}

func (client *Client) setReceiving(receiving bool) {
    client.mutexLock()
    client.Receiving = receiving
}

func (client *Client) getReceivingInitial() bool {
    client.mutexLock()
    return client.ReceivingInitial
}

func (client *Client) setReceivingInitial(receivingInitial bool) {
    client.mutexLock()
    client.ReceivingInitial = receivingInitial
}

func (client *Client) playerDisconnectActions() {
    client.mutexLock()

    if (client.Player != nil) {
        client.Player.setConnected(false)
        client.Player.makeSendTrue("conn", client.Game.getPlayers())
    }
}

func (client *Client) mutexLock() {
    client.Mutex.Lock()
    defer client.Mutex.Unlock()
}
